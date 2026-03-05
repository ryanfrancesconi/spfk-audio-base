// Copyright Ryan Francesconi. All Rights Reserved. Revision History at https://github.com/ryanfrancesconi/spfk-audio-base

import AVFoundation
import Foundation
import SPFKBase

/// Streams an audio file in fixed-size chunks, delivering PCM sample buffers
/// via an event handler.
///
/// Used by analysis engines (BPM detection, musical key detection) to process
/// audio incrementally without loading the entire file into memory. Emits
/// progress, periodic progress, data, and completion events.
///
/// When `minimumDuration` is set and the file is shorter than half that value,
/// the scanner loops by seeking back to frame 0 on EOF, providing enough
/// material for analysis algorithms that require a minimum input length.
public struct AudioFileScanner: Sendable {
    private let bufferDuration: TimeInterval
    private let minimumDuration: TimeInterval?
    private var sendPeriodicProgressEvery: UInt32
    private let eventHandler: AudioFileScannerEventHandler

    /// Creates a scanner for streaming audio file data.
    ///
    /// - Parameters:
    ///   - bufferDuration: The duration in seconds of each chunk delivered to the event handler.
    ///   - sendPeriodicProgressEvery: Interval in seconds (of processed audio, not wall time)
    ///     between ``AudioFileScannerEvent/periodicProgress(url:value:)`` events.
    ///   - minimumDuration: When non-nil and the file is shorter than half this value,
    ///     the scanner loops by seeking back to frame 0 until the target duration is reached.
    ///   - eventHandler: Async callback that receives scanner events.
    public init(
        bufferDuration: TimeInterval = 0.2,
        sendPeriodicProgressEvery: TimeInterval = 4,
        minimumDuration: TimeInterval? = nil,
        eventHandler: @escaping AudioFileScannerEventHandler
    ) {
        self.bufferDuration = max(0.1, bufferDuration)
        self.minimumDuration = minimumDuration
        self.sendPeriodicProgressEvery = UInt32(max(1, sendPeriodicProgressEvery))
        self.eventHandler = eventHandler
    }

    /// Opens the audio file at `url` and streams its contents through the event handler.
    ///
    /// - Parameter url: A file URL for any audio format supported by Core Audio.
    /// - Throws: If the file cannot be opened or read.
    public func process(url: URL) async throws {
        try await process(audioFile: AVAudioFile(forReading: url))
    }

    /// Streams the contents of an already-opened audio file through the event handler.
    ///
    /// The file's `framePosition` is saved before scanning and restored afterward.
    /// Supports cooperative cancellation via `Task.checkCancellation()`.
    ///
    /// - Parameter audioFile: An open `AVAudioFile` to scan.
    /// - Throws: If the file contains no audio data, or if the task is cancelled.
    public func process(audioFile: AVAudioFile) async throws {
        // store the current frame before scanning the file
        let currentFrame = audioFile.framePosition

        defer {
            // return the file to frame is was on previously
            audioFile.framePosition = currentFrame
        }

        try await _process(audioFile: audioFile)

        await eventHandler(.complete(url: audioFile.url))
    }

    private func _process(audioFile: AVAudioFile) async throws {
        let url = audioFile.url
        let totalFrames = AVAudioFrameCount(audioFile.length)
        let pcmFormat: AVAudioFormat = audioFile.processingFormat

        guard totalFrames > 0 else {
            throw NSError(description: "No audio was found in \(audioFile.url.path)")
        }

        let fileDuration = Double(totalFrames) / pcmFormat.sampleRate

        let targetFrames: AVAudioFrameCount = if let minimumDuration, minimumDuration > 0, fileDuration > 0, fileDuration * 2 < minimumDuration {
            AVAudioFrameCount(minimumDuration * pcmFormat.sampleRate)
        } else {
            totalFrames
        }

        let targetFramesDouble = Double(targetFrames)

        // analysis buffer size
        let nominalFramesPerBuffer = AVAudioFrameCount(bufferDuration * pcmFormat.sampleRate)

        guard
            let buffer = AVAudioPCMBuffer(
                pcmFormat: pcmFormat,
                frameCapacity: nominalFramesPerBuffer
            )
        else {
            throw NSError(description: "Unable to create buffer")
        }

        var currentFrame: AVAudioFramePosition = 0

        // check for rolling bpm every 4 seconds
        let performCheckAt: AVAudioFrameCount = AVAudioFrameCount(pcmFormat.sampleRate) * sendPeriodicProgressEvery
        var framesSinceLastDetect: AVAudioFrameCount = 0

        func send(progress: UnitInterval) async {
            await eventHandler(.progress(url: url, value: progress))
        }

        func send(samples: UnsafePointer<UnsafeMutablePointer<Float>>, length: AVAudioFrameCount) async {
            await eventHandler(.data(format: pcmFormat, length: length, samples: samples))
        }

        while currentFrame < targetFrames {
            try Task.checkCancellation()
            let progress: UnitInterval = Double(currentFrame) / targetFramesDouble
            await send(progress: progress)

            // Determine the file-relative position, wrapping for looped playback
            let filePosition = AVAudioFramePosition(AVAudioFrameCount(currentFrame) % totalFrames)
            audioFile.framePosition = filePosition

            // Clamp to both the remaining target frames and the remaining file frames before EOF
            let remainingTarget = targetFrames - AVAudioFrameCount(currentFrame)
            let remainingFile = totalFrames - AVAudioFrameCount(filePosition)
            let framesPerBuffer = min(nominalFramesPerBuffer, remainingTarget, remainingFile)

            guard framesPerBuffer > 0 else { break }

            currentFrame += AVAudioFramePosition(framesPerBuffer)

            do {
                try audioFile.read(into: buffer, frameCount: framesPerBuffer)
            } catch {
                continue
            }

            if let rawData = buffer.floatChannelData {
                await send(samples: rawData, length: buffer.frameLength)
            }

            framesSinceLastDetect += framesPerBuffer

            if framesSinceLastDetect > performCheckAt {
                await eventHandler(.periodicProgress(url: url, value: progress))

                framesSinceLastDetect = 0
            }
        }
    }
}

/// An async callback that receives ``AudioFileScannerEvent`` updates during scanning.
public typealias AudioFileScannerEventHandler = @Sendable (AudioFileScannerEvent) async -> Void

/// Events emitted by ``AudioFileScanner`` during file processing.
///
/// Not `Sendable` because the ``data`` case contains a raw pointer to the PCM sample buffer,
/// which is only valid for the duration of the callback.
public enum AudioFileScannerEvent {
    /// Scanning progress (0–1), emitted before each buffer read.
    case progress(url: URL, value: UnitInterval)
    /// Periodic progress checkpoint, emitted at the interval specified by
    /// `sendPeriodicProgressEvery`. Useful for running intermediate analysis.
    case periodicProgress(url: URL, value: UnitInterval)
    /// A chunk of PCM audio data. The `samples` pointer is only valid during the callback.
    case data(format: AVAudioFormat, length: AVAudioFrameCount, samples: UnsafePointer<UnsafeMutablePointer<Float>>)
    /// Scanning has completed for the given URL.
    case complete(url: URL)
}

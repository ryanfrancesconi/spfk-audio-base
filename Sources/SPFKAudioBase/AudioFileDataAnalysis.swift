// Copyright Ryan Francesconi. All Rights Reserved. Revision History at https://github.com/ryanfrancesconi/spfk-audio-base

import AVFoundation
import Foundation
import SPFKBase

public typealias AudioAnalysisEventHandler = @Sendable (AudioAnalysisEvent) async -> Void

public enum AudioAnalysisEvent {
    case progress(url: URL, value: UnitInterval)
    case periodicProgress(url: URL, value: UnitInterval)

    case data(format: AVAudioFormat, length: AVAudioFrameCount, samples: UnsafeMutablePointer<Float>)
    case complete(url: URL)
}

public struct AudioFileDataAnalysis: Sendable {
    private let bufferDuration: TimeInterval
    private var sendPeriodicProgressEvery: UInt32
    private let eventHandler: AudioAnalysisEventHandler

    public init(
        bufferDuration: TimeInterval = 0.2,
        sendPeriodicProgressEvery: TimeInterval = 4,
        eventHandler: @escaping AudioAnalysisEventHandler
    ) {
        self.bufferDuration = max(0.1, bufferDuration)
        self.sendPeriodicProgressEvery = UInt32(max(1, sendPeriodicProgressEvery))
        self.eventHandler = eventHandler
    }

    public func process(url: URL) async throws {
        try await process(audioFile: AVAudioFile(forReading: url))
    }

    public func process(audioFile: AVAudioFile) async throws {
        Log.debug(audioFile.url.lastPathComponent, audioFile.duration, "seconds")

        // store the current frame before scanning the file
        let currentFrame = audioFile.framePosition

        defer {
            // return the file to frame is was on previously
            audioFile.framePosition = currentFrame
        }

        try await _progress(audioFile: audioFile)

        // let bpm = try chooseMostLikelyBpm(from: results)

        await eventHandler(.complete(url: audioFile.url))
    }

    private func _progress(audioFile: AVAudioFile) async throws {
        let url = audioFile.url
        let totalFrames = AVAudioFrameCount(audioFile.length)
        let totalFramesDouble = Double(totalFrames)
        let pcmFormat: AVAudioFormat = audioFile.processingFormat

        guard totalFrames > 0 else {
            throw NSError(description: "No audio was found in \(audioFile.url.path)")
        }

        // analysis buffer size
        var framesPerBuffer = AVAudioFrameCount(bufferDuration * pcmFormat.sampleRate)

        if framesPerBuffer > totalFrames {
            framesPerBuffer = totalFrames
        }

        Log.debug(pcmFormat)

        guard
            let buffer = AVAudioPCMBuffer(
                pcmFormat: pcmFormat,
                frameCapacity: framesPerBuffer
            )
        else {
            throw NSError(description: "Unable to create buffer")
        }

        var currentFrame: AVAudioFramePosition = 0

        // check for rolling bpm every 4 seconds
        let performCheckAt: AVAudioFrameCount = AVAudioFrameCount(pcmFormat.sampleRate) * sendPeriodicProgressEvery
        var framesSinceLastDetect: AVAudioFrameCount = 0

//        var results: [Bpm] = []
//        let bpmDetect: DetectTempo = .init(format: pcmFormat)

        func send(progress: UnitInterval) async {
            await eventHandler(.progress(url: url, value: progress))
        }

        func send(samples: UnsafeMutablePointer<Float>) async {
            await eventHandler(.data(format: pcmFormat, length: framesPerBuffer, samples: samples))
        }

        while currentFrame < totalFrames {
            try Task.checkCancellation()

            audioFile.framePosition = currentFrame

            let progress: UnitInterval = Double(currentFrame) / totalFramesDouble

            await send(progress: progress)

            try audioFile.read(into: buffer, frameCount: framesPerBuffer)

            if let rawData = buffer.floatChannelData {
                let samples: UnsafeMutablePointer<Float> = rawData.pointee

                await send(samples: samples)

//                bpmDetect.process(
//                    rawData.pointee,
//                    numberOfSamples: buffer.frameLength.int32
//                )
            }

            currentFrame += AVAudioFramePosition(framesPerBuffer)

            // buffer has reached end of file, trim it
            if currentFrame + AVAudioFramePosition(framesPerBuffer) > totalFrames {
                framesPerBuffer = totalFrames - AVAudioFrameCount(currentFrame)

                guard framesPerBuffer > 0 else { break }
            }

            framesSinceLastDetect += framesPerBuffer

            if framesSinceLastDetect > performCheckAt {
                await eventHandler(.periodicProgress(url: url, value: progress))

                // Send Event

//                let value = bpmDetect.getBpm().double.rounded(.toNearestOrAwayFromZero)
//
//                if value > 0, let bpm = Bpm(value) {
//                    results.append(bpm)
//
//                    Log.debug(progress, "\(audioFile.url.lastPathComponent) bpm @ \(currentFrame)", bpm)
//
//                    let count = results.count(of: bpm)
//
//                    if let matchesRequired, count >= matchesRequired {
//                        Log.debug("Returning early found \(count) duplicates of", bpm)
//                        return results
//                    }
//                }

                framesSinceLastDetect = 0
            }
        }

//        return results
    }

//    func chooseMostLikelyBpm(from bpms: [Bpm]) throws -> Bpm {
//        guard bpms.isNotEmpty else {
//            throw NSError(description: "failed to detect bpm")
//        }
//
//        // order bpms by how many repeat values there are
//        let frequencyMap: [(key: Bpm, value: Int)] = bpms.reduce(into: [:]) { counts, value in
//            counts[value, default: 0] += 1
//        }.sorted { lhs, rhs in
//            lhs.value > rhs.value
//        }
//
//        guard let value = frequencyMap.first else {
//            throw NSError(description: "failed to detect bpm")
//        }
//
//        Log.debug("sorted results:", frequencyMap)
//
//        return value.key
//    }
}

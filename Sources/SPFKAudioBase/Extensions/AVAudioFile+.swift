// Copyright Ryan Francesconi. All Rights Reserved. Revision History at https://github.com/ryanfrancesconi/spfk-audio-base

import AVFoundation
import SPFKBase

extension AVAudioFile {
    public var audioStreamBasicDescription: AudioStreamBasicDescription? {
        fileFormat.formatDescription.audioStreamBasicDescription
    }

    /// Duration in seconds
    public var duration: TimeInterval {
        TimeInterval(length) / fileFormat.sampleRate
    }

    /// Estimated data rate in kbps.
    /// Not especially accurate for compressed files.
    public var dataRate: Float? {
        if audioStreamBasicDescription?.mFormatID == kAudioFormatLinearPCM {
            let bitrate = fileFormat.sampleRate *
                Double(fileFormat.channelCount) *
                Double(fileFormat.bitsPerChannel)

            return Float(bitrate / 1000)
        }

        guard duration > 0,
              let fileSize = url.fileSize
        else { return nil }

        let fileSizeInBits = fileSize * 8 // Convert bytes to bits

        return Float(fileSizeInBits) / Float(duration) / 1000
    }

    /// The estimated data rate when available in kbps. Generally accurate for
    /// compressed files such as mp3 or m4a but back on dataRate for PCM, FLAC or OGG.
    public func estimatedDataRate() async throws -> Float {
        let asset = AVAsset(url: url)

        let tracks = try await asset.loadTracks(withMediaType: .audio)

        guard let audioTrack = tracks.first else {
            throw NSError(description: "Failed to get audio track from asset")
        }

        // only works with compressed audio
        let estimatedDataRate = try await audioTrack.load(.estimatedDataRate)

        if estimatedDataRate > 0 {
            return estimatedDataRate / 1000
        }

        return dataRate ?? 0
    }

    /// Convenience init to write file from an AVAudioPCMBuffer. Will overwrite.
    public convenience init(url: URL, fromBuffer buffer: AVAudioPCMBuffer) throws {
        try self.init(forWriting: url, settings: buffer.format.settings)
        framePosition = 0
        try write(from: buffer)
    }

    /// Reads up to `frameCount` frames into `chunk`, leaving it empty at the end of the file.
    ///
    /// Stops at `length` without reading past it, since what that read returns is not guaranteed:
    /// `eofErr`, or a failure with no error set. `eofErr` is still treated as the end, for a file
    /// that holds fewer frames than it declares. Any other failure is thrown as
    /// ``AudioFileReadError/readFailed(_:framePosition:length:underlying:)``. `framePosition` is
    /// read inside the trap: `AVAudioFile` raises from it when it has no converter for the format.
    public func readUpToLength(into chunk: AVAudioPCMBuffer, frameCount: AVAudioFrameCount) throws {
        var framePosition: AVAudioFramePosition?

        do {
            try ExceptionTrap.withThrowing {
                let position = self.framePosition
                framePosition = position

                guard position < self.length else {
                    chunk.frameLength = 0
                    return
                }

                try self.read(into: chunk, frameCount: frameCount)
            }
        } catch let error as NSError where error.domain == NSOSStatusErrorDomain && error.code == eofErr {
            chunk.frameLength = 0
        } catch {
            throw AudioFileReadError.readFailed(url, framePosition: framePosition, length: length, underlying: error)
        }
    }

    /// converts to a 32 bit PCM buffer
    public func toAVAudioPCMBuffer() throws -> AVAudioPCMBuffer {
        guard
            let buffer = AVAudioPCMBuffer(
                pcmFormat: processingFormat,
                frameCapacity: AVAudioFrameCount(length),
            )
        else {
            throw NSError(description: "Error reading into input buffer")
        }

        framePosition = 0

        try read(into: buffer)

        return buffer
    }

    public func toAVAudioPCMBuffer(maxDuration seconds: TimeInterval) throws -> AVAudioPCMBuffer {
        guard seconds < duration else {
            return try toAVAudioPCMBuffer()
        }

        let frameCapacity = AVAudioFrameCount(seconds * fileFormat.sampleRate)

        guard
            let buffer = AVAudioPCMBuffer(
                pcmFormat: processingFormat,
                frameCapacity: frameCapacity,
            )
        else {
            throw NSError(description: "Failed creating buffer")
        }

        framePosition = 0
        try read(into: buffer, frameCount: frameCapacity)

        return buffer
    }

    /// converts to Swift friendly Float array
    func toFloatChannelData() throws -> FloatChannelData {
        let pcmBuffer = try toAVAudioPCMBuffer()

        guard let data = pcmBuffer.floatData else {
            throw NSError(description: "Failed getting float data")
        }

        return data
    }
}

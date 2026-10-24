// Copyright Ryan Francesconi. All Rights Reserved. Revision History at https://github.com/ryanfrancesconi/spfk-audio-base

import Accelerate
@preconcurrency import AVFoundation
import Foundation
import SPFKBase

extension AVAudioPCMBuffer {
    /// Find peak in the buffer
    /// - Returns: A Peak struct containing the time, frame position and peak amplitude
    public func peak() throws -> BufferPeak {
        guard frameLength > 0 else {
            throw NSError(description: "buffer is empty")
        }

        guard let floatData = floatChannelData else {
            throw NSError(description: "Failed to create floatChannelData")
        }

        var result = BufferPeak()
        var peakValue: Float = BufferPeak.min
        let channelCount = Int(format.channelCount)
        let length = vDSP_Length(frameLength)

        for channel in 0 ..< channelCount {
            var channelPeak: Float = 0
            var channelPeakIndex: vDSP_Length = 0
            vDSP_maxmgvi(floatData[channel], 1, &channelPeak, &channelPeakIndex, length)

            if channelPeak > peakValue {
                peakValue = channelPeak
                result.framePosition = Int(channelPeakIndex)
                result.sampleRate = format.sampleRate
            }
        }

        result.amplitude = peakValue
        return result
    }

    /// - Returns: A normalized buffer
    public func normalize() throws -> AVAudioPCMBuffer {
        guard let floatData = floatChannelData else {
            throw NSError(description: "Failed to create floatChannelData")
        }

        guard
            let normalizedBuffer = AVAudioPCMBuffer(
                pcmFormat: format,
                frameCapacity: frameCapacity
            )
        else {
            throw NSError(description: "Failed to create buffer")
        }

        let length = vDSP_Length(frameLength)
        let channelCount = Int(format.channelCount)
        var gainFactor: Float = try 1 / peak().amplitude

        for channel in 0 ..< channelCount {
            guard let dest = normalizedBuffer.floatChannelData?[channel] else { continue }
            vDSP_vsmul(floatData[channel], 1, &gainFactor, dest, 1, length)
        }

        normalizedBuffer.frameLength = frameLength
        return normalizedBuffer
    }

    /// - Returns: A reversed buffer
    public func reverse() throws -> AVAudioPCMBuffer {
        guard
            let reversedBuffer = AVAudioPCMBuffer(
                pcmFormat: format,
                frameCapacity: frameCapacity
            )
        else {
            throw NSError(description: "Failed to create buffer")
        }

        let length = Int(frameLength)
        let channelCount = Int(format.channelCount)

        for channel in 0 ..< channelCount {
            guard let src = floatChannelData?[channel],
                  let dest = reversedBuffer.floatChannelData?[channel]
            else { continue }
            cblas_scopy(Int32(length), src, 1, dest, 1)
            vDSP_vrvrs(dest, 1, vDSP_Length(length))
        }

        reversedBuffer.frameLength = AVAudioFrameCount(length)
        return reversedBuffer
    }

    /// Fade this buffer
    /// - Parameters:
    ///   - inTime: Fade In time
    ///   - outTime: Fade Out time
    ///   - inTaper: Curve shape applied to the fade-in (default `.default`)
    ///   - outTaper: Curve shape applied to the fade-out (default `.default`)
    /// - Returns: A new buffer from this one that has fades applied to it
    public func fade(
        inTime: TimeInterval = 0,
        outTime: TimeInterval = 0,
        inTaper: AudioTaper = .default,
        outTaper: AudioTaper = .default
    ) throws -> AVAudioPCMBuffer {
        guard inTime > 0 || outTime > 0 else {
            throw NSError(description: "Error fading buffer, inTime or outTime must be > 0")
        }

        guard let floatChannelData else {
            throw NSError(description: "floatChannelData is nil")
        }

        guard
            let fadeBuffer = AVAudioPCMBuffer(
                pcmFormat: format,
                frameCapacity: frameCapacity
            )
        else {
            throw NSError(description: "Failed to create buffer")
        }

        let length: UInt32 = frameLength
        let sampleRate = format.sampleRate
        let channelCount = Int(format.channelCount)

        // The curve playback evaluates, frame i at i / sampleRate. Overlapping fades are clamped
        // favoring the fade-out, as the fade editor draws them.
        let fade = FadeDescription(inTime: inTime, outTime: outTime, inTaper: inTaper, outTaper: outTaper)
        let curve = try fade.curve(regionDuration: Double(length) / sampleRate)

        for i in 0 ..< Int(length) {
            let gain = curve.value(at: Double(i) / sampleRate)

            for n in 0 ..< channelCount {
                fadeBuffer.floatChannelData?[n][i] = floatChannelData[n][i] * gain
            }
        }

        fadeBuffer.frameLength = length
        return fadeBuffer
    }

    /// Convert this buffer to a new format
    /// - Parameter convertToFormat: The destination format
    /// - Returns: A new `AVAudioPCMBuffer`
    public func convert(to convertToFormat: AVAudioFormat) throws -> AVAudioPCMBuffer {
        guard let converter = AVAudioConverter(from: format, to: convertToFormat) else {
            throw NSError(description: "Failed to create converter")
        }

        let inputBlock: AVAudioConverterInputBlock = { _, outStatus in
            outStatus.pointee = AVAudioConverterInputStatus.haveData
            return self
        }

        // the frame capacity will be different if the sample rate is different
        let newFrameCapacity = (convertToFormat.sampleRate / format.sampleRate) * frameCapacity.double

        guard
            let outBuffer = AVAudioPCMBuffer(
                pcmFormat: convertToFormat,
                frameCapacity: AVAudioFrameCount(newFrameCapacity)
            )
        else {
            throw NSError(description: "Failed to create buffer with format \(convertToFormat.readableDescription)")
        }

        var error: NSError?
        let status: AVAudioConverterOutputStatus = converter.convert(
            to: outBuffer,
            error: &error,
            withInputFrom: inputBlock
        )
        switch status {
        case .haveData:
            /// All of the requested data was returned.
            return outBuffer

        case .inputRanDry:
            /// contains as much as could be converted.
            Log.error("inputRanDry")
            return outBuffer

        case .endOfStream:
            /// The end of stream has been reached. No data was returned.
            throw NSError(description: "endOfStream")

        case .error:
            /// An error occurred.
            throw error ?? NSError(description: "Unknown error")

        @unknown default:
            throw NSError(description: "Unknown status returned")
        }
    }

    /// Extract a portion of the buffer
    ///
    /// - Parameter startTime: The time of the in point of the extraction
    /// - Parameter endTime: The time of the out point
    /// - Returns: A new edited AVAudioPCMBuffer
    public func extract(
        from startTime: TimeInterval,
        to endTime: TimeInterval,
    ) throws -> AVAudioPCMBuffer {
        let sampleRate = format.sampleRate
        let startSample = AVAudioFrameCount(max(0, startTime * sampleRate))
        var endSample: AVAudioFrameCount

        // endTime <= 0 means "use the full buffer length" (same as passing 0 explicitly)
        if endTime <= 0 {
            endSample = frameLength
        } else {
            endSample = min(AVAudioFrameCount(endTime * sampleRate), frameLength)
            if endSample == 0 {
                endSample = frameLength
            }
        }

        guard endSample > startSample else {
            throw NSError(description: "startSample must be before endSample")
        }

        let frameCapacity = endSample - startSample

        guard let editedBuffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCapacity) else {
            throw NSError(description: "Failed to create edited buffer")
        }

        guard try editedBuffer.copy(from: self, readOffset: startSample, frames: frameCapacity) > 0 else {
            throw NSError(description: "Failed to write to edited buffer")
        }

        return editedBuffer
    }

    /// Multiply all samples in this buffer by a linear gain factor.
    /// Returns `self` unchanged when `factor` is effectively unity.
    public func gain(_ factor: AUValue) throws -> AVAudioPCMBuffer {
        guard abs(factor - 1) >= 0.001 else { return self }

        guard let src = floatChannelData else {
            throw NSError(description: "floatChannelData is nil")
        }

        guard let output = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCapacity) else {
            throw NSError(description: "Failed to create gain buffer")
        }

        var g = factor
        let length = vDSP_Length(frameLength)
        let channelCount = Int(format.channelCount)

        for ch in 0 ..< channelCount {
            guard let dest = output.floatChannelData?[ch] else { continue }
            vDSP_vsmul(src[ch], 1, &g, dest, 1, length)
        }

        output.frameLength = frameLength
        return output
    }

    /// Copy the contents of this buffer into a new buffer `numberOfDuplicates` amounts
    public func loop(numberOfDuplicates: Int) throws -> AVAudioPCMBuffer {
        guard
            let duplicatedBuffer = AVAudioPCMBuffer(
                pcmFormat: format,
                frameCapacity: frameCapacity * AVAudioFrameCount(numberOfDuplicates),
            )
        else {
            throw NSError(description: "Failed to create new buffer")
        }

        for _ in 0 ..< numberOfDuplicates {
            try duplicatedBuffer.copy(from: self)
        }

        return duplicatedBuffer
    }
}

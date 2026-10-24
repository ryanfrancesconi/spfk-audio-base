// Copyright Ryan Francesconi. All Rights Reserved. Revision History at https://github.com/ryanfrancesconi/spfk-audio-base

import Accelerate
@preconcurrency import AVFoundation
import Foundation
import SPFKBase

extension AVAudioPCMBuffer {
    /// Apply a `ChannelOperation`, following the formulas on that type.
    ///
    /// The mono cases return a 1-channel buffer; every other case keeps the format. Throws for a
    /// buffer that is not 2-channel, unless `operation` is `.none`.
    public func applyingChannelOperation(_ operation: ChannelOperation) throws -> AVAudioPCMBuffer {
        guard operation != .none else { return self }

        guard format.channelCount == 2 else {
            throw NSError(description: "A channel operation needs a 2-channel buffer, not \(format.channelCount)")
        }

        guard let src = floatChannelData else {
            throw NSError(description: "floatChannelData is nil")
        }

        let outputChannels = operation.outputChannelCount(forInput: 2)

        guard let outputFormat = AVAudioFormat(standardFormatWithSampleRate: format.sampleRate, channels: outputChannels),
              let output = AVAudioPCMBuffer(pcmFormat: outputFormat, frameCapacity: max(frameLength, 1)),
              let dest = output.floatChannelData
        else {
            throw NSError(description: "Failed to create channel buffer")
        }

        let length = vDSP_Length(frameLength)
        let count = Int(frameLength)
        let left = src[0]
        let right = src[1]

        switch operation {
        case .none:
            break

        case .swap:
            dest[0].update(from: right, count: count)
            dest[1].update(from: left, count: count)

        case .mono(.average):
            var half: Float = 0.5
            vDSP_vasm(left, 1, right, 1, &half, dest[0], 1, length)

        case .mono(.left):
            dest[0].update(from: left, count: count)

        case .mono(.right):
            dest[0].update(from: right, count: count)

        case let .midSideDecode(width):
            // Element-wise rather than vDSP_vsma, so the rounding matches ChannelGainDSP's `m + w * s`.
            for i in 0 ..< count {
                let side = width * right[i]
                dest[0][i] = left[i] + side
                dest[1][i] = left[i] - side
            }

        case .midSideEncode:
            var half: Float = 0.5
            vDSP_vasm(left, 1, right, 1, &half, dest[0], 1, length)
            vDSP_vsbsm(left, 1, right, 1, &half, dest[1], 1, length)
        }

        output.frameLength = frameLength
        return output
    }
}

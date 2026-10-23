// Copyright Ryan Francesconi. All Rights Reserved. Revision History at https://github.com/ryanfrancesconi/spfk-audio-base

import Accelerate
@preconcurrency import AVFoundation
import Foundation
import SPFKBase

extension AVAudioPCMBuffer {
    /// An offline lookahead peak limiter with linked channels: one gain curve applies to every
    /// channel, so the image does not shift. Measures sample peak, not true peak.
    ///
    /// Returns `self` when no sample exceeds `ceiling`.
    /// - Parameters:
    ///   - ceiling: linear sample-peak ceiling
    ///   - lookahead: seconds the gain starts falling before a peak, as a linear ramp
    ///   - release: time constant of the one-pole recovery after a peak, in seconds
    public func limited(
        ceiling: Float = 1,
        lookahead: TimeInterval = 0.002,
        release: TimeInterval = 0.1
    ) throws -> AVAudioPCMBuffer {
        guard let src = floatChannelData else {
            throw NSError(description: "floatChannelData is nil")
        }

        let count = Int(frameLength)
        let channelCount = Int(format.channelCount)
        guard count > 0, channelCount > 0 else { return self }

        var detected = [Float](repeating: 0, count: count)
        vDSP_vabs(src[0], 1, &detected, 1, vDSP_Length(count))
        for ch in 1 ..< channelCount {
            vDSP_vmaxmg(src[ch], 1, detected, 1, &detected, 1, vDSP_Length(count))
        }

        guard let maximum = detected.max(), maximum > ceiling else { return self }

        let gain = Self.limiterGain(
            detected: detected,
            ceiling: ceiling,
            lookaheadFrames: max(1, Int(lookahead * format.sampleRate)),
            releaseFrames: max(1, release * format.sampleRate)
        )

        guard let output = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCapacity),
              let dest = output.floatChannelData
        else {
            throw NSError(description: "Failed to create limiter buffer")
        }

        for ch in 0 ..< channelCount {
            vDSP_vmul(src[ch], 1, gain, 1, dest[ch], 1, vDSP_Length(count))
        }

        output.frameLength = frameLength
        return output
    }

    /// The per-frame gain for a linked detector signal (the largest magnitude across channels).
    static func limiterGain(
        detected: [Float],
        ceiling: Float,
        lookaheadFrames: Int,
        releaseFrames: Double
    ) -> [Float] {
        let count = detected.count

        // The gain each frame needs on its own, rounded down until the product is at or under the ceiling.
        var required = [Float](repeating: 1, count: count)
        for i in 0 ..< count where detected[i] > ceiling {
            var g = ceiling / detected[i]
            while detected[i] * g > ceiling {
                g = g.nextDown
            }
            required[i] = g
        }

        // Attack: a linear ramp from 1, lookaheadFrames + 1 frames out, down to each frame's requirement.
        var attack = required
        let ramp = Float(lookaheadFrames + 1)
        for j in 0 ..< count where required[j] < 1 {
            let depth = 1 - required[j]
            for k in 1 ... lookaheadFrames where j - k >= 0 {
                let g = required[j] + depth * Float(k) / ramp
                if g < attack[j - k] { attack[j - k] = g }
            }
        }

        // Release: one-pole recovery toward 1, never above the attack curve.
        let coefficient = Float(exp(-1 / releaseFrames))
        var gain = [Float](repeating: 1, count: count)
        var previous: Float = 1
        for i in 0 ..< count {
            let recovered = coefficient * previous + (1 - coefficient)
            // The minimum against the per-frame requirement is what guarantees the ceiling.
            let g = min(recovered, attack[i], required[i])
            gain[i] = g
            previous = g
        }

        return gain
    }
}

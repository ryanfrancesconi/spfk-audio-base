// Copyright Ryan Francesconi. All Rights Reserved. Revision History at https://github.com/ryanfrancesconi/spfk-audio-base

import AVFoundation
import Foundation
import SPFKAudioBase
import SPFKBase
import Testing

@Suite("Audio edit pipeline with time/pitch")
struct TimePitchPipelineTests {
    private let sampleRate: Double = 48000

    private func buffer(channels: [[Float]]) throws -> AVAudioPCMBuffer {
        let format = try #require(AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: AVAudioChannelCount(channels.count)))
        let buffer = try #require(AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(channels[0].count)))
        buffer.frameLength = buffer.frameCapacity
        let data = try #require(buffer.floatChannelData)
        for (c, samples) in channels.enumerated() {
            for (i, v) in samples.enumerated() { data[c][i] = v }
        }
        return buffer
    }

    private func samples(_ buffer: AVAudioPCMBuffer) throws -> [[Float]] {
        let data = try #require(buffer.floatChannelData)
        return (0 ..< Int(buffer.format.channelCount)).map { c in
            Array(UnsafeBufferPointer(start: data[c], count: Int(buffer.frameLength)))
        }
    }

    private func ramp(_ count: Int, scale: Float) -> [Float] {
        (0 ..< count).map { Float($0 % 1000) / 1000 * scale - 0.5 * scale }
    }

    @Test func applyingThrowsForAPendingTimePitch() throws {
        let input = try buffer(channels: [ramp(4800, scale: 1)])
        #expect(throws: (any Error).self) {
            try input.applying(AudioEditDescription(timePitch: TimePitchDescription(rate: 1.5)))
        }
        // Timbre options alone are an identity, so they do not throw.
        let identity = AudioEditDescription(timePitch: TimePitchDescription(formantCorrection: true))
        #expect(try input.applying(identity) === input)
    }

    @Test func applyingMatchesTheTwoStagesWhenTimePitchIsEmpty() throws {
        let input = try buffer(channels: [ramp(48000, scale: 0.5), ramp(48000, scale: 0.25)])
        let edit = AudioEditDescription(
            trim: TrimDescription(inPoint: 0.1, outPoint: 0.9),
            channels: .swap,
            normalize: NormalizeDescription(gain: 1.5),
            fade: FadeDescription(inTime: 0.2, outTime: 0.1)
        )
        let composed = try input.applyingSourceStages(edit).applyingOutputStages(edit)
        #expect(try samples(input.applying(edit)) == samples(composed))
        #expect(try samples(input.applyingSourceStages(edit).applyingOutputStages(edit, timeScale: 1)) == samples(composed))
    }

    @Test func fadesAtTimeScaleTwoCoverHalfTheFrames() throws {
        let input = try buffer(channels: [[Float](repeating: 1, count: 48000)])
        let edit = AudioEditDescription(fade: FadeDescription(inTime: 0.5))

        let unscaled = try samples(input.applyingOutputStages(edit))[0]
        let scaled = try samples(input.applyingOutputStages(edit, timeScale: 2))[0]

        let quarter = Int(sampleRate * 0.25)
        // A 0.5 s fade at 2× ends at 0.25 s of output.
        #expect(scaled[quarter - 100] < 1)
        #expect(scaled[quarter + 1] == 1)
        #expect(unscaled[quarter + 1] < 1)
        #expect(unscaled[Int(sampleRate * 0.5) + 1] == 1)
    }

    @Test func deClickStaysFiveMillisecondsOfOutput() throws {
        // A trim with no fade: only the de-click shapes the edges, whatever the time scale.
        let input = try buffer(channels: [[Float](repeating: 1, count: 48000)])
        let edit = AudioEditDescription(trim: TrimDescription(inPoint: 0.1, outPoint: 0.9))
        let fiveMs = Int(sampleRate * 0.005)

        for scale in [0.5, 2.0] {
            let out = try samples(input.applyingOutputStages(edit, timeScale: scale))[0]
            #expect(out[fiveMs - 10] < 1)
            #expect(out[fiveMs + 1] == 1)
        }
    }
}

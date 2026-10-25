// Copyright Ryan Francesconi. All Rights Reserved. Revision History at https://github.com/ryanfrancesconi/spfk-audio-base

import AVFoundation
import Foundation
import SPFKAudioBase
import SPFKBase
import SPFKTesting
import Testing

@Suite(.tags(.reverse))
final class ReverseEditTests {
    private let sampleRate: Double = 1000

    private func makeBuffer(channels: [[Float]]) throws -> AVAudioPCMBuffer {
        let frames = channels[0].count
        let format = try #require(AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: AVAudioChannelCount(channels.count)))
        let buffer = try #require(AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(frames)))
        buffer.frameLength = AVAudioFrameCount(frames)
        let data = try #require(buffer.floatChannelData)
        for (ch, samples) in channels.enumerated() {
            for (i, sample) in samples.enumerated() { data[ch][i] = sample }
        }
        return buffer
    }

    private func samples(_ buffer: AVAudioPCMBuffer) -> [[Float]] {
        guard let data = buffer.floatChannelData else { return [] }
        return (0 ..< Int(buffer.format.channelCount)).map { ch in
            Array(UnsafeBufferPointer(start: data[ch], count: Int(buffer.frameLength)))
        }
    }

    // MARK: - Taper

    /// The identity is exact; the tolerance is `skew`'s `Float` storage of 1 − k.
    @Test(arguments: [Float(0.2), 0.5, 0.8])
    func timeMirroredTaperTracesTheFadeBackwards(skew: Float) {
        for value: Float in [3, 1, 1 / 3] {
            let taper = AudioTaper(value: value, skew: skew)
            let mirrored = taper.timeMirrored
            for step in 0 ... 100 {
                let s = Double(step) / 100
                #expect(abs(mirrored.fadeOutGain(at: s) - taper.gain(at: 1 - s)) < 1e-6)
                #expect(abs(mirrored.gain(at: s) - taper.fadeOutGain(at: 1 - s)) < 1e-6)
            }
        }
    }

    // MARK: - Fade mirror

    @Test func mirroredFadeSwapsDirectionsAndTapers() {
        let fade = FadeDescription(inTime: 0.1, outTime: 0.3, inTaper: .linear, outTaper: .default)
        let mirrored = fade.mirroredForReverse(regionDuration: 2)
        #expect(mirrored.inTime == 0.3)
        #expect(mirrored.outTime == 0.1)
        #expect(mirrored.inTaper == AudioTaper.default.timeMirrored)
        #expect(mirrored.outTaper == AudioTaper.linear.timeMirrored)
    }

    @Test func mirroredFadeClampsAnOverlapBeforeMirroring() {
        let fade = FadeDescription(inTime: 0.8, outTime: 0.6)
        let mirrored = fade.mirroredForReverse(regionDuration: 1)
        // The original fade-out keeps its length and is now the fade-in.
        #expect(mirrored.inTime == 0.6)
        #expect(abs(mirrored.outTime - 0.4) < 1e-12)
    }

    // MARK: - Reversed view

    @Test(arguments: [
        TrimDescription(),
        TrimDescription(inPoint: 0.5),
        TrimDescription(outPoint: 3),
        TrimDescription(inPoint: 1.25, outPoint: 3.5),
    ])
    func reversedViewIsItsOwnInverse(trim: TrimDescription) {
        let edit = AudioEditDescription(
            trim: trim,
            channels: .swap,
            isReversed: true,
            fade: FadeDescription(inTime: 0.2, outTime: 0.7, inTaper: .linear, outTaper: .reverseAudio)
        )
        let back = edit.reversedView(duration: 4).reversedView(duration: 4)
        #expect(abs(back.trim.inPoint - edit.trim.inPoint) < 1e-12)
        #expect(abs(back.trim.outPoint - edit.trim.outPoint) < 1e-12)
        #expect(back.fade.inTime == edit.fade.inTime)
        #expect(back.fade.outTime == edit.fade.outTime)
        #expect(abs(back.fade.inTaper.skew - edit.fade.inTaper.skew) < 1e-6)
        #expect(abs(back.fade.outTaper.skew - edit.fade.outTaper.skew) < 1e-6)
        #expect(back.channels == .swap)
        #expect(back.isReversed)
    }

    @Test func reversedViewMirrorsTheTrimWindow() {
        let view = AudioEditDescription(trim: TrimDescription(inPoint: 1, outPoint: 3)).reversedView(duration: 10)
        #expect(view.trim.inPoint == 7)
        #expect(view.trim.outPoint == 9)

        let untilEnd = AudioEditDescription(trim: TrimDescription(inPoint: 2)).reversedView(duration: 10)
        #expect(untilEnd.trim.inPoint == 0)
        #expect(untilEnd.trim.outPoint == 8)

        let fromStart = AudioEditDescription(trim: TrimDescription(outPoint: 4)).reversedView(duration: 10)
        #expect(fromStart.trim.inPoint == 6)
        #expect(fromStart.trim.outPoint == 0)

        #expect(AudioEditDescription().reversedView(duration: 10).trim.isEmpty)
    }

    // MARK: - Buffer

    @Test func reverseTwiceIsIdentity() throws {
        let input = try makeBuffer(channels: [(0 ..< 37).map { Float($0) }, (0 ..< 37).map { Float(-$0) * 0.5 }])
        let reversed = try input.reverse()
        #expect(samples(reversed)[0].first == 36)
        #expect(samples(try reversed.reverse()) == samples(input))
    }

    @Test func sourceStagesTrimThenChannelsThenReverse() throws {
        let left = (0 ..< 1000).map { Float($0) }
        let right = (0 ..< 1000).map { Float(-$0) }
        let input = try makeBuffer(channels: [left, right])
        let edit = AudioEditDescription(trim: TrimDescription(inPoint: 0.1, outPoint: 0.4), channels: .swap, isReversed: true)

        let output = samples(try input.applyingSourceStages(edit))

        #expect(output[0] == Array(right[100 ..< 400].reversed()))
        #expect(output[1] == Array(left[100 ..< 400].reversed()))
    }

    /// Frame i of the reversed output carries the mirrored curve at i / sampleRate, and so sits
    /// within one frame's step of the reversed forward fade.
    @Test func outputStageAppliesTheMirroredCurve() throws {
        let frames = 2000
        let ones = try makeBuffer(channels: [[Float](repeating: 1, count: frames)])
        let fade = FadeDescription(inTime: 0.3, outTime: 0.5, inTaper: .default, outTaper: .reverseAudio)
        let duration = Double(frames) / sampleRate

        let reversedEdit = AudioEditDescription(isReversed: true, fade: fade)
        let output = samples(try ones.applyingOutputStages(reversedEdit))[0]

        let mirroredCurve = try fade.mirroredForReverse(regionDuration: duration).curve(regionDuration: duration)
        let mirrored = (0 ..< frames).map { Float(mirroredCurve.value(at: Double($0) / sampleRate)) }
        #expect(output == mirrored)

        let forward = samples(try ones.applyingOutputStages(AudioEditDescription(fade: fade)).reverse())[0]
        for i in 0 ..< frames {
            let previous = i > 0 ? abs(mirrored[i] - mirrored[i - 1]) : 0
            let next = i < frames - 1 ? abs(mirrored[i + 1] - mirrored[i]) : 0
            #expect(abs(output[i] - forward[i]) <= max(previous, next) + 1e-6, "frame \(i)")
        }
    }

    // MARK: - Model

    @Test func decodesFalseWhenAbsent() throws {
        let json = #"{"trim":{"inPoint":1,"outPoint":2}}"#
        let edit = try JSONDecoder().decode(AudioEditDescription.self, from: Data(json.utf8))
        #expect(!edit.isReversed)
    }

    @Test func roundTripsAndCountsAsAnEdit() throws {
        let edit = AudioEditDescription(isReversed: true)
        #expect(!edit.isEmpty)
        #expect(!edit.needsCeiling)
        let decoded = try JSONDecoder().decode(AudioEditDescription.self, from: JSONEncoder().encode(edit))
        #expect(decoded == edit)
    }

    @Test func maskedKeepsAndDropsReverse() {
        let edit = AudioEditDescription(trim: TrimDescription(inPoint: 1), isReversed: true)
        #expect(edit.activeKinds == [.trim, .reverse])
        #expect(edit.masked(to: [.reverse]) == AudioEditDescription(isReversed: true))
        #expect(!edit.masked(to: [.trim]).isReversed)
    }
}

// Copyright Ryan Francesconi. All Rights Reserved. Revision History at https://github.com/ryanfrancesconi

import AVFoundation
import Foundation
import SPFKAudioBase
import SPFKBase
import Testing

/// `applying` split into source and output stages must render exactly what the single-pass
/// pipeline rendered.
@Suite
final class AudioEditStagesTests {
    private func makeNoise(seconds: Double, sampleRate: Double = 44100, channels: Int = 2) throws -> AVAudioPCMBuffer {
        let frames = Int(seconds * sampleRate)
        let format = try #require(AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: AVAudioChannelCount(channels)))
        let buffer = try #require(AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(frames)))
        buffer.frameLength = AVAudioFrameCount(frames)
        let data = try #require(buffer.floatChannelData)
        var seed: UInt32 = 0x1234_5678
        for ch in 0 ..< channels {
            for i in 0 ..< frames {
                seed = seed &* 1_664_525 &+ 1_013_904_223
                data[ch][i] = Float(Int32(bitPattern: seed)) / Float(Int32.max) * 0.8
            }
        }
        return buffer
    }

    private func samples(_ buffer: AVAudioPCMBuffer) -> [[Float]] {
        guard let data = buffer.floatChannelData else { return [] }
        return (0 ..< Int(buffer.format.channelCount)).map { ch in
            Array(UnsafeBufferPointer(start: data[ch], count: Int(buffer.frameLength)))
        }
    }

    /// The single-pass pipeline as it stood before the split.
    private func reference(_ input: AVAudioPCMBuffer, _ edit: AudioEditDescription, isPreTrimmed: Bool) throws -> AVAudioPCMBuffer {
        guard !edit.isEmpty else { return input }
        let deClick: TimeInterval = 0.005
        var buffer = input
        var trimmed = false
        if !edit.trim.isEmpty {
            if !isPreTrimmed {
                let start = edit.trim.inPoint
                let end = edit.trim.outPoint > 0 ? edit.trim.outPoint : Double(buffer.frameLength) / buffer.format.sampleRate
                buffer = try buffer.extract(from: start, to: end)
            }
            trimmed = true
        }
        if !edit.normalize.isEmpty {
            buffer = try buffer.gain(edit.normalize.gain)
        }
        let deClickSamples = Int(buffer.format.sampleRate * deClick)
        let canDeClick = trimmed && deClickSamples > 0 && deClickSamples * 2 <= Int(buffer.frameLength)
        var fadeIn = canDeClick ? max(edit.fade.inTime, deClick) : edit.fade.inTime
        var fadeOut = canDeClick ? max(edit.fade.outTime, deClick) : edit.fade.outTime
        if fadeIn > 0 || fadeOut > 0 {
            let bufferDuration = Double(buffer.frameLength) / buffer.format.sampleRate
            let safe = AudioEditDescription.clampedFades(inTime: fadeIn, outTime: fadeOut, duration: bufferDuration)
            fadeIn = safe.inTime
            fadeOut = safe.outTime
            if fadeIn > 0 || fadeOut > 0 {
                buffer = try buffer.fade(inTime: fadeIn, outTime: fadeOut, inTaper: edit.fade.inTaper, outTaper: edit.fade.outTaper)
            }
        }
        return buffer
    }

    private static let edits: [AudioEditDescription] = [
        AudioEditDescription(trim: TrimDescription(inPoint: 0.1, outPoint: 0.7)),
        AudioEditDescription(trim: TrimDescription(inPoint: 0.25)),
        AudioEditDescription(normalize: NormalizeDescription(gain: 1.7)),
        AudioEditDescription(fade: FadeDescription(inTime: 0.05, outTime: 0.1)),
        AudioEditDescription(
            trim: TrimDescription(inPoint: 0.1, outPoint: 0.9),
            normalize: NormalizeDescription(gain: 0.5),
            fade: FadeDescription(inTime: 0.002, outTime: 0.2, inTaper: .linear, outTaper: .default)
        ),
        // Too short for a de-click: 3 ms window.
        AudioEditDescription(trim: TrimDescription(inPoint: 0.5, outPoint: 0.503)),
    ]

    @Test(arguments: edits)
    func stagesMatchSinglePass(edit: AudioEditDescription) throws {
        let input = try makeNoise(seconds: 1)
        let expected = try samples(reference(input, edit, isPreTrimmed: false))
        #expect(try samples(input.applying(edit)) == expected)
        #expect(try samples(input.applyingSourceStages(edit).applyingOutputStages(edit)) == expected)
    }

    @Test(arguments: edits)
    func preTrimmedStagesMatchSinglePass(edit: AudioEditDescription) throws {
        let input = try makeNoise(seconds: 0.6)
        let expected = try samples(reference(input, edit, isPreTrimmed: true))
        #expect(try samples(input.applying(edit, isPreTrimmed: true)) == expected)
        #expect(try samples(input.applyingSourceStages(edit, isPreTrimmed: true).applyingOutputStages(edit)) == expected)
    }
}

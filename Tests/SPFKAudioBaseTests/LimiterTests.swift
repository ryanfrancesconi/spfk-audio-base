// Copyright Ryan Francesconi. All Rights Reserved. Revision History at https://github.com/ryanfrancesconi

import AVFoundation
import Foundation
import SPFKBase
import Testing

@testable import SPFKAudioBase

@Suite
final class LimiterTests {
    private let sampleRate: Double = 48000
    private let lookahead: TimeInterval = 0.002
    private let release: TimeInterval = 0.1

    private func makeBuffer(left: [Float], right: [Float]) throws -> AVAudioPCMBuffer {
        let format = try #require(AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 2))
        let buffer = try #require(AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(left.count)))
        buffer.frameLength = AVAudioFrameCount(left.count)
        let data = try #require(buffer.floatChannelData)
        for i in 0 ..< left.count {
            data[0][i] = left[i]
            data[1][i] = right[i]
        }
        return buffer
    }

    private func samples(_ buffer: AVAudioPCMBuffer, _ channel: Int) -> [Float] {
        guard let data = buffer.floatChannelData else { return [] }
        return Array(UnsafeBufferPointer(start: data[channel], count: Int(buffer.frameLength)))
    }

    /// A 0.5 sine with one sample per isolated peak raised over the ceiling.
    private func isolatedPeaks(at peaks: [Int], count: Int) -> [Float] {
        var signal = (0 ..< count).map { Float(0.5 * sin(Double($0) * 0.05)) }
        for p in peaks { signal[p] = 1.6 }
        return signal
    }

    private func limit(_ buffer: AVAudioPCMBuffer) throws -> AVAudioPCMBuffer {
        try buffer.limited(ceiling: 1, lookahead: lookahead, release: release)
    }

    @Test func isolatedPeaksStayUnderCeiling() throws {
        let count = Int(sampleRate)
        let left = isolatedPeaks(at: [1000, 20000, 40000], count: count)
        let output = try limit(makeBuffer(left: left, right: left.map { -$0 * 0.8 }))
        for ch in 0 ..< 2 {
            #expect(samples(output, ch).allSatisfy { abs($0) <= 1 })
        }
    }

    @Test func denseOverloadStaysUnderCeiling() throws {
        let count = Int(sampleRate / 2)
        let left = (0 ..< count).map { Float(1.9 * sin(Double($0) * 0.031)) }
        let right = (0 ..< count).map { Float(2.4 * sin(Double($0) * 0.017 + 1)) }
        let output = try limit(makeBuffer(left: left, right: right))
        for ch in 0 ..< 2 {
            #expect(samples(output, ch).allSatisfy { abs($0) <= 1 })
        }
    }

    @Test func untouchedWhenNothingExceedsCeiling() throws {
        let left = (0 ..< 4800).map { Float(0.99 * sin(Double($0) * 0.02)) }
        let input = try makeBuffer(left: left, right: left)
        let output = try limit(input)
        #expect(samples(output, 0) == left)
        #expect(samples(output, 1) == left)
    }

    @Test func gainFallsBeforePeakAndRecoversAfterRelease() {
        let count = Int(sampleRate)
        let peak = 10000
        var detected = [Float](repeating: 0.5, count: count)
        detected[peak] = 2

        let lookaheadFrames = Int(lookahead * sampleRate)
        let releaseFrames = release * sampleRate
        let gain = AVAudioPCMBuffer.limiterGain(
            detected: detected, ceiling: 1, lookaheadFrames: lookaheadFrames, releaseFrames: releaseFrames
        )

        #expect(gain[peak - lookaheadFrames] < 1)
        #expect(gain[peak - lookaheadFrames - 1] == 1)
        #expect(gain[peak] <= 0.5)

        let recovered = gain[peak + Int(5 * releaseFrames)]
        #expect(20 * log10(recovered) > -0.1)
    }

    @Test func gainIsLinkedAcrossChannels() throws {
        let count = Int(sampleRate / 4)
        let left = isolatedPeaks(at: [3000], count: count).map { $0 + 0.1 }
        let right = left.map { $0 * 0.5 }
        let input = try makeBuffer(left: left, right: right)
        let output = try limit(input)

        let outL = samples(output, 0)
        let outR = samples(output, 1)
        for i in stride(from: 2800, to: 8000, by: 7) where abs(left[i]) > 0.01 {
            #expect(abs(outL[i] / left[i] - outR[i] / right[i]) < 1e-5)
        }
    }
}

// Copyright Ryan Francesconi. All Rights Reserved. Revision History at https://github.com/ryanfrancesconi/spfk-audio-base

import AVFoundation
import Foundation
import SPFKAudioBase
import Testing

struct AudioFileScannerTests {
    private actor Collector {
        var channelCounts: Set<AVAudioChannelCount> = []
        /// Largest absolute sample per delivered channel.
        var peaks: [Int: Float] = [:]

        func record(channelCount: AVAudioChannelCount, peaks: [Float]) {
            channelCounts.insert(channelCount)
            for (channel, peak) in peaks.enumerated() {
                self.peaks[channel] = max(self.peaks[channel] ?? 0, peak)
            }
        }
    }

    /// 1 s of stereo at 44.1 kHz: silence on the left, a constant 0.5 on the right.
    private func writeRightOnly() throws -> URL {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("scanner-\(UUID().uuidString).wav")

        guard let format = AVAudioFormat(standardFormatWithSampleRate: 44100, channels: 2),
              let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: 44100),
              let channels = buffer.floatChannelData else {
            throw NSError(domain: "AudioFileScannerTests", code: 1)
        }

        buffer.frameLength = 44100
        for frame in 0 ..< 44100 {
            channels[0][frame] = 0
            channels[1][frame] = 0.5
        }

        let file = try AVAudioFile(forWriting: url, settings: format.settings)
        try file.write(from: buffer)
        return url
    }

    private func scan(mixesToMono: Bool?) async throws -> Collector {
        let url = try writeRightOnly()
        defer { try? FileManager.default.removeItem(at: url) }

        let collector = Collector()
        let handler: AudioFileScannerEventHandler = { event in
            guard case let .data(format, length, samples) = event else { return }

            let peaks = (0 ..< Int(format.channelCount)).map { channel in
                UnsafeBufferPointer(start: samples[channel], count: Int(length)).map(abs).max() ?? 0
            }
            await collector.record(channelCount: format.channelCount, peaks: peaks)
        }

        let scanner = if let mixesToMono {
            AudioFileScanner(bufferDuration: 0.25, mixesToMono: mixesToMono, eventHandler: handler)
        } else {
            AudioFileScanner(bufferDuration: 0.25, eventHandler: handler)
        }

        try await scanner.process(url: url)
        return collector
    }

    @Test func theDefaultDeliversTheMeanOfEveryChannel() async throws {
        let collector = try await scan(mixesToMono: nil)

        #expect(await collector.channelCounts == [1])
        #expect(await collector.peaks == [0: 0.25])
    }

    @Test func turningMixingOffDeliversEachChannel() async throws {
        let collector = try await scan(mixesToMono: false)

        #expect(await collector.channelCounts == [2])
        #expect(await collector.peaks == [0: 0, 1: 0.5])
    }
}

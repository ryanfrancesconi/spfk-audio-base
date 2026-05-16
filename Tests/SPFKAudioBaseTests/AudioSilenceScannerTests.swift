import AVFoundation
import Foundation
import SPFKBase
import Testing

@testable import SPFKAudioBase

@Suite(.tags(.file))
struct AudioSilenceScannerTests {
    // -60 dBFS ≈ 0.001 linear
    private let threshold: Float = 0.001
    private let audioLevel: Float = 0.5

    // MARK: - leadingSilenceEnd

    @Test("leadingSilenceEnd returns onset frame after multi-chunk leading silence")
    func leadingSilenceEndDetected() async throws {
        let silenceFrames = 5000 // spans two 4096-frame chunks
        let (url, _) = try makeAudioFile(segments: [
            (silenceFrames, 0.0),
            (2000, audioLevel),
        ])
        defer { try? FileManager.default.removeItem(at: url) }

        let scanner = AudioSilenceScanner(silenceThreshold: threshold)
        let result = try await scanner.leadingSilenceEnd(in: AVAudioFile(forReading: url))

        #expect(result == AVAudioFrameCount(silenceFrames))
    }

    @Test("leadingSilenceEnd returns 0 when audio starts at frame zero")
    func leadingSilenceEndNone() async throws {
        let (url, _) = try makeAudioFile(segments: [(3000, audioLevel)])
        defer { try? FileManager.default.removeItem(at: url) }

        let scanner = AudioSilenceScanner(silenceThreshold: threshold)
        let result = try await scanner.leadingSilenceEnd(in: AVAudioFile(forReading: url))

        #expect(result == 0)
    }

    @Test("leadingSilenceEnd returns nil for fully silent file")
    func leadingSilenceEndAllSilent() async throws {
        let (url, _) = try makeAudioFile(segments: [(4000, 0.0)])
        defer { try? FileManager.default.removeItem(at: url) }

        let scanner = AudioSilenceScanner(silenceThreshold: threshold)
        let result = try await scanner.leadingSilenceEnd(in: AVAudioFile(forReading: url))

        #expect(result == nil)
    }

    // MARK: - trailingSilenceStart

    @Test("trailingSilenceStart returns last audio frame before multi-chunk trailing silence")
    func trailingSilenceStartDetected() async throws {
        let audioFrames = 3000
        let (url, _) = try makeAudioFile(segments: [
            (audioFrames, audioLevel),
            (5000, 0.0), // spans two 4096-frame chunks
        ])
        defer { try? FileManager.default.removeItem(at: url) }

        let scanner = AudioSilenceScanner(silenceThreshold: threshold)
        let result = try await scanner.trailingSilenceStart(in: AVAudioFile(forReading: url))

        #expect(result == AVAudioFrameCount(audioFrames - 1))
    }

    @Test("trailingSilenceStart returns last frame when no trailing silence")
    func trailingSilenceStartNone() async throws {
        let frameCount = 3000
        let (url, _) = try makeAudioFile(segments: [(frameCount, audioLevel)])
        defer { try? FileManager.default.removeItem(at: url) }

        let scanner = AudioSilenceScanner(silenceThreshold: threshold)
        let result = try await scanner.trailingSilenceStart(in: AVAudioFile(forReading: url))

        #expect(result == AVAudioFrameCount(frameCount - 1))
    }

    @Test("trailingSilenceStart returns nil for fully silent file")
    func trailingSilenceStartAllSilent() async throws {
        let (url, _) = try makeAudioFile(segments: [(4000, 0.0)])
        defer { try? FileManager.default.removeItem(at: url) }

        let scanner = AudioSilenceScanner(silenceThreshold: threshold)
        let result = try await scanner.trailingSilenceStart(in: AVAudioFile(forReading: url))

        #expect(result == nil)
    }

    // MARK: - nonSilentRegions

    @Test("nonSilentRegions finds two regions separated by silence longer than minimum duration")
    func nonSilentRegionsTwoRegions() async throws {
        let leadSilence = 1000
        let region1Length = 2000
        let gapSilence = 5000   // ~113ms at 44.1kHz — above minimumSilenceDuration of 50ms
        let region2Length = 2000
        let trailSilence = 1000

        let region1Start = leadSilence
        let region2Start = leadSilence + region1Length + gapSilence

        let (url, _) = try makeAudioFile(segments: [
            (leadSilence, 0.0),
            (region1Length, audioLevel),
            (gapSilence, 0.0),
            (region2Length, audioLevel),
            (trailSilence, 0.0),
        ])
        defer { try? FileManager.default.removeItem(at: url) }

        let scanner = AudioSilenceScanner(silenceThreshold: threshold)
        let regions = try await scanner.nonSilentRegions(
            in: AVAudioFile(forReading: url),
            minimumSilenceDuration: 0.05
        )

        #expect(regions.count == 2)
        #expect(regions[0].lowerBound == AVAudioFrameCount(region1Start))
        #expect(regions[0].upperBound == AVAudioFrameCount(region1Start + region1Length - 1))
        #expect(regions[1].lowerBound == AVAudioFrameCount(region2Start))
        #expect(regions[1].upperBound == AVAudioFrameCount(region2Start + region2Length - 1))
    }

    @Test("nonSilentRegions bridges a gap shorter than minimum silence duration into one region")
    func nonSilentRegionsBridgesShortGap() async throws {
        let block1 = 2000
        let gap = 100   // ~2ms at 44.1kHz — below minimumSilenceDuration of 100ms
        let block2 = 2000

        let (url, _) = try makeAudioFile(segments: [
            (block1, audioLevel),
            (gap, 0.0),
            (block2, audioLevel),
        ])
        defer { try? FileManager.default.removeItem(at: url) }

        let scanner = AudioSilenceScanner(silenceThreshold: threshold)
        let regions = try await scanner.nonSilentRegions(
            in: AVAudioFile(forReading: url),
            minimumSilenceDuration: 0.1
        )

        #expect(regions.count == 1)
        #expect(regions[0].lowerBound == 0)
        #expect(regions[0].upperBound == AVAudioFrameCount(block1 + gap + block2 - 1))
    }

    @Test("nonSilentRegions returns empty for fully silent file")
    func nonSilentRegionsAllSilent() async throws {
        let (url, _) = try makeAudioFile(segments: [(4000, 0.0)])
        defer { try? FileManager.default.removeItem(at: url) }

        let scanner = AudioSilenceScanner(silenceThreshold: threshold)
        let regions = try await scanner.nonSilentRegions(in: AVAudioFile(forReading: url))

        #expect(regions.isEmpty)
    }

    // MARK: - Threshold boundary

    @Test("samples at exactly the threshold amplitude are treated as silence")
    func thresholdBoundary() async throws {
        // Frame 0 = exactly threshold (should be silent), frame 1 = just above
        let (url, _) = try makeAudioFile(segments: [
            (1, threshold),           // == threshold → silent
            (3000, threshold * 1.01), // > threshold → audio
        ])
        defer { try? FileManager.default.removeItem(at: url) }

        let scanner = AudioSilenceScanner(silenceThreshold: threshold)
        let result = try await scanner.leadingSilenceEnd(in: AVAudioFile(forReading: url))

        #expect(result == 1)
    }

    // MARK: - Helpers

    private func makeAudioFile(
        sampleRate: Double = 44100,
        channelCount: AVAudioChannelCount = 1,
        segments: [(Int, Float)]
    ) throws -> (url: URL, totalFrames: Int) {
        let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: channelCount)!
        let totalFrames = segments.reduce(0) { $0 + $1.0 }

        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(totalFrames)) else {
            throw NSError(description: "Failed to allocate PCM buffer")
        }
        buffer.frameLength = AVAudioFrameCount(totalFrames)

        guard let floatData = buffer.floatChannelData else {
            throw NSError(description: "No float channel data")
        }

        var offset = 0
        for (count, amplitude) in segments {
            for i in 0 ..< count {
                for ch in 0 ..< Int(channelCount) {
                    floatData[ch][offset + i] = amplitude
                }
            }
            offset += count
        }

        let url = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("silence_scanner_test_\(UUID().uuidString).wav")
        _ = try AVAudioFile(url: url, fromBuffer: buffer)
        return (url, totalFrames)
    }
}

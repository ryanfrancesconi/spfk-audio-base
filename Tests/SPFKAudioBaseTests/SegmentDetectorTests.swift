// Copyright Ryan Francesconi. All Rights Reserved. Revision History at https://github.com/ryanfrancesconi

import AVFoundation
import Foundation
import SPFKBase
import SPFKTesting
import Testing

@testable import SPFKAudioBase

@Suite(.tags(.file))
struct SegmentDetectorTests {
    // Threshold matching SegmentDetectorOptions default of -60 dBFS.
    private let audioLevel: Float = 0.5

    // MARK: - Segment count

    @Test("two audio regions separated by a gap above minimumSilenceDuration produce two segments")
    func twoSegmentsWithLongGap() async throws {
        // Gap: 8820 frames = 200 ms at 44100 Hz — exceeds minimumSilenceDuration of 100 ms.
        let (url, _) = try AudioTestFile.make(segments: [
            (4410, audioLevel), // 100 ms audio
            (8820, 0.0),        // 200 ms silence
            (4410, audioLevel), // 100 ms audio
        ])
        defer { try? FileManager.default.removeItem(at: url) }

        var options = SegmentDetectorOptions()
        options.minimumSegmentDuration = 0.05  // segments are 100 ms; bypass the duration filter
        options.preRollPadding = 0
        options.postRollPadding = 0

        let segments = try await SegmentDetector(options: options).detect(in: AVAudioFile(forReading: url))
        #expect(segments.count == 2)
    }

    @Test("two audio regions separated by a gap below minimumSilenceDuration are bridged into one segment")
    func shortGapIsBridged() async throws {
        // Gap: 2205 frames = 50 ms — below minimumSilenceDuration of 100 ms.
        let (url, _) = try AudioTestFile.make(segments: [
            (4410, audioLevel),
            (2205, 0.0),
            (4410, audioLevel),
        ])
        defer { try? FileManager.default.removeItem(at: url) }

        var options = SegmentDetectorOptions()
        options.minimumSegmentDuration = 0.05  // bridged segment is ~250 ms; bypass the duration filter
        options.preRollPadding = 0
        options.postRollPadding = 0

        let segments = try await SegmentDetector(options: options).detect(in: AVAudioFile(forReading: url))
        #expect(segments.count == 1)
    }

    @Test("segment shorter than minimumSegmentDuration is discarded")
    func shortSegmentFiltered() async throws {
        // Middle segment: 882 frames ≈ 20 ms — below minimumSegmentDuration of 50 ms.
        let (url, _) = try AudioTestFile.make(segments: [
            (4410, audioLevel), // 100 ms — kept
            (8820, 0.0),
            (882, audioLevel),  // ~20 ms — discarded
            (8820, 0.0),
            (4410, audioLevel), // 100 ms — kept
        ])
        defer { try? FileManager.default.removeItem(at: url) }

        var options = SegmentDetectorOptions()
        options.minimumSegmentDuration = 0.05
        options.preRollPadding = 0
        options.postRollPadding = 0

        let segments = try await SegmentDetector(options: options).detect(in: AVAudioFile(forReading: url))
        #expect(segments.count == 2)
    }

    @Test("fully silent file returns no segments")
    func allSilentReturnsEmpty() async throws {
        let (url, _) = try AudioTestFile.make(segments: [(44100, 0.0)])
        defer { try? FileManager.default.removeItem(at: url) }

        let segments = try await SegmentDetector().detect(in: AVAudioFile(forReading: url))
        #expect(segments.isEmpty)
    }

    @Test("file with no silence returns a single segment")
    func noSilenceSingleSegment() async throws {
        let (url, _) = try AudioTestFile.make(segments: [(44100, audioLevel)])
        defer { try? FileManager.default.removeItem(at: url) }

        var options = SegmentDetectorOptions()
        options.preRollPadding = 0
        options.postRollPadding = 0

        let segments = try await SegmentDetector(options: options).detect(in: AVAudioFile(forReading: url))
        #expect(segments.count == 1)
        #expect(segments[0].inPoint == 0)
        #expect(abs(segments[0].outPoint - 1.0) < 0.001)
    }

    // MARK: - Time conversion

    @Test("segment boundaries convert from frames to seconds correctly")
    func frameToTimeConversion() async throws {
        let sampleRate = 44100.0
        // 4410 frames = 0.1 s exactly at 44100 Hz.
        let (url, _) = try AudioTestFile.make(segments: [
            (4410, 0.0),        // 0.1 s leading silence
            (4410, audioLevel), // 0.1 s audio
            (4410, 0.0),        // 0.1 s trailing silence
        ])
        defer { try? FileManager.default.removeItem(at: url) }

        var options = SegmentDetectorOptions()
        options.minimumSegmentDuration = 0.05  // segment is 0.1 s; keep it below that so it isn't filtered
        options.preRollPadding = 0
        options.postRollPadding = 0

        let segments = try await SegmentDetector(options: options).detect(in: AVAudioFile(forReading: url))
        #expect(segments.count == 1)
        #expect(abs(segments[0].inPoint - 4410.0 / sampleRate) < 0.001)
        #expect(abs(segments[0].outPoint - 8820.0 / sampleRate) < 0.001)
    }

    // MARK: - Padding

    @Test("preRollPadding extends inPoint backward from the audio onset")
    func preRollPaddingExtendsInPoint() async throws {
        let sampleRate = 44100.0
        // Audio starts at frame 4410 (0.1 s). Pre-roll of 0.05 s should pull inPoint back to 0.05 s.
        let (url, _) = try AudioTestFile.make(segments: [
            (4410, 0.0),        // 0.1 s silence
            (4410, audioLevel),
        ])
        defer { try? FileManager.default.removeItem(at: url) }

        var options = SegmentDetectorOptions()
        options.minimumSegmentDuration = 0.05  // padded segment is ~150 ms; bypass the duration filter
        options.preRollPadding = 0.05
        options.postRollPadding = 0

        let segments = try await SegmentDetector(options: options).detect(in: AVAudioFile(forReading: url))
        #expect(segments.count == 1)
        let expected = (4410.0 - 0.05 * sampleRate) / sampleRate // 4410 - 2205 = 2205 frames = 0.05 s
        #expect(abs(segments[0].inPoint - expected) < 0.001)
    }

    @Test("postRollPadding extends outPoint forward from the audio end")
    func postRollPaddingExtendsOutPoint() async throws {
        let sampleRate = 44100.0
        // Audio ends at frame 4410 (exclusive). Post-roll of 0.05 s extends to frame 6615 = 0.15 s.
        let (url, _) = try AudioTestFile.make(segments: [
            (4410, audioLevel),
            (4410, 0.0),
        ])
        defer { try? FileManager.default.removeItem(at: url) }

        var options = SegmentDetectorOptions()
        options.minimumSegmentDuration = 0.05  // padded segment is ~150 ms; bypass the duration filter
        options.preRollPadding = 0
        options.postRollPadding = 0.05

        let segments = try await SegmentDetector(options: options).detect(in: AVAudioFile(forReading: url))
        #expect(segments.count == 1)
        let expected = (4410.0 + 0.05 * sampleRate) / sampleRate // frame 6615 / 44100 = 0.15 s
        #expect(abs(segments[0].outPoint - expected) < 0.001)
    }

    @Test("preRollPadding clamps to 0 when audio starts at file beginning")
    func preRollClampedToZero() async throws {
        let (url, _) = try AudioTestFile.make(segments: [(44100, audioLevel)])
        defer { try? FileManager.default.removeItem(at: url) }

        var options = SegmentDetectorOptions()
        options.preRollPadding = 0.5
        options.postRollPadding = 0

        let segments = try await SegmentDetector(options: options).detect(in: AVAudioFile(forReading: url))
        #expect(segments.count == 1)
        #expect(segments[0].inPoint == 0)
    }

    @Test("postRollPadding clamps to file duration when audio extends to end of file")
    func postRollClampedToFileDuration() async throws {
        let (url, _) = try AudioTestFile.make(segments: [(44100, audioLevel)])
        defer { try? FileManager.default.removeItem(at: url) }

        var options = SegmentDetectorOptions()
        options.preRollPadding = 0
        options.postRollPadding = 0.5

        let segments = try await SegmentDetector(options: options).detect(in: AVAudioFile(forReading: url))
        #expect(segments.count == 1)
        #expect(abs(segments[0].outPoint - 1.0) < 0.001)
    }

    // MARK: - linearThreshold

    @Test("linearThreshold converts dBFS to linear amplitude correctly")
    func linearThresholdFormula() {
        // 0 dBFS is full scale: 10^(0/20) = 1.0
        #expect(abs(SegmentDetectorOptions(silenceThreshold: 0).linearThreshold - 1.0) < 0.0001)
        // -20 dBFS: 10^(-20/20) = 10^(-1) = 0.1
        #expect(abs(SegmentDetectorOptions(silenceThreshold: -20).linearThreshold - 0.1) < 0.0001)
        // -60 dBFS: 10^(-60/20) = 10^(-3) = 0.001
        #expect(abs(SegmentDetectorOptions(silenceThreshold: -60).linearThreshold - 0.001) < 0.00001)
    }

    // MARK: - Padding and minimum duration interaction

    @Test("padding is applied before minimum-duration filter so it can rescue an otherwise-discarded segment")
    func paddingRescuesShortSegment() async throws {
        // Raw audio: 441 frames ≈ 10 ms — below minimumSegmentDuration of 100 ms without padding.
        // With 50 ms pre-roll + 50 ms post-roll the padded window is ≈ 110 ms → passes filter.
        let (url, _) = try AudioTestFile.make(segments: [
            (4410, 0.0),       // 100 ms leading silence — room for pre-roll
            (441, audioLevel), // 10 ms audio burst
            (4410, 0.0),       // 100 ms trailing silence — room for post-roll
        ])
        defer { try? FileManager.default.removeItem(at: url) }

        var options = SegmentDetectorOptions()
        options.minimumSegmentDuration = 0.1  // 100 ms
        options.preRollPadding = 0.05
        options.postRollPadding = 0.05

        let segments = try await SegmentDetector(options: options).detect(in: AVAudioFile(forReading: url))
        // Without padding: 10 ms raw < 100 ms minimum → filtered. With padding: ~110 ms → kept.
        #expect(segments.count == 1)
    }

    // MARK: - Codable

    @Test("SegmentDetectorOptions encodes and decodes without data loss")
    func codableRoundTrip() throws {
        var options = SegmentDetectorOptions()
        options.silenceThreshold = -40
        options.minimumSilenceDuration = 0.25
        options.minimumSegmentDuration = 1.0
        options.preRollPadding = 0.01
        options.postRollPadding = 0.02

        let data = try JSONEncoder().encode(options)
        let decoded = try JSONDecoder().decode(SegmentDetectorOptions.self, from: data)

        #expect(decoded.silenceThreshold == options.silenceThreshold)
        #expect(decoded.minimumSilenceDuration == options.minimumSilenceDuration)
        #expect(decoded.minimumSegmentDuration == options.minimumSegmentDuration)
        #expect(decoded.preRollPadding == options.preRollPadding)
        #expect(decoded.postRollPadding == options.postRollPadding)
    }

    @Test("SegmentDetectorOptions decoding falls back to defaults when all fields are absent")
    func codableMissingFieldsUseDefaults() throws {
        let data = "{}".data(using: .utf8)!
        let decoded = try JSONDecoder().decode(SegmentDetectorOptions.self, from: data)
        let defaults = SegmentDetectorOptions()

        #expect(decoded.silenceThreshold == defaults.silenceThreshold)
        #expect(decoded.minimumSilenceDuration == defaults.minimumSilenceDuration)
        #expect(decoded.minimumSegmentDuration == defaults.minimumSegmentDuration)
        #expect(decoded.preRollPadding == defaults.preRollPadding)
        #expect(decoded.postRollPadding == defaults.postRollPadding)
    }
}

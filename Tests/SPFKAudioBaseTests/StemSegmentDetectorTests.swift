// Copyright Ryan Francesconi. All Rights Reserved. Revision History at https://github.com/ryanfrancesconi

import AVFoundation
import Foundation
import SPFKBase
import SPFKTesting
import Testing

@testable import SPFKAudioBase

@Suite(.tags(.file))
struct StemSegmentDetectorTests {
    // Threshold matching StemSegmentDetectorOptions default of -60 dBFS.
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

        var options = StemSegmentDetectorOptions()
        options.preRollPadding = 0
        options.postRollPadding = 0

        let segments = try await StemSegmentDetector(options: options).detect(in: AVAudioFile(forReading: url))
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

        var options = StemSegmentDetectorOptions()
        options.preRollPadding = 0
        options.postRollPadding = 0

        let segments = try await StemSegmentDetector(options: options).detect(in: AVAudioFile(forReading: url))
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

        var options = StemSegmentDetectorOptions()
        options.minimumSegmentDuration = 0.05
        options.preRollPadding = 0
        options.postRollPadding = 0

        let segments = try await StemSegmentDetector(options: options).detect(in: AVAudioFile(forReading: url))
        #expect(segments.count == 2)
    }

    @Test("fully silent file returns no segments")
    func allSilentReturnsEmpty() async throws {
        let (url, _) = try AudioTestFile.make(segments: [(44100, 0.0)])
        defer { try? FileManager.default.removeItem(at: url) }

        let segments = try await StemSegmentDetector().detect(in: AVAudioFile(forReading: url))
        #expect(segments.isEmpty)
    }

    @Test("file with no silence returns a single segment")
    func noSilenceSingleSegment() async throws {
        let (url, _) = try AudioTestFile.make(segments: [(44100, audioLevel)])
        defer { try? FileManager.default.removeItem(at: url) }

        var options = StemSegmentDetectorOptions()
        options.preRollPadding = 0
        options.postRollPadding = 0

        let segments = try await StemSegmentDetector(options: options).detect(in: AVAudioFile(forReading: url))
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

        var options = StemSegmentDetectorOptions()
        options.preRollPadding = 0
        options.postRollPadding = 0

        let segments = try await StemSegmentDetector(options: options).detect(in: AVAudioFile(forReading: url))
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

        var options = StemSegmentDetectorOptions()
        options.preRollPadding = 0.05
        options.postRollPadding = 0

        let segments = try await StemSegmentDetector(options: options).detect(in: AVAudioFile(forReading: url))
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

        var options = StemSegmentDetectorOptions()
        options.preRollPadding = 0
        options.postRollPadding = 0.05

        let segments = try await StemSegmentDetector(options: options).detect(in: AVAudioFile(forReading: url))
        #expect(segments.count == 1)
        let expected = (4410.0 + 0.05 * sampleRate) / sampleRate // frame 6615 / 44100 = 0.15 s
        #expect(abs(segments[0].outPoint - expected) < 0.001)
    }

    @Test("preRollPadding clamps to 0 when audio starts at file beginning")
    func preRollClampedToZero() async throws {
        let (url, _) = try AudioTestFile.make(segments: [(44100, audioLevel)])
        defer { try? FileManager.default.removeItem(at: url) }

        var options = StemSegmentDetectorOptions()
        options.preRollPadding = 0.5
        options.postRollPadding = 0

        let segments = try await StemSegmentDetector(options: options).detect(in: AVAudioFile(forReading: url))
        #expect(segments.count == 1)
        #expect(segments[0].inPoint == 0)
    }

    @Test("postRollPadding clamps to file duration when audio extends to end of file")
    func postRollClampedToFileDuration() async throws {
        let (url, _) = try AudioTestFile.make(segments: [(44100, audioLevel)])
        defer { try? FileManager.default.removeItem(at: url) }

        var options = StemSegmentDetectorOptions()
        options.preRollPadding = 0
        options.postRollPadding = 0.5

        let segments = try await StemSegmentDetector(options: options).detect(in: AVAudioFile(forReading: url))
        #expect(segments.count == 1)
        #expect(abs(segments[0].outPoint - 1.0) < 0.001)
    }
}

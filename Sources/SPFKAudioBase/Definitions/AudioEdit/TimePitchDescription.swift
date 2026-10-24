// Copyright Ryan Francesconi. All Rights Reserved. Revision History at https://github.com/ryanfrancesconi/spfk-audio-base

import Foundation
import SPFKBase

/// A pending change of rate and pitch, with the stretcher's timbre options.
///
/// Every value is clamped into its range at construction, on decode and on assignment. Frequencies
/// are stored in Hz, so an edit means the same at any sample rate.
public struct TimePitchDescription: Hashable, Sendable {
    public static let rateRange: ClosedRange<Double> = 0.5 ... 2.0
    public static let semitoneRange: ClosedRange<Int> = -24 ... 24
    public static let centRange: ClosedRange<Double> = -100 ... 100
    public static let tonalityLimitRange: ClosedRange<Double> = 1000 ... 20000
    public static let formantBaseRange: ClosedRange<Double> = 50 ... 1000
    public static let formantShiftRange: ClosedRange<Double> = -12 ... 12

    public var semitones: Int = 0 {
        didSet { semitones = semitones.clamped(to: Self.semitoneRange) }
    }

    public var cents: Double = 0 {
        didSet { cents = Self.clamp(cents, into: Self.centRange, otherwise: 0) }
    }

    /// Output speed relative to the source; above 1 is faster.
    public var rate: Double = 1 {
        didSet { rate = Self.clamp(rate, into: Self.rateRange, otherwise: 1) }
    }

    /// In Hz; 0 is off.
    public var tonalityLimitHz: Double = 0 {
        didSet { tonalityLimitHz = Self.clampOptional(tonalityLimitHz, into: Self.tonalityLimitRange) }
    }

    public var formantCorrection = false

    /// In Hz; 0 is automatic detection.
    public var formantBaseHz: Double = 0 {
        didSet { formantBaseHz = Self.clampOptional(formantBaseHz, into: Self.formantBaseRange) }
    }

    public var formantSemitones: Double = 0 {
        didSet { formantSemitones = Self.clamp(formantSemitones, into: Self.formantShiftRange, otherwise: 0) }
    }

    public var pitchCents: Double { Double(semitones) * 100 + cents }

    public var transposeFactor: Double { pow(2, pitchCents / 1200) }

    /// The tonality limit and formant correction act only on a pitch shift, so they do not count.
    public var isEmpty: Bool { rate == 1 && pitchCents == 0 && formantSemitones == 0 }

    public init(
        semitones: Int = 0,
        cents: Double = 0,
        rate: Double = 1,
        tonalityLimitHz: Double = 0,
        formantCorrection: Bool = false,
        formantBaseHz: Double = 0,
        formantSemitones: Double = 0
    ) {
        self.semitones = semitones.clamped(to: Self.semitoneRange)
        self.cents = Self.clamp(cents, into: Self.centRange, otherwise: 0)
        self.rate = Self.clamp(rate, into: Self.rateRange, otherwise: 1)
        self.tonalityLimitHz = Self.clampOptional(tonalityLimitHz, into: Self.tonalityLimitRange)
        self.formantCorrection = formantCorrection
        self.formantBaseHz = Self.clampOptional(formantBaseHz, into: Self.formantBaseRange)
        self.formantSemitones = Self.clamp(formantSemitones, into: Self.formantShiftRange, otherwise: 0)
    }

    /// `rate = targetBpm / sourceBpm`, clamped into ``rateRange``.
    public init(targetBpm: Bpm, sourceBpm: Bpm, semitones: Int = 0, cents: Double = 0) {
        self.init(semitones: semitones, cents: cents, rate: targetBpm.rawValue / sourceBpm.rawValue)
    }

    /// Output frames for `inputFrames` source frames: `round(inputFrames / rate)`, half away from zero.
    public func outputFrameCount(forInput inputFrames: Int) -> Int {
        Int((Double(inputFrames) / rate).rounded())
    }

    private static func clamp(_ value: Double, into range: ClosedRange<Double>, otherwise fallback: Double) -> Double {
        value.isFinite ? value.clamped(to: range) : fallback
    }

    /// 0 (or anything non-positive) keeps its meaning of off or automatic.
    private static func clampOptional(_ value: Double, into range: ClosedRange<Double>) -> Double {
        value.isFinite && value > 0 ? value.clamped(to: range) : 0
    }
}

// MARK: - Codable

extension TimePitchDescription: Codable {
    private enum CodingKeys: String, CodingKey {
        case semitones, cents, rate, tonalityLimitHz, formantCorrection, formantBaseHz, formantSemitones
    }

    public init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.init(
            semitones: try c.decodeIfPresent(Int.self, forKey: .semitones) ?? 0,
            cents: try c.decodeIfPresent(Double.self, forKey: .cents) ?? 0,
            rate: try c.decodeIfPresent(Double.self, forKey: .rate) ?? 1,
            tonalityLimitHz: try c.decodeIfPresent(Double.self, forKey: .tonalityLimitHz) ?? 0,
            formantCorrection: try c.decodeIfPresent(Bool.self, forKey: .formantCorrection) ?? false,
            formantBaseHz: try c.decodeIfPresent(Double.self, forKey: .formantBaseHz) ?? 0,
            formantSemitones: try c.decodeIfPresent(Double.self, forKey: .formantSemitones) ?? 0
        )
    }

    public func encode(to encoder: any Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(semitones, forKey: .semitones)
        try c.encode(cents, forKey: .cents)
        try c.encode(rate, forKey: .rate)
        try c.encode(tonalityLimitHz, forKey: .tonalityLimitHz)
        try c.encode(formantCorrection, forKey: .formantCorrection)
        try c.encode(formantBaseHz, forKey: .formantBaseHz)
        try c.encode(formantSemitones, forKey: .formantSemitones)
    }
}

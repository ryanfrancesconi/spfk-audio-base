import Foundation
import SPFKBase
import SwiftExtensions

public struct LoudnessDescription: Comparable, Hashable, Sendable {
    public static func < (lhs: LoudnessDescription, rhs: LoudnessDescription) -> Bool {
        guard let lhs = lhs.loudnessIntegrated,
              let rhs = rhs.loudnessIntegrated else { return false }

        return lhs < rhs
    }

    /// Integrated Loudness Value of the file in LUFS dB. (Note: Added in version 2.)
    public var loudnessIntegrated: Float64?

    /// Loudness Range of the file in LU. (Note: Added in version 2.)
    public var loudnessRange: Float64?

    /// Maximum True Peak Value of the file (dBTP). (Note: Added in version 2.)
    public var maxTruePeakLevel: Float32?

    /// highest value of the Momentary Loudness Level of the file in LUFS dB. (Note: Added in version 2.)
    public var maxMomentaryLoudness: Float64?

    /// highest value of the Short-term Loudness Level of the file in LUFS dB. (Note: Added in version 2.)
    public var maxShortTermLoudness: Float64?

    /// A summary string of all values
    public var stringValue: String {
        var out = ""

        let lufsString = loudnessIntegrated?.string(decimalPlaces: 1) ?? "N/A"
        out += "I \(lufsString) LUFS, "

        let truePeakString = maxTruePeakLevel?.string(decimalPlaces: 1) ?? "N/A"
        out += "TP \(truePeakString) dB, "

        let loudnessRangeString = loudnessRange?.string(decimalPlaces: 1) ?? "N/A"
        out += "LRA \(loudnessRangeString) LU"

        if let value = maxMomentaryLoudness?.string(decimalPlaces: 1) {
            out += ", M \(value) LU"
        }

        if let value = maxShortTermLoudness?.string(decimalPlaces: 1) {
            out += ", S \(value) LU"
        }

        return out
    }

    public init(
        loudnessIntegrated: Float64? = nil,
        loudnessRange: Float64? = nil,
        maxTruePeakLevel: Float32? = nil,
        maxMomentaryLoudness: Float64? = nil,
        maxShortTermLoudness: Float64? = nil
    ) {
        self.loudnessIntegrated = loudnessIntegrated
        self.loudnessRange = loudnessRange
        self.maxTruePeakLevel = maxTruePeakLevel
        self.maxMomentaryLoudness = maxMomentaryLoudness
        self.maxShortTermLoudness = maxShortTermLoudness
    }

    /// 0x7fff might be used to designate an unused value
    /// valid audio range in spec is: -99.99 ... 99.99
    /// invalid = 0x7FFF / 100 // 327.67 (short.max)
    static func isValid(value: some BinaryFloatingPoint & Comparable) -> Bool {
        (-99.99 ... 99.99).contains(value)
    }

    public func validated() -> LoudnessDescription {
        var desc = self

        if let value = loudnessIntegrated, !Self.isValid(value: value) {
            desc.loudnessIntegrated = nil
        }

        if let value = loudnessRange, !Self.isValid(value: value) {
            desc.loudnessRange = nil
        }

        if let value = maxTruePeakLevel, !Self.isValid(value: value) {
            desc.maxTruePeakLevel = nil
        }

        if let value = maxMomentaryLoudness, !Self.isValid(value: value) {
            desc.maxMomentaryLoudness = nil
        }

        if let value = maxShortTermLoudness, !Self.isValid(value: value) {
            desc.maxShortTermLoudness = nil
        }

        return desc
    }

    // don't check LRA here, a value of zero is valid
    public var isValid: Bool {
        loudnessIntegrated != nil ||
            maxTruePeakLevel != nil ||
            maxMomentaryLoudness != nil ||
            maxShortTermLoudness != nil
    }
}

extension LoudnessDescription: Codable {
    enum CodingKeys: String, CodingKey {
        case loudnessIntegrated
        case loudnessRange
        case maxMomentaryLoudness
        case maxShortTermLoudness
        case maxTruePeakLevel
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        loudnessIntegrated = try? container.decodeIfPresent(Float64.self, forKey: .loudnessIntegrated)
        loudnessRange = try? container.decodeIfPresent(Float64.self, forKey: .loudnessRange)
        maxTruePeakLevel = try? container.decodeIfPresent(Float32.self, forKey: .maxTruePeakLevel)
        maxMomentaryLoudness = try? container.decodeIfPresent(Float64.self, forKey: .maxMomentaryLoudness)
        maxShortTermLoudness = try? container.decodeIfPresent(Float64.self, forKey: .maxShortTermLoudness)
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try? container.encodeIfPresent(loudnessIntegrated, forKey: .loudnessIntegrated)
        try? container.encodeIfPresent(loudnessRange, forKey: .loudnessRange)
        try? container.encodeIfPresent(maxTruePeakLevel, forKey: .maxTruePeakLevel)
        try? container.encodeIfPresent(maxMomentaryLoudness, forKey: .maxMomentaryLoudness)
        try? container.encodeIfPresent(maxShortTermLoudness, forKey: .maxShortTermLoudness)
    }
}

extension [LoudnessDescription] {
    /// Create a single average object representing all values
    public var average: LoudnessDescription {
        var out = LoudnessDescription()

        let values = self.map { $0.validated() }.filter(\.isValid)

        guard values.isNotEmpty else {
            return out
        }

        let loudnessValue = values.compactMap(\.loudnessIntegrated)
        if loudnessValue.count > 0 {
            out.loudnessIntegrated = loudnessValue.reduce(0, +) / Float64(loudnessValue.count)
        }

        let loudnessRange = values.compactMap(\.loudnessRange)
        if loudnessRange.count > 0 {
            out.loudnessRange = loudnessRange.reduce(0, +) / Float64(loudnessRange.count)
        }

        let truePeak = values.compactMap(\.maxTruePeakLevel)
        if truePeak.count > 0 {
            out.maxTruePeakLevel = truePeak.reduce(0, +) / Float32(truePeak.count)
        }

        let maxMomentaryLoudness = values.compactMap(\.maxMomentaryLoudness)
        if maxMomentaryLoudness.count > 0 {
            out.maxMomentaryLoudness = maxMomentaryLoudness.reduce(0, +) / Float64(maxMomentaryLoudness.count)
        }

        let maxShortTermLoudness = values.compactMap(\.maxShortTermLoudness)
        if maxShortTermLoudness.count > 0 {
            out.maxShortTermLoudness = maxShortTermLoudness.reduce(0, +) / Float64(maxShortTermLoudness.count)
        }

        return out
    }
}

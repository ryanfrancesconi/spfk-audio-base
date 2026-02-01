import Foundation
import SPFKBase
import SwiftExtensions

public struct LoudnessDescription: Comparable, Hashable, Codable, Sendable {
    public static func < (lhs: LoudnessDescription, rhs: LoudnessDescription) -> Bool {
        guard let lhs = lhs.loudnessValue,
              let rhs = rhs.loudnessValue else { return false }

        return lhs < rhs
    }

    public var loudnessValue: Double?
    public var loudnessRange: Double?
    public var maxTruePeakLevel: Float?
    public var maxMomentaryLoudness: Double?
    public var maxShortTermLoudness: Double?

    /// A summary suitable for displaying in a UI
    public var stringValue: String {
        var out = ""

        let lufsString = loudnessValue?.string(decimalPlaces: 1) ?? "N/A"
        out += "\(lufsString) LUFS, "

        let truePeakString = maxTruePeakLevel?.string(decimalPlaces: 1) ?? "N/A"
        out += "\(truePeakString) dBTP, "

        let loudnessRangeValue: Double? = loudnessRange == 0 ? nil : loudnessRange
        let loudnessRangeString = loudnessRangeValue?.string(decimalPlaces: 1) ?? "N/A"
        out += "\(loudnessRangeString) LRA"

        return out
    }

    public init(
        loudnessValue: Double? = nil,
        loudnessRange: Double? = nil,
        maxTruePeakLevel: Float? = nil,
        maxMomentaryLoudness: Double? = nil,
        maxShortTermLoudness: Double? = nil
    ) {
        self.loudnessValue = loudnessValue
        self.loudnessRange = loudnessRange
        self.maxTruePeakLevel = maxTruePeakLevel
        self.maxMomentaryLoudness = maxMomentaryLoudness
        self.maxShortTermLoudness = maxShortTermLoudness
    }
}

extension LoudnessDescription {
    public static func averageLoudness(from array: [LoudnessDescription]) -> LoudnessDescription {
        var out = LoudnessDescription()

        guard array.isNotEmpty else {
            return out
        }

        let lufs = array.compactMap(\.loudnessValue).filter { !$0.isInfinite }

        if lufs.count > 0 {
            out.loudnessValue = lufs.reduce(0, +) / Double(lufs.count)
        }

        let loudnessRange = array.compactMap(\.loudnessRange)

        if loudnessRange.count > 0 {
            out.loudnessRange = loudnessRange.reduce(0, +) / Double(loudnessRange.count)
        }

        let truePeak = array.compactMap(\.maxTruePeakLevel)

        if truePeak.count > 0 {
            out.maxTruePeakLevel = truePeak.reduce(0, +) / Float(truePeak.count)
        }

        return out
    }
}

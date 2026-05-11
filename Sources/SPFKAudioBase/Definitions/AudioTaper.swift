// Copyright Ryan Francesconi. All Rights Reserved. Revision History at https://github.com/ryanfrancesconi/spfk-audio-base

import AudioToolbox

public struct AudioTaper: Codable, Equatable, Sendable {
    public var value: AUValue = 3
    public var inverseValue: AUValue { 1 / value }
    public var skew: AUValue = 0.333

    public init(value: AUValue, skew: AUValue) {
        self.value = value
        self.skew = skew
    }
}

// MARK: - Codable

extension AudioTaper {
    private enum CodingKeys: String, CodingKey {
        case value, skew
    }

    public init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        value = try c.decodeIfPresent(AUValue.self, forKey: .value) ?? 3
        skew = try c.decodeIfPresent(AUValue.self, forKey: .skew) ?? 0.333
    }

    public func encode(to encoder: any Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(value, forKey: .value)
        try c.encode(skew, forKey: .skew)
    }
}

// MARK: - Presets

extension AudioTaper {
    /// Half pipe
    public static let `default` = AudioTaper(value: 3, skew: 1 / 3)

    /// Straight line
    public static let linear = AudioTaper(value: 1, skew: 0)

    /// Inverse of .default
    public static let reverseAudio = AudioTaper(value: 1 / 3, skew: 1 / 3)
}

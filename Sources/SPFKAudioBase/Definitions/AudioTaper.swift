// Copyright Ryan Francesconi. All Rights Reserved. Revision History at https://github.com/ryanfrancesconi/spfk-audio-base

import AudioToolbox

/// Describes the shape of a fade or gain-ramp curve via a power-law exponent and a blend weight.
///
/// `value` sets the curvature exponent and `skew` adjusts the curve shape by blending
/// between curve variants. The exact blend formula is consumer-specific: PCM buffer fading
/// blends the power-law curve with a linear ramp, while parameter automation blends the
/// forward curve with its inverse (concave ↔ convex). Use the named presets rather than
/// constructing raw values — the two properties are only meaningful together.
public struct AudioTaper: Codable, Equatable, Sendable {
    /// Power-law exponent. Values > 1 produce a concave (slow-start) curve;
    /// values < 1 produce a convex (fast-start) curve; 1 is linear.
    public var value: AUValue = 3
    public var inverseValue: AUValue { 1 / value }
    /// Blend weight in [0, 1] that adjusts the curve shape away from the pure power-law.
    /// At `0`, behavior is governed entirely by `value`. At the default of `1/3`, the curve
    /// is softened so it doesn't hug 0 or 1 too aggressively at the extremes.
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
    /// Concave (slow-start) curve — the standard audio fade shape.
    public static let `default` = AudioTaper(value: 3, skew: 1 / 3)

    /// Straight line — no curve applied.
    public static let linear = AudioTaper(value: 1, skew: 0)

    /// Convex (fast-start) curve — the mirror image of ``default``.
    public static let reverseAudio = AudioTaper(value: 1 / 3, skew: 1 / 3)
}

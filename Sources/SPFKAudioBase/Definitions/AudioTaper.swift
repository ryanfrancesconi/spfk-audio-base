// Copyright Ryan Francesconi. All Rights Reserved. Revision History at https://github.com/ryanfrancesconi/spfk-audio-base

import AudioToolbox
import CoreGraphics
import SPFKAudioBaseC

/// Describes the shape of a fade or gain-ramp curve via a power-law exponent and a blend weight.
///
/// `value` sets the curvature exponent and `skew` blends that power curve with its own
/// inverse (concave ↔ convex). Every consumer — PCM buffer fading, parameter automation
/// and the drawn overlay — evaluates ``gain(at:)`` / ``fadeOutGain(at:)``, so a fade renders
/// as it was auditioned. Use the named presets rather than constructing raw values — the
/// two properties are only meaningful together.
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

    /// All named presets in display order: default → linear → reverseAudio.
    public static let presets: [AudioTaper] = [.default, .linear, .reverseAudio]

    /// Returns the preset at `index`, or `nil` if out of range.
    public static func preset(at index: Int) -> AudioTaper? {
        guard presets.indices.contains(index) else { return nil }
        return presets[index]
    }

    /// Index of this taper in ``presets``, or `nil` if it is not a named preset.
    public var presetIndex: Int? { AudioTaper.presets.firstIndex(of: self) }

    /// The taper that traces this one backwards in time: a fade-out on it, played reversed, is a
    /// fade-in on the result, and the reverse.
    public var timeMirrored: AudioTaper {
        AudioTaper(value: value, skew: 1 - skew)
    }
}

// MARK: - Curve

extension AudioTaper {
    /// Gain value at normalized position `t` ∈ [0, 1] using the blend formula, through
    /// `spfk_taper_gain`, the evaluation the render thread shares.
    public func gain(at t: Double) -> Double {
        spfk_taper_gain(t, Double(value), Double(skew))
    }

    /// Gain value at normalized fade-out position `s` ∈ [0, 1] (0 = fade start, 1 = silence).
    /// The descending ramp of the inverse taper: `1 − gain(at: s)` with exponent `1 / value`.
    public func fadeOutGain(at s: Double) -> Double {
        1 - spfk_taper_gain(s, 1 / Double(value), Double(skew))
    }

    /// Returns a `CGPath` tracing the gain curve for this taper across `rect`.
    /// - Parameters:
    ///   - flipped: `false` = fade-in orientation (bottom-left → top-right);
    ///              `true`  = fade-out orientation (top-left → bottom-right).
    ///   - steps: Number of line segments. Higher values produce smoother curves.
    public func curvePath(in rect: CGRect, flipped: Bool = false, steps: Int = 40) -> CGPath {
        let path = CGMutablePath()
        for i in 0 ... steps {
            let t = Double(i) / Double(steps)
            let gain = gain(at: t)
            let x = rect.minX + rect.width * (flipped ? (1.0 - t) : t)
            let y = flipped
                ? rect.minY + rect.height * (1.0 - gain)
                : rect.maxY - rect.height * gain
            let point = CGPoint(x: x, y: y)
            if i == 0 { path.move(to: point) } else { path.addLine(to: point) }
        }
        return path
    }
}

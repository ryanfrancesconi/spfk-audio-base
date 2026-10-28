// Copyright Ryan Francesconi. All Rights Reserved. Revision History at https://github.com/ryanfrancesconi/spfk-audio-base

import Foundation
import SPFKBase

/// Which detected transient candidates count as transients. Changing these re-picks from the
/// candidates already found; it never re-scans the audio.
public struct TransientDetectorOptions: Equatable, Sendable, Codable {
    public static let sensitivityRange: ClosedRange<Float> = 0 ... 1
    public static let minimumSpacingRange: ClosedRange<TimeInterval> = 0.03 ... 0.5

    /// 0 keeps only the strongest attacks, 1 nearly every candidate. Default 0.5.
    public var sensitivity: Float = 0.5

    /// Of two transients closer than this, the stronger is kept. Default 0.05 s.
    public var minimumSpacing: TimeInterval = 0.05

    /// The least candidate strength `sensitivity` keeps: 2.274 at 0, 0.2274 at 0.5, 0.02274 at 1.
    public var strengthThreshold: Float {
        let sensitivity = sensitivity.clamped(to: Self.sensitivityRange)
        return 0.2274 * powf(10, 1 - 2 * sensitivity)
    }

    public init(sensitivity: Float = 0.5, minimumSpacing: TimeInterval = 0.05) {
        self.sensitivity = sensitivity.clamped(to: Self.sensitivityRange)
        self.minimumSpacing = minimumSpacing.clamped(to: Self.minimumSpacingRange)
    }

    // Forward-compatible decode: fields added in future versions fall back to their defaults.
    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.init(
            sensitivity: try c.decodeIfPresent(Float.self, forKey: .sensitivity) ?? 0.5,
            minimumSpacing: try c.decodeIfPresent(TimeInterval.self, forKey: .minimumSpacing) ?? 0.05
        )
    }
}

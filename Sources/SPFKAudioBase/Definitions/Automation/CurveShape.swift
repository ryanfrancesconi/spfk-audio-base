// Copyright Ryan Francesconi. All Rights Reserved. Revision History at https://github.com/ryanfrancesconi/spfk-audio-base

import Foundation
import SPFKAudioBaseC

/// How a ``CurveSegment`` moves from its start value to its end value: a map from normalized
/// position x ∈ [0, 1] to y ∈ [0, 1].
public enum CurveShape: Codable, Equatable, Sendable {
    case linear

    /// ``AudioTaper``'s exponent and blend weight, evaluated by `spfk_taper_gain`.
    case taper(value: Double, skew: Double)

    /// The start value up to the segment's end, then the end value.
    case step
}

extension CurveShape {
    public init(_ taper: AudioTaper) {
        self = .taper(value: Double(taper.value), skew: Double(taper.skew))
    }

    var isValid: Bool {
        guard case let .taper(value, skew) = self else { return true }
        return value.isFinite && value > 0 && skew.isFinite
    }

    var kind: SPFKCurveShapeKind {
        switch self {
        case .linear: .linear
        case .taper: .taper
        case .step: .step
        }
    }
}

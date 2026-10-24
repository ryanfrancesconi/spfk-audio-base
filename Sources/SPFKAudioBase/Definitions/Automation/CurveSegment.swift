// Copyright Ryan Francesconi. All Rights Reserved. Revision History at https://github.com/ryanfrancesconi/spfk-audio-base

import AudioToolbox
import Foundation
import SPFKAudioBaseC

/// One shaped move of a parameter, in seconds of source time.
///
/// `startValue` and `endValue` are the shape's values at 0 and 1. A segment cut by
/// ``ParameterCurve/replacing(range:with:)`` covers only part of its shape, recorded in
/// `shapeRange`, so the cut evaluates exactly as the whole did.
public struct CurveSegment: Codable, Equatable, Sendable {
    public var start: Double
    public var end: Double
    public var startValue: AUValue
    public var endValue: AUValue
    public var shape: CurveShape

    /// The normalized part of `shape` this segment covers; `0 ... 1` unless it was cut.
    public var shapeRange: ClosedRange<Double>

    public init(
        start: Double,
        end: Double,
        startValue: AUValue,
        endValue: AUValue,
        shape: CurveShape = .linear,
        shapeRange: ClosedRange<Double> = 0 ... 1
    ) {
        self.start = start
        self.end = end
        self.startValue = startValue
        self.endValue = endValue
        self.shape = shape
        self.shapeRange = shapeRange
    }

    /// The segment's value at `position`, held at its ends outside it.
    public func value(at position: Double) -> AUValue {
        var segment = cSegment
        return AUValue(spfk_curve_segment_value(&segment, position))
    }

    var isValid: Bool {
        start.isFinite && end.isFinite && startValue.isFinite && endValue.isFinite && shape.isValid
            && shapeRange.lowerBound >= 0 && shapeRange.upperBound <= 1
    }

    /// The two halves either side of `position`, which lies strictly inside the segment.
    func split(at position: Double) -> (CurveSegment, CurveSegment) {
        let u = (position - start) / (end - start)
        let x = shapeRange.lowerBound + (shapeRange.upperBound - shapeRange.lowerBound) * u

        var left = self, right = self
        left.end = position
        left.shapeRange = shapeRange.lowerBound ... x
        right.start = position
        right.shapeRange = x ... shapeRange.upperBound
        return (left, right)
    }

    var cSegment: SPFKCurveSegment {
        var taper = (value: 1.0, skew: 0.0)
        if case let .taper(value, skew) = shape { taper = (value, skew) }

        return SPFKCurveSegment(
            start: start,
            end: end,
            shapeStart: shapeRange.lowerBound,
            shapeEnd: shapeRange.upperBound,
            startValue: Double(startValue),
            endValue: Double(endValue),
            shape: shape.kind,
            taperValue: taper.value,
            taperSkew: taper.skew
        )
    }
}

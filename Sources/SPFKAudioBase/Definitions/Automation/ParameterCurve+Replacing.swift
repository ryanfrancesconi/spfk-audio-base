// Copyright Ryan Francesconi. All Rights Reserved. Revision History at https://github.com/ryanfrancesconi/spfk-audio-base

import Foundation

extension ParameterCurve {
    public enum ReplacementError: Error, Equatable {
        case invalidRange
        /// The replacement segment at `index` reaches outside the range it replaces.
        case outsideRange(index: Int)
    }

    /// This curve with `range` replaced by `replacement`, the recording merge.
    ///
    /// Outside `range` the curve is unchanged: a segment crossing a bound is cut there and keeps
    /// its shape, and where a bound falls in a hold, a zero-length segment keeps the held value.
    /// Inside, gaps between replacement segments hold as in any curve.
    public func replacing(range: Range<Double>, with replacement: [CurveSegment]) throws -> ParameterCurve {
        let lower = range.lowerBound, upper = range.upperBound
        guard lower.isFinite, upper.isFinite else { throw ReplacementError.invalidRange }

        for (index, segment) in replacement.enumerated() where segment.start < lower || segment.end > upper {
            throw ReplacementError.outsideRange(index: index)
        }

        var before: [CurveSegment] = []
        var after: [CurveSegment] = []

        for segment in segments {
            if segment.start < lower {
                before.append(segment.end > lower ? segment.split(at: lower).0 : segment)
            }

            if segment.start >= upper {
                after.append(segment)
            } else if segment.end > upper, segment.start < upper {
                after.append(segment.split(at: upper).1)
            }
        }

        var merged = before

        // With nothing left before `lower`, the first segment is what holds there.
        if before.isEmpty {
            let held = value(at: -.infinity)
            merged.append(CurveSegment(start: lower, end: lower, startValue: held, endValue: held))
        }

        merged += replacement

        if after.first?.start != upper {
            let held = value(at: upper)
            merged.append(CurveSegment(start: upper, end: upper, startValue: held, endValue: held))
        }

        return try ParameterCurve(merged + after)
    }
}

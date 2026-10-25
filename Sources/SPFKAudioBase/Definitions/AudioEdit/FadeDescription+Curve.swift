// Copyright Ryan Francesconi. All Rights Reserved. Revision History at https://github.com/ryanfrancesconi/spfk-audio-base

import AudioToolbox
import Foundation

extension FadeDescription {
    /// Which fade keeps its length when the two cannot both fit.
    public enum Priority: Sendable {
        case fadeIn
        case fadeOut
    }

    /// A copy whose fades fit inside a region of `duration` seconds without overlapping: the fade
    /// named by `priority` keeps its length and the other is shortened. Both are 0 for a region
    /// of 0 or less.
    public func clamped(toRegion duration: TimeInterval, favoring priority: Priority = .fadeOut) -> FadeDescription {
        var result = self
        guard duration > 0 else {
            result.inTime = 0
            result.outTime = 0
            return result
        }

        let inTime = max(0, self.inTime), outTime = max(0, self.outTime)

        switch priority {
        case .fadeOut:
            result.inTime = min(inTime, max(0, duration - outTime))
            result.outTime = min(outTime, max(0, duration - result.inTime))
        case .fadeIn:
            result.outTime = min(outTime, max(0, duration - inTime))
            result.inTime = min(inTime, max(0, duration - result.outTime))
        }
        return result
    }

    /// The same fades on the time-reversed region: each stays on the material it covered, so the
    /// fade-out becomes the fade-in on ``AudioTaper/timeMirrored`` and the reverse. Clamped first,
    /// so an overlap resolves in favor of the original fade-out.
    public func mirroredForReverse(regionDuration: TimeInterval) -> FadeDescription {
        let fade = clamped(toRegion: regionDuration)
        return FadeDescription(
            inTime: fade.outTime,
            outTime: fade.inTime,
            inTaper: fade.outTaper.timeMirrored,
            outTaper: fade.inTaper.timeMirrored
        )
    }

    /// The gain these fades apply over a region of `regionDuration` seconds, in seconds from the
    /// region's start, clamped with ``clamped(toRegion:favoring:)`` favoring the fade-out.
    ///
    /// The fade-in rises from 0 to `maximumGain` on ``inTaper``; the fade-out falls on the
    /// descending inverse of ``outTaper``, which is ``AudioTaper/fadeOutGain(at:)``.
    public func curve(regionDuration: TimeInterval, maximumGain: AUValue = 1) throws -> ParameterCurve {
        let fade = clamped(toRegion: regionDuration)
        var segments: [CurveSegment] = []

        if fade.inTime > 0 {
            segments.append(
                CurveSegment(start: 0, end: fade.inTime, startValue: 0, endValue: maximumGain, shape: CurveShape(fade.inTaper))
            )
        }

        if fade.outTime > 0 {
            // Touching fades can round a ulp into each other; the fade-in's end is the boundary.
            segments.append(
                CurveSegment(
                    start: max(regionDuration - fade.outTime, fade.inTime),
                    end: regionDuration,
                    startValue: maximumGain,
                    endValue: 0,
                    shape: .taper(value: 1 / Double(fade.outTaper.value), skew: Double(fade.outTaper.skew))
                )
            )
        }

        guard !segments.isEmpty else { return try ParameterCurve(constant: maximumGain) }
        return try ParameterCurve(segments)
    }
}

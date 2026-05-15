// Copyright Ryan Francesconi. All Rights Reserved.

import Foundation

extension AudioEditDescription {
    /// Proportionally clamps fade-in and fade-out so their sum does not exceed `duration`.
    /// When the total exceeds `duration`, both are scaled down by the same factor so each
    /// fade retains its relative proportion. Returns the original values unchanged otherwise.
    public static func clampedFades(
        inTime: TimeInterval,
        outTime: TimeInterval,
        duration: TimeInterval
    ) -> (inTime: TimeInterval, outTime: TimeInterval) {
        let total = inTime + outTime
        guard total > duration, total > 0 else {
            return (inTime, outTime)
        }
        let scale = duration / total
        return (inTime * scale, outTime * scale)
    }

    /// Returns a copy with `inTime` and `outTime` replaced by the given values.
    /// All other fields (`trim`, `isReversed`, `fade.taper`) are preserved.
    public func settingFades(inTime: TimeInterval, outTime: TimeInterval) -> AudioEditDescription {
        var copy = self
        copy.fade.inTime = inTime
        copy.fade.outTime = outTime
        return copy
    }

    /// Returns a copy with both fades zeroed.
    /// All other fields (`trim`, `isReversed`, `fade.taper`) are preserved.
    public func clearingFades() -> AudioEditDescription {
        settingFades(inTime: 0, outTime: 0)
    }

    /// Returns fade durations derived from a waveform selection.
    ///
    /// When the selection starts at or near time 0 (within `tolerance`), the fade-in equals the
    /// selection duration. When it ends at or near the file duration, the fade-out equals the
    /// selection duration. Both can apply when the selection spans the entire file.
    ///
    /// Returns `nil` when the selection is fully interior — no boundary is touched and no
    /// meaningful fade can be inferred.
    public static func selectionFades(
        selectionStart: TimeInterval,
        selectionEnd: TimeInterval,
        duration: TimeInterval,
        tolerance: TimeInterval = 0.001
    ) -> (inTime: TimeInterval, outTime: TimeInterval)? {
        let selDuration = selectionEnd - selectionStart
        guard selDuration > 0, duration > 0 else { return nil }

        let atStart = selectionStart < tolerance
        let atEnd = selectionEnd > duration - tolerance
        guard atStart || atEnd else { return nil }

        return (
            inTime: atStart ? selDuration : 0,
            outTime: atEnd ? selDuration : 0
        )
    }
}

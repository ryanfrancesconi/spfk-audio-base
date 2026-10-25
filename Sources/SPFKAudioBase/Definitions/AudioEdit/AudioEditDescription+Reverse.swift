// Copyright Ryan Francesconi. All Rights Reserved. Revision History at https://github.com/ryanfrancesconi/spfk-audio-base

import Foundation
import SPFKBase

extension AudioEditDescription {
    /// This edit as it appears on the reversed file of `duration` seconds: the trim window mirrored
    /// to [D − out, D − in] and the fades mirrored over it. Its own inverse, so it converts in both
    /// directions. Every other part, `isReversed` included, is copied.
    public func reversedView(duration: TimeInterval) -> AudioEditDescription {
        var copy = self
        copy.trim = trim.mirrored(duration: duration)
        copy.fade = fade.mirroredForReverse(regionDuration: effectiveDuration(fileDuration: duration))
        return copy
    }
}

extension TrimDescription {
    /// The window [D − out, D − in], with an out point of 0 read as `duration` and an out point
    /// landing on `duration` written back as 0.
    public func mirrored(duration: TimeInterval) -> TrimDescription {
        let end = outPoint > 0 ? outPoint : duration
        let mirroredIn = max(0, duration - end)
        let mirroredOut = duration - inPoint
        return TrimDescription(
            inPoint: mirroredIn,
            outPoint: mirroredOut >= duration || mirroredOut <= mirroredIn ? 0 : mirroredOut
        )
    }
}

// Copyright Ryan Francesconi. All Rights Reserved. Revision History at https://github.com/ryanfrancesconi/spfk-audio-base

import Foundation
import SPFKBase

/// One independently renderable part of an ``AudioEditDescription``, in pipeline order.
public enum AudioEditKind: String, Hashable, Sendable, CaseIterable {
    case trim
    case channels
    case reverse
    case normalize
    case fade
    case timePitch
}

extension AudioEditDescription {
    /// The kinds this description holds a non-empty value for.
    public var activeKinds: Set<AudioEditKind> {
        var kinds = Set<AudioEditKind>()
        if !trim.isEmpty { kinds.insert(.trim) }
        if channels != .none { kinds.insert(.channels) }
        if isReversed { kinds.insert(.reverse) }
        if !normalize.isEmpty { kinds.insert(.normalize) }
        if !fade.isEmpty { kinds.insert(.fade) }
        if !timePitch.isEmpty { kinds.insert(.timePitch) }
        return kinds
    }

    /// A copy keeping only `kinds`, with every other part reset to its identity.
    public func masked(to kinds: Set<AudioEditKind>) -> AudioEditDescription {
        AudioEditDescription(
            trim: kinds.contains(.trim) ? trim : TrimDescription(),
            channels: kinds.contains(.channels) ? channels : .none,
            isReversed: kinds.contains(.reverse) && isReversed,
            normalize: kinds.contains(.normalize) ? normalize : NormalizeDescription(),
            fade: kinds.contains(.fade) ? fade : FadeDescription(),
            timePitch: kinds.contains(.timePitch) ? timePitch : TimePitchDescription()
        )
    }
}

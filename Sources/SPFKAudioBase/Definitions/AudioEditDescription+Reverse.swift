// Copyright Ryan Francesconi. All Rights Reserved.

import Foundation

extension AudioEditDescription {
    /// Returns a copy with `isReversed` set to the given value.
    /// All other fields (`trim`, `fade`) are preserved.
    public func settingReversed(_ reversed: Bool) -> AudioEditDescription {
        var copy = self
        copy.isReversed = reversed
        return copy
    }
}

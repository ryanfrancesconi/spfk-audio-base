// Copyright Ryan Francesconi. All Rights Reserved. Revision History at https://github.com/ryanfrancesconi/spfk-audio-base

import Foundation

/// One possible transient, before ``TransientDetectorOptions`` decide whether it counts.
public struct TransientCandidate: Sendable, Equatable {
    /// The onset in source time, in seconds.
    public let time: TimeInterval

    /// Onset strength, independent of any options. ``TransientDetectorOptions/strengthThreshold``
    /// is on the same scale.
    public let strength: Float

    public init(time: TimeInterval, strength: Float) {
        self.time = time
        self.strength = strength
    }
}

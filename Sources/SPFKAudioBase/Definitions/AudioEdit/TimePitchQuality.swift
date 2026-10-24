// Copyright Ryan Francesconi. All Rights Reserved. Revision History at https://github.com/ryanfrancesconi/spfk-audio-base

import Foundation

/// The stretcher's CPU and quality trade-off. Preview and every render use the same one.
public enum TimePitchQuality: String, Codable, Sendable, CaseIterable {
    /// 120 ms blocks at a 30 ms interval.
    case best
    /// 100 ms blocks at a 40 ms interval.
    case efficient
}

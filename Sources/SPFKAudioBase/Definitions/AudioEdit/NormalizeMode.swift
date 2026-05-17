// Copyright Ryan Francesconi. All Rights Reserved.

import Foundation

/// Algorithm used during a normalization analysis pass.
public enum NormalizeMode: String, Codable, Sendable, CaseIterable {
    /// EBU R128 integrated loudness measurement.
    case lufs
    /// Sample peak measurement.
    case peak
}

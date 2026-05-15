// Copyright Ryan Francesconi. All Rights Reserved.

import Foundation

/// Describes an in/out trim window applied to an audio file or region.
/// Both values default to 0, meaning no trim is applied.
public struct TrimDescription: Equatable, Sendable, Codable {
    /// Start of the playback/render window in seconds. 0 means start from the beginning.
    public var inPoint: TimeInterval = 0

    /// End of the playback/render window in seconds. 0 means play to the end of the file.
    public var outPoint: TimeInterval = 0

    /// True when no trim is configured.
    public var isEmpty: Bool { inPoint == 0 && outPoint == 0 }

    public init(inPoint: TimeInterval = 0, outPoint: TimeInterval = 0) {
        self.inPoint = inPoint
        self.outPoint = outPoint
    }
}

// Copyright Ryan Francesconi. All Rights Reserved. Revision History at https://github.com/ryanfrancesconi/spfk-audio-base

import Foundation

/// How a render that would clip is brought under 0 dBFS.
public enum ClippingCeiling: String, Codable, Sendable, CaseIterable {
    /// Lower the whole render until its peak is at the ceiling.
    case scale
    /// Keep the level and pull down only the peaks, with a lookahead limiter.
    case limit
}

/// App-wide choices a render of pending edits follows.
public struct AudioRenderSettings: Hashable, Codable, Sendable {
    public var ceiling: ClippingCeiling = .scale

    /// The stretcher setting a preview and every render of a time/pitch edit share.
    public var timePitchQuality: TimePitchQuality = .best

    public init(ceiling: ClippingCeiling = .scale, timePitchQuality: TimePitchQuality = .best) {
        self.ceiling = ceiling
        self.timePitchQuality = timePitchQuality
    }

    private enum CodingKeys: String, CodingKey {
        case ceiling, timePitchQuality
    }

    public init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        ceiling = try c.decodeIfPresent(ClippingCeiling.self, forKey: .ceiling) ?? .scale
        timePitchQuality = try c.decodeIfPresent(TimePitchQuality.self, forKey: .timePitchQuality) ?? .best
    }
}

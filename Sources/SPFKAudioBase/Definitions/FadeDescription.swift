// Copyright Ryan Francesconi. All Rights Reserved.

import Foundation

/// Describes a fade-in and fade-out applied to an audio file or region,
/// along with the taper curve shared by both.
public struct FadeDescription: Equatable, Sendable {
    /// Fade-in duration in seconds.
    public var inTime: TimeInterval = 0

    /// Fade-out duration in seconds.
    public var outTime: TimeInterval = 0

    /// Taper curve applied to both fade-in and fade-out.
    public var taper: AudioTaper = .default

    /// True when no fade is configured.
    public var isEmpty: Bool { inTime == 0 && outTime == 0 }

    public init(
        inTime: TimeInterval = 0,
        outTime: TimeInterval = 0,
        taper: AudioTaper = .default
    ) {
        self.inTime = inTime
        self.outTime = outTime
        self.taper = taper
    }
}

// MARK: - Codable

extension FadeDescription: Codable {
    private enum CodingKeys: String, CodingKey {
        case inTime, outTime, taper
        // Migration from prior format that used fadeIn/fadeOut/fadeTaper as keys
        case fadeIn, fadeOut, fadeTaper
    }

    public init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        inTime = try c.decodeIfPresent(TimeInterval.self, forKey: .inTime)
            ?? c.decodeIfPresent(TimeInterval.self, forKey: .fadeIn) ?? 0
        outTime = try c.decodeIfPresent(TimeInterval.self, forKey: .outTime)
            ?? c.decodeIfPresent(TimeInterval.self, forKey: .fadeOut) ?? 0
        taper = try c.decodeIfPresent(AudioTaper.self, forKey: .taper)
            ?? c.decodeIfPresent(AudioTaper.self, forKey: .fadeTaper) ?? .default
    }

    public func encode(to encoder: any Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(inTime, forKey: .inTime)
        try c.encode(outTime, forKey: .outTime)
        try c.encode(taper, forKey: .taper)
    }
}

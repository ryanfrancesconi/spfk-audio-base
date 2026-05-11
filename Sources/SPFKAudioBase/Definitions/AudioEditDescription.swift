// Copyright Ryan Francesconi. All Rights Reserved. Revision History at https://github.com/ryanfrancesconi

import Foundation

/// Describes a set of pending non-destructive audio edits for a file.
/// A nil instance means no edits are queued. An instance with all default
/// values (isEmpty == true) is functionally equivalent to nil.
///
/// Stored on PlaylistElement and persisted to JSON so edits survive app restarts.
/// Cleared to nil after the edit is rendered and written to disk.
///
/// Operations are applied in pipeline order: trim → reverse → fade.
public struct AudioEditDescription: Equatable, Sendable {
    // MARK: - Trim

    /// Seconds to remove from the head of the file.
    public var trimStart: TimeInterval = 0

    /// Seconds to remove from the tail of the file. Zero means no tail trim.
    public var trimEnd: TimeInterval = 0

    // MARK: - Reverse

    /// Whether the audio content should be reversed.
    public var isReversed: Bool = false

    // MARK: - Fade

    /// Fade-in duration in seconds.
    public var fadeIn: TimeInterval = 0

    /// Fade-out duration in seconds.
    public var fadeOut: TimeInterval = 0

    /// Taper curve applied to fade-in and fade-out operations.
    public var fadeTaper: AudioTaper = .default

    // MARK: -

    /// True when no edit operations are set — the description is a no-op.
    public var isEmpty: Bool {
        trimStart == 0 && trimEnd == 0 && fadeIn == 0 && fadeOut == 0 && !isReversed
    }

    public init(
        trimStart: TimeInterval = 0,
        trimEnd: TimeInterval = 0,
        isReversed: Bool = false,
        fadeIn: TimeInterval = 0,
        fadeOut: TimeInterval = 0,
        fadeTaper: AudioTaper = .default
    ) {
        self.trimStart = trimStart
        self.trimEnd = trimEnd
        self.isReversed = isReversed
        self.fadeIn = fadeIn
        self.fadeOut = fadeOut
        self.fadeTaper = fadeTaper
    }
}

// MARK: - Codable

extension AudioEditDescription: Codable {
    private enum CodingKeys: String, CodingKey {
        case trimStart, trimEnd, isReversed, fadeIn, fadeOut, fadeTaper
    }

    public init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        trimStart = try c.decodeIfPresent(TimeInterval.self, forKey: .trimStart) ?? 0
        trimEnd = try c.decodeIfPresent(TimeInterval.self, forKey: .trimEnd) ?? 0
        isReversed = try c.decodeIfPresent(Bool.self, forKey: .isReversed) ?? false
        fadeIn = try c.decodeIfPresent(TimeInterval.self, forKey: .fadeIn) ?? 0
        fadeOut = try c.decodeIfPresent(TimeInterval.self, forKey: .fadeOut) ?? 0
        fadeTaper = try c.decodeIfPresent(AudioTaper.self, forKey: .fadeTaper) ?? .default
    }

    public func encode(to encoder: any Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(trimStart, forKey: .trimStart)
        try c.encode(trimEnd, forKey: .trimEnd)
        try c.encode(isReversed, forKey: .isReversed)
        try c.encode(fadeIn, forKey: .fadeIn)
        try c.encode(fadeOut, forKey: .fadeOut)
        try c.encode(fadeTaper, forKey: .fadeTaper)
    }
}

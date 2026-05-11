// Copyright Ryan Francesconi. All Rights Reserved. Revision History at https://github.com/ryanfrancesconi

import Foundation

/// Describes a set of pending non-destructive audio edits for a file.
/// A nil instance means no edits are queued. An instance with all default
/// values (isEmpty == true) is functionally equivalent to nil.
///
/// Stored on PlaylistElement and persisted to JSON so edits survive app restarts.
/// Cleared to nil after the edit is rendered and written to disk.
///
/// Operations are applied in pipeline order: extract → reverse → fade.
public struct AudioEditDescription: Equatable, Sendable {
    // MARK: - Extract

    /// Ordered list of source time ranges to keep. Ranges are applied in sequence
    /// and their output is concatenated.
    ///
    /// Empty means keep the entire file. A single range [0.2, 0.7] trims head and tail.
    /// Multiple ranges allow mid-file deletions: [[0, 0.3], [0.6, 1.0]] removes 0.3–0.6 s.
    public var keepRanges: [AudioTimeRange] = []

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
        keepRanges.isEmpty && fadeIn == 0 && fadeOut == 0 && !isReversed
    }

    public init(
        keepRanges: [AudioTimeRange] = [],
        isReversed: Bool = false,
        fadeIn: TimeInterval = 0,
        fadeOut: TimeInterval = 0,
        fadeTaper: AudioTaper = .default
    ) {
        self.keepRanges = keepRanges
        self.isReversed = isReversed
        self.fadeIn = fadeIn
        self.fadeOut = fadeOut
        self.fadeTaper = fadeTaper
    }
}

// MARK: - Codable

extension AudioEditDescription: Codable {
    private enum CodingKeys: String, CodingKey {
        case keepRanges, isReversed, fadeIn, fadeOut, fadeTaper
    }

    public init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        keepRanges = try c.decodeIfPresent([AudioTimeRange].self, forKey: .keepRanges) ?? []
        isReversed = try c.decodeIfPresent(Bool.self, forKey: .isReversed) ?? false
        fadeIn = try c.decodeIfPresent(TimeInterval.self, forKey: .fadeIn) ?? 0
        fadeOut = try c.decodeIfPresent(TimeInterval.self, forKey: .fadeOut) ?? 0
        fadeTaper = try c.decodeIfPresent(AudioTaper.self, forKey: .fadeTaper) ?? .default
    }

    public func encode(to encoder: any Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(keepRanges, forKey: .keepRanges)
        try c.encode(isReversed, forKey: .isReversed)
        try c.encode(fadeIn, forKey: .fadeIn)
        try c.encode(fadeOut, forKey: .fadeOut)
        try c.encode(fadeTaper, forKey: .fadeTaper)
    }
}

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

    /// Start of the playback/render window in seconds. 0 means start from the beginning.
    public var inPoint: TimeInterval = 0

    /// End of the playback/render window in seconds. 0 means play to the end of the file.
    public var outPoint: TimeInterval = 0

    // MARK: - Reverse

    /// Whether the audio content should be reversed.
    public var isReversed: Bool = false

    // MARK: - Fade

    /// Fade-in, fade-out, and taper curve settings.
    public var fade: FadeDescription = FadeDescription()

    // MARK: -

    /// True when no edit operations are set — the description is a no-op.
    public var isEmpty: Bool {
        inPoint == 0 && outPoint == 0 && fade.isEmpty && !isReversed
    }

    public init(
        inPoint: TimeInterval = 0,
        outPoint: TimeInterval = 0,
        isReversed: Bool = false,
        fade: FadeDescription = FadeDescription()
    ) {
        self.inPoint = inPoint
        self.outPoint = outPoint
        self.isReversed = isReversed
        self.fade = fade
    }
}

// MARK: - Codable

extension AudioEditDescription: Codable {
    private enum CodingKeys: String, CodingKey {
        case inPoint, outPoint, isReversed, fade
        // Legacy keys decoded during migration only
        case fadeIn, fadeOut, fadeTaper
    }

    public init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        inPoint = try c.decodeIfPresent(TimeInterval.self, forKey: .inPoint) ?? 0
        outPoint = try c.decodeIfPresent(TimeInterval.self, forKey: .outPoint) ?? 0
        isReversed = try c.decodeIfPresent(Bool.self, forKey: .isReversed) ?? false

        if let savedFade = try c.decodeIfPresent(FadeDescription.self, forKey: .fade) {
            fade = savedFade
        } else {
            // Migrate from the old flat format where fadeIn/fadeOut/fadeTaper were top-level keys.
            let fadeIn = try c.decodeIfPresent(TimeInterval.self, forKey: .fadeIn) ?? 0
            let fadeOut = try c.decodeIfPresent(TimeInterval.self, forKey: .fadeOut) ?? 0
            let fadeTaper = try c.decodeIfPresent(AudioTaper.self, forKey: .fadeTaper) ?? .default
            fade = FadeDescription(inTime: fadeIn, outTime: fadeOut, taper: fadeTaper)
        }
    }

    public func encode(to encoder: any Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(inPoint, forKey: .inPoint)
        try c.encode(outPoint, forKey: .outPoint)
        try c.encode(isReversed, forKey: .isReversed)
        try c.encode(fade, forKey: .fade)
    }
}

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

    /// In/out trim window settings.
    public var trim: TrimDescription = TrimDescription()

    // MARK: - Reverse

    /// Whether the audio content should be reversed.
    public var isReversed: Bool = false

    // MARK: - Fade

    /// Fade-in, fade-out, and taper curve settings.
    public var fade: FadeDescription = FadeDescription()

    // MARK: -

    /// True when no edit operations are set — the description is a no-op.
    public var isEmpty: Bool {
        trim.isEmpty && fade.isEmpty && !isReversed
    }

    public init(
        trim: TrimDescription = TrimDescription(),
        isReversed: Bool = false,
        fade: FadeDescription = FadeDescription()
    ) {
        self.trim = trim
        self.isReversed = isReversed
        self.fade = fade
    }
}

// MARK: - Codable

extension AudioEditDescription: Codable {
    private enum CodingKeys: String, CodingKey {
        case trim, isReversed, fade
        // Legacy flat-format keys decoded during migration only
        case inPoint, outPoint, fadeIn, fadeOut, fadeTaper
    }

    public init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        isReversed = try c.decodeIfPresent(Bool.self, forKey: .isReversed) ?? false

        if let savedTrim = try c.decodeIfPresent(TrimDescription.self, forKey: .trim) {
            trim = savedTrim
        } else {
            // Migrate from the prior flat format where inPoint/outPoint were top-level keys.
            let inPoint = try c.decodeIfPresent(TimeInterval.self, forKey: .inPoint) ?? 0
            let outPoint = try c.decodeIfPresent(TimeInterval.self, forKey: .outPoint) ?? 0
            trim = TrimDescription(inPoint: inPoint, outPoint: outPoint)
        }

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
        try c.encode(trim, forKey: .trim)
        try c.encode(isReversed, forKey: .isReversed)
        try c.encode(fade, forKey: .fade)
    }
}

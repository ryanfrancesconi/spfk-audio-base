// Copyright Ryan Francesconi. All Rights Reserved. Revision History at https://github.com/ryanfrancesconi

import Foundation

/// Describes a set of pending non-destructive audio edits for a file.
/// A nil instance means no edits are queued. An instance with all default
/// values (isEmpty == true) is functionally equivalent to nil.
///
/// Stored on PlaylistElement and persisted to JSON so edits survive app restarts.
/// Cleared to nil after the edit is rendered and written to disk.
///
/// Operations are applied in pipeline order: trim → fade.
public struct AudioEditDescription: Equatable, Sendable {
    // MARK: - Trim

    /// In/out trim window settings.
    public var trim: TrimDescription = TrimDescription()

    // MARK: - Fade

    /// Fade-in, fade-out, and taper curve settings.
    public var fade: FadeDescription = FadeDescription()

    // MARK: -

    /// True when no edit operations are set — the description is a no-op.
    public var isEmpty: Bool {
        trim.isEmpty && fade.isEmpty
    }

    public init(
        trim: TrimDescription = TrimDescription(),
        fade: FadeDescription = FadeDescription()
    ) {
        self.trim = trim
        self.fade = fade
    }
}

// MARK: - Codable

extension AudioEditDescription: Codable {
    private enum CodingKeys: String, CodingKey {
        case trim, fade
    }

    public init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        trim = try c.decodeIfPresent(TrimDescription.self, forKey: .trim) ?? TrimDescription()
        fade = try c.decodeIfPresent(FadeDescription.self, forKey: .fade) ?? FadeDescription()
    }
}


// Copyright Ryan Francesconi. All Rights Reserved. Revision History at https://github.com/ryanfrancesconi/spfk-audio-base

import Foundation
import SPFKBase

/// Describes a set of pending non-destructive audio edits for a file.
/// A nil instance means no edits are queued. An instance with all default
/// values (isEmpty == true) is functionally equivalent to nil.
///
/// Stored on PlaylistElement and persisted to JSON so edits survive app restarts.
/// Cleared to nil after the edit is rendered and written to disk.
///
/// Operations are applied in pipeline order: trim → channels → reverse → time/pitch → normalize → fade.
public struct AudioEditDescription: Equatable, Sendable {
    // MARK: - Trim

    /// In/out trim window settings.
    public var trim: TrimDescription = TrimDescription()

    // MARK: - Channels

    /// A stereo channel operation, applied after the trim.
    public var channels: ChannelOperation = .none

    // MARK: - Reverse

    /// Reverses the whole trimmed window, after the channel operation and before the stretch.
    public var isReversed = false

    // MARK: - Time/pitch

    /// A change of rate and pitch, applied after the channel operation.
    public var timePitch: TimePitchDescription = TimePitchDescription()

    // MARK: - Normalize

    /// Normalization gain computed from a loudness analysis pass.
    public var normalize: NormalizeDescription = NormalizeDescription()

    // MARK: - Fade

    /// Fade-in, fade-out, and taper curve settings.
    public var fade: FadeDescription = FadeDescription()

    // MARK: -

    /// True when no edit operations are set — the description is a no-op.
    public var isEmpty: Bool {
        trim.isEmpty && channels == .none && !isReversed && normalize.isEmpty && fade.isEmpty && timePitch.isEmpty
    }

    /// True when a render of this edit can exceed 0 dBFS from something other than a normalize the
    /// user measured, so the renderer must bring it under the ceiling. A stretch raises sample peaks.
    public var needsCeiling: Bool {
        channels != .none || !timePitch.isEmpty
    }

    public init(
        trim: TrimDescription = TrimDescription(),
        channels: ChannelOperation = .none,
        isReversed: Bool = false,
        normalize: NormalizeDescription = NormalizeDescription(),
        fade: FadeDescription = FadeDescription(),
        timePitch: TimePitchDescription = TimePitchDescription()
    ) {
        self.trim = trim
        self.channels = channels
        self.isReversed = isReversed
        self.normalize = normalize
        self.fade = fade
        self.timePitch = timePitch
    }
}

// MARK: - Codable

extension AudioEditDescription: Codable {
    private enum CodingKeys: String, CodingKey {
        case trim, channels, isReversed, normalize, fade, timePitch
    }

    public init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        trim = try c.decodeIfPresent(TrimDescription.self, forKey: .trim) ?? TrimDescription()
        channels = try c.decodeIfPresent(ChannelOperation.self, forKey: .channels) ?? .none
        isReversed = try c.decodeIfPresent(Bool.self, forKey: .isReversed) ?? false
        normalize = try c.decodeIfPresent(NormalizeDescription.self, forKey: .normalize) ?? NormalizeDescription()
        fade = try c.decodeIfPresent(FadeDescription.self, forKey: .fade) ?? FadeDescription()
        timePitch = try c.decodeIfPresent(TimePitchDescription.self, forKey: .timePitch) ?? TimePitchDescription()
    }
}


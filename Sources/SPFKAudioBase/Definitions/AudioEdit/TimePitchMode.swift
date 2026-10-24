// Copyright Ryan Francesconi. All Rights Reserved. Revision History at https://github.com/ryanfrancesconi/spfk-audio-base

import Foundation

/// How the tempo of a ``TimePitchDescription`` is entered. The rate is stored either way.
public enum TimePitchMode: String, Codable, Sendable, CaseIterable {
    case rate
    /// A target BPM, available when the file's source BPM is known.
    case bpm
}

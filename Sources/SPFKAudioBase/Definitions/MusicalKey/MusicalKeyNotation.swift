// Copyright Ryan Francesconi. All Rights Reserved. Revision History at https://github.com/ryanfrancesconi/spfk-audio-base

import Foundation

/// The ways a key is written into a file's key tag by the tools that write one.
public enum MusicalKeyNotation: Sendable, Hashable, Equatable, CaseIterable {
    /// `"C# Minor"`, as key detection writes it.
    case standard
    /// `"C#m"`, `"Dbm"`, `"A"`: the ID3v2.4 `TKEY` form, at most three characters.
    case short
    /// `"8A"`, `"12B"`: Mixed In Key's wheel, A minor and B major.
    case camelot
    /// `"1m"`, `"12d"`: Traktor's wheel, m minor and d major.
    case openKey
}

/// A key read from text, with how it was written.
public struct ParsedMusicalKey: Sendable, Hashable, Equatable {
    public var value: MusicalKeyValue
    public var notation: MusicalKeyNotation
    /// The note was spelled with a flat (`"Dbm"`). Always false for a wheel notation.
    public var usesFlats: Bool

    public init(value: MusicalKeyValue, notation: MusicalKeyNotation, usesFlats: Bool) {
        self.value = value
        self.notation = notation
        self.usesFlats = usesFlats
    }
}

/// A file's key, and which of its tags supplied it.
public struct ResolvedMusicalKey: Sendable, Hashable, Equatable {
    public enum Source: Sendable, Hashable, Equatable {
        case initialKey
        /// The comment led with the key. `remainder` is the comment with the key and its
        /// separator removed, which is what the comment becomes once the key moves to its tag.
        case comment(remainder: String)
    }

    public var key: ParsedMusicalKey
    public var source: Source

    public init(key: ParsedMusicalKey, source: Source) {
        self.key = key
        self.source = source
    }
}

// Copyright Ryan Francesconi. All Rights Reserved. Revision History at https://github.com/ryanfrancesconi/spfk-audio-base

import Foundation
import SPFKBase

/// A musical key as a note name and tonality pair: the 24 major and minor keys, or a root alone
/// when the tonality is `.unknown`. Round-trips through the pipeline's numeric key index.
public struct MusicalKeyValue: Sendable, Hashable, Equatable, CustomStringConvertible {
    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.name == rhs.name && lhs.tonality == rhs.tonality
    }

    public var name: NoteName
    public var tonality: MusicalTonality

    public var description: String {
        "\(name) \(tonality)"
    }

    /// The numeric key index used by the detection pipeline, 0–23.
    public var keyIndex: Int32 {
        var value = name.rawValue

        if tonality == .minor {
            value += 12
        }

        return value
    }

    /// Splits the pipeline's key index into a note name and a tonality: 0–11 is C Major through B
    /// Major, 12–23 C Minor through B Minor. The pipeline's 24 ("no chord") has no value here and
    /// returns `nil`, as does anything out of range.
    public init?(keyIndex: Int32) {
        guard keyIndex >= 0, keyIndex <= 23 else {
            return nil
        }

        tonality = (12 ... 23).contains(keyIndex) ? .minor : .major

        let nameValue: Int32 = keyIndex >= 12 ? keyIndex - 12 : keyIndex

        guard let keyName = NoteName(rawValue: nameValue) else { return nil }

        name = keyName
    }

    public init(name: NoteName, tonality: MusicalTonality) {
        self.name = name
        self.tonality = tonality
    }
}

// swiftformat:disable consecutiveSpaces

extension MusicalKeyValue {
    /// The relative major or minor key — C Major → A Minor, A Minor → C Major.
    public var relativeKey: MusicalKeyValue {
        switch (name, tonality) {
        // --- Major to Minor
        case (.c, .major):      .init(name: .a, tonality: .minor)
        case (.cSharp, .major): .init(name: .aSharp, tonality: .minor)
        case (.d, .major):      .init(name: .b, tonality: .minor)
        case (.dSharp, .major): .init(name: .c, tonality: .minor)
        case (.e, .major):      .init(name: .cSharp, tonality: .minor)
        case (.f, .major):      .init(name: .d, tonality: .minor)
        case (.fSharp, .major): .init(name: .dSharp, tonality: .minor)
        case (.g, .major):      .init(name: .e, tonality: .minor)
        case (.gSharp, .major): .init(name: .f, tonality: .minor)
        case (.a, .major):      .init(name: .fSharp, tonality: .minor)
        case (.aSharp, .major): .init(name: .g, tonality: .minor)
        case (.b, .major):      .init(name: .gSharp, tonality: .minor)
        // --- Minor to Major
        case (.a, .minor):      .init(name: .c, tonality: .major)
        case (.aSharp, .minor): .init(name: .cSharp, tonality: .major)
        case (.b, .minor):      .init(name: .d, tonality: .major)
        case (.c, .minor):      .init(name: .dSharp, tonality: .major)
        case (.cSharp, .minor): .init(name: .e, tonality: .major)
        case (.d, .minor):      .init(name: .f, tonality: .major)
        case (.dSharp, .minor): .init(name: .fSharp, tonality: .major)
        case (.e, .minor):      .init(name: .g, tonality: .major)
        case (.f, .minor):      .init(name: .gSharp, tonality: .major)
        case (.fSharp, .minor): .init(name: .a, tonality: .major)
        case (.g, .minor):      .init(name: .aSharp, tonality: .major)
        case (.gSharp, .minor): .init(name: .b, tonality: .major)
        // .unknown tonality has no relative key.
        default:
            .init(name: name, tonality: tonality)
        }
    }
}

// swiftformat:enable consecutiveSpaces

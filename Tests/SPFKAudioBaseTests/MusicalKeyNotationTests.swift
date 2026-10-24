// Copyright Ryan Francesconi. All Rights Reserved. Revision History at https://github.com/ryanfrancesconi/spfk-audio-base

import Foundation
import SPFKBase
import Testing

@testable import SPFKAudioBase

@Suite("MusicalKeyNotation")
struct MusicalKeyNotationTests {
    struct Row: Sendable, CustomTestStringConvertible {
        let key: MusicalKeyValue
        let camelot: String
        let openKey: String
        var testDescription: String { key.description }
    }

    /// The published wheel (mixgraph.io's Open Key glossary, 2026-10-24), not the formula.
    static let wheel: [Row] = [
        Row(key: .init(name: .a, tonality: .minor), camelot: "8A", openKey: "1m"),
        Row(key: .init(name: .g, tonality: .minor), camelot: "6A", openKey: "11m"),
        Row(key: .init(name: .d, tonality: .minor), camelot: "7A", openKey: "12m"),
        Row(key: .init(name: .f, tonality: .minor), camelot: "4A", openKey: "9m"),
        Row(key: .init(name: .e, tonality: .minor), camelot: "9A", openKey: "2m"),
        Row(key: .init(name: .c, tonality: .minor), camelot: "5A", openKey: "10m"),
        Row(key: .init(name: .f, tonality: .major), camelot: "7B", openKey: "12d"),
        Row(key: .init(name: .g, tonality: .major), camelot: "9B", openKey: "2d"),
        Row(key: .init(name: .fSharp, tonality: .minor), camelot: "11A", openKey: "4m"),
        Row(key: .init(name: .dSharp, tonality: .minor), camelot: "2A", openKey: "7m"),
        Row(key: .init(name: .d, tonality: .major), camelot: "10B", openKey: "3d"),
        Row(key: .init(name: .b, tonality: .minor), camelot: "10A", openKey: "3m"),
        Row(key: .init(name: .aSharp, tonality: .minor), camelot: "3A", openKey: "8m"),
        Row(key: .init(name: .c, tonality: .major), camelot: "8B", openKey: "1d"),
        Row(key: .init(name: .a, tonality: .major), camelot: "11B", openKey: "4d"),
        Row(key: .init(name: .e, tonality: .major), camelot: "12B", openKey: "5d"),
        Row(key: .init(name: .gSharp, tonality: .minor), camelot: "1A", openKey: "6m"),
        Row(key: .init(name: .dSharp, tonality: .major), camelot: "5B", openKey: "10d"),
        Row(key: .init(name: .cSharp, tonality: .minor), camelot: "12A", openKey: "5m"),
        Row(key: .init(name: .fSharp, tonality: .major), camelot: "2B", openKey: "7d"),
        Row(key: .init(name: .gSharp, tonality: .major), camelot: "4B", openKey: "9d"),
        Row(key: .init(name: .aSharp, tonality: .major), camelot: "6B", openKey: "11d"),
        Row(key: .init(name: .cSharp, tonality: .major), camelot: "3B", openKey: "8d"),
        Row(key: .init(name: .b, tonality: .major), camelot: "1B", openKey: "6d"),
    ]

    @Test func theWheelCoversEveryKeyOnce() {
        #expect(Set(Self.wheel.map(\.key)).count == 24)
        #expect(Set(Self.wheel.map(\.camelot)).count == 24)
        #expect(Set(Self.wheel.map(\.openKey)).count == 24)
    }

    @Test(arguments: wheel)
    func wheelCodesMatchThePublishedWheel(row: Row) {
        #expect(row.key.string(in: .camelot) == row.camelot)
        #expect(row.key.string(in: .openKey) == row.openKey)
        #expect(MusicalKeyValue.parse(row.camelot) == ParsedMusicalKey(value: row.key, notation: .camelot, usesFlats: false))
        #expect(MusicalKeyValue.parse(row.openKey) == ParsedMusicalKey(value: row.key, notation: .openKey, usesFlats: false))
    }

    @Test(arguments: wheel)
    func relativeKeysShareANumber(row: Row) {
        let relative = row.key.relativeKey
        #expect(relative.string(in: .camelot).dropLast() == row.camelot.dropLast())
        #expect(relative.string(in: .openKey).dropLast() == row.openKey.dropLast())
    }

    @Test(arguments: wheel)
    func everyNotationRoundTrips(row: Row) {
        for notation in MusicalKeyNotation.allCases {
            for flats in [false, true] {
                let text = row.key.string(in: notation, flats: flats)
                let parsed = MusicalKeyValue.parse(text)
                let spellsFlat = flats && row.key.name.enharmonic != row.key.name.description
                    && (notation == .standard || notation == .short)

                #expect(parsed == ParsedMusicalKey(value: row.key, notation: notation, usesFlats: spellsFlat), "\(text)")
            }
        }
    }

    @Test(arguments: wheel)
    func theShortFormFitsTKEY(row: Row) {
        #expect(row.key.string(in: .short).count <= 3)
        #expect(row.key.string(in: .short, flats: true).count <= 3)
    }

    @Test(arguments: [
        ("C# Minor", "C#m", MusicalKeyNotation.standard, false),
        ("c#min", "C#m", .short, false),
        ("C♯m", "C#m", .short, false),
        ("  db minor ", "Dbm", .standard, true),
        ("D♭m", "Dbm", .short, true),
        ("Bbm", "Bbm", .short, true),
        ("bb", "Bb", .short, true),
        ("Bm", "Bm", .short, false),
        ("A", "A", .short, false),
        ("a maj", "A", .short, false),
        ("Amaj", "A", .short, false),
        ("F MAJOR", "F", .standard, false),
        ("gminor", "Gm", .short, false),
        ("12a", "C#m", .camelot, false),
        ("1D", "C", .openKey, false),
    ])
    func acceptedVariantsParse(text: String, short: String, notation: MusicalKeyNotation, flats: Bool) throws {
        let parsed = try #require(MusicalKeyValue.parse(text))
        #expect(parsed.notation == notation)
        #expect(parsed.usesFlats == flats)
        #expect(parsed.value.string(in: .short, flats: parsed.usesFlats) == short)
    }

    @Test(arguments: ["", "  ", "13A", "0d", "0A", "123B", "H", "Hm", "o", "Cb", "E#", "Amazing", "C Diminished", "8C", "C Major Extra"])
    func malformedInputIsNil(text: String) {
        #expect(MusicalKeyValue.parse(text) == nil)
    }

    @Test func theStandardParseStaysStandardOnly() {
        #expect(MusicalKeyValue(string: "C#m") == nil)
        #expect(MusicalKeyValue(string: "C# Minor") == MusicalKeyValue(name: .cSharp, tonality: .minor))
    }

    // MARK: - Transposition

    @Test(arguments: [
        (NoteName.a, 2, NoteName.b),
        (.b, 1, .c),
        (.c, -1, .b),
        (.c, -13, .b),
        (.a, 15, .c),
        (.g, 0, .g),
        (.d, -24, .d),
    ])
    func transpositionWrapsTheOctave(from: NoteName, semitones: Int, to: NoteName) {
        let key = MusicalKeyValue(name: from, tonality: .minor).transposed(bySemitones: semitones)
        #expect(key == MusicalKeyValue(name: to, tonality: .minor))
    }

    @Test func aTransposedCamelotTagIsWrittenShort() throws {
        let parsed = try #require(MusicalKeyValue.parse("8A"))
        #expect(parsed.value.transposed(bySemitones: 2).string(in: .short, flats: parsed.usesFlats) == "Bm")
    }

    @Test func aFlatSpellingSurvivesTransposition() throws {
        let parsed = try #require(MusicalKeyValue.parse("Dbm"))
        #expect(parsed.value.transposed(bySemitones: 2).string(in: .short, flats: parsed.usesFlats) == "Ebm")
        #expect(parsed.value.transposed(bySemitones: -1).string(in: .short, flats: parsed.usesFlats) == "Cm")
    }

    @Test func anUnknownTonalityIsNoKey() {
        let key = MusicalKeyValue(name: .c, tonality: .unknown)
        for notation in MusicalKeyNotation.allCases {
            #expect(key.string(in: notation).isEmpty)
        }
    }
}

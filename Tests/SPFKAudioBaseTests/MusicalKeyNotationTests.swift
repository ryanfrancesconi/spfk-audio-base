// Copyright Ryan Francesconi. All Rights Reserved. Revision History at https://github.com/ryanfrancesconi/spfk-audio-base

import Foundation
import SPFKBase
import SPFKTesting
import Testing

@testable import SPFKAudioBase

@Suite("MusicalKeyNotation", .tags(.musicalKey))
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
        #expect(relative.string(in: .camelot)?.dropLast() == row.camelot.dropLast())
        #expect(relative.string(in: .openKey)?.dropLast() == row.openKey.dropLast())
    }

    @Test(arguments: wheel)
    func everyNotationRoundTrips(row: Row) throws {
        for notation in MusicalKeyNotation.allCases {
            for flats in [false, true] {
                let text = try #require(row.key.string(in: notation, flats: flats))
                let parsed = MusicalKeyValue.parse(text)
                let spellsFlat = flats && row.key.name.enharmonic != row.key.name.description
                    && (notation == .standard || notation == .short)

                #expect(parsed == ParsedMusicalKey(value: row.key, notation: notation, usesFlats: spellsFlat), "\(text)")
            }
        }
    }

    @Test(arguments: wheel)
    func theShortFormIsAtMostFiveCharacters(row: Row) throws {
        #expect(try #require(row.key.string(in: .short, flats: false)).count <= 5)
        #expect(try #require(row.key.string(in: .short, flats: true)).count <= 5)
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
        ("a maj", "Amaj", .short, false),
        ("Amaj", "Amaj", .short, false),
        ("F MAJOR", "Fmaj", .standard, false),
        ("gminor", "Gm", .short, false),
        ("AM", "Am", .short, false),
        ("C#M", "C#m", .short, false),
        ("12a", "C#m", .camelot, false),
        ("1D", "Cmaj", .openKey, false),
    ])
    func acceptedVariantsParse(text: String, short: String, notation: MusicalKeyNotation, flats: Bool) throws {
        let parsed = try #require(MusicalKeyValue.parse(text))
        #expect(parsed.notation == notation)
        #expect(parsed.usesFlats == flats)
        #expect(parsed.string(in: .short) == short)
    }

    @Test(arguments: ["", "  ", "13A", "0d", "0A", "123B", "H", "Hm", "o", "Cb", "E#", "Amazing", "C Diminished", "8C", "C Major Extra", "B\u{1D12C}", "B\u{1D12B}m"])
    func malformedInputIsNil(text: String) {
        #expect(MusicalKeyValue.parse(text) == nil)
    }

    @Test(arguments: ["A", "f#", "Db", "B♭"])
    func aBareNoteIsARootAlone(text: String) throws {
        #expect(try #require(MusicalKeyValue.parse(text)).value.tonality == .unknown)
    }

    @Test func aRootAloneIsTheNoteInANoteNameNotationAndNothingOnAWheel() {
        let key = MusicalKeyValue(name: .fSharp, tonality: .unknown)
        #expect(key.string(in: .standard) == "F#")
        #expect(key.string(in: .short) == "F#")
        #expect(key.string(in: .camelot) == nil)
        #expect(key.string(in: .openKey) == nil)
    }

    // MARK: - Spelling

    /// Key-signature theory: the fewest accidentals, with the F#/Gb and D#m/Ebm ties in sharps.
    static let signatureSpellings: [String: String] = [
        "8B": "Cmaj", "3B": "Dbmaj", "10B": "Dmaj", "5B": "Ebmaj", "12B": "Emaj", "7B": "Fmaj",
        "2B": "F#maj", "9B": "Gmaj", "4B": "Abmaj", "11B": "Amaj", "6B": "Bbmaj", "1B": "Bmaj",
        "5A": "Cm", "12A": "C#m", "7A": "Dm", "2A": "D#m", "9A": "Em", "4A": "Fm",
        "11A": "F#m", "6A": "Gm", "1A": "G#m", "8A": "Am", "3A": "Bbm", "10A": "Bm",
    ]

    @Test(arguments: wheel)
    func aWheelKeyIsSpelledAsItsSignature(row: Row) throws {
        let expected = try #require(Self.signatureSpellings[row.camelot])
        #expect(try #require(MusicalKeyValue.parse(row.camelot)).string(in: .short) == expected)
        #expect(try #require(MusicalKeyValue.parse(row.openKey)).string(in: .short) == expected)
        #expect(row.key.string(in: .short) == expected)
    }

    @Test(arguments: ["Dbm", "C#m", "G#maj", "Ebmaj", "D#maj", "Gb"])
    func aWrittenSpellingIsKept(text: String) throws {
        #expect(try #require(MusicalKeyValue.parse(text)).string(in: .short) == text)
    }

    @Test(arguments: [
        ("B♭", "Bb", "Bb"),
        ("B♭ Minor", "Bbm", "Bb Minor"),
        ("B♭maj", "Bbmaj", "Bb Major"),
        ("C♯m", "C#m", "C# Minor"),
    ])
    func typedGlyphsAreWrittenInASCII(text: String, short: String, standard: String) throws {
        let parsed = try #require(MusicalKeyValue.parse(text))
        #expect(parsed.string(in: .short) == short)
        #expect(parsed.string(in: .standard) == standard)

        for notation in MusicalKeyNotation.allCases {
            let written = parsed.string(in: notation) ?? ""
            #expect(!written.contains("♭") && !written.contains("♯"), "\(written)")
        }
    }

    @Test func glyphsAreOnlyForDisplay() throws {
        let parsed = try #require(MusicalKeyValue.parse("Bbm"))
        #expect(parsed.string(in: .short, glyphs: true) == "B♭m")
        #expect(MusicalKeyValue(name: .cSharp, tonality: .minor).string(in: .standard, glyphs: true) == "C♯ Minor")
        #expect(MusicalKeyValue(name: .b, tonality: .major).string(in: .short, glyphs: true) == "Bmaj")
        #expect(MusicalKeyValue(name: .a, tonality: .minor).string(in: .camelot, glyphs: true) == "8A")
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
        #expect(parsed.value.transposed(bySemitones: 2).string(in: .short) == "Bm")
    }

    @Test(arguments: [
        ("E", 4, "G#"),
        ("Emaj", 4, "Abmaj"),
        ("Dbm", 2, "D#m"),
        ("Dbm", -1, "Cm"),
        ("C#m", 1, "Dm"),
        ("Amaj", 1, "Bbmaj"),
        ("Am", 1, "Bbm"),
        ("F#maj", 0, "F#maj"),
    ])
    func aTranspositionIsSpelledAsItsSignature(text: String, semitones: Int, expected: String) throws {
        let parsed = try #require(MusicalKeyValue.parse(text))
        #expect(parsed.value.transposed(bySemitones: semitones).string(in: .short) == expected)
    }

    @Test func aRootAloneStaysARootAloneWhenTransposed() throws {
        let parsed = try #require(MusicalKeyValue.parse("Bb"))
        let transposed = parsed.value.transposed(bySemitones: 2)
        #expect(transposed.tonality == .unknown)
        #expect(transposed.string(in: .standard) == "C")
    }
}

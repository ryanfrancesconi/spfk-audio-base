// Copyright Ryan Francesconi. All Rights Reserved. Revision History at https://github.com/ryanfrancesconi/spfk-audio-base

import Foundation
import SPFKBase
import Testing

@testable import SPFKAudioBase

@Suite("MusicalKeyValue")
struct MusicalKeyValueTests {
    @Test("Major keys have correct tonality", arguments: 0 ..< 12)
    func keyIndexMajorTonality(index: Int) {
        let key = MusicalKeyValue(keyIndex: Int32(index))
        #expect(key != nil)
        #expect(key?.tonality == .major)
    }

    @Test("Minor keys have correct tonality", arguments: 12 ..< 24)
    func keyIndexMinorTonality(index: Int) {
        let key = MusicalKeyValue(keyIndex: Int32(index))
        #expect(key != nil)
        #expect(key?.tonality == .minor)
    }

    @Test("Valid boundary key indices", arguments: [0, 23])
    func keyIndexBoundaryValid(index: Int) {
        #expect(MusicalKeyValue(keyIndex: Int32(index)) != nil)
    }

    @Test("Invalid key indices return nil", arguments: [-1, 24, 100])
    func keyIndexBoundaryInvalid(index: Int) {
        #expect(MusicalKeyValue(keyIndex: Int32(index)) == nil)
    }

    @Test("keyIndex round-trips correctly", arguments: 0 ..< 24)
    func keyIndexRoundTrip(index: Int) {
        let key = MusicalKeyValue(keyIndex: Int32(index))
        #expect(key?.keyIndex == Int32(index))
    }

    @Test(
        "Specific key indices map to expected keys",
        arguments: [
            (0, NoteName.c, MusicalTonality.major),
            (9, NoteName.a, MusicalTonality.major),
            (12, NoteName.c, MusicalTonality.minor),
            (21, NoteName.a, MusicalTonality.minor),
        ]
    )
    func specificKeyIndices(index: Int, name: NoteName, tonality: MusicalTonality) {
        let key = MusicalKeyValue(keyIndex: Int32(index))
        #expect(key == MusicalKeyValue(name: name, tonality: tonality))
    }

    // MARK: - String init

    @Test(
        "Valid strings parse correctly",
        arguments: [
            ("C Major", NoteName.c, MusicalTonality.major),
            ("A Minor", NoteName.a, MusicalTonality.minor),
            ("F# Major", NoteName.fSharp, MusicalTonality.major),
        ]
    )
    func stringInitValid(string: String, name: NoteName, tonality: MusicalTonality) {
        #expect(MusicalKeyValue(string: string) == MusicalKeyValue(name: name, tonality: tonality))
    }

    @Test("Invalid strings return nil", arguments: ["", "CMajor", "C Major Extra", "Z Major", "C Diminished"])
    func stringInitInvalid(string: String) {
        #expect(MusicalKeyValue(string: string) == nil)
    }

    // MARK: - description

    @Test(
        "Description formats correctly",
        arguments: [
            (NoteName.c, MusicalTonality.major, "C Major"),
            (NoteName.fSharp, MusicalTonality.minor, "F# Minor"),
        ]
    )
    func description(name: NoteName, tonality: MusicalTonality, expected: String) {
        #expect(MusicalKeyValue(name: name, tonality: tonality).description == expected)
    }

    // MARK: - Equatable

    @Test("Same name and tonality are equal")
    func equalitySameValues() {
        #expect(MusicalKeyValue(name: .g, tonality: .major) == MusicalKeyValue(name: .g, tonality: .major))
    }

    @Test("Same name, different tonality are not equal")
    func equalityDifferentTonality() {
        #expect(MusicalKeyValue(name: .g, tonality: .major) != MusicalKeyValue(name: .g, tonality: .minor))
    }

    @Test("Different name, same tonality are not equal")
    func equalityDifferentName() {
        #expect(MusicalKeyValue(name: .c, tonality: .major) != MusicalKeyValue(name: .d, tonality: .major))
    }

    // MARK: - Hashable

    @Test("Equal values produce the same hash")
    func hashableEqualValues() {
        let a = MusicalKeyValue(name: .d, tonality: .minor)
        let b = MusicalKeyValue(name: .d, tonality: .minor)
        #expect(a.hashValue == b.hashValue)
    }

    @Test("Usable in a Set")
    func usableInSet() {
        var set: Set<MusicalKeyValue> = []
        set.insert(MusicalKeyValue(name: .c, tonality: .major))
        set.insert(MusicalKeyValue(name: .c, tonality: .major))
        set.insert(MusicalKeyValue(name: .a, tonality: .minor))
        #expect(set.count == 2)
    }

    @Test("Usable as a Dictionary key")
    func usableAsDictionaryKey() {
        var dict: [MusicalKeyValue: String] = [:]
        let key = MusicalKeyValue(name: .e, tonality: .major)
        dict[key] = "E Major"
        #expect(dict[MusicalKeyValue(name: .e, tonality: .major)] == "E Major")
    }

    // MARK: - relativeKey

    @Test(
        "Major keys map to correct relative minor",
        arguments: [
            (NoteName.c, NoteName.a),
            (NoteName.g, NoteName.e),
            (NoteName.f, NoteName.d),
            (NoteName.d, NoteName.b),
            (NoteName.aSharp, NoteName.g),
        ]
    )
    func relativeKeyMajorToMinor(major: NoteName, expectedMinor: NoteName) {
        let key = MusicalKeyValue(name: major, tonality: .major)
        #expect(key.relativeKey == MusicalKeyValue(name: expectedMinor, tonality: .minor))
    }

    @Test(
        "Minor keys map to correct relative major",
        arguments: [
            (NoteName.a, NoteName.c),
            (NoteName.e, NoteName.g),
            (NoteName.d, NoteName.f),
        ]
    )
    func relativeKeyMinorToMajor(minor: NoteName, expectedMajor: NoteName) {
        let key = MusicalKeyValue(name: minor, tonality: .minor)
        #expect(key.relativeKey == MusicalKeyValue(name: expectedMajor, tonality: .major))
    }

    @Test("Relative key is symmetric for all keys", arguments: 0 ..< 24)
    func relativeKeySymmetric(index: Int) throws {
        let key = try #require(MusicalKeyValue(keyIndex: Int32(index)))
        #expect(key.relativeKey.relativeKey == key)
    }

    @Test("Relative key always has opposite tonality", arguments: 0 ..< 24)
    func relativeKeySwapsTonality(index: Int) throws {
        let key = try #require(MusicalKeyValue(keyIndex: Int32(index)))
        #expect(key.tonality != key.relativeKey.tonality)
    }

    // MARK: - Major note names map to indices 0-11 in order

    @Test("Major key indices match NoteName raw values", arguments: Array(NoteName.allCases.enumerated()))
    func majorKeyIndicesMatchNoteNames(offset: Int, note: NoteName) {
        let key = MusicalKeyValue(name: note, tonality: .major)
        #expect(key.keyIndex == Int32(offset))
    }

    // MARK: - Description round-trip

    @Test("Description round-trips through string init", arguments: 0 ..< 24)
    func descriptionRoundTrip(index: Int) throws {
        let key = try #require(MusicalKeyValue(keyIndex: Int32(index)))
        let parsed = MusicalKeyValue(string: key.description)
        #expect(parsed == key)
    }

    // MARK: - Unknown tonality

    @Test("Unknown tonality description")
    func unknownTonalityDescription() {
        let key = MusicalKeyValue(name: .c, tonality: .unknown)
        #expect(key.description == "C ")
    }

    @Test("Unknown tonality relativeKey returns self")
    func unknownTonalityRelativeKey() {
        let key = MusicalKeyValue(name: .c, tonality: .unknown)
        #expect(key.relativeKey == key)
    }

    // MARK: - Exhaustive relativeKey

    @Test("All 12 major keys have correct relative minor", arguments: NoteName.allCases)
    func exhaustiveRelativeKeyMajor(note: NoteName) {
        let major = MusicalKeyValue(name: note, tonality: .major)
        let relative = major.relativeKey
        #expect(relative.tonality == .minor)
        // Verify symmetry
        #expect(relative.relativeKey == major)
    }

    @Test("All 12 minor keys have correct relative major", arguments: NoteName.allCases)
    func exhaustiveRelativeKeyMinor(note: NoteName) {
        let minor = MusicalKeyValue(name: note, tonality: .minor)
        let relative = minor.relativeKey
        #expect(relative.tonality == .major)
        // Verify symmetry
        #expect(relative.relativeKey == minor)
    }
}

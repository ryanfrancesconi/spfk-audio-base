// Copyright Ryan Francesconi. All Rights Reserved. Revision History at https://github.com/ryanfrancesconi/spfk-audio-base

import Foundation
import SPFKBase
import Testing

@testable import SPFKAudioBase

@Suite("MusicalKeyValue comment fallback")
struct MusicalKeyCommentTests {
    @Test(arguments: [
        ("8A - Energy 6", "Am", "Energy 6"),
        ("8A", "Am", ""),
        ("1m, Energy 7", "Am", "Energy 7"),
        ("C#m / energy", "C#m", "energy"),
        ("8A Energy 6", "Am", "Energy 6"),
        ("C Minor - Energy 5", "Cm", "Energy 5"),
        ("Dbm,take 2", "Dbm", "take 2"),
        ("  12B  ", "E", ""),
        ("A - Energy 4", "A", "Energy 4"),
    ])
    func aLeadingKeyParses(comment: String, short: String, remainder: String) throws {
        let leading = try #require(MusicalKeyValue.parseLeading(comment: comment))
        #expect(leading.key.value.string(in: .short, flats: leading.key.usesFlats) == short)
        #expect(String(comment[leading.range.upperBound...]) == remainder)
    }

    @Test(arguments: ["Recorded in 8A", "A good take", "Amazing", "Am I right", "8A-Energy 6", "", "Energy 6 - 8A", "C#m energy"])
    func aKeyNotAtTheStartDoesNotParse(comment: String) {
        #expect(MusicalKeyValue.parseLeading(comment: comment) == nil)
    }

    @Test func initialKeyWinsOverTheComment() throws {
        let resolved = try #require(MusicalKeyValue.resolve(initialKey: "Dbm", comment: "8A - Energy 6"))
        #expect(resolved.source == .initialKey)
        #expect(resolved.key.value == MusicalKeyValue(name: .cSharp, tonality: .minor))
        #expect(resolved.key.usesFlats)
    }

    @Test func anUnreadableInitialKeyIsNotPassedOver() {
        #expect(MusicalKeyValue.resolve(initialKey: "varies", comment: "8A - Energy 6") == nil)
    }

    @Test(arguments: [nil, "", "  "] as [String?])
    func anEmptyInitialKeyFallsBackToTheComment(initialKey: String?) throws {
        let resolved = try #require(MusicalKeyValue.resolve(initialKey: initialKey, comment: "8A - Energy 6"))
        #expect(resolved.source == .comment(remainder: "Energy 6"))
        #expect(resolved.key.notation == .camelot)
    }

    @Test func aCommentThatWasOnlyTheKeyLeavesNothing() throws {
        let resolved = try #require(MusicalKeyValue.resolve(initialKey: nil, comment: "8A"))
        #expect(resolved.source == .comment(remainder: ""))
    }

    @Test func noKeyAnywhereIsNil() {
        #expect(MusicalKeyValue.resolve(initialKey: nil, comment: "A good take") == nil)
        #expect(MusicalKeyValue.resolve(initialKey: nil, comment: nil) == nil)
    }
}

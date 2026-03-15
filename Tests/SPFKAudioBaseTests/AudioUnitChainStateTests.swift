// Copyright Ryan Francesconi. All Rights Reserved.

import Foundation
import SPFKBase
import Testing

@testable import SPFKAudioBase

struct AudioUnitInsertTests {
    // MARK: - Init

    @Test func initSetsAllProperties() {
        let insert = AudioUnitInsert(
            uid: "test-uid",
            index: 2,
            isBypassed: true,
            name: "My Plugin",
            isWindowVisible: true
        )

        #expect(insert.uid == "test-uid")
        #expect(insert.index == 2)
        #expect(insert.isBypassed == true)
        #expect(insert.name == "My Plugin")
        #expect(insert.isWindowVisible == true)
        #expect(insert.fullStatePlistData == nil)
        #expect(insert.windowFrame == nil)
    }

    @Test func initDefaults() {
        let insert = AudioUnitInsert(uid: "uid", index: 0, isBypassed: false)

        #expect(insert.name == nil)
        #expect(insert.fullStatePlistData == nil)
        #expect(insert.isWindowVisible == false)
        #expect(insert.windowFrame == nil)
    }

    // MARK: - componentDescription

    @Test func componentDescriptionNilForInvalidUID() {
        let insert = AudioUnitInsert(uid: "invalid", index: 0, isBypassed: false)
        #expect(insert.componentDescription == nil)
    }

    @Test func componentDescriptionNilForEmptyUID() {
        let insert = AudioUnitInsert(uid: "", index: 0, isBypassed: false)
        #expect(insert.componentDescription == nil)
    }

    // MARK: - fullStateDictionary

    @Test func fullStateDictionaryNilWhenNoData() {
        let insert = AudioUnitInsert(uid: "uid", index: 0, isBypassed: false)
        #expect(insert.fullStateDictionary == nil)
    }

    @Test func fullStateDictionaryFromPlistData() throws {
        let dict: [String: Any] = ["key": "value", "number": 42]
        let plistData = try PropertyListSerialization.data(
            fromPropertyList: dict,
            format: .xml,
            options: 0
        )

        let insert = AudioUnitInsert(
            uid: "uid", index: 0, isBypassed: false,
            fullStatePlistData: plistData
        )

        let result = insert.fullStateDictionary
        #expect(result?["key"] as? String == "value")
        #expect(result?["number"] as? Int == 42)
    }

    // MARK: - Codable

    @Test func codableRoundTrip() throws {
        let original = AudioUnitInsert(
            uid: "test-uid",
            index: 3,
            isBypassed: true,
            name: "Plugin",
            isWindowVisible: true
        )

        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(AudioUnitInsert.self, from: data)

        #expect(decoded.uid == original.uid)
        #expect(decoded.index == original.index)
        #expect(decoded.isBypassed == original.isBypassed)
        #expect(decoded.name == original.name)
        #expect(decoded.isWindowVisible == original.isWindowVisible)
    }

    @Test func decodingThrowsWhenUIDMissing() throws {
        // JSON with no "uid" key — simulates SwiftData empty container
        let json = #"{"index": 0, "isBypassed": false}"#
        let data = json.data(using: .utf8)!

        #expect(throws: DecodingError.self) {
            try JSONDecoder().decode(AudioUnitInsert.self, from: data)
        }
    }

    @Test func decodingDefaultsForMissingOptionalFields() throws {
        // Only uid is required; index, isBypassed, isWindowVisible default
        let json = #"{"uid": "test-uid"}"#
        let data = json.data(using: .utf8)!

        let decoded = try JSONDecoder().decode(AudioUnitInsert.self, from: data)

        #expect(decoded.uid == "test-uid")
        #expect(decoded.index == 0)
        #expect(decoded.isBypassed == false)
        #expect(decoded.isWindowVisible == false)
        #expect(decoded.name == nil)
    }

    // MARK: - Equatable / Hashable

    @Test func equalityByValue() {
        let a = AudioUnitInsert(uid: "uid", index: 0, isBypassed: false)
        let b = AudioUnitInsert(uid: "uid", index: 0, isBypassed: false)

        #expect(a == b)
    }

    @Test func inequalityDifferentUID() {
        let a = AudioUnitInsert(uid: "uid-a", index: 0, isBypassed: false)
        let b = AudioUnitInsert(uid: "uid-b", index: 0, isBypassed: false)

        #expect(a != b)
    }
}

struct AudioUnitChainStateTests {
    // MARK: - Init

    @Test func initSetsProperties() {
        let insert = AudioUnitInsert(uid: "uid", index: 0, isBypassed: false)
        let chain = AudioUnitChainState(insertCount: 4, inserts: [insert])

        #expect(chain.insertCount == 4)
        #expect(chain.inserts.count == 1)
    }

    // MARK: - Codable

    @Test func codableRoundTrip() throws {
        let insert = AudioUnitInsert(uid: "uid", index: 0, isBypassed: false, name: "Test")
        let original = AudioUnitChainState(insertCount: 4, inserts: [insert])

        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(AudioUnitChainState.self, from: data)

        #expect(decoded.insertCount == original.insertCount)
        #expect(decoded.inserts.count == original.inserts.count)
        #expect(decoded.inserts[0].uid == "uid")
    }

    @Test func decodingThrowsWhenAllKeysMissing() throws {
        // Empty JSON object simulates SwiftData empty container
        let json = #"{}"#
        let data = json.data(using: .utf8)!

        #expect(throws: DecodingError.self) {
            try JSONDecoder().decode(AudioUnitChainState.self, from: data)
        }
    }

    @Test func decodingSucceedsWithOnlyInsertCount() throws {
        let json = #"{"insertCount": 8}"#
        let data = json.data(using: .utf8)!

        let decoded = try JSONDecoder().decode(AudioUnitChainState.self, from: data)

        #expect(decoded.insertCount == 8)
        #expect(decoded.inserts.isEmpty)
    }

    @Test func decodingSucceedsWithOnlyInserts() throws {
        let json = #"{"inserts": [{"uid": "abc", "index": 0, "isBypassed": false}]}"#
        let data = json.data(using: .utf8)!

        let decoded = try JSONDecoder().decode(AudioUnitChainState.self, from: data)

        #expect(decoded.insertCount == 0)
        #expect(decoded.inserts.count == 1)
    }

    // MARK: - Equatable

    @Test func equalityByValue() {
        let insert = AudioUnitInsert(uid: "uid", index: 0, isBypassed: false)
        let a = AudioUnitChainState(insertCount: 4, inserts: [insert])
        let b = AudioUnitChainState(insertCount: 4, inserts: [insert])

        #expect(a == b)
    }

    @Test func inequalityDifferentCount() {
        let a = AudioUnitChainState(insertCount: 4, inserts: [])
        let b = AudioUnitChainState(insertCount: 8, inserts: [])

        #expect(a != b)
    }
}

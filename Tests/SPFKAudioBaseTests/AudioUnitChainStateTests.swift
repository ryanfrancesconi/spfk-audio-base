// Copyright Ryan Francesconi. All Rights Reserved.

import Foundation
import SPFKBase
import Testing

@testable import SPFKAudioBase

struct AudioUnitInsertTests {
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
}

struct AudioUnitChainStateTests {
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

    @Test func decodingEmptyJSONDecodesToDefaults() throws {
        let json = #"{}"#
        let data = json.data(using: .utf8)!

        let decoded = try JSONDecoder().decode(AudioUnitChainState.self, from: data)

        #expect(decoded.insertCount == 0)
        #expect(decoded.inserts.isEmpty)
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
}

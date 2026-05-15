// Copyright Ryan Francesconi. All Rights Reserved.

import Foundation
import SPFKBase
import Testing

@testable import SPFKAudioBase

@Suite("TrimDescription")
struct TrimDescriptionTests {
    // MARK: - isEmpty

    @Test func defaultIsEmpty() {
        #expect(TrimDescription().isEmpty)
    }

    @Test func inPointOnlyIsNotEmpty() {
        #expect(!TrimDescription(inPoint: 1.0).isEmpty)
    }

    @Test func outPointOnlyIsNotEmpty() {
        #expect(!TrimDescription(outPoint: 4.0).isEmpty)
    }

    @Test func bothSetIsNotEmpty() {
        #expect(!TrimDescription(inPoint: 1.0, outPoint: 4.0).isEmpty)
    }

    // MARK: - Codable round-trip

    @Test func roundTrips() throws {
        let original = TrimDescription(inPoint: 1.5, outPoint: 3.0)
        let encoded = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(TrimDescription.self, from: encoded)
        #expect(decoded == original)
    }

    @Test func roundTripsDefaultValues() throws {
        let original = TrimDescription()
        let encoded = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(TrimDescription.self, from: encoded)
        #expect(decoded == original)
        #expect(decoded.isEmpty)
    }

    // MARK: - Codable validation

    @Test func decodeThrowsWhenInPointIsNegative() throws {
        let json = #"{"inPoint": -1.0, "outPoint": 3.0}"#.data(using: .utf8)!
        #expect(throws: (any Error).self) {
            try JSONDecoder().decode(TrimDescription.self, from: json)
        }
    }

    @Test func decodeThrowsWhenOutPointIsNegative() throws {
        let json = #"{"inPoint": 1.0, "outPoint": -1.0}"#.data(using: .utf8)!
        #expect(throws: (any Error).self) {
            try JSONDecoder().decode(TrimDescription.self, from: json)
        }
    }

    @Test func decodeThrowsWhenInPointExceedsOutPoint() throws {
        let json = #"{"inPoint": 5.0, "outPoint": 2.0}"#.data(using: .utf8)!
        #expect(throws: (any Error).self) {
            try JSONDecoder().decode(TrimDescription.self, from: json)
        }
    }

    @Test func decodeThrowsWhenInPointEqualsOutPoint() throws {
        let json = #"{"inPoint": 3.0, "outPoint": 3.0}"#.data(using: .utf8)!
        #expect(throws: (any Error).self) {
            try JSONDecoder().decode(TrimDescription.self, from: json)
        }
    }

    @Test func decodeAcceptsOnlyInPointSet() throws {
        let json = #"{"inPoint": 2.0, "outPoint": 0.0}"#.data(using: .utf8)!
        let result = try JSONDecoder().decode(TrimDescription.self, from: json)
        #expect(result.inPoint == 2.0)
        #expect(result.outPoint == 0.0)
    }
}

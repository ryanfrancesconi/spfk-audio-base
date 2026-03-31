// Copyright Ryan Francesconi. All Rights Reserved.

import Foundation
import SPFKBase
import Testing

@testable import SPFKAudioBase

struct FileConflictSchemeTests {
    // MARK: - CaseIterable

    @Test func allCasesCount() {
        #expect(FileConflictScheme.allCases.count == 3)
    }

    @Test func allCasesContainsExpected() {
        let cases = FileConflictScheme.allCases
        #expect(cases.contains(.overwrite))
        #expect(cases.contains(.unique))
        #expect(cases.contains(.error))
    }

    // MARK: - Raw values

    @Test func overwriteRawValue() {
        #expect(FileConflictScheme.overwrite.rawValue == 0)
    }

    @Test func uniqueRawValue() {
        #expect(FileConflictScheme.unique.rawValue == 1)
    }

    @Test func errorRawValue() {
        #expect(FileConflictScheme.error.rawValue == 2)
    }

    // MARK: - displayName

    @Test func overwriteDisplayName() {
        #expect(FileConflictScheme.overwrite.displayName == "Overwrite Files")
    }

    @Test func uniqueDisplayName() {
        #expect(FileConflictScheme.unique.displayName == "Rename Uniquely")
    }

    @Test func errorDisplayName() {
        #expect(FileConflictScheme.error.displayName == "Show Errors")
    }

    // MARK: - init?(displayName:)

    @Test func initFromOverwriteDisplayName() {
        #expect(FileConflictScheme(displayName: "Overwrite Files") == .overwrite)
    }

    @Test func initFromUniqueDisplayName() {
        #expect(FileConflictScheme(displayName: "Rename Uniquely") == .unique)
    }

    @Test func initFromErrorDisplayName() {
        #expect(FileConflictScheme(displayName: "Show Errors") == .error)
    }

    @Test func initFromUnknownDisplayNameReturnsNil() {
        #expect(FileConflictScheme(displayName: "Unknown") == nil)
    }

    // MARK: - Codable

    @Test func codableRoundTripOverwrite() throws {
        let data = try JSONEncoder().encode(FileConflictScheme.overwrite)
        let decoded = try JSONDecoder().decode(FileConflictScheme.self, from: data)
        #expect(decoded == .overwrite)
    }

    @Test func codableRoundTripUnique() throws {
        let data = try JSONEncoder().encode(FileConflictScheme.unique)
        let decoded = try JSONDecoder().decode(FileConflictScheme.self, from: data)
        #expect(decoded == .unique)
    }

    @Test func codableRoundTripError() throws {
        let data = try JSONEncoder().encode(FileConflictScheme.error)
        let decoded = try JSONDecoder().decode(FileConflictScheme.self, from: data)
        #expect(decoded == .error)
    }
}

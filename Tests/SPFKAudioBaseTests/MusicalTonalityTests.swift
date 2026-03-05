import Foundation
@testable import SPFKAudioBase
import Testing

@Suite("MusicalTonality")
struct MusicalTonalityTests {
    @Test("init from string")
    func initFromString() {
        #expect(MusicalTonality(string: "Major") == .major)
        #expect(MusicalTonality(string: "Minor") == .minor)
    }

    @Test("init is case insensitive")
    func caseInsensitive() {
        #expect(MusicalTonality(string: "major") == .major)
        #expect(MusicalTonality(string: "MINOR") == .minor)
    }

    @Test("empty string returns unknown")
    func emptyString() {
        #expect(MusicalTonality(string: "") == .unknown)
    }

    @Test("invalid string returns nil")
    func invalidString() {
        #expect(MusicalTonality(string: "diminished") == nil)
        #expect(MusicalTonality(string: "xyz") == nil)
    }

    @Test("description values")
    func descriptions() {
        #expect(MusicalTonality.major.description == "Major")
        #expect(MusicalTonality.minor.description == "Minor")
        #expect(MusicalTonality.unknown.description == "")
    }

    @Test("allCases contains all three")
    func allCases() {
        #expect(MusicalTonality.allCases.count == 3)
        #expect(MusicalTonality.allCases.contains(.major))
        #expect(MusicalTonality.allCases.contains(.minor))
        #expect(MusicalTonality.allCases.contains(.unknown))
    }
}

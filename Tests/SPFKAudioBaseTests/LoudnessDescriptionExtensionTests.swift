import Foundation
@testable import SPFKAudioBase
import Testing

@Suite("LoudnessDescription Extensions")
struct LoudnessDescriptionExtensionTests {
    @Test("stringValue formatting")
    func stringValue() {
        let desc = LoudnessDescription(
            loudnessIntegrated: -14.0,
            loudnessRange: 8.5,
            maxTruePeakLevel: -1.2,
            maxMomentaryLoudness: -10.0,
            maxShortTermLoudness: -12.5
        )
        let str = desc.stringValue
        #expect(str.contains("I"))
        #expect(str.contains("LUFS"))
        #expect(str.contains("TP"))
        #expect(str.contains("LRA"))
        #expect(str.contains("M"))
        #expect(str.contains("S"))
    }

    @Test("stringValue with nil values shows N/A")
    func stringValueNil() {
        let desc = LoudnessDescription()
        let str = desc.stringValue
        #expect(str.contains("N/A"))
    }

    @Test("isValid requires at least one non-nil non-LRA value")
    func isValid() {
        let empty = LoudnessDescription()
        #expect(!empty.isValid)

        let withIntegrated = LoudnessDescription(loudnessIntegrated: -14.0)
        #expect(withIntegrated.isValid)

        // loudnessRange alone does NOT make it valid
        let withRangeOnly = LoudnessDescription(loudnessRange: 5.0)
        #expect(!withRangeOnly.isValid)
    }

    @Test("Comparable uses loudnessIntegrated")
    func comparable() {
        let a = LoudnessDescription(loudnessIntegrated: -14.0)
        let b = LoudnessDescription(loudnessIntegrated: -10.0)
        #expect(a < b)
    }

    @Test("Comparable with nil is not less than")
    func comparableNil() {
        let a = LoudnessDescription()
        let b = LoudnessDescription(loudnessIntegrated: -10.0)
        #expect(!(a < b))
        #expect(!(b < a))
    }

    @Test("Codable round-trip")
    func codable() throws {
        let original = LoudnessDescription(
            loudnessIntegrated: -14.0,
            loudnessRange: 8.5,
            maxTruePeakLevel: -1.2,
            maxMomentaryLoudness: -10.0,
            maxShortTermLoudness: -12.5
        )
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(LoudnessDescription.self, from: data)
        #expect(decoded == original)
    }

    @Test("Codable handles missing keys")
    func codableMissingKeys() throws {
        let json = "{}".data(using: .utf8)!
        let decoded = try JSONDecoder().decode(LoudnessDescription.self, from: json)
        #expect(decoded.loudnessIntegrated == nil)
        #expect(decoded.loudnessRange == nil)
    }

    @Test("empty array average returns invalid")
    func emptyAverage() {
        let avg: LoudnessDescription = [LoudnessDescription]().average
        #expect(!avg.isValid)
    }
}

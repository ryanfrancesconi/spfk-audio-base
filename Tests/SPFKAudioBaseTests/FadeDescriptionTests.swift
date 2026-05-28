// Copyright Ryan Francesconi. All Rights Reserved. Revision History at https://github.com/ryanfrancesconi/spfk-audio-base

import Foundation
import SPFKAudioBase
import SPFKBase
import Testing

@Suite("FadeDescription")
struct FadeDescriptionTests {
    // MARK: - Defaults

    @Test func defaultTapersAreAudioDefault() {
        let fade = FadeDescription()
        #expect(fade.inTaper == .default)
        #expect(fade.outTaper == .default)
    }

    @Test func initWithIndependentTapers() {
        let fade = FadeDescription(inTime: 1, outTime: 2, inTaper: .linear, outTaper: .reverseAudio)
        #expect(fade.inTime == 1)
        #expect(fade.outTime == 2)
        #expect(fade.inTaper == .linear)
        #expect(fade.outTaper == .reverseAudio)
    }

    @Test func inTaperAndOutTaperAreIndependent() {
        var fade = FadeDescription()
        fade.inTaper = .linear
        #expect(fade.inTaper == .linear)
        #expect(fade.outTaper == .default)

        fade.outTaper = .reverseAudio
        #expect(fade.inTaper == .linear)
        #expect(fade.outTaper == .reverseAudio)
    }

    // MARK: - Codable round-trip

    @Test func codableRoundTripPreservesIndependentTapers() throws {
        let original = FadeDescription(inTime: 1.5, outTime: 0.5, inTaper: .linear, outTaper: .reverseAudio)
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(FadeDescription.self, from: data)
        #expect(decoded == original)
        #expect(decoded.inTaper == .linear)
        #expect(decoded.outTaper == .reverseAudio)
    }

    // MARK: - Backward compatibility

    @Test func missingTaperKeysDefaultToAudioDefault() throws {
        let minimalJSON = """
        {"inTime":1.0,"outTime":0.5}
        """.data(using: .utf8)!

        let decoded = try JSONDecoder().decode(FadeDescription.self, from: minimalJSON)
        #expect(decoded.inTaper == .default)
        #expect(decoded.outTaper == .default)
    }

    @Test func newKeysOverrideLegacyTaperKey() throws {
        // When both old and new keys are present, the new keys win.
        let json = """
        {"inTime":1.0,"outTime":1.0,"taper":{"value":1.0,"skew":0.0},"inTaper":{"value":3.0,"skew":0.3333333432674408},"outTaper":{"value":0.3333333432674408,"skew":0.3333333432674408}}
        """.data(using: .utf8)!

        let decoded = try JSONDecoder().decode(FadeDescription.self, from: json)
        #expect(decoded.inTaper == .default)
        #expect(decoded.outTaper == .reverseAudio)
    }
}

// Copyright Ryan Francesconi. All Rights Reserved.

import Foundation
import Numerics
import Testing

@testable import SPFKAudioBase

@Suite
struct LoudnessDescriptionEdgeCaseTests {
    // MARK: - Validation

    @Test("validated() clears out-of-range values")
    func validatedClearsOutOfRange() {
        let desc = LoudnessDescription(
            loudnessIntegrated: -200,
            loudnessRange: 500,
            maxTruePeakLevel: 327.67,
            maxMomentaryLoudness: -100,
            maxShortTermLoudness: 100
        ).validated()

        #expect(desc.loudnessIntegrated == nil)
        #expect(desc.loudnessRange == nil)
        #expect(desc.maxTruePeakLevel == nil)
        #expect(desc.maxMomentaryLoudness == nil)
        #expect(desc.maxShortTermLoudness == nil)
        #expect(!desc.isValid)
    }

    @Test("validated() preserves in-range values")
    func validatedPreservesInRange() {
        let desc = LoudnessDescription(
            loudnessIntegrated: -24.0,
            loudnessRange: 5.0,
            maxTruePeakLevel: -0.1,
            maxMomentaryLoudness: -20.0,
            maxShortTermLoudness: -22.0
        ).validated()

        #expect(desc.loudnessIntegrated == -24.0)
        #expect(desc.loudnessRange == 5.0)
        #expect(desc.maxTruePeakLevel == -0.1)
        #expect(desc.maxMomentaryLoudness == -20.0)
        #expect(desc.maxShortTermLoudness == -22.0)
        #expect(desc.isValid)
    }

    @Test("validated() handles boundary values")
    func validatedBoundaryValues() {
        let atBoundary = LoudnessDescription(
            loudnessIntegrated: -99.99,
            loudnessRange: 99.99,
            maxTruePeakLevel: 0,
            maxMomentaryLoudness: -99.99,
            maxShortTermLoudness: 99.99
        ).validated()

        #expect(atBoundary.loudnessIntegrated == -99.99)
        #expect(atBoundary.loudnessRange == 99.99)
        #expect(atBoundary.maxTruePeakLevel == 0)
        #expect(atBoundary.maxMomentaryLoudness == -99.99)
        #expect(atBoundary.maxShortTermLoudness == 99.99)
    }

    @Test("validated() clears just-outside-boundary values")
    func validatedJustOutsideBoundary() {
        let justOutside = LoudnessDescription(
            loudnessIntegrated: -100.0,
            loudnessRange: 100.0
        ).validated()

        #expect(justOutside.loudnessIntegrated == nil)
        #expect(justOutside.loudnessRange == nil)
    }

    @Test("isValid returns true with only one non-nil metric")
    func isValidPartialMetrics() {
        let integratedOnly = LoudnessDescription(loudnessIntegrated: -24.0)
        #expect(integratedOnly.isValid)

        let truePeakOnly = LoudnessDescription(maxTruePeakLevel: -1.0)
        #expect(truePeakOnly.isValid)

        let momentaryOnly = LoudnessDescription(maxMomentaryLoudness: -20.0)
        #expect(momentaryOnly.isValid)

        let shortTermOnly = LoudnessDescription(maxShortTermLoudness: -22.0)
        #expect(shortTermOnly.isValid)
    }

    @Test("0x7FFF sentinel value is cleared by validation")
    func sentinelValueCleared() {
        let sentinel: Float64 = 327.67 // 0x7FFF / 100
        let desc = LoudnessDescription(
            loudnessIntegrated: sentinel,
            loudnessRange: sentinel,
            maxTruePeakLevel: Float32(sentinel),
            maxMomentaryLoudness: sentinel,
            maxShortTermLoudness: sentinel
        ).validated()

        #expect(!desc.isValid)
    }

    // MARK: - Codable

    @Test("JSON round-trip preserves nil values")
    func jsonRoundTripNils() throws {
        let original = LoudnessDescription(
            loudnessIntegrated: -24.0,
            loudnessRange: nil,
            maxTruePeakLevel: nil,
            maxMomentaryLoudness: nil,
            maxShortTermLoudness: nil
        )

        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(LoudnessDescription.self, from: data)

        #expect(decoded.loudnessIntegrated == -24.0)
        #expect(decoded.loudnessRange == nil)
        #expect(decoded.maxTruePeakLevel == nil)
        #expect(decoded.maxMomentaryLoudness == nil)
        #expect(decoded.maxShortTermLoudness == nil)
    }

    @Test("decodes from partial JSON")
    func decodesPartialJSON() throws {
        let json = #"{"loudnessIntegrated": -14.5}"#
        let data = Data(json.utf8)
        let decoded = try JSONDecoder().decode(LoudnessDescription.self, from: data)

        #expect(decoded.loudnessIntegrated == -14.5)
        #expect(decoded.loudnessRange == nil)
        #expect(decoded.maxTruePeakLevel == nil)
    }

    // MARK: - Averaging

    @Test("single item average equals that item")
    func singleItemAverage() {
        let desc = LoudnessDescription(
            loudnessIntegrated: -24.0,
            loudnessRange: 5.0,
            maxTruePeakLevel: -0.1
        )

        let avg = [desc].average

        #expect(avg.loudnessIntegrated == -24.0)
        #expect(avg.loudnessRange == 5.0)
        #expect(avg.maxTruePeakLevel == -0.1)
    }

    @Test("average of all-invalid descriptions is invalid")
    func allInvalidAverage() {
        let invalid1 = LoudnessDescription() // all nil
        let invalid2 = LoudnessDescription(loudnessRange: 5.0) // only range, isValid=false

        let avg = [invalid1, invalid2].average
        #expect(!avg.isValid)
    }

    // MARK: - stringValue

    @Test("all-nil description produces N/A values")
    func allNilStringValue() {
        let desc = LoudnessDescription()
        let sv = desc.stringValue

        #expect(sv.contains("I N/A LUFS"))
        #expect(sv.contains("TP N/A dB"))
        #expect(sv.contains("LRA N/A LU"))
        // Momentary and ShortTerm should be omitted when nil
        #expect(!sv.contains("M "))
        #expect(!sv.contains("S "))
    }

    @Test("partial values show N/A only for missing metrics")
    func partialStringValue() {
        let desc = LoudnessDescription(
            loudnessIntegrated: -24.0,
            maxMomentaryLoudness: -19.5
        )
        let sv = desc.stringValue

        #expect(sv.contains("I -24.0 LUFS"))
        #expect(sv.contains("TP N/A dB"))
        #expect(sv.contains("LRA N/A LU"))
        #expect(sv.contains("M -19.5 LU"))
        #expect(!sv.contains("S "))
    }
}

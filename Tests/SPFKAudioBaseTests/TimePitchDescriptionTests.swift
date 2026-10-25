// Copyright Ryan Francesconi. All Rights Reserved. Revision History at https://github.com/ryanfrancesconi/spfk-audio-base

import Foundation
import SPFKAudioBase
import SPFKBase
import Testing

@Suite("TimePitchDescription")
struct TimePitchDescriptionTests {
    @Test(arguments: [
        (210_900, 0.9, 234_333),
        (210_900, 0.5, 421_800),
        (210_900, 2.0, 105_450),
        (1, 2.0, 1), // 0.5 rounds away from zero
        (3, 2.0, 2), // 1.5 rounds away from zero
        (0, 1.5, 0),
        (100, 1.03, 97),
    ])
    func outputFrameCountRoundsHalfAwayFromZero(input: Int, rate: Double, expected: Int) {
        #expect(TimePitchDescription(rate: rate).outputFrameCount(forInput: input) == expected)
    }

    @Test func constructionClampsEveryField() {
        let high = TimePitchDescription(
            semitones: 99, cents: 500, rate: 9, tonalityLimitHz: 99_000, formantCorrection: true,
            formantBaseHz: 5000, formantSemitones: 40
        )
        #expect(high.semitones == 24)
        #expect(high.cents == 100)
        #expect(high.rate == 2)
        #expect(high.tonalityLimitHz == 20000)
        #expect(high.formantBaseHz == 1000)
        #expect(high.formantSemitones == 12)

        let low = TimePitchDescription(
            semitones: -99, cents: -500, rate: 0.01, tonalityLimitHz: 10, formantBaseHz: 1, formantSemitones: -40
        )
        #expect(low.semitones == -24)
        #expect(low.cents == -100)
        #expect(low.rate == 0.5)
        #expect(low.tonalityLimitHz == 1000)
        #expect(low.formantBaseHz == 50)
        #expect(low.formantSemitones == -12)
    }

    @Test func zeroAndNonPositiveKeepOffAndAuto() {
        #expect(TimePitchDescription(tonalityLimitHz: 0, formantBaseHz: 0).tonalityLimitHz == 0)
        let negative = TimePitchDescription(tonalityLimitHz: -5, formantBaseHz: -5)
        #expect(negative.tonalityLimitHz == 0)
        #expect(negative.formantBaseHz == 0)
    }

    @Test func nonFiniteValuesFallBackToIdentity() {
        let value = TimePitchDescription(
            cents: .nan, rate: .infinity, tonalityLimitHz: .nan, formantBaseHz: .infinity, formantSemitones: .nan
        )
        #expect(value == TimePitchDescription())
    }

    @Test func assignmentClamps() {
        var value = TimePitchDescription()
        value.rate = 5
        value.semitones = -30
        value.cents = .nan
        value.tonalityLimitHz = 50
        value.formantSemitones = 13
        #expect(value.rate == 2)
        #expect(value.semitones == -24)
        #expect(value.cents == 0)
        #expect(value.tonalityLimitHz == 1000)
        #expect(value.formantSemitones == 12)
    }

    @Test func decodeClampsThroughTheSameInit() throws {
        let json = #"{"semitones":40,"cents":-300,"rate":0.1,"tonalityLimitHz":50,"formantBaseHz":2000,"formantSemitones":-20}"#
        let value = try JSONDecoder().decode(TimePitchDescription.self, from: Data(json.utf8))
        #expect(value == TimePitchDescription(
            semitones: 24, cents: -100, rate: 0.5, tonalityLimitHz: 1000, formantBaseHz: 1000, formantSemitones: -12
        ))
    }

    @Test func roundTripsEveryField() throws {
        let value = TimePitchDescription(
            semitones: 3, cents: -12.5, rate: 1.25, tonalityLimitHz: 8000, formantCorrection: true,
            formantBaseHz: 200, formantSemitones: -4
        )
        let decoded = try JSONDecoder().decode(TimePitchDescription.self, from: JSONEncoder().encode(value))
        #expect(decoded == value)
    }

    @Test func targetBpmSetsTheRate() throws {
        let source = try #require(Bpm(60))
        let half = TimePitchDescription(targetBpm: try #require(Bpm(30)), sourceBpm: source, semitones: 2, cents: 5)
        #expect(half.rate == 0.5)
        #expect(half.pitchCents == 205)
        // Beyond the range, the rate clamps rather than the target being honored.
        #expect(TimePitchDescription(targetBpm: try #require(Bpm(240)), sourceBpm: source).rate == 2)
    }

    @Test func transposeFactorCombinesSemitonesAndCents() {
        #expect(abs(TimePitchDescription(semitones: 12).transposeFactor - 2) < 1e-12)
        #expect(abs(TimePitchDescription(semitones: 1, cents: -100).transposeFactor - 1) < 1e-12)
    }

    @Test func isEmptyIgnoresOnlyTheOptionsThatNeedAPitchShift() {
        #expect(TimePitchDescription().isEmpty)
        #expect(TimePitchDescription(tonalityLimitHz: 8000, formantCorrection: true, formantBaseHz: 200).isEmpty)
        #expect(!TimePitchDescription(rate: 1.5).isEmpty)
        #expect(!TimePitchDescription(cents: 1).isEmpty)
        #expect(!TimePitchDescription(formantSemitones: 4).isEmpty)
        // Opposing semitones and cents are no shift at all.
        #expect(TimePitchDescription(semitones: 1, cents: -100).isEmpty)
    }
}

@Suite("AudioEditDescription time/pitch")
struct AudioEditDescriptionTimePitchTests {
    @Test func timePitchCountsTowardIsEmptyAndTheCeiling() {
        let edit = AudioEditDescription(timePitch: TimePitchDescription(rate: 0.75))
        #expect(!edit.isEmpty)
        #expect(edit.needsCeiling)
        #expect(!AudioEditDescription(timePitch: TimePitchDescription(formantCorrection: true)).needsCeiling)
    }

    @Test func descriptionEncodedBeforeTheFieldDecodesToIdentity() throws {
        let current = AudioEditDescription(trim: TrimDescription(inPoint: 1, outPoint: 2), channels: .swap)
        var object = try #require(try JSONSerialization.jsonObject(with: JSONEncoder().encode(current)) as? [String: Any])
        #expect(object.removeValue(forKey: "timePitch") != nil)
        let old = try JSONSerialization.data(withJSONObject: object)

        let edit = try JSONDecoder().decode(AudioEditDescription.self, from: old)
        #expect(edit.timePitch == TimePitchDescription())
        #expect(edit == current)
    }

    @Test func roundTripsTimePitch() throws {
        let edit = AudioEditDescription(timePitch: TimePitchDescription(semitones: -5, rate: 1.5))
        #expect(try JSONDecoder().decode(AudioEditDescription.self, from: JSONEncoder().encode(edit)) == edit)
    }

    @Test func activeKindsListsTheNonEmptyParts() {
        #expect(AudioEditDescription().activeKinds.isEmpty)
        let edit = AudioEditDescription(
            trim: TrimDescription(inPoint: 1, outPoint: 3),
            fade: FadeDescription(inTime: 0.5),
            timePitch: TimePitchDescription(rate: 0.8)
        )
        #expect(edit.activeKinds == [.trim, .fade, .timePitch])
    }

    @Test func maskedKeepsExactlyItsKinds() {
        let full = AudioEditDescription(
            trim: TrimDescription(inPoint: 1, outPoint: 3),
            channels: .swap,
            isReversed: true,
            normalize: NormalizeDescription(gain: 2),
            fade: FadeDescription(inTime: 0.5, outTime: 0.25),
            timePitch: TimePitchDescription(semitones: 3, rate: 0.8)
        )
        #expect(full.activeKinds == Set(AudioEditKind.allCases))
        #expect(full.masked(to: Set(AudioEditKind.allCases)) == full)
        #expect(full.masked(to: []).isEmpty)

        for kind in AudioEditKind.allCases {
            let masked = full.masked(to: [kind])
            #expect(masked.activeKinds == [kind], "\(kind)")
        }

        let trimAndFade = full.masked(to: [.trim, .fade])
        #expect(trimAndFade == AudioEditDescription(trim: full.trim, fade: full.fade))
    }
}

@Suite("Bpm scaling and AudioRenderSettings")
struct TimePitchSettingsTests {
    @Test func scaledBpmRoundsToTwoDecimals() throws {
        let scaled = try #require(Bpm(120)?.scaled(by: 0.7777))
        #expect(scaled.rawValue == 93.32)
        #expect(scaled.stringValue == "93.32")
        #expect(try #require(Bpm(120)?.scaled(by: 0.5)).stringValue == "60")
    }

    @Test func settingsEncodedBeforeTheFieldDecodeToBest() throws {
        let json = #"{"ceiling":"limit"}"#
        let settings = try JSONDecoder().decode(AudioRenderSettings.self, from: Data(json.utf8))
        #expect(settings == AudioRenderSettings(ceiling: .limit, timePitchQuality: .best))
    }

    @Test func settingsRoundTripTheQuality() throws {
        let settings = AudioRenderSettings(timePitchQuality: .efficient)
        #expect(try JSONDecoder().decode(AudioRenderSettings.self, from: JSONEncoder().encode(settings)) == settings)
    }
}

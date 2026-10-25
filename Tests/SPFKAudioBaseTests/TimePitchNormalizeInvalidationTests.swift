// Copyright Ryan Francesconi. All Rights Reserved. Revision History at https://github.com/ryanfrancesconi/spfk-audio-base

import Foundation
import SPFKAudioBase
import SPFKBase
import Testing

@Suite("TimePitchDescription.invalidatesNormalize")
struct TimePitchNormalizeInvalidationTests {
    @Test(arguments: [
        TimePitchDescription(rate: 1.25),
        TimePitchDescription(semitones: 3),
        TimePitchDescription(cents: 12),
        TimePitchDescription(formantSemitones: -2),
    ])
    func aLevelMovingChangeInvalidates(_ new: TimePitchDescription) {
        #expect(new.invalidatesNormalize(from: TimePitchDescription()))
        #expect(TimePitchDescription().invalidatesNormalize(from: new))
    }

    @Test(arguments: [
        TimePitchDescription(tonalityLimitHz: 8000),
        TimePitchDescription(formantCorrection: true),
        TimePitchDescription(formantBaseHz: 200),
        TimePitchDescription(tonalityLimitHz: 8000, formantCorrection: true, formantBaseHz: 200),
    ])
    func aTimbreOnlyChangeDoesNotInvalidate(_ new: TimePitchDescription) {
        #expect(!new.invalidatesNormalize(from: TimePitchDescription()))
    }

    @Test func identityToIdentityDoesNotInvalidate() {
        #expect(!TimePitchDescription().invalidatesNormalize(from: TimePitchDescription()))
    }

    @Test func theSamePitchSpelledDifferentlyDoesNotInvalidate() {
        let old = TimePitchDescription(semitones: 1, cents: 0)
        let new = TimePitchDescription(semitones: 0, cents: 100)
        #expect(!new.invalidatesNormalize(from: old))
    }
}

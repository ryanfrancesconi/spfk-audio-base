// Copyright Ryan Francesconi. All Rights Reserved. Revision History at https://github.com/ryanfrancesconi/spfk-audio-base

import AudioToolbox
import Foundation
import SPFKTesting
import Testing

@testable import SPFKAudioBase

@Suite(.tags(.automation))
struct AudioTaperTests {
    @Test func defaultPreset() {
        let taper = AudioTaper.default
        #expect(taper.value == 3)
        #expect(taper.skew == AUValue(1) / AUValue(3))
        #expect(taper.inverseValue == AUValue(1) / AUValue(3))
    }

    @Test func linearPreset() {
        let taper = AudioTaper.linear
        #expect(taper.value == 1)
        #expect(taper.skew == 0)
        #expect(taper.inverseValue == 1)
    }

    @Test func reverseAudioPreset() {
        let taper = AudioTaper.reverseAudio
        #expect(taper.value == AUValue(1) / AUValue(3))
        #expect(taper.skew == AUValue(1) / AUValue(3))
        #expect(taper.inverseValue == 3)
    }

    @Test func customInit() {
        let taper = AudioTaper(value: 2, skew: 0.5)
        #expect(taper.value == 2)
        #expect(taper.skew == 0.5)
        #expect(taper.inverseValue == 0.5)
    }

    @Test func inverseValueRelationship() {
        // For any taper, value * inverseValue should equal 1
        let tapers: [AudioTaper] = [.default, .linear, .reverseAudio]

        for taper in tapers {
            #expect(
                (taper.value * taper.inverseValue).isApproximatelyEqual(to: 1, absoluteTolerance: 0.0001)
            )
        }
    }
}

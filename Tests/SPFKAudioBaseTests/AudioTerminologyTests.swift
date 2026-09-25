// Copyright Ryan Francesconi. All Rights Reserved. Revision History at https://github.com/ryanfrancesconi/spfk-audio-base

import Foundation
@testable import SPFKAudioBase
import Testing

struct AudioTerminologyTests {
    private let english = Locale(identifier: "en_US")
    private let german = Locale(identifier: "de_DE")

    /// Whole kilohertz drop the fraction; 22.05 and 11.025 keep every digit rather than
    /// rounding to a rate that doesn't exist.
    @Test(arguments: [
        (44100.0, "44.1 kHz"), (48000.0, "48 kHz"), (88200.0, "88.2 kHz"), (96000.0, "96 kHz"),
        (192_000.0, "192 kHz"), (22050.0, "22.05 kHz"), (11025.0, "11.025 kHz"), (8000.0, "8 kHz"),
    ])
    func sampleRateInKilohertz(hertz: Double, expected: String) {
        #expect(AudioTerminology.sampleRate(hertz, locale: english) == expected)
    }

    @Test func theDecimalSeparatorFollowsTheLocale() {
        #expect(AudioTerminology.sampleRate(44100, locale: german) == "44,1 kHz")
        #expect(AudioTerminology.sampleRate(176_400, locale: german) == "176,4 kHz")
    }

    /// Never "44100.0 Hz", and never grouped.
    @Test func exactRatesAreWholeHertz() {
        #expect(AudioTerminology.sampleRateInHertz(44100) == "44100 Hz")
        #expect(AudioTerminology.sampleRateInHertz(192_000) == "192000 Hz")
    }

    @Test func channelsNameTheCommonLayoutsAndCountTheRest() {
        #expect(AudioTerminology.channels(0) == "")
        #expect(AudioTerminology.channels(1) == "Mono")
        #expect(AudioTerminology.channels(2) == "Stereo")
        #expect(AudioTerminology.channels(6) == "6 Channels")
    }

    @Test func depthAndRateCarryTheirUnits() {
        #expect(AudioTerminology.bitDepth(24) == "24 bit")
        #expect(AudioTerminology.bitRate(kbps: 320) == "320 kbps")
    }
}

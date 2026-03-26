// Copyright Ryan Francesconi. All Rights Reserved.

import Foundation
import SPFKAudioBase
import SPFKBase
import Testing

struct BpmTempoStringTests {
    // MARK: - Prefix patterns

    @Test func tempoColon() {
        #expect(Bpm(tempoString: "Tempo: 120")?.rawValue == 120)
    }

    @Test func tempoSpace() {
        #expect(Bpm(tempoString: "Tempo 97")?.rawValue == 97)
    }

    @Test func bpmPrefixWithSpace() {
        #expect(Bpm(tempoString: "BPM 130")?.rawValue == 130)
    }

    @Test func bpmPrefixNoSpace() {
        #expect(Bpm(tempoString: "BPM140")?.rawValue == 140)
    }

    // MARK: - Suffix patterns

    @Test func bpmSuffixWithSpace() {
        #expect(Bpm(tempoString: "120 BPM")?.rawValue == 120)
    }

    @Test func bpmSuffixNoSpace() {
        #expect(Bpm(tempoString: "174bpm")?.rawValue == 174)
    }

    // MARK: - Case insensitivity

    @Test func lowercaseTempo() {
        #expect(Bpm(tempoString: "tempo: 88")?.rawValue == 88)
    }

    @Test func lowercaseBpmSuffix() {
        #expect(Bpm(tempoString: "110 bpm")?.rawValue == 110)
    }

    // MARK: - Decimal values

    @Test func decimalWithTempoPrefix() {
        #expect(Bpm(tempoString: "Tempo: 87.5")?.rawValue == 87.5)
    }

    @Test func decimalWithBpmSuffix() {
        #expect(Bpm(tempoString: "92.3 BPM")?.rawValue == 92.3)
    }

    // MARK: - Embedded in longer strings (filename stems)

    @Test func embeddedInFilename() {
        #expect(Bpm(tempoString: "120bpm_kick_drum")?.rawValue == 120)
    }

    @Test func bpmPrefixInFilename() {
        #expect(Bpm(tempoString: "BPM140_loop")?.rawValue == 140)
    }

    // MARK: - No match

    @Test func noPatternReturnsNil() {
        #expect(Bpm(tempoString: "Intro") == nil)
    }

    @Test func emptyStringReturnsNil() {
        #expect(Bpm(tempoString: "") == nil)
    }
}

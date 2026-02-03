import AVFoundation
import Numerics
import SPFKAudioBase
import SPFKBase
import SPFKTesting
import Testing

final class LoudnessDescriptionTests {
    @Test func averageLoudness() async throws {
        let _1 = LoudnessDescription(loudnessIntegrated: nil, loudnessRange: 1, maxTruePeakLevel: 1, maxMomentaryLoudness: 1, maxShortTermLoudness: 1)
        let _2 = LoudnessDescription(loudnessIntegrated: 5, loudnessRange: 2, maxTruePeakLevel: 2, maxMomentaryLoudness: 2, maxShortTermLoudness: 2)
        let _invalid = LoudnessDescription(loudnessIntegrated: 327.67, loudnessRange: 0, maxTruePeakLevel: 327.67, maxMomentaryLoudness: 327.67, maxShortTermLoudness: 327.67)
        let average = [_1, _2, _invalid].average

        #expect(average == LoudnessDescription(loudnessIntegrated: 5, loudnessRange: 1.5, maxTruePeakLevel: 1.5, maxMomentaryLoudness: 1.5, maxShortTermLoudness: 1.5))
    }

    @Test func validated() async throws {
        let desc = LoudnessDescription(
            loudnessIntegrated: 327.67,
            loudnessRange: 0,
            maxTruePeakLevel: Float.nan,
            maxMomentaryLoudness: Double.infinity,
            maxShortTermLoudness: 327.67
        ).validated()

        #expect(!desc.isValid)
        #expect(desc.loudnessIntegrated == nil)
        #expect(desc.loudnessRange == 0)
        #expect(desc.maxTruePeakLevel == nil)
        #expect(desc.maxMomentaryLoudness == nil)
        #expect(desc.maxShortTermLoudness == nil)
    }
}

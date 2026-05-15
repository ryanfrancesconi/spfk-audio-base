import Foundation
import SPFKAudioBase
import SPFKBase
import Testing

@Suite("AudioEditDescription fade helpers")
struct AudioEditDescriptionFadesTests {
    // MARK: - clampedFades

    @Test func clampedFadesUnderLimitUnchanged() {
        let result = AudioEditDescription.clampedFades(inTime: 1, outTime: 2, duration: 10)
        #expect(result.inTime == 1)
        #expect(result.outTime == 2)
    }

    @Test func clampedFadesExactlyAtLimitUnchanged() {
        let result = AudioEditDescription.clampedFades(inTime: 5, outTime: 5, duration: 10)
        #expect(result.inTime == 5)
        #expect(result.outTime == 5)
    }

    @Test func clampedFadesProportionalWhenTotalExceedsDuration() {
        // inTime=4, outTime=6 → total=10 > duration=4 → scale=0.4
        let result = AudioEditDescription.clampedFades(inTime: 4, outTime: 6, duration: 4)
        #expect(abs(result.inTime - 1.6) < 1e-10)
        #expect(abs(result.outTime - 2.4) < 1e-10)
        #expect(abs(result.inTime + result.outTime - 4) < 1e-10)
    }

    @Test func clampedFadesBothZeroReturnZero() {
        let result = AudioEditDescription.clampedFades(inTime: 0, outTime: 0, duration: 10)
        #expect(result.inTime == 0)
        #expect(result.outTime == 0)
    }

    @Test func clampedFadesOnlyFadeInExceedsDuration() {
        // inTime=8, outTime=0 → total=8 > duration=4 → scale=0.5
        let result = AudioEditDescription.clampedFades(inTime: 8, outTime: 0, duration: 4)
        #expect(abs(result.inTime - 4) < 1e-10)
        #expect(result.outTime == 0)
    }

    // MARK: - selectionFades

    @Test func selectionFadesAtStartReturnsFadeInOnly() {
        let result = AudioEditDescription.selectionFades(selectionStart: 0, selectionEnd: 2, duration: 10)
        #expect(result != nil)
        #expect(result?.inTime == 2)
        #expect(result?.outTime == 0)
    }

    @Test func selectionFadesAtEndReturnsFadeOutOnly() {
        let result = AudioEditDescription.selectionFades(selectionStart: 8, selectionEnd: 10, duration: 10)
        #expect(result != nil)
        #expect(result?.inTime == 0)
        #expect(result?.outTime == 2)
    }

    @Test func selectionFadesSpanningWholeFileReturnsBoth() {
        let result = AudioEditDescription.selectionFades(selectionStart: 0, selectionEnd: 10, duration: 10)
        #expect(result != nil)
        #expect(result?.inTime == 10)
        #expect(result?.outTime == 10)
    }

    @Test func selectionFadesFullyInteriorReturnsNil() {
        let result = AudioEditDescription.selectionFades(selectionStart: 2, selectionEnd: 8, duration: 10)
        #expect(result == nil)
    }

    @Test func selectionFadesWithinToleranceTreatedAsBoundary() {
        // 0.0005 is within the default 0.001 tolerance
        let result = AudioEditDescription.selectionFades(selectionStart: 0.0005, selectionEnd: 3, duration: 10)
        #expect(result != nil)
        #expect(result?.inTime ?? 0 > 0)
        #expect(result?.outTime == 0)
    }

    @Test func selectionFadesZeroDurationReturnsNil() {
        let result = AudioEditDescription.selectionFades(selectionStart: 3, selectionEnd: 3, duration: 10)
        #expect(result == nil)
    }

    // MARK: - settingFades / clearingFades

    @Test func settingFadesPreservesOtherFields() {
        let original = AudioEditDescription(
            keepRanges: [AudioTimeRange(start: 0, end: 1)],
            isReversed: true,
            fade: FadeDescription(taper: .linear)
        )
        let result = original.settingFades(inTime: 2, outTime: 3)
        #expect(result.fade.inTime == 2)
        #expect(result.fade.outTime == 3)
        #expect(result.isReversed == true)
        #expect(result.keepRanges.count == 1)
        #expect(result.fade.taper == .linear)
    }

    @Test func clearingFadesPreservesKeepRangesAndReverse() {
        let original = AudioEditDescription(
            keepRanges: [AudioTimeRange(start: 0, end: 1)],
            isReversed: true,
            fade: FadeDescription(inTime: 5, outTime: 3)
        )
        let result = original.clearingFades()
        #expect(result.fade.inTime == 0)
        #expect(result.fade.outTime == 0)
        #expect(result.isReversed == true)
        #expect(result.keepRanges.count == 1)
    }

    @Test func clearingFadesOnFadesOnlyDescriptionIsEmpty() {
        let original = AudioEditDescription(fade: FadeDescription(inTime: 5, outTime: 3))
        let result = original.clearingFades()
        #expect(result.isEmpty)
    }
}

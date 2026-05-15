import Foundation
import SPFKAudioBase
import SPFKBase
import Testing

@Suite("AudioEditDescription trim helpers")
struct AudioEditDescriptionTrimTests {
    @Test func settingTrimReplacesTrim() {
        let trim = TrimDescription(inPoint: 0.5, outPoint: 3.0)
        let result = AudioEditDescription().settingTrim(trim)
        #expect(result.trim == trim)
        #expect(!result.isEmpty)
    }

    @Test func settingTrimPreservesOtherFields() {
        let fade = FadeDescription(inTime: 1.0, outTime: 2.0, taper: .linear)
        let trim = TrimDescription(inPoint: 0.5, outPoint: 3.0)
        let original = AudioEditDescription(isReversed: true, fade: fade)
        let result = original.settingTrim(trim)
        #expect(result.trim == trim)
        #expect(result.isReversed == true)
        #expect(result.fade == fade)
    }

    @Test func clearingTrimResetsToEmpty() {
        let trim = TrimDescription(inPoint: 0.5, outPoint: 3.0)
        let original = AudioEditDescription(trim: trim)
        let result = original.clearingTrim()
        #expect(result.trim.isEmpty)
    }

    @Test func clearingTrimPreservesOtherFields() {
        let fade = FadeDescription(inTime: 1.0, outTime: 2.0)
        let trim = TrimDescription(inPoint: 0.5, outPoint: 3.0)
        let original = AudioEditDescription(trim: trim, isReversed: true, fade: fade)
        let result = original.clearingTrim()
        #expect(result.trim.isEmpty)
        #expect(result.isReversed == true)
        #expect(result.fade == fade)
    }

    @Test func settingEmptyTrimOnEmptyDescriptionStaysEmpty() {
        let result = AudioEditDescription().settingTrim(TrimDescription())
        #expect(result.isEmpty)
    }

    @Test func clearingTrimOnTrimOnlyDescriptionIsEmpty() {
        let trim = TrimDescription(inPoint: 0.5, outPoint: 3.0)
        let original = AudioEditDescription(trim: trim)
        let result = original.clearingTrim()
        #expect(result.isEmpty)
    }
}

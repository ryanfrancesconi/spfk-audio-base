// Copyright Ryan Francesconi. All Rights Reserved. Revision History at https://github.com/ryanfrancesconi/spfk-audio-base

import AudioToolbox
import Foundation
import SPFKBase
import Testing

@testable import SPFKAudioBase

@Suite(.tags(.automation))
struct FadeCurveTests {
    // MARK: - clamped(toRegion:favoring:)

    @Test func clampFavoringTheFadeOutShortensTheFadeIn() {
        let fade = FadeDescription(inTime: 3, outTime: 2).clamped(toRegion: 4)
        #expect(fade.inTime == 2)
        #expect(fade.outTime == 2)
    }

    @Test func clampFavoringTheFadeInShortensTheFadeOut() {
        let fade = FadeDescription(inTime: 3, outTime: 2).clamped(toRegion: 4, favoring: .fadeIn)
        #expect(fade.inTime == 3)
        #expect(fade.outTime == 1)
    }

    @Test func clampingAFadeLongerThanTheRegionLeavesNoRoomForTheOther() {
        let favoringOut = FadeDescription(inTime: 1, outTime: 6).clamped(toRegion: 4)
        #expect(favoringOut.inTime == 0)
        #expect(favoringOut.outTime == 4)

        let favoringIn = FadeDescription(inTime: 6, outTime: 1).clamped(toRegion: 4, favoring: .fadeIn)
        #expect(favoringIn.inTime == 4)
        #expect(favoringIn.outTime == 0)
    }

    @Test func clampToAnEmptyRegionRemovesBothFades() {
        for region in [0, -1, Double.nan] {
            let fade = FadeDescription(inTime: 1, outTime: 1, inTaper: .linear).clamped(toRegion: region)
            #expect(fade.inTime == 0)
            #expect(fade.outTime == 0)
            #expect(fade.inTaper == .linear)
        }
    }

    @Test func fadesThatFitAreUnchanged() {
        let fade = FadeDescription(inTime: 1, outTime: 2)
        #expect(fade.clamped(toRegion: 3) == fade)
        #expect(fade.clamped(toRegion: 3, favoring: .fadeIn) == fade)
    }

    // MARK: - curve(regionDuration:maximumGain:)

    @Test(arguments: AudioTaper.presets)
    func curveMatchesTheTapersAndHoldsBetweenThem(taper: AudioTaper) throws {
        let fade = FadeDescription(inTime: 1, outTime: 2, inTaper: taper, outTaper: taper)
        let curve = try fade.curve(regionDuration: 5, maximumGain: 0.8)

        for i in 0 ... 200 {
            let x = Double(i) / 200
            #expect(abs(curve.value(at: x) - Float(0.8 * taper.gain(at: x))) < 1e-6, "fade-in at \(x)")
            #expect(abs(curve.value(at: 3 + 2 * x) - Float(0.8 * taper.fadeOutGain(at: x))) < 1e-6, "fade-out at \(x)")
        }
        #expect(abs(curve.value(at: 2) - 0.8) < 1e-6)
        #expect(curve.value(at: -1) == 0)
        #expect(curve.value(at: 6) == 0)
    }

    @Test func noFadeIsAConstantAtTheMaximum() throws {
        let curve = try FadeDescription().curve(regionDuration: 5, maximumGain: 0.5)
        #expect(curve.value(at: 0) == 0.5)
        #expect(curve.value(at: 5) == 0.5)
    }

    @Test func fadeOutOnlyHoldsTheMaximumBeforeIt() throws {
        let curve = try FadeDescription(outTime: 1).curve(regionDuration: 5)
        #expect(curve.value(at: 0) == 1)
        #expect(curve.value(at: 4) == 1)
        #expect(curve.value(at: 5) == 0)
    }

    /// Touching fades sum to the region exactly, which rounding can turn into a one-ulp overlap.
    @Test func touchingFadesBuildAValidCurve() throws {
        for (region, inTime, outTime) in [(0.3, 0.1, 0.2), (0.7, 0.4, 0.3), (1.1, 0.3, 0.8), (0.3, 0.2, 0.2)] {
            let curve = try FadeDescription(inTime: inTime, outTime: outTime).curve(regionDuration: region)
            #expect(curve.segments.count == 2)
        }
    }

    @Test func overlappingFadesCurveAsTheEditorClampsThem() throws {
        let fade = FadeDescription(inTime: 3, outTime: 2, inTaper: .linear, outTaper: .linear)
        let curve = try fade.curve(regionDuration: 4)

        #expect(abs(curve.value(at: 1) - 0.5) < 1e-6)
        #expect(abs(curve.value(at: 2) - 1) < 1e-6)
        #expect(abs(curve.value(at: 3) - 0.5) < 1e-6)
    }
}

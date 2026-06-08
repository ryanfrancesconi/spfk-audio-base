// Copyright Ryan Francesconi. All Rights Reserved. Revision History at https://github.com/ryanfrancesconi/spfk-audio-base

import AudioToolbox
import Foundation
import SPFKBase
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

    // MARK: - Presets index

    @Test func presetsContainsAllThreeNamed() {
        #expect(AudioTaper.presets.count == 3)
    }

    @Test func presetIndexRoundTrips() {
        for taper in AudioTaper.presets {
            let index = taper.presetIndex
            #expect(index != nil)
            #expect(AudioTaper.preset(at: index!) == taper)
        }
    }

    @Test func presetAtOutOfRangeReturnsNil() {
        #expect(AudioTaper.preset(at: -1) == nil)
        #expect(AudioTaper.preset(at: 99) == nil)
    }

    @Test func customTaperHasNoPresetIndex() {
        let custom = AudioTaper(value: 2, skew: 0.1)
        #expect(custom.presetIndex == nil)
    }

    // MARK: - gain(at:)

    @Test func gainAtBoundaries() {
        for taper in AudioTaper.presets {
            #expect(taper.gain(at: 0).isApproximatelyEqual(to: 0, absoluteTolerance: 0.0001))
            #expect(taper.gain(at: 1).isApproximatelyEqual(to: 1, absoluteTolerance: 0.0001))
        }
    }

    @Test func gainAtMidpointLinear() {
        #expect(AudioTaper.linear.gain(at: 0.5).isApproximatelyEqual(to: 0.5, absoluteTolerance: 0.0001))
    }

    @Test func gainAtMidpointDefaultIsConcave() {
        // Default (concave) curve: gain at midpoint is well below 0.5
        let mid = AudioTaper.default.gain(at: 0.5)
        #expect(mid < 0.5)
        #expect(mid.isApproximatelyEqual(to: 0.152, absoluteTolerance: 0.001))
    }

    @Test func gainAtMidpointReverseAudioIsConvex() {
        // ReverseAudio (convex) curve: gain at midpoint is well above 0.5
        let mid = AudioTaper.reverseAudio.gain(at: 0.5)
        #expect(mid > 0.5)
        #expect(mid.isApproximatelyEqual(to: 0.820, absoluteTolerance: 0.001))
    }

    @Test func gainAtIsMonotonicallyIncreasing() {
        for taper in AudioTaper.presets {
            var prev = 0.0
            for i in 1 ... 20 {
                let gain = taper.gain(at: Double(i) / 20.0)
                #expect(gain >= prev)
                prev = gain
            }
        }
    }

    // MARK: - fadeOutGain(at:)

    @Test func fadeOutGainAtBoundaries() {
        for taper in AudioTaper.presets {
            #expect(taper.fadeOutGain(at: 0).isApproximatelyEqual(to: 1, absoluteTolerance: 0.0001))
            #expect(taper.fadeOutGain(at: 1).isApproximatelyEqual(to: 0, absoluteTolerance: 0.0001))
        }
    }

    @Test func fadeOutGainAtMidpointLinear() {
        #expect(AudioTaper.linear.fadeOutGain(at: 0.5).isApproximatelyEqual(to: 0.5, absoluteTolerance: 0.0001))
    }

    @Test func fadeOutGainAtMidpointDefault() {
        // Default taper fade-out drops quickly then levels off; midpoint is well below 0.5
        let mid = AudioTaper.default.fadeOutGain(at: 0.5)
        #expect(mid < 0.5)
        #expect(mid.isApproximatelyEqual(to: 0.179, absoluteTolerance: 0.001))
    }

    @Test func fadeOutGainAtMidpointReverseAudio() {
        // ReverseAudio taper fade-out holds high then drops; midpoint is well above 0.5
        let mid = AudioTaper.reverseAudio.fadeOutGain(at: 0.5)
        #expect(mid > 0.5)
        #expect(mid.isApproximatelyEqual(to: 0.848, absoluteTolerance: 0.001))
    }

    @Test func fadeOutGainAtIsMonotonicallyDecreasing() {
        for taper in AudioTaper.presets {
            var prev = 1.0
            for i in 1 ... 20 {
                let gain = taper.fadeOutGain(at: Double(i) / 20.0)
                #expect(gain <= prev)
                prev = gain
            }
        }
    }

    // MARK: - curvePath

    @Test func curvePathStartAndEndFadeIn() {
        let rect = CGRect(x: 0, y: 0, width: 100, height: 50)
        let path = AudioTaper.default.curvePath(in: rect, flipped: false)
        let box = path.boundingBox

        // path starts near bottom-left (gain=0) and ends near top-right (gain=1)
        #expect(box.minX.isApproximatelyEqual(to: 0, absoluteTolerance: 1))
        #expect(box.maxX.isApproximatelyEqual(to: 100, absoluteTolerance: 1))
    }

    @Test func curvePathStartAndEndFadeOut() {
        let rect = CGRect(x: 0, y: 0, width: 100, height: 50)
        let path = AudioTaper.default.curvePath(in: rect, flipped: true)
        let box = path.boundingBox

        // flipped path spans the same horizontal extent
        #expect(box.minX.isApproximatelyEqual(to: 0, absoluteTolerance: 1))
        #expect(box.maxX.isApproximatelyEqual(to: 100, absoluteTolerance: 1))
    }
}

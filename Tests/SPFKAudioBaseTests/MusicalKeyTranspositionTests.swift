// Copyright Ryan Francesconi. All Rights Reserved. Revision History at https://github.com/ryanfrancesconi/spfk-audio-base

import Foundation
import SPFKAudioBase
import SPFKBase
import Testing

@Suite("MusicalKeyValue.nearestTransposition(to:)")
struct MusicalKeyTranspositionTests {
    @Test(arguments: [MusicalTonality.major, .minor])
    func everyTonicPairInOneModeTakesTheSmallestShift(tonality: MusicalTonality) throws {
        for from in NoteName.allCases {
            for to in NoteName.allCases {
                let source = MusicalKeyValue(name: from, tonality: tonality)
                let target = MusicalKeyValue(name: to, tonality: tonality)
                let shift = try #require(source.nearestTransposition(to: target))

                #expect((-5 ... 6).contains(shift), "\(source) → \(target) gave \(shift)")
                #expect(source.transposed(bySemitones: shift) == target)
            }
        }
    }

    @Test func theTritoneGoesUp() {
        let c = MusicalKeyValue(name: .c, tonality: .major)
        let fSharp = MusicalKeyValue(name: .fSharp, tonality: .major)
        #expect(c.nearestTransposition(to: fSharp) == 6)
        #expect(fSharp.nearestTransposition(to: c) == 6)
    }

    @Test func aDifferentModeMatchesTheTargetsRelativeKey() {
        let cMajor = MusicalKeyValue(name: .c, tonality: .major)
        let aMinor = MusicalKeyValue(name: .a, tonality: .minor)
        let dMajor = MusicalKeyValue(name: .d, tonality: .major)

        #expect(cMajor.nearestTransposition(to: aMinor) == 0)
        #expect(aMinor.nearestTransposition(to: cMajor) == 0)
        // A minor moves to B minor, D major's relative.
        #expect(aMinor.nearestTransposition(to: dMajor) == 2)
    }

    @Test func anUnknownTonalityOnEitherSideHasNoShift() {
        let unknown = MusicalKeyValue(name: .d, tonality: .unknown)
        let cMajor = MusicalKeyValue(name: .c, tonality: .major)
        #expect(unknown.nearestTransposition(to: cMajor) == nil)
        #expect(cMajor.nearestTransposition(to: unknown) == nil)
    }
}

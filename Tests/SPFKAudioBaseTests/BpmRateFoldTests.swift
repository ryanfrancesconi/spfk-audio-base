// Copyright Ryan Francesconi. All Rights Reserved. Revision History at https://github.com/ryanfrancesconi/spfk-audio-base

import Foundation
import SPFKAudioBase
import SPFKBase
import Testing

@Suite("Bpm.rate(toReach:within:)")
struct BpmRateFoldTests {
    private let rates = TimePitchDescription.rateRange

    private func rate(from source: Double, to target: Double) throws -> Double {
        let source = try #require(Bpm(source))
        let target = try #require(Bpm(target))
        return try #require(source.rate(toReach: target, within: rates))
    }

    @Test(arguments: [
        (100.0, 120.0, 1.2), // its pair, 0.6, is farther from 1×
        (100.0, 600.0, 0.75), // ratio 6: 1.5 and 0.75, 0.75 is nearer
        (120.0, 20.0, 4.0 / 3), // ratio 1/6: 0.667 and 1.333, 1.333 is nearer
        (90.0, 120.0, 4.0 / 3), // not 0.667
        (60.0, 120.0, 1.0), // ratio 2 folds to 1
        (60.0, 240.0, 1.0), // ratio 4 folds to 1
        (240.0, 60.0, 1.0),
        (100.0, 100.0, 1.0),
        (40.0, 240.0, 0.75),
    ])
    func foldsToTheCandidateNearestOne(source: Double, target: Double, expected: Double) throws {
        #expect(abs(try rate(from: source, to: target) - expected) < 1e-12)
    }

    @Test func theSquareRootOfTwoTiePrefersTheFaster() throws {
        let result = try rate(from: 100, to: 100 * 2.0.squareRoot())
        #expect(abs(result - 2.0.squareRoot()) < 1e-12)
    }

    @Test func everySourceAndTargetIn40To240LandsInTheRateRange() throws {
        for source in stride(from: 40.0, through: 240, by: 1) {
            for target in stride(from: 40.0, through: 240, by: 1) {
                let result = try rate(from: source, to: target)
                #expect(rates.contains(result), "\(source) → \(target) gave \(result)")
            }
        }
    }

    @Test func theResultReachesTheTargetByOctaves() throws {
        for (source, target) in [(97.0, 173.0), (133.0, 41.0), (60.0, 1000.0)] {
            let reached = source * (try rate(from: source, to: target))
            let octaves = log2(target / reached)
            #expect(abs(octaves - octaves.rounded()) < 1e-9)
        }
    }

    @Test func aWindowNarrowerThanAnOctaveCanMiss() throws {
        let source = try #require(Bpm(100))
        let target = try #require(Bpm(140))
        #expect(source.rate(toReach: target, within: 0.9 ... 1.1) == nil)
    }
}

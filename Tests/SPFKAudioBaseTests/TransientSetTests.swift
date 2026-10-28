// Copyright Ryan Francesconi. All Rights Reserved.

import Foundation
import SPFKBase
import Testing

@testable import SPFKAudioBase

@Suite
final class TransientSetTests {
    let set = TransientSet(times: [1, 2, 3, 4])
    let all: ClosedRange<TimeInterval> = 0 ... 10

    // MARK: - next / previous

    @Test func nextStepsPastATransientTheTimeSitsOn() {
        #expect(set.next(after: 2, within: all) == 3)
        #expect(set.next(after: 2 + TransientSet.tolerance / 2, within: all) == 3)
        #expect(set.next(after: 2.5, within: all) == 3)
    }

    @Test func previousStepsPastATransientTheTimeSitsOn() {
        #expect(set.previous(before: 3, within: all) == 2)
        #expect(set.previous(before: 3 - TransientSet.tolerance / 2, within: all) == 2)
        #expect(set.previous(before: 2.5, within: all) == 2)
    }

    @Test func repeatedStepsVisitEveryTransientInOrder() {
        var forward: [TimeInterval] = []
        var time: TimeInterval = 0
        while let next = set.next(after: time, within: all) {
            forward.append(next)
            time = next
        }
        #expect(forward == set.times)

        var backward: [TimeInterval] = []
        time = 10
        while let previous = set.previous(before: time, within: all) {
            backward.append(previous)
            time = previous
        }
        #expect(backward == set.times.reversed())
    }

    @Test func nothingBeyondTheLastOrFirstTransient() {
        #expect(set.next(after: 4, within: all) == nil)
        #expect(set.previous(before: 1, within: all) == nil)
    }

    @Test func boundsExcludeTransientsOutsideThem() {
        let bounds: ClosedRange<TimeInterval> = 1.5 ... 3.5
        #expect(set.next(after: 3, within: bounds) == nil)
        #expect(set.previous(before: 2, within: bounds) == nil)
        #expect(set.next(after: 2, within: bounds) == 3)
    }

    @Test func aTimeOutsideTheBoundsFindsTheNearestTransientInside() {
        let bounds: ClosedRange<TimeInterval> = 1.5 ... 3.5
        #expect(set.next(after: 0, within: bounds) == 2)
        #expect(set.previous(before: 9, within: bounds) == 3)
    }

    @Test func anEmptySetFindsNothing() {
        let empty = TransientSet(times: [])
        #expect(empty.next(after: 0, within: all) == nil)
        #expect(empty.previous(before: 10, within: all) == nil)
        #expect(empty.times(in: all).isEmpty)
    }

    // MARK: - times(in:)

    @Test func timesInARangeIncludeItsEnds() {
        #expect(Array(set.times(in: 2 ... 3)) == [2, 3])
        #expect(Array(set.times(in: 2.1 ... 2.9)).isEmpty)
        #expect(Array(set.times(in: 5 ... 6)).isEmpty)
    }

    // MARK: - mirrored

    @Test func mirroringKeepsTheTimesSorted() {
        let mirrored = set.mirrored(duration: 5)
        #expect(mirrored.times == [1, 2, 3, 4])
        #expect(TransientSet(times: [0.5, 1]).mirrored(duration: 5).times == [4, 4.5])
    }

    // MARK: - Picking from candidates

    @Test func candidatesBelowTheThresholdAreDropped() {
        let options = TransientDetectorOptions()
        let threshold = options.strengthThreshold
        let candidates = [
            TransientCandidate(time: 1, strength: threshold * 2),
            TransientCandidate(time: 2, strength: threshold / 2),
        ]

        #expect(TransientSet(candidates: candidates, options: options).times == [1])
    }

    @Test func ofTwoCloseCandidatesTheStrongerIsKept() {
        let options = TransientDetectorOptions(minimumSpacing: 0.1)
        let strong = options.strengthThreshold * 4
        let candidates = [
            TransientCandidate(time: 1, strength: strong),
            TransientCandidate(time: 1.05, strength: strong * 2),
            TransientCandidate(time: 1.5, strength: strong),
        ]

        #expect(TransientSet(candidates: candidates, options: options).times == [1.05, 1.5])
    }

    @Test func higherSensitivityKeepsMoreCandidates() {
        let candidates = stride(from: 0, to: 20, by: 1).map {
            TransientCandidate(time: Double($0), strength: powf(10, Float($0) / 10 - 1.5))
        }

        let counts = [Float(0), 0.25, 0.5, 0.75, 1].map {
            TransientSet(candidates: candidates, options: TransientDetectorOptions(sensitivity: $0)).times.count
        }

        #expect(counts == counts.sorted())
        #expect(counts.first ?? 0 < counts.last ?? 0)
    }

    // MARK: - Options

    @Test func optionsDecodeMissingFieldsAsDefaults() throws {
        let decoded = try JSONDecoder().decode(TransientDetectorOptions.self, from: Data("{}".utf8))
        #expect(decoded == TransientDetectorOptions())
    }

    @Test func optionsClampOutOfRangeValues() throws {
        let json = Data(#"{"sensitivity": 4, "minimumSpacing": 0}"#.utf8)
        let decoded = try JSONDecoder().decode(TransientDetectorOptions.self, from: json)
        #expect(decoded.sensitivity == TransientDetectorOptions.sensitivityRange.upperBound)
        #expect(decoded.minimumSpacing == TransientDetectorOptions.minimumSpacingRange.lowerBound)
    }
}

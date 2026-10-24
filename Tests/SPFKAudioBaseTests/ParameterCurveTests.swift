// Copyright Ryan Francesconi. All Rights Reserved. Revision History at https://github.com/ryanfrancesconi/spfk-audio-base

import AudioToolbox
import Foundation
import SPFKBase
import Testing

@testable import SPFKAudioBase

@Suite(.tags(.automation))
struct ParameterCurveTests {
    private func segment(
        _ start: Double, _ end: Double, _ startValue: AUValue, _ endValue: AUValue, _ shape: CurveShape = .linear
    ) -> CurveSegment {
        CurveSegment(start: start, end: end, startValue: startValue, endValue: endValue, shape: shape)
    }

    // MARK: - Validation

    @Test func rejectsInvalidSegments() {
        #expect(throws: ParameterCurve.ValidationError.empty) { try ParameterCurve([]) }
        #expect(throws: ParameterCurve.ValidationError.endBeforeStart(index: 0)) {
            try ParameterCurve([segment(1, 0.5, 0, 1)])
        }
        #expect(throws: ParameterCurve.ValidationError.overlap(index: 1)) {
            try ParameterCurve([segment(0, 1, 0, 1), segment(0.9, 2, 1, 0)])
        }
        #expect(throws: ParameterCurve.ValidationError.invalidSegment(index: 1)) {
            try ParameterCurve([segment(0, 1, 0, 1), segment(1, 2, .nan, 0)])
        }
        #expect(throws: ParameterCurve.ValidationError.invalidSegment(index: 0)) {
            try ParameterCurve([segment(0, .infinity, 0, 1)])
        }
        #expect(throws: ParameterCurve.ValidationError.invalidSegment(index: 0)) {
            try ParameterCurve([segment(0, 1, 0, 1, .taper(value: 0, skew: 0.3))])
        }
        #expect(throws: ParameterCurve.ValidationError.invalidSegment(index: 0)) {
            try ParameterCurve([CurveSegment(start: 0, end: 1, startValue: 0, endValue: 1, shapeRange: 0 ... 1.5)])
        }
    }

    @Test func decodingAnInvalidCurveThrows() throws {
        let json = #"{"segments":[]}"#
        #expect(throws: ParameterCurve.ValidationError.empty) {
            try JSONDecoder().decode(ParameterCurve.self, from: Data(json.utf8))
        }
    }

    @Test func codableRoundTrip() throws {
        let curve = try ParameterCurve([
            segment(0, 1, 0, 1, CurveShape(.default)),
            segment(2, 2.5, 1, 0.25, .step),
            CurveSegment(start: 3, end: 4, startValue: 0.25, endValue: 1, shapeRange: 0.2 ... 0.7),
        ])
        let decoded = try JSONDecoder().decode(ParameterCurve.self, from: JSONEncoder().encode(curve))
        #expect(decoded == curve)
        #expect(decoded.value(at: 3.5) == curve.value(at: 3.5))
    }

    // MARK: - value(at:)

    @Test func holdsBeforeBetweenAndAfterSegments() throws {
        let curve = try ParameterCurve([segment(1, 2, 0.2, 0.8), segment(3, 4, 0.5, 0.1)])

        #expect(curve.value(at: -10) == 0.2)
        #expect(curve.value(at: 1) == 0.2)
        #expect(abs(curve.value(at: 1.5) - 0.5) < 1e-6)
        #expect(curve.value(at: 2) == 0.8)
        #expect(curve.value(at: 2.9) == 0.8)
        #expect(curve.value(at: 3) == 0.5)
        #expect(curve.value(at: 4) == 0.1)
        #expect(curve.value(at: 100) == 0.1)
    }

    @Test func taperSegmentEvaluatesTheTaper() throws {
        let taper = AudioTaper.default
        let curve = try ParameterCurve([segment(2, 4, 0, 0.5, CurveShape(taper))])

        for i in 0 ... 100 {
            let x = Double(i) / 100
            let expected = Float(0.5 * taper.gain(at: x))
            #expect(abs(curve.value(at: 2 + 2 * x) - expected) < 1e-6, "at \(x)")
        }
    }

    @Test func stepHoldsItsStartValueUntilItsEnd() throws {
        let curve = try ParameterCurve([segment(1, 2, 0.3, 0.9, .step)])

        #expect(curve.value(at: 1) == 0.3)
        #expect(curve.value(at: 1.999999) == 0.3)
        #expect(curve.value(at: 2) == 0.9)
    }

    @Test func zeroLengthSegmentJumps() throws {
        let curve = try ParameterCurve([segment(0, 1, 0, 1), segment(1, 1, 0.25, 0.25), segment(1, 2, 0.25, 0.75)])

        #expect(curve.value(at: 0.999) > 0.99)
        #expect(curve.value(at: 1) == 0.25)
        #expect(abs(curve.value(at: 1.5) - 0.5) < 1e-6)
    }

    @Test func constantHoldsEverywhere() throws {
        let curve = try ParameterCurve(constant: 0.7)
        for position in [-1e9, 0, 1, 1e9] {
            #expect(curve.value(at: position) == 0.7)
        }
    }

    // MARK: - replacing(range:with:)

    @Test func replacingKeepsACutTaperExactOutsideTheRange() throws {
        let original = try ParameterCurve([segment(0, 4, 0, 1, CurveShape(.default))])
        let replaced = try original.replacing(range: 1 ..< 2, with: [segment(1, 2, 0.5, 0.5)])

        for i in 0 ... 400 {
            let position = Double(i) / 100
            if position < 1 || position >= 2 {
                #expect(abs(replaced.value(at: position) - original.value(at: position)) < 1e-6, "at \(position)")
            } else {
                #expect(replaced.value(at: position) == 0.5, "at \(position)")
            }
        }
    }

    @Test func replacingInAHoldKeepsTheHeldValueAfterTheRange() throws {
        let original = try ParameterCurve([segment(0, 1, 0, 0.6), segment(5, 6, 0.6, 0)])
        let replaced = try original.replacing(range: 2 ..< 3, with: [segment(2, 2.5, 0.1, 0.9)])

        #expect(replaced.value(at: 1.5) == 0.6)
        #expect(abs(replaced.value(at: 2.25) - 0.5) < 1e-6)
        #expect(replaced.value(at: 2.75) == 0.9)
        #expect(replaced.value(at: 3) == 0.6)
        #expect(replaced.value(at: 4) == 0.6)
        #expect(abs(replaced.value(at: 5.5) - 0.3) < 1e-6)
    }

    @Test func replacingAtTheStartKeepsTheValueBeforeIt() throws {
        let original = try ParameterCurve([segment(1, 2, 0.4, 1)])
        let replaced = try original.replacing(range: 0 ..< 1.5, with: [segment(0.5, 1.5, 0, 0)])

        #expect(replaced.value(at: -1) == 0.4)
        #expect(replaced.value(at: 0.25) == 0.4)
        #expect(replaced.value(at: 1) == 0)
        #expect(abs(replaced.value(at: 1.75) - original.value(at: 1.75)) < 1e-6)
    }

    @Test func replacingRejectsSegmentsOutsideTheRange() throws {
        let original = try ParameterCurve(constant: 1)
        #expect(throws: ParameterCurve.ReplacementError.outsideRange(index: 1)) {
            try original.replacing(range: 1 ..< 2, with: [segment(1, 1.5, 0, 0), segment(1.5, 2.5, 0, 1)])
        }
    }

    @Test func replacingTwiceMergesBothRecordings() throws {
        let original = try ParameterCurve([segment(0, 10, 0, 1)])
        let first = try original.replacing(range: 2 ..< 3, with: [segment(2, 3, 0.9, 0.9)])
        let second = try first.replacing(range: 2.5 ..< 6, with: [segment(2.5, 6, 0.1, 0.1)])

        #expect(second.value(at: 2.25) == 0.9)
        #expect(second.value(at: 4) == 0.1)
        #expect(abs(second.value(at: 7) - 0.7) < 1e-6)
        #expect(abs(second.value(at: 1) - 0.1) < 1e-6)
    }
}

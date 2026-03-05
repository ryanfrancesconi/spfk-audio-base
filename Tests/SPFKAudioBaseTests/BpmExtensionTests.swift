import Foundation
@testable import SPFKAudioBase
import Testing

@Suite("Bpm Extensions")
struct BpmExtensionTests {
    @Test("init with zero returns nil")
    func initZero() {
        #expect(Bpm(0) == nil)
    }

    @Test("init with negative returns nil")
    func initNegative() {
        #expect(Bpm(-10) == nil)
    }

    @Test("init with positive succeeds")
    func initPositive() {
        let bpm = Bpm(120)
        #expect(bpm != nil)
        #expect(bpm?.rawValue == 120)
    }

    @Test("stringValue for whole number")
    func stringValueWhole() {
        #expect(Bpm(120)!.stringValue == "120")
    }

    @Test("stringValue for fractional")
    func stringValueFractional() {
        #expect(Bpm(120.5)!.stringValue == "120.5")
    }

    @Test("isWholeNumber")
    func isWholeNumber() {
        #expect(Bpm(120)!.isWholeNumber)
        #expect(!Bpm(120.5)!.isWholeNumber)
    }

    @Test("quarterNoteDuration")
    func quarterNoteDuration() {
        #expect(Bpm(60)!.quarterNoteDuration == 1.0)
        #expect(Bpm(120)!.quarterNoteDuration == 0.5)
    }

    @Test("multiples are computed correctly")
    func multiples() {
        let bpm = Bpm(100)!
        #expect(bpm.multiples == [12.5, 25, 50, 100, 200, 400, 800])
    }

    @Test("isMultiple with tolerance")
    func isMultipleWithTolerance() {
        let bpm = Bpm(120)!
        // 240.5 is not an exact multiple but within tolerance
        #expect(bpm.isMultiple(of: 240.5, tolerance: 1.0))
        #expect(!bpm.isMultiple(of: 240.5, tolerance: 0))
    }

    @Test("description format")
    func description() {
        #expect(Bpm(120)!.description == "Bpm(120)")
        #expect(Bpm(99.5)!.description == "Bpm(99.5)")
    }

    @Test("tempoRange bounds")
    func tempoRange() {
        #expect(Bpm.tempoRange.lowerBound == Bpm(1))
        #expect(Bpm.tempoRange.upperBound == Bpm(1024))
    }

    @Test("array average")
    func average() {
        let bpms = [Bpm(100)!, Bpm(120)!, Bpm(140)!]
        let avg = bpms.average
        #expect(avg == Bpm(120))
    }

    @Test("empty array average returns nil")
    func averageEmpty() {
        let bpms: [Bpm] = []
        #expect(bpms.average == nil)
    }

    @Test("comparable ordering")
    func comparable() {
        #expect(Bpm(80)! < Bpm(120)!)
        #expect(!(Bpm(120)! < Bpm(80)!))
    }
}

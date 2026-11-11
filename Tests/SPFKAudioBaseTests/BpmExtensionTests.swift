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
}

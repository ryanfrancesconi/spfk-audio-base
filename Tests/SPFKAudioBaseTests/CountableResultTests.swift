import Foundation
@testable import SPFKAudioBase
import Testing

@Suite("CountableResult")
struct CountableResultTests {
    @Test("choose returns most frequent value")
    func chooseMostFrequent() {
        var cr = CountableResult<Int>(elements: [])
        _ = cr.append(1)
        _ = cr.append(2)
        _ = cr.append(2)
        _ = cr.append(3)

        #expect(cr.choose() == 2)
    }

    @Test("choose returns nil for empty results")
    func chooseEmpty() {
        let cr = CountableResult<Int>(elements: [])
        #expect(cr.choose() == nil)
    }

    @Test("choose breaks tie with first occurrence by default")
    func chooseTieBreakerFirst() {
        var cr = CountableResult<Int>(elements: [])
        _ = cr.append(1)
        _ = cr.append(2)

        #expect(cr.choose(tieBreakerWeight: .first) == 1)
    }

    @Test("choose breaks tie with last occurrence")
    func chooseTieBreakerLast() {
        var cr = CountableResult<Int>(elements: [])
        _ = cr.append(1)
        _ = cr.append(2)

        #expect(cr.choose(tieBreakerWeight: .last) == 2)
    }

    @Test("append returns true when matchesRequired threshold met")
    func matchesRequiredThreshold() {
        var cr = CountableResult<Int>(matchesRequired: 3)
        var result = cr.append(5)
        #expect(!result)
        result = cr.append(5)
        #expect(!result)
        result = cr.append(5)
        #expect(result)
    }

    @Test("suggestedValue is set once threshold met")
    func suggestedValue() {
        var cr = CountableResult<String>(matchesRequired: 2)
        _ = cr.append("a")
        _ = cr.append("b")
        _ = cr.append("a")

        #expect(cr.suggestedValue == "a")
        // choose returns suggestedValue when set
        #expect(cr.choose() == "a")
    }

    @Test("custom isMatch groups approximate values")
    func customIsMatch() {
        var cr = CountableResult<Double>(
            matchesRequired: 3,
            isMatch: { abs($0 - $1) <= 1.0 }
        )
        _ = cr.append(120.0)
        _ = cr.append(120.5)
        let matched = cr.append(119.8)

        #expect(matched)
        #expect(cr.suggestedValue == 119.8)
    }

    @Test("custom isMatch choose picks most frequent group")
    func customIsMatchChoose() {
        var cr = CountableResult<Double>(
            isMatch: { abs($0 - $1) <= 1.0 }
        )
        _ = cr.append(120.0)
        _ = cr.append(80.0)
        _ = cr.append(120.3)
        _ = cr.append(80.5)
        _ = cr.append(119.8)

        // 120 group has 3 entries, 80 group has 2
        let result = cr.choose()
        #expect(result != nil)
        #expect(abs(result! - 120.0) <= 1.0)
    }

    @Test("arrayLiteral initialization")
    func arrayLiteral() {
        let cr: CountableResult<Int> = [1, 2, 2, 3]
        #expect(cr.choose() == 2)
    }

    @Test("elements initialization")
    func elementsInit() {
        let cr = CountableResult<String>(elements: ["a", "b", "a"])
        #expect(cr.choose() == "a")
    }

    @Test("results tracks all appended values")
    func resultsTracking() {
        var cr = CountableResult<Int>(elements: [])
        _ = cr.append(1)
        _ = cr.append(2)
        _ = cr.append(1)

        #expect(cr.results == [1, 2, 1])
    }
}

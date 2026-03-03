import Foundation
@testable import SPFKAudioBase
import Testing

@Suite("RealTimeDomain DisplayString")
struct RealTimeDomainDisplayStringTests {
    @Test("compact rounds up to next second")
    func compactRoundsUp() {
        let ds = RealTimeDomain.DisplayString(seconds: 0.1)
        #expect(ds.compact == "00:01")
    }

    @Test("compact for zero seconds is 00:00")
    func compactZero() {
        let ds = RealTimeDomain.DisplayString(seconds: 0.0)
        #expect(ds.compact == "00:00")
    }

    @Test("full shows milliseconds")
    func fullShowsMs() {
        let ds = RealTimeDomain.DisplayString(seconds: 1.5)
        #expect(ds.full == "00:01.500")
    }

    @Test("full shows hours for long durations")
    func fullShowsHours() {
        let ds = RealTimeDomain.DisplayString(seconds: 3661.5)
        #expect(ds.full.contains(":01:01"))
    }

    @Test("string for width returns compact when narrow")
    func stringForWidthNarrow() {
        let ds = RealTimeDomain.DisplayString(seconds: 90.5)
        #expect(ds.string(forWidth: 50, widthThreshold: 100) == ds.compact)
    }

    @Test("string for width returns full when wide")
    func stringForWidthWide() {
        let ds = RealTimeDomain.DisplayString(seconds: 90.5)
        #expect(ds.string(forWidth: 150, widthThreshold: 100) == ds.full)
    }

    @Test("Codable round-trip")
    func codable() throws {
        let original = RealTimeDomain.DisplayString(seconds: 125.678)
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(RealTimeDomain.DisplayString.self, from: data)
        #expect(decoded == original)
    }

    @Test("seconds parsing round-trip")
    func parseRoundTrip() {
        let seconds: TimeInterval = 125.5
        let string = RealTimeDomain.string(seconds: seconds, showHours: .auto, showMilliseconds: true)
        let parsed = RealTimeDomain.seconds(string: string)
        #expect(parsed == seconds)
    }

    @Test("instance string method uses masterSeconds")
    func instanceString() {
        var domain = RealTimeDomain()
        domain.update(seconds: 90.5)
        let str = domain.string(showHours: .auto, showMilliseconds: true)
        #expect(str == "01:30.500")
    }

    @Test("instance string method with offset")
    func instanceStringWithOffset() {
        var domain = RealTimeDomain()
        domain.update(seconds: 60.0)
        let str = domain.string(showHours: .auto, showMilliseconds: false, offset: 30.0)
        #expect(str == "01:30")
    }
}

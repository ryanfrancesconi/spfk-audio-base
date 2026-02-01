
@testable import SPFKAudioBase
import Testing

class RealTimeDomainTests {
    @Test func stringSeconds_Zero() {
        let seconds = 0.0

        // hours variations, no ms

        #expect(
            RealTimeDomain.string(seconds: seconds,
                                  showHours: .enable,
                                  showMilliseconds: false) ==
                "0:00:00")

        #expect(
            RealTimeDomain.string(seconds: seconds,
                                  showHours: .disable,
                                  showMilliseconds: false) ==
                "00:00")

        #expect(
            RealTimeDomain.string(seconds: seconds,
                                  showHours: .auto,
                                  showMilliseconds: false) ==
                "00:00")

        // hours variations, with ms

        #expect(
            RealTimeDomain.string(seconds: seconds,
                                  showHours: .enable,
                                  showMilliseconds: true) ==
                "0:00:00.000")

        #expect(
            RealTimeDomain.string(seconds: seconds,
                                  showHours: .disable,
                                  showMilliseconds: true) ==
                "00:00.000")

        #expect(
            RealTimeDomain.string(seconds: seconds,
                                  showHours: .auto,
                                  showMilliseconds: true) ==
                "00:00.000")
    }

    @Test func stringSeconds_Positive() {
        var seconds = 1.0

        // hours variations, no ms

        #expect(
            RealTimeDomain.string(seconds: seconds,
                                  showHours: .enable,
                                  showMilliseconds: false) ==
                "0:00:01")

        #expect(
            RealTimeDomain.string(seconds: seconds,
                                  showHours: .disable,
                                  showMilliseconds: false) ==
                "00:01")

        #expect(
            RealTimeDomain.string(seconds: seconds,
                                  showHours: .auto,
                                  showMilliseconds: false) ==
                "00:01")

        // hours variations, with ms

        #expect(
            RealTimeDomain.string(seconds: seconds,
                                  showHours: .enable,
                                  showMilliseconds: true) ==
                "0:00:01.000")

        #expect(
            RealTimeDomain.string(seconds: seconds,
                                  showHours: .disable,
                                  showMilliseconds: true) ==
                "00:01.000")

        #expect(
            RealTimeDomain.string(seconds: seconds,
                                  showHours: .auto,
                                  showMilliseconds: true) ==
                "00:01.000")

        seconds = 59.9

        // hours variations, no ms

        #expect(
            RealTimeDomain.string(seconds: seconds,
                                  showHours: .enable,
                                  showMilliseconds: false) ==
                "0:00:59")

        #expect(
            RealTimeDomain.string(seconds: seconds,
                                  showHours: .disable,
                                  showMilliseconds: false) ==
                "00:59")

        #expect(
            RealTimeDomain.string(seconds: seconds,
                                  showHours: .auto,
                                  showMilliseconds: false) ==
                "00:59")

        // hours variations, with ms

        #expect(
            RealTimeDomain.string(seconds: seconds,
                                  showHours: .enable,
                                  showMilliseconds: true) ==
                "0:00:59.900")

        #expect(
            RealTimeDomain.string(seconds: seconds,
                                  showHours: .disable,
                                  showMilliseconds: true) ==
                "00:59.900")

        #expect(
            RealTimeDomain.string(seconds: seconds,
                                  showHours: .auto,
                                  showMilliseconds: true) ==
                "00:59.900")

        seconds = 60.0

        // hours variations, no ms

        #expect(
            RealTimeDomain.string(seconds: seconds,
                                  showHours: .enable,
                                  showMilliseconds: false) ==
                "0:01:00")

        #expect(
            RealTimeDomain.string(seconds: seconds,
                                  showHours: .disable,
                                  showMilliseconds: false) ==
                "01:00")

        #expect(
            RealTimeDomain.string(seconds: seconds,
                                  showHours: .auto,
                                  showMilliseconds: false) ==
                "01:00")

        // hours variations, with ms

        #expect(
            RealTimeDomain.string(seconds: seconds,
                                  showHours: .enable,
                                  showMilliseconds: true) ==
                "0:01:00.000")

        #expect(
            RealTimeDomain.string(seconds: seconds,
                                  showHours: .disable,
                                  showMilliseconds: true) ==
                "01:00.000")

        #expect(
            RealTimeDomain.string(seconds: seconds,
                                  showHours: .auto,
                                  showMilliseconds: true) ==
                "01:00.000")

        seconds = 3600.0

        // hours variations, no ms

        #expect(
            RealTimeDomain.string(seconds: seconds,
                                  showHours: .enable,
                                  showMilliseconds: false) ==
                "1:00:00")

        #expect(
            RealTimeDomain.string(seconds: seconds,
                                  showHours: .disable,
                                  showMilliseconds: false) ==
                "60:00")

        #expect(
            RealTimeDomain.string(seconds: seconds,
                                  showHours: .auto,
                                  showMilliseconds: false) ==
                "1:00:00")

        // hours variations, with ms

        #expect(
            RealTimeDomain.string(seconds: seconds,
                                  showHours: .enable,
                                  showMilliseconds: true) ==
                "1:00:00.000")

        #expect(
            RealTimeDomain.string(seconds: seconds,
                                  showHours: .disable,
                                  showMilliseconds: true) ==
                "60:00.000")

        #expect(
            RealTimeDomain.string(seconds: seconds,
                                  showHours: .auto,
                                  showMilliseconds: true) ==
                "1:00:00.000")
    }

    @Test func stringSeconds_Negative() {
        var seconds = -1.0

        // hours variations, no ms

        #expect(
            RealTimeDomain.string(seconds: seconds,
                                  showHours: .enable,
                                  showMilliseconds: false) ==
                "-0:00:01")

        #expect(
            RealTimeDomain.string(seconds: seconds,
                                  showHours: .disable,
                                  showMilliseconds: false) ==
                "-00:01")

        #expect(
            RealTimeDomain.string(seconds: seconds,
                                  showHours: .auto,
                                  showMilliseconds: false) ==
                "-00:01")

        // hours variations, with ms

        #expect(
            RealTimeDomain.string(seconds: seconds,
                                  showHours: .enable,
                                  showMilliseconds: true) ==
                "-0:00:01.000")

        #expect(
            RealTimeDomain.string(seconds: seconds,
                                  showHours: .disable,
                                  showMilliseconds: true) ==
                "-00:01.000")

        #expect(
            RealTimeDomain.string(seconds: seconds,
                                  showHours: .auto,
                                  showMilliseconds: true) ==
                "-00:01.000")

        seconds = -10.0

        // hours variations, no ms

        #expect(
            RealTimeDomain.string(seconds: seconds,
                                  showHours: .enable,
                                  showMilliseconds: false) ==
                "-0:00:10")

        #expect(
            RealTimeDomain.string(seconds: seconds,
                                  showHours: .disable,
                                  showMilliseconds: false) ==
                "-00:10")

        #expect(
            RealTimeDomain.string(seconds: seconds,
                                  showHours: .auto,
                                  showMilliseconds: false) ==
                "-00:10")

        // hours variations, with ms

        #expect(
            RealTimeDomain.string(seconds: seconds,
                                  showHours: .enable,
                                  showMilliseconds: true) ==
                "-0:00:10.000")

        #expect(
            RealTimeDomain.string(seconds: seconds,
                                  showHours: .disable,
                                  showMilliseconds: true) ==
                "-00:10.000")

        #expect(
            RealTimeDomain.string(seconds: seconds,
                                  showHours: .auto,
                                  showMilliseconds: true) ==
                "-00:10.000")

        seconds = -59.9

        // hours variations, no ms

        #expect(
            RealTimeDomain.string(seconds: seconds,
                                  showHours: .enable,
                                  showMilliseconds: false) ==
                "-0:00:59")

        #expect(
            RealTimeDomain.string(seconds: seconds,
                                  showHours: .disable,
                                  showMilliseconds: false) ==
                "-00:59")

        #expect(
            RealTimeDomain.string(seconds: seconds,
                                  showHours: .auto,
                                  showMilliseconds: false) ==
                "-00:59")

        // hours variations, with ms

        #expect(
            RealTimeDomain.string(seconds: seconds,
                                  showHours: .enable,
                                  showMilliseconds: true) ==
                "-0:00:59.900")

        #expect(
            RealTimeDomain.string(seconds: seconds,
                                  showHours: .disable,
                                  showMilliseconds: true) ==
                "-00:59.900")

        #expect(
            RealTimeDomain.string(seconds: seconds,
                                  showHours: .auto,
                                  showMilliseconds: true) ==
                "-00:59.900")

        seconds = -60.0

        // hours variations, no ms

        #expect(
            RealTimeDomain.string(seconds: seconds,
                                  showHours: .enable,
                                  showMilliseconds: false) ==
                "-0:01:00")

        #expect(
            RealTimeDomain.string(seconds: seconds,
                                  showHours: .disable,
                                  showMilliseconds: false) ==
                "-01:00")

        #expect(
            RealTimeDomain.string(seconds: seconds,
                                  showHours: .auto,
                                  showMilliseconds: false) ==
                "-01:00")

        // hours variations, with ms

        #expect(
            RealTimeDomain.string(seconds: seconds,
                                  showHours: .enable,
                                  showMilliseconds: true) ==
                "-0:01:00.000")

        #expect(
            RealTimeDomain.string(seconds: seconds,
                                  showHours: .disable,
                                  showMilliseconds: true) ==
                "-01:00.000")

        #expect(
            RealTimeDomain.string(seconds: seconds,
                                  showHours: .auto,
                                  showMilliseconds: true) ==
                "-01:00.000")

        seconds = -3600.0

        // hours variations, no ms

        #expect(
            RealTimeDomain.string(seconds: seconds,
                                  showHours: .enable,
                                  showMilliseconds: false) ==
                "-1:00:00")

        #expect(
            RealTimeDomain.string(seconds: seconds,
                                  showHours: .disable,
                                  showMilliseconds: false) ==
                "-60:00")

        #expect(
            RealTimeDomain.string(seconds: seconds,
                                  showHours: .auto,
                                  showMilliseconds: false) ==
                "-1:00:00")

        // hours variations, with ms

        #expect(
            RealTimeDomain.string(seconds: seconds,
                                  showHours: .enable,
                                  showMilliseconds: true) ==
                "-1:00:00.000")

        #expect(
            RealTimeDomain.string(seconds: seconds,
                                  showHours: .disable,
                                  showMilliseconds: true) ==
                "-60:00.000")

        #expect(
            RealTimeDomain.string(seconds: seconds,
                                  showHours: .auto,
                                  showMilliseconds: true) ==
                "-1:00:00.000")
    }

    @Test func stringSeconds_MillisecondsPaddingAndTruncation() {
        // test ms padding to ensure it always shows 3 digit places in the string

        #expect(
            RealTimeDomain.string(seconds: 1.000,
                                  showHours: .enable,
                                  showMilliseconds: true) ==
                "0:00:01.000")

        #expect(
            RealTimeDomain.string(seconds: 1.200,
                                  showHours: .enable,
                                  showMilliseconds: true) ==
                "0:00:01.200")

        #expect(
            RealTimeDomain.string(seconds: 1.020,
                                  showHours: .enable,
                                  showMilliseconds: true) ==
                "0:00:01.020")

        #expect(
            RealTimeDomain.string(seconds: 1.002,
                                  showHours: .enable,
                                  showMilliseconds: true) ==
                "0:00:01.002")

        // ms truncation - we don't want to round up, always truncate down

        #expect(
            RealTimeDomain.string(seconds: 1.0099,
                                  showHours: .enable,
                                  showMilliseconds: true) ==
                "0:00:01.009")
    }
}

//  MARK: - Parse

extension RealTimeDomainTests {
    @Test func parseString1() {
        #expect(
            RealTimeDomain.seconds(string: "30") ==
                30
        )

        #expect(
            RealTimeDomain.seconds(string: "00:30") ==
                30
        )

        #expect(
            RealTimeDomain.seconds(string: "30.50") ==
                30.5
        )

        #expect(
            RealTimeDomain.seconds(string: "00:30.50") ==
                30.5
        )

        #expect(
            RealTimeDomain.seconds(string: "30:30.50") ==
                1830.5
        )

        #expect(
            RealTimeDomain.seconds(string: "00:30:30.50") ==
                1830.5
        )

        // 108000 = 30 hours
        #expect(
            RealTimeDomain.seconds(string: "30:30:30.50") ==
                109_830.5
        )
    }

    @Test func parseString2() {
        #expect(
            RealTimeDomain.seconds(string: "Hi 4.5 qwerty") ==
                4.5
        )
    }

    @Test func parseMinus() {
        #expect(
            RealTimeDomain.seconds(string: "-30:30.50") ==
                -1830.5
        )

        #expect(
            RealTimeDomain.seconds(string: "-3") ==
                -3
        )
    }
}

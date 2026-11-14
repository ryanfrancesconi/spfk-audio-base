// Copyright Ryan Francesconi. All Rights Reserved. Revision History at https://github.com/ryanfrancesconi/spfk-audio-base

import Foundation
import os

/// How the apps write audio quantities: one spelling for each, localized where it is a word.
///
/// Unit symbols (kHz, Hz, kbps) read the same in every language and are not localized. Never
/// interpolate a `Double` into a `localized()` key: it is formatted `%lf`, so 44100 becomes
/// `44100.000000`. Format it here first.
///
/// Each answer is cached: these are read for every element a library loads, and a bundle lookup
/// or a `FormatStyle` per row is most of that read's cost.
public enum AudioTerminology {
    private static let cache = OSAllocatedUnfairLock(initialState: [String: String]())

    private static func cached(_ key: String, _ make: () -> String) -> String {
        if let hit = cache.withLock({ $0[key] }) { return hit }

        let value = make()
        cache.withLock { $0[key] = value }
        return value
    }

    /// "44.1 kHz", "48 kHz", "22.05 kHz"; the decimal separator follows `locale` ("44,1 kHz").
    public static func sampleRate(_ hertz: Double, locale: Locale = .current) -> String {
        cached("sampleRate \(hertz) \(locale.identifier)") {
            let kilohertz = (hertz / 1000).formatted(
                .number.precision(.fractionLength(0 ... 3)).grouping(.never).locale(locale)
            )
            return kilohertz + " kHz"
        }
    }

    /// "44100 Hz", for a list of exact rates such as a device's.
    public static func sampleRateInHertz(_ hertz: Double) -> String {
        "\(Int(hertz.rounded())) Hz"
    }

    /// "24 bit".
    public static func bitDepth(_ bits: Int) -> String {
        cached("bitDepth \(bits)") { localized("\(bits) bit") }
    }

    /// "320 kbps".
    public static func bitRate(kbps: Int) -> String {
        "\(kbps) kbps"
    }

    /// "Mono", "Stereo", "6 Channels". Empty for no channels.
    public static func channels(_ count: Int) -> String {
        cached("channels \(count)") {
            switch count {
            case ..<1: ""
            case 1: localized("Mono")
            case 2: localized("Stereo")
            default: localized("\(count) Channels")
            }
        }
    }
}

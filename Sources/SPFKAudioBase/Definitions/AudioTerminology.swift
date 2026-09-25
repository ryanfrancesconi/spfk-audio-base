// Copyright Ryan Francesconi. All Rights Reserved. Revision History at https://github.com/ryanfrancesconi/spfk-audio-base

import Foundation

/// How the apps write audio quantities: one spelling for each, localized where it is a word.
///
/// Unit symbols (kHz, Hz, kbps) read the same in every language and are not localized. Never
/// interpolate a `Double` into a `localized()` key: it is formatted `%lf`, so 44100 becomes
/// `44100.000000`. Format it here first.
public enum AudioTerminology {
    /// "44.1 kHz", "48 kHz", "22.05 kHz"; the decimal separator follows `locale` ("44,1 kHz").
    public static func sampleRate(_ hertz: Double, locale: Locale = .current) -> String {
        let kilohertz = (hertz / 1000).formatted(
            .number.precision(.fractionLength(0 ... 3)).grouping(.never).locale(locale)
        )
        return kilohertz + " kHz"
    }

    /// "44100 Hz", for a list of exact rates such as a device's.
    public static func sampleRateInHertz(_ hertz: Double) -> String {
        "\(Int(hertz.rounded())) Hz"
    }

    /// "24 bit".
    public static func bitDepth(_ bits: Int) -> String {
        localized("\(bits) bit")
    }

    /// "320 kbps".
    public static func bitRate(kbps: Int) -> String {
        "\(kbps) kbps"
    }

    /// "Mono", "Stereo", "6 Channels". Empty for no channels.
    public static func channels(_ count: Int) -> String {
        switch count {
        case ..<1: ""
        case 1: localized("Mono")
        case 2: localized("Stereo")
        default: localized("\(count) Channels")
        }
    }
}

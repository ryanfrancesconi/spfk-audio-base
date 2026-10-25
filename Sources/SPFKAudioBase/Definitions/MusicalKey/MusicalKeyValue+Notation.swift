// Copyright Ryan Francesconi. All Rights Reserved. Revision History at https://github.com/ryanfrancesconi/spfk-audio-base

import Foundation

extension MusicalKeyValue {
    /// The key moved by `semitones`, wrapping around the octave in either direction.
    public func transposed(bySemitones semitones: Int) -> MusicalKeyValue {
        let index = (Int(name.rawValue) + semitones % 12 + 12) % 12
        return MusicalKeyValue(name: NoteName(rawValue: Int32(index)) ?? name, tonality: tonality)
    }

    /// The shift in −5…+6 that brings this key to `target`, or to `target`'s relative key when the
    /// modes differ; a tritone is +6. Nil when either tonality is unknown.
    public func nearestTransposition(to target: MusicalKeyValue) -> Int? {
        guard tonality != .unknown, target.tonality != .unknown else { return nil }

        let target = target.tonality == tonality ? target : target.relativeKey
        let distance = (Int(target.name.rawValue) - Int(name.rawValue) + 12) % 12

        return distance <= 6 ? distance : distance - 12
    }

    /// Reads a key in any `MusicalKeyNotation`, ignoring case and surrounding whitespace.
    ///
    /// `♯`/`♭` read as `#`/`b`; "m", "min" and "minor" mark a minor key, "maj" and "major" (or
    /// nothing) a major one. Returns nil for anything else, including ID3's `"o"` (off key).
    public static func parse(_ string: String) -> ParsedMusicalKey? {
        let text = string.trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "♯", with: "#")
            .replacingOccurrences(of: "♭", with: "b")

        guard !text.isEmpty else { return nil }

        if let wheel = parseWheel(text) {
            return wheel
        }

        return parseNoteName(text)
    }

    /// The key written in `notation`. A note-name notation spells accidentals as flats when
    /// `flats` is true. A key of `.unknown` tonality is no key, and formats as an empty string.
    public func string(in notation: MusicalKeyNotation, flats: Bool = false) -> String {
        guard tonality != .unknown else { return "" }

        let note = flats ? name.enharmonic : name.description
        let isMinor = tonality == .minor

        switch notation {
        case .standard:
            return "\(note) \(tonality)"
        case .short:
            return isMinor ? "\(note)m" : note
        case .camelot:
            return "\(camelotNumber)\(isMinor ? "A" : "B")"
        case .openKey:
            return "\(openKeyNumber)\(isMinor ? "m" : "d")"
        }
    }
}

// MARK: - Wheels

extension MusicalKeyValue {
    /// 1…12 on the Camelot wheel. 8B is C major and 8A A minor; each step is a fifth.
    var camelotNumber: Int {
        let tonic = Int(name.rawValue)
        // 7 is its own inverse mod 12, so stepping by fifths inverts the same way.
        let offset = tonality == .minor ? tonic - 9 : tonic
        return ((7 * offset % 12 + 12) % 12 + 7) % 12 + 1
    }

    /// 1…12 on the Open Key wheel: Camelot shifted by seven, so 1d is C major and 1m A minor.
    var openKeyNumber: Int {
        (camelotNumber - 8 + 12) % 12 + 1
    }

    static func fromCamelot(number: Int, isMinor: Bool) -> MusicalKeyValue? {
        guard (1 ... 12).contains(number) else { return nil }

        let fifths = 7 * (number - 8)
        let tonic = ((isMinor ? 9 + fifths : fifths) % 12 + 12) % 12

        guard let name = NoteName(rawValue: Int32(tonic)) else { return nil }

        return MusicalKeyValue(name: name, tonality: isMinor ? .minor : .major)
    }

    private static func parseWheel(_ text: String) -> ParsedMusicalKey? {
        guard let letter = text.last?.lowercased(),
              case let digits = text.dropLast(),
              (1 ... 2).contains(digits.count),
              digits.allSatisfy(\.isASCII),
              let number = Int(digits)
        else { return nil }

        switch letter {
        case "a", "b":
            guard let value = fromCamelot(number: number, isMinor: letter == "a") else { return nil }
            return ParsedMusicalKey(value: value, notation: .camelot, usesFlats: false)

        case "m", "d":
            guard (1 ... 12).contains(number),
                  let value = fromCamelot(number: (number + 6) % 12 + 1, isMinor: letter == "m")
            else { return nil }
            return ParsedMusicalKey(value: value, notation: .openKey, usesFlats: false)

        default:
            return nil
        }
    }
}

// MARK: - Note names

extension MusicalKeyValue {
    private static let minorSuffixes: Set<String> = ["m", "min", "minor"]
    private static let majorSuffixes: Set<String> = ["", "maj", "major"]
    /// The words that may follow a note name as a second word, as in `"C Minor"`.
    static let tonalityWords: Set<String> = ["maj", "major", "min", "minor"]

    private static func parseNoteName(_ text: String) -> ParsedMusicalKey? {
        guard let first = text.first, "abcdefg".contains(first.lowercased()) else { return nil }

        var rest = text.dropFirst()
        var accidental = ""

        if let next = rest.first, next == "#" || next == "b" || next == "B" {
            accidental = next == "#" ? "#" : "b"
            rest = rest.dropFirst()
        }

        let separated = rest.first?.isWhitespace == true
        let suffix = rest.trimmingCharacters(in: .whitespaces).lowercased()

        let tonality: MusicalTonality
        if minorSuffixes.contains(suffix) {
            tonality = .minor
        } else if majorSuffixes.contains(suffix) {
            tonality = .major
        } else {
            return nil
        }

        guard let name = NoteName(string: first.uppercased() + accidental) else { return nil }

        let notation: MusicalKeyNotation = separated && (suffix == "major" || suffix == "minor") ? .standard : .short

        return ParsedMusicalKey(
            value: MusicalKeyValue(name: name, tonality: tonality),
            notation: notation,
            usesFlats: accidental == "b"
        )
    }
}

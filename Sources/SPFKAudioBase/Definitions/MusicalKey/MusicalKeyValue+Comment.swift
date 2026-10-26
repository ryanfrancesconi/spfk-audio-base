// Copyright Ryan Francesconi. All Rights Reserved. Revision History at https://github.com/ryanfrancesconi/spfk-audio-base

import Foundation

extension MusicalKeyValue {
    /// Reads a key written at the very start of a comment, as Mixed In Key can write one
    /// (`"8A - Energy 6"`).
    ///
    /// The key must be followed by the end of the comment, `" - "` (or an en or em dash), `"/"` or `","`. A Camelot or
    /// Open Key code may also be followed by whitespace and more words; a note name may not, so
    /// `"A good take"` is not a key. `range` covers the key and its separator, and is what
    /// removing the key from the comment removes.
    public static func parseLeading(comment: String) -> (key: ParsedMusicalKey, range: Range<String.Index>)? {
        guard let start = comment.firstIndex(where: { !$0.isWhitespace }) else { return nil }

        let first = token(in: comment, from: start)
        var candidates = [first]

        // "C Minor" is one key across two words.
        if let secondStart = comment[first.upperBound...].firstIndex(where: { !$0.isWhitespace }),
           secondStart > first.upperBound
        {
            let second = token(in: comment, from: secondStart)

            if tonalityWords.contains(comment[second].lowercased()) {
                candidates.insert(start ..< second.upperBound, at: 0)
            }
        }

        for candidate in candidates {
            guard let key = parse(String(comment[candidate])),
                  let end = separatorEnd(in: comment, after: candidate.upperBound, key: key)
            else { continue }

            return (key, comment.startIndex ..< end)
        }

        return nil
    }

    /// The file's key: `initialKey` when it holds any text, otherwise a key leading the comment.
    /// Returns nil when the text that applies does not parse — an unreadable `initialKey` is not
    /// passed over for the comment.
    public static func resolve(initialKey: String?, comment: String?) -> ResolvedMusicalKey? {
        if let initialKey, !initialKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return parse(initialKey).map { ResolvedMusicalKey(key: $0, source: .initialKey) }
        }

        guard let comment, let leading = parseLeading(comment: comment) else { return nil }

        let remainder = String(comment[leading.range.upperBound...])
        return ResolvedMusicalKey(key: leading.key, source: .comment(remainder: remainder))
    }

    private static let dashes: Set<Character> = ["-", "–", "—"]
    private static let separators: Set<Character> = dashes.union(["/", ","])

    /// A run of characters up to whitespace, `/` or `,`.
    private static func token(in text: String, from start: String.Index) -> Range<String.Index> {
        let end = text[start...].firstIndex { $0.isWhitespace || $0 == "/" || $0 == "," } ?? text.endIndex
        return start ..< end
    }

    /// Where the comment's remainder begins after a key ending at `index`, or nil when what
    /// follows the key does not separate it from the rest.
    private static func separatorEnd(in text: String, after index: String.Index, key: ParsedMusicalKey) -> String.Index? {
        guard index < text.endIndex else { return index }

        let afterSpace = text[index...].firstIndex { !$0.isWhitespace } ?? text.endIndex

        guard afterSpace < text.endIndex else { return text.endIndex }

        let next = text[afterSpace]

        if separators.contains(next) {
            // A dash separates only with space before it, as in " - ".
            guard !dashes.contains(next) || afterSpace > index else { return nil }

            let rest = text.index(after: afterSpace)
            return text[rest...].firstIndex { !$0.isWhitespace } ?? text.endIndex
        }

        let isWheel = key.notation == .camelot || key.notation == .openKey

        return isWheel && afterSpace > index ? afterSpace : nil
    }
}

// Copyright Ryan Francesconi. All Rights Reserved. Revision History at https://github.com/ryanfrancesconi/spfk-audio-base

import Foundation

/// Works out what rewriting each file's key tag into one notation does to it.
///
/// A key keeps the spelling its source wrote; one from a wheel is spelled as its key signature
/// (``ParsedMusicalKey/string(in:glyphs:)``). Text that does not parse is never touched.
public enum OrganizeMusicalKeyPlanner {
    public struct Options: Hashable, Sendable {
        public var notation: MusicalKeyNotation
        /// Move a key leading the comment (`"8A - Energy 6"`) into an empty key tag.
        public var movesCommentKeys: Bool
        public var detectsMissing: Bool

        public init(notation: MusicalKeyNotation, movesCommentKeys: Bool = false, detectsMissing: Bool = false) {
            self.notation = notation
            self.movesCommentKeys = movesCommentKeys
            self.detectsMissing = detectsMissing
        }
    }

    public struct File: Hashable, Sendable {
        public var initialKey: String?
        public var comment: String?

        public init(initialKey: String?, comment: String?) {
            self.initialKey = initialKey
            self.comment = comment
        }
    }

    public enum Outcome: Hashable, Sendable {
        /// `comment` is nil when the comment is untouched, and empty when the key was all of it.
        case rewrite(key: String, comment: String?)
        /// Already in the notation, once trimmed.
        case unchanged
        case offKey
        case unreadable(String)
        /// A root of unknown tonality, which a wheel notation cannot write.
        case rootOnly
        case noKey
        case detect
    }

    public struct Summary: Hashable, Sendable {
        public static let unreadableValueLimit = 10

        public var rewrites = 0
        /// The rewrites that took their key from the comment.
        public var commentMoves = 0
        public var unchanged = 0
        public var offKey = 0
        public var unreadable = 0
        public var rootOnly = 0
        public var noKey = 0
        public var detect = 0
        /// Distinct unreadable values in the order first seen, at most ``unreadableValueLimit``.
        public var unreadableValues: [String] = []

        public var withoutKey: Int { noKey + detect }
        public var hasWork: Bool { rewrites + detect > 0 }

        public init(
            rewrites: Int = 0,
            commentMoves: Int = 0,
            unchanged: Int = 0,
            offKey: Int = 0,
            unreadable: Int = 0,
            rootOnly: Int = 0,
            noKey: Int = 0,
            detect: Int = 0,
            unreadableValues: [String] = []
        ) {
            self.rewrites = rewrites
            self.commentMoves = commentMoves
            self.unchanged = unchanged
            self.offKey = offKey
            self.unreadable = unreadable
            self.rootOnly = rootOnly
            self.noKey = noKey
            self.detect = detect
            self.unreadableValues = unreadableValues
        }
    }

    public struct Plan: Hashable, Sendable {
        /// One per input file, in order.
        public var outcomes: [Outcome]
        public var summary: Summary
    }

    /// The values ID3 and the tag editor accept for off key.
    public static let offKeyValues: Set<String> = ["o", "off", "off key"]

    public static func plan(_ options: Options, files: [File]) -> Plan {
        var summary = Summary()

        let outcomes = files.map { file in
            let outcome = outcome(for: file, options: options)

            switch outcome {
            case let .rewrite(_, comment):
                summary.rewrites += 1
                if comment != nil { summary.commentMoves += 1 }
            case .unchanged:
                summary.unchanged += 1
            case .offKey:
                summary.offKey += 1
            case let .unreadable(text):
                summary.unreadable += 1
                if summary.unreadableValues.count < Summary.unreadableValueLimit, !summary.unreadableValues.contains(text) {
                    summary.unreadableValues.append(text)
                }
            case .rootOnly:
                summary.rootOnly += 1
            case .noKey:
                summary.noKey += 1
            case .detect:
                summary.detect += 1
            }

            return outcome
        }

        return Plan(outcomes: outcomes, summary: summary)
    }

    public static func outcome(for file: File, options: Options) -> Outcome {
        let stored = file.initialKey?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

        guard stored.isEmpty else {
            if offKeyValues.contains(stored.lowercased()) { return .offKey }

            guard let parsed = MusicalKeyValue.parse(stored) else { return .unreadable(stored) }
            guard let written = parsed.string(in: options.notation) else { return .rootOnly }

            return written == stored ? .unchanged : .rewrite(key: written, comment: nil)
        }

        if options.movesCommentKeys,
           let comment = file.comment,
           let leading = MusicalKeyValue.parseLeading(comment: comment)
        {
            guard let written = leading.key.string(in: options.notation) else { return .rootOnly }
            return .rewrite(key: written, comment: String(comment[leading.range.upperBound...]))
        }

        return options.detectsMissing ? .detect : .noKey
    }
}

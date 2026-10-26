// Copyright Ryan Francesconi. All Rights Reserved. Revision History at https://github.com/ryanfrancesconi/spfk-audio-base

import Foundation
import SPFKAudioBase
import SPFKBase
import SPFKTesting
import Testing

@Suite("OrganizeMusicalKeyPlanner", .tags(.musicalKey))
struct OrganizeMusicalKeyPlannerTests {
    typealias Planner = OrganizeMusicalKeyPlanner

    private func outcome(
        _ initialKey: String?,
        comment: String? = nil,
        in notation: MusicalKeyNotation = .standard,
        movesCommentKeys: Bool = false,
        detectsMissing: Bool = false
    ) -> Planner.Outcome {
        let options = Planner.Options(notation: notation, movesCommentKeys: movesCommentKeys, detectsMissing: detectsMissing)
        return Planner.plan(options, files: [Planner.File(initialKey: initialKey, comment: comment)]).outcomes[0]
    }

    @Test(arguments: [
        ("8A", MusicalKeyNotation.standard, "A Minor"),
        ("C# Minor", .short, "C#m"),
        ("Abmin", .camelot, "1A"),
        ("1m", .short, "Am"),
        ("f#", .standard, "F#"),
        ("B♭maj", .short, "Bbmaj"),
        ("4B", .standard, "Ab Major"),
        ("Dbm", .standard, "Db Minor"),
        ("Am", .openKey, "1m"),
    ])
    func aReadableKeyIsRewrittenInTheTarget(stored: String, notation: MusicalKeyNotation, expected: String) {
        #expect(outcome(stored, in: notation) == .rewrite(key: expected, comment: nil))
    }

    @Test(arguments: [
        ("A Minor", MusicalKeyNotation.standard),
        (" C#m ", .short),
        ("8A\n", .camelot),
        ("1m", .openKey),
        ("F", .short),
    ])
    func aKeyAlreadyInTheTargetIsUnchangedOnceTrimmed(stored: String, notation: MusicalKeyNotation) {
        #expect(outcome(stored, in: notation) == .unchanged)
    }

    /// The parser labels "A min" short and "F MAJOR" standard, so the decision is the string's.
    @Test func alreadyInTheTargetIsDecidedByTheTextNotTheParsedNotation() {
        #expect(outcome("A min", in: .short) == .rewrite(key: "Am", comment: nil))
        #expect(outcome("F MAJOR", in: .standard) == .rewrite(key: "F Major", comment: nil))
    }

    @Test(arguments: ["o", "off", "Off Key", " O "])
    func offKeyIsLeftAlone(stored: String) {
        #expect(outcome(stored, in: .camelot) == .offKey)
    }

    @Test(arguments: ["Am/C", "Piano", "F#/Gb", "C Dorian", "N/A", "-"])
    func unreadableTextIsLeftAloneAndReported(stored: String) {
        #expect(outcome(stored) == .unreadable(stored))
    }

    @Test(arguments: [MusicalKeyNotation.camelot, .openKey])
    func aRootAloneCannotBeWrittenOnAWheel(notation: MusicalKeyNotation) {
        #expect(outcome("F", in: notation) == .rootOnly)
    }

    @Test(arguments: [nil, "", "  "] as [String?])
    func noKeyIsDetectedOnlyWhenAsked(stored: String?) {
        #expect(outcome(stored) == .noKey)
        #expect(outcome(stored, detectsMissing: true) == .detect)
    }

    @Test func anUnreadableKeyIsNeverDetectedOver() {
        #expect(outcome("Piano", detectsMissing: true) == .unreadable("Piano"))
    }

    @Test func aCommentKeyMovesOnlyWithTheOption() {
        #expect(outcome(nil, comment: "8A - Energy 6") == .noKey)
        #expect(outcome(nil, comment: "8A - Energy 6", movesCommentKeys: true) == .rewrite(key: "A Minor", comment: "Energy 6"))
        #expect(outcome("", comment: "10A – Vibe", in: .short, movesCommentKeys: true) == .rewrite(key: "Bm", comment: "Vibe"))
    }

    @Test func aCommentThatWasOnlyTheKeyIsEmptied() {
        #expect(outcome(nil, comment: "8A", movesCommentKeys: true) == .rewrite(key: "A Minor", comment: ""))
    }

    @Test func aStoredKeyWinsOverTheComment() {
        #expect(outcome("Am", comment: "5B - Energy", movesCommentKeys: true) == .rewrite(key: "A Minor", comment: nil))
    }

    @Test func aCommentWithNoKeyFallsThroughToDetection() {
        #expect(outcome(nil, comment: "A good take", movesCommentKeys: true, detectsMissing: true) == .detect)
    }

    @Test func aCommentRootCannotMoveOntoAWheel() {
        #expect(outcome(nil, comment: "A - Energy", in: .camelot, movesCommentKeys: true) == .rootOnly)
    }

    @Test func theSummaryCountsEveryOutcome() {
        let files = ["8A", "A Minor", "o", "Piano", "Am/C", "Piano", "F", nil, nil].map {
            Planner.File(initialKey: $0, comment: nil)
        } + [Planner.File(initialKey: nil, comment: "8A - Energy")]

        let plan = Planner.plan(
            Planner.Options(notation: .standard, movesCommentKeys: true, detectsMissing: true),
            files: files
        )

        #expect(plan.outcomes.count == files.count)
        #expect(plan.summary == Planner.Summary(
            rewrites: 2,
            commentMoves: 1,
            unchanged: 2,
            offKey: 1,
            unreadable: 3,
            rootOnly: 0,
            noKey: 0,
            detect: 2,
            unreadableValues: ["Piano", "Am/C"]
        ))
        #expect(plan.summary.withoutKey == 2)
        #expect(plan.summary.hasWork)
    }

    @Test func theUnreadableValuesAreCapped() {
        let files = (0 ..< 30).map { Planner.File(initialKey: "Sample \($0)", comment: nil) }
        let summary = Planner.plan(Planner.Options(notation: .short), files: files).summary

        #expect(summary.unreadable == 30)
        #expect(summary.unreadableValues.count == Planner.Summary.unreadableValueLimit)
        #expect(summary.unreadableValues.first == "Sample 0")
    }

    @Test func nothingToDoHasNoWork() {
        let files = ["Am", "Piano"].map { Planner.File(initialKey: $0, comment: nil) }
        #expect(!Planner.plan(Planner.Options(notation: .short), files: files).summary.hasWork)
    }
}

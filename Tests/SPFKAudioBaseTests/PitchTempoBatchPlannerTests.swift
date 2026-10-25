// Copyright Ryan Francesconi. All Rights Reserved. Revision History at https://github.com/ryanfrancesconi/spfk-audio-base

import Foundation
import SPFKAudioBase
import SPFKBase
import Testing

@Suite("PitchTempoBatchPlanner")
struct PitchTempoBatchPlannerTests {
    typealias Planner = PitchTempoBatchPlanner

    private let aMinor = MusicalKeyValue(name: .a, tonality: .minor)
    private let cMajor = MusicalKeyValue(name: .c, tonality: .major)
    private let dMajor = MusicalKeyValue(name: .d, tonality: .major)

    private func file(
        bpm: Double? = nil,
        key: MusicalKeyValue? = nil,
        existing: TimePitchDescription = TimePitchDescription(),
        hasNormalize: Bool = false
    ) -> Planner.File {
        Planner.File(sourceBpm: bpm.flatMap { Bpm($0) }, key: key, existing: existing, hasNormalize: hasNormalize)
    }

    private func description(_ outcome: Planner.Outcome) -> TimePitchDescription? {
        if case let .change(description, _) = outcome { return description }
        return nil
    }

    @Test func aTargetBpmGivesEachFileItsOwnFoldedRate() throws {
        let target = try #require(Bpm(120))
        let plan = Planner.plan(
            TimePitchDescription(),
            tempo: .targetBpm(target),
            pitch: .semitones,
            files: [file(bpm: 100), file(bpm: 90), file(bpm: 60), file(bpm: 40)]
        )

        let rates = plan.outcomes.compactMap { description($0)?.rate }
        #expect(rates.count == 3)
        #expect(abs(rates[0] - 1.2) < 1e-12)
        #expect(abs(rates[1] - 4.0 / 3) < 1e-12)
        // 40 → 120 is ratio 3: 1.5 or 0.75, and 0.75 is nearer 1×.
        #expect(abs(rates[2] - 0.75) < 1e-12)
        // 60 → 120 folds to 1, identity over identity.
        #expect(plan.outcomes[2] == .unchanged)
    }

    @Test func aTargetBpmSkipsAFileWithNoBpm() throws {
        let target = try #require(Bpm(120))
        let plan = Planner.plan(TimePitchDescription(), tempo: .targetBpm(target), pitch: .semitones, files: [file()])
        #expect(plan.outcomes == [.skip(.noBpm)])
        #expect(plan.summary.noBpm == 1)
    }

    @Test func aTargetKeyGivesEachFileItsOwnShift() {
        let plan = Planner.plan(
            TimePitchDescription(cents: 7),
            tempo: .rate,
            pitch: .targetKey(dMajor),
            files: [file(key: cMajor), file(key: aMinor), file(key: dMajor)]
        )

        let shifts = plan.outcomes.map { description($0)?.semitones }
        // C major → D major is +2; A minor matches D major's relative, B minor, at +2; D major is 0.
        #expect(shifts == [2, 2, 0])
        #expect(plan.outcomes.allSatisfy { description($0)?.cents == 7 })
    }

    @Test func aTargetKeySkipsAFileWithNoKey() {
        let plan = Planner.plan(TimePitchDescription(), tempo: .rate, pitch: .targetKey(cMajor), files: [
            file(),
            file(key: MusicalKeyValue(name: .c, tonality: .unknown)),
        ])
        #expect(plan.outcomes == [.skip(.noKey), .skip(.noKey)])
        #expect(plan.summary.noKey == 2)
    }

    @Test func everyOtherFieldIsOverwrittenFromThePanel() {
        let panel = TimePitchDescription(
            semitones: -3, cents: 12, rate: 0.8, tonalityLimitHz: 9000,
            formantCorrection: true, formantBaseHz: 220, formantSemitones: 1.5
        )
        let existing = TimePitchDescription(semitones: 5, rate: 1.7, tonalityLimitHz: 3000, formantBaseHz: 400)

        let plan = Planner.plan(panel, tempo: .rate, pitch: .semitones, files: [file(bpm: 100, key: cMajor, existing: existing)])
        #expect(plan.outcomes.map(description) == [panel])
    }

    @Test func clearReturnsEveryFileToIdentity() {
        let plan = Planner.clear(files: [
            file(existing: TimePitchDescription(semitones: 2, rate: 1.1), hasNormalize: true),
            file(existing: TimePitchDescription()),
            file(existing: TimePitchDescription(tonalityLimitHz: 9000)),
        ])

        #expect(plan.outcomes == [
            .change(TimePitchDescription(), clearsNormalize: true),
            .unchanged,
            .change(TimePitchDescription(), clearsNormalize: false),
        ])
        #expect(plan.summary.normalizesCleared == 1)
    }

    @Test func clearDoesNotSkipForAMissingBpmOrKey() {
        let plan = Planner.clear(files: [file(existing: TimePitchDescription(rate: 1.5))])
        #expect(plan.summary.changed == 1)
        #expect(plan.summary.skipped == 0)
    }

    @Test func aResultEqualToTheExistingEditIsUnchanged() {
        let existing = TimePitchDescription(semitones: 2, rate: 1.25)
        let plan = Planner.plan(existing, tempo: .rate, pitch: .semitones, files: [file(existing: existing)])
        #expect(plan.outcomes == [.unchanged])
        #expect(!plan.summary.hasChanges)
    }

    @Test(arguments: [
        (TimePitchDescription(rate: 1.25), true),
        (TimePitchDescription(semitones: 1), true),
        (TimePitchDescription(formantSemitones: 2), true),
        (TimePitchDescription(tonalityLimitHz: 8000), false),
        (TimePitchDescription(formantCorrection: true, formantBaseHz: 200), false),
    ])
    func clearsNormalizeFollowsTheSharedRule(panel: TimePitchDescription, clears: Bool) {
        let plan = Planner.plan(panel, tempo: .rate, pitch: .semitones, files: [file()])
        #expect(plan.outcomes == [.change(panel, clearsNormalize: clears)])
    }

    @Test func theSummaryCountsEachOutcome() throws {
        let target = try #require(Bpm(120))
        let plan = Planner.plan(
            TimePitchDescription(semitones: 1),
            tempo: .targetBpm(target),
            pitch: .semitones,
            files: [
                file(bpm: 100, hasNormalize: true), // change, clears
                file(bpm: 100), // change, nothing pending
                file(bpm: 120, existing: TimePitchDescription(semitones: 1)), // unchanged
                file(), // no BPM
                file(), // no BPM
            ]
        )

        #expect(plan.summary == Planner.Summary(changed: 2, unchanged: 1, noBpm: 2, noKey: 0, normalizesCleared: 1))
        #expect(plan.summary.skipped == 2)
        #expect(plan.summary.hasChanges)
    }

    @Test func aFileMissingBothIsCountedOnceAsNoBpm() throws {
        let target = try #require(Bpm(120))
        let plan = Planner.plan(TimePitchDescription(), tempo: .targetBpm(target), pitch: .targetKey(cMajor), files: [file()])
        #expect(plan.outcomes == [.skip(.noBpm)])
        #expect(plan.summary.skipped == 1)
    }
}

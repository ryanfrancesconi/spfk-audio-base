// Copyright Ryan Francesconi. All Rights Reserved. Revision History at https://github.com/ryanfrancesconi/spfk-audio-base

import Foundation
import SPFKBase

/// Works out what one pitch and tempo setting does to each file of a batch.
///
/// Every field comes from the setting verbatim except the rate under a target BPM, folded by octaves
/// per file, and the semitones under a target key, the nearest transposition per file.
public enum PitchTempoBatchPlanner {
    public enum TempoTarget: Hashable, Sendable {
        case rate
        case targetBpm(Bpm)
    }

    public enum PitchTarget: Hashable, Sendable {
        case semitones
        case targetKey(MusicalKeyValue)
    }

    public struct File: Hashable, Sendable {
        public var sourceBpm: Bpm?
        public var key: MusicalKeyValue?
        public var existing: TimePitchDescription
        /// Whether the file has a pending normalize, for ``Summary/normalizesCleared``.
        public var hasNormalize: Bool

        public init(sourceBpm: Bpm?, key: MusicalKeyValue?, existing: TimePitchDescription, hasNormalize: Bool) {
            self.sourceBpm = sourceBpm
            self.key = key
            self.existing = existing
            self.hasNormalize = hasNormalize
        }
    }

    public enum SkipReason: Hashable, Sendable {
        case noBpm
        case noKey
    }

    public enum Outcome: Hashable, Sendable {
        /// `clearsNormalize` is the change's effect on a normalize, whether or not one is pending.
        case change(TimePitchDescription, clearsNormalize: Bool)
        case unchanged
        case skip(SkipReason)
    }

    public struct Summary: Hashable, Sendable {
        public var changed = 0
        public var unchanged = 0
        public var noBpm = 0
        public var noKey = 0
        /// Changes that clear a normalize the file actually has.
        public var normalizesCleared = 0

        public var skipped: Int { noBpm + noKey }
        public var hasChanges: Bool { changed > 0 }

        public init(changed: Int = 0, unchanged: Int = 0, noBpm: Int = 0, noKey: Int = 0, normalizesCleared: Int = 0) {
            self.changed = changed
            self.unchanged = unchanged
            self.noBpm = noBpm
            self.noKey = noKey
            self.normalizesCleared = normalizesCleared
        }
    }

    public struct Plan: Hashable, Sendable {
        /// One per input file, in order.
        public var outcomes: [Outcome]
        public var summary: Summary
    }

    /// A file missing both a BPM and a key under both targets is skipped as `.noBpm`.
    public static func plan(
        _ setting: TimePitchDescription,
        tempo: TempoTarget,
        pitch: PitchTarget,
        files: [File]
    ) -> Plan {
        var summary = Summary()

        let outcomes = files.map { file in
            let outcome = outcome(for: file, setting: setting, tempo: tempo, pitch: pitch)

            switch outcome {
            case let .change(_, clearsNormalize):
                summary.changed += 1
                if clearsNormalize, file.hasNormalize { summary.normalizesCleared += 1 }
            case .unchanged:
                summary.unchanged += 1
            case .skip(.noBpm):
                summary.noBpm += 1
            case .skip(.noKey):
                summary.noKey += 1
            }

            return outcome
        }

        return Plan(outcomes: outcomes, summary: summary)
    }

    /// Every file back to identity.
    public static func clear(files: [File]) -> Plan {
        plan(TimePitchDescription(), tempo: .rate, pitch: .semitones, files: files)
    }

    private static func outcome(
        for file: File,
        setting: TimePitchDescription,
        tempo: TempoTarget,
        pitch: PitchTarget
    ) -> Outcome {
        var result = setting

        if case let .targetBpm(target) = tempo {
            guard let rate = file.sourceBpm?.rate(toReach: target, within: TimePitchDescription.rateRange) else {
                return .skip(.noBpm)
            }
            result.rate = rate
        }

        if case let .targetKey(target) = pitch {
            guard let semitones = file.key?.nearestTransposition(to: target) else {
                return .skip(.noKey)
            }
            result.semitones = semitones
        }

        guard result != file.existing else { return .unchanged }

        return .change(result, clearsNormalize: result.invalidatesNormalize(from: file.existing))
    }
}

// Copyright Ryan Francesconi. All Rights Reserved. Revision History at https://github.com/ryanfrancesconi/spfk-audio-base

import Foundation

/// A file's transients, sorted, in seconds.
public struct TransientSet: Sendable, Equatable {
    /// How far past a time a transient must lie to count as after it, so a playhead parked on a
    /// transient steps to the next one rather than to itself. Well under the smallest spacing.
    public static let tolerance: TimeInterval = 0.001

    public let times: [TimeInterval]

    public var isEmpty: Bool { times.isEmpty }

    /// - Parameter times: Sorted ascending.
    public init(times: [TimeInterval]) {
        self.times = times
    }

    /// The candidates `options` keep: those at least as strong as its threshold, then of any two
    /// closer than its spacing the stronger. Linear in the candidate count.
    ///
    /// - Parameter candidates: Sorted by time.
    public init(candidates: [TransientCandidate], options: TransientDetectorOptions) {
        let threshold = options.strengthThreshold
        var kept: [TransientCandidate] = []

        for candidate in candidates where candidate.strength >= threshold {
            if let last = kept.last, candidate.time - last.time < options.minimumSpacing {
                if candidate.strength > last.strength {
                    kept[kept.count - 1] = candidate
                }
            } else {
                kept.append(candidate)
            }
        }

        times = kept.map(\.time)
    }

    /// The set as a reversed view of `duration` shows it: each `t` at `duration - t`.
    public func mirrored(duration: TimeInterval) -> TransientSet {
        TransientSet(times: times.reversed().map { max(0, duration - $0) })
    }

    /// The first transient later than `time` by more than ``tolerance``, inside `bounds`.
    public func next(after time: TimeInterval, within bounds: ClosedRange<TimeInterval>) -> TimeInterval? {
        let index = max(firstIndex(greaterThan: time + Self.tolerance), firstIndex(notLessThan: bounds.lowerBound))
        guard index < times.count, bounds.contains(times[index]) else { return nil }
        return times[index]
    }

    /// The last transient earlier than `time` by more than ``tolerance``, inside `bounds`.
    public func previous(before time: TimeInterval, within bounds: ClosedRange<TimeInterval>) -> TimeInterval? {
        let index = min(firstIndex(notLessThan: time - Self.tolerance), firstIndex(greaterThan: bounds.upperBound)) - 1
        guard index >= 0, bounds.contains(times[index]) else { return nil }
        return times[index]
    }

    public func times(in range: ClosedRange<TimeInterval>) -> ArraySlice<TimeInterval> {
        let lower = firstIndex(notLessThan: range.lowerBound)
        let upper = firstIndex(greaterThan: range.upperBound)
        return times[lower ..< max(lower, upper)]
    }

    // MARK: - Binary search

    private func firstIndex(greaterThan time: TimeInterval) -> Int {
        partition { $0 > time }
    }

    private func firstIndex(notLessThan time: TimeInterval) -> Int {
        partition { $0 >= time }
    }

    /// The first index whose time satisfies `predicate`, which must be false then true across `times`.
    private func partition(_ predicate: (TimeInterval) -> Bool) -> Int {
        var low = 0
        var high = times.count

        while low < high {
            let mid = (low + high) / 2
            if predicate(times[mid]) {
                high = mid
            } else {
                low = mid + 1
            }
        }

        return low
    }
}

// Copyright Ryan Francesconi. All Rights Reserved. Revision History at https://github.com/ryanfrancesconi/spfk-audio-base

import Foundation
import SPFKAudioBaseC

/// Where a ``TimelineMapping`` is pinned to the engine's render timeline.
public enum TimelineAnchor: Equatable, Sendable {
    /// A render sample time on the engine's timeline: exact, and the one offline rendering uses.
    case sample(Int64)

    /// A host time, bound to a render sample on the render thread from the timestamp of the block
    /// that adopts it.
    case host(UInt64)

    /// The first frame of the block that adopts it.
    case atAdoption
}

/// Which source position a node processes at each render sample:
/// `sourceAnchor + direction × rate × (S − anchor) / renderSampleRate`, wrapped into `loop`.
///
/// Positions are computed per sample from the anchor rather than accumulated, so a loop of any
/// length and any number of iterations is one mapping. Before the anchor, the position is
/// `sourceAnchor`.
public struct TimelineMapping: Equatable, Sendable {
    public enum Direction: Int32, Sendable {
        case forward = 1
        case reverse = -1
    }

    public enum ValidationError: Error, Equatable {
        case invalidRate
        case invalidSampleRate
        case invalidSourceAnchor
        case invalidLoop
    }

    public let renderAnchor: TimelineAnchor

    /// Seconds of source time at the anchor.
    public let sourceAnchor: Double

    /// Source seconds per render second, > 0.
    public let rate: Double
    public let direction: Direction

    /// Seconds of source time. A forward position at or past `upperBound`, or a reverse one below
    /// `lowerBound`, wraps.
    public let loop: Range<Double>?

    public let renderSampleRate: Double

    public init(
        renderAnchor: TimelineAnchor,
        sourceAnchor: Double,
        rate: Double = 1,
        direction: Direction = .forward,
        loop: Range<Double>? = nil,
        renderSampleRate: Double
    ) throws {
        guard rate.isFinite, rate > 0 else { throw ValidationError.invalidRate }
        guard renderSampleRate.isFinite, renderSampleRate > 0 else { throw ValidationError.invalidSampleRate }
        guard sourceAnchor.isFinite else { throw ValidationError.invalidSourceAnchor }

        if let loop {
            guard loop.lowerBound.isFinite, loop.upperBound.isFinite, !loop.isEmpty else {
                throw ValidationError.invalidLoop
            }
        }

        self.renderAnchor = renderAnchor
        self.sourceAnchor = sourceAnchor
        self.rate = rate
        self.direction = direction
        self.loop = loop
        self.renderSampleRate = renderSampleRate
    }

    /// The source position at `renderSample`, with the anchor bound to `anchorSample`.
    public func position(atRenderSample renderSample: Int64, anchorSample: Int64) -> Double {
        var mapping = renderMapping(anchorSample: anchorSample)
        return spfk_timeline_position(&mapping, renderSample)
    }

    /// The source position at `renderSample`, for a mapping anchored at a ``TimelineAnchor/sample(_:)``;
    /// nil for an anchor only the render thread can bind.
    public func position(atRenderSample renderSample: Int64) -> Double? {
        guard case let .sample(anchorSample) = renderAnchor else { return nil }
        return position(atRenderSample: renderSample, anchorSample: anchorSample)
    }

    /// The mapping as the render thread reads it, with the anchor bound to `anchorSample`.
    public func renderMapping(anchorSample: Int64) -> SPFKTimelineMapping {
        SPFKTimelineMapping(
            renderAnchor: anchorSample,
            sourceAnchor: sourceAnchor,
            rate: rate,
            direction: direction.rawValue,
            loopStart: loop?.lowerBound ?? 0,
            loopEnd: loop?.upperBound ?? 0,
            renderSampleRate: renderSampleRate
        )
    }
}

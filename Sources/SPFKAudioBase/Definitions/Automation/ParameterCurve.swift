// Copyright Ryan Francesconi. All Rights Reserved. Revision History at https://github.com/ryanfrancesconi/spfk-audio-base

import AudioToolbox
import Foundation
import SPFKAudioBaseC

/// A parameter's automation: ordered, non-overlapping shaped segments in seconds of source time.
///
/// Before the first segment the value holds that segment's start, and between and after
/// segments the previous one's end. ``value(at:)`` runs the evaluation the render thread runs.
public struct ParameterCurve: Sendable {
    public let segments: [CurveSegment]

    /// `segments` as the render thread reads them, built once.
    private let evaluation: [SPFKCurveSegment]

    public enum ValidationError: Error, Equatable {
        case empty
        /// A time or value is NaN or infinite, the shape is invalid, or `shapeRange` leaves 0 ... 1.
        case invalidSegment(index: Int)
        case endBeforeStart(index: Int)
        /// Starts before the previous segment ends.
        case overlap(index: Int)
    }

    public init(_ segments: [CurveSegment]) throws {
        guard !segments.isEmpty else { throw ValidationError.empty }

        for (index, segment) in segments.enumerated() {
            guard segment.isValid else { throw ValidationError.invalidSegment(index: index) }
            guard segment.end >= segment.start else { throw ValidationError.endBeforeStart(index: index) }
            guard index == 0 || segments[index - 1].end <= segment.start else {
                throw ValidationError.overlap(index: index)
            }
        }

        self.segments = segments
        evaluation = segments.map(\.cSegment)
    }

    /// A curve that holds `value` everywhere.
    public init(constant value: AUValue) throws {
        try self.init([CurveSegment(start: 0, end: 0, startValue: value, endValue: value)])
    }

    public func value(at position: Double) -> AUValue {
        evaluation.withUnsafeBufferPointer { buffer in
            AUValue(spfk_curve_value(buffer.baseAddress, buffer.count, position))
        }
    }
}

extension ParameterCurve: Equatable {
    public static func == (lhs: ParameterCurve, rhs: ParameterCurve) -> Bool {
        lhs.segments == rhs.segments
    }
}

extension ParameterCurve: Codable {
    private enum CodingKeys: String, CodingKey {
        case segments
    }

    public init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        try self.init(c.decode([CurveSegment].self, forKey: .segments))
    }

    public func encode(to encoder: any Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(segments, forKey: .segments)
    }
}

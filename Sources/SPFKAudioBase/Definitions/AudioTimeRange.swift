// Copyright Ryan Francesconi. All Rights Reserved. Revision History at https://github.com/ryanfrancesconi

import Foundation

/// A half-open time range [start, end) in seconds.
public struct AudioTimeRange: Equatable, Hashable, Sendable {
    public let start: TimeInterval
    public let end: TimeInterval

    public var duration: TimeInterval { end - start }

    public init(start: TimeInterval, end: TimeInterval) {
        precondition(start >= 0, "AudioTimeRange: start (\(start)) must be >= 0")
        precondition(start < end, "AudioTimeRange: start (\(start)) must be < end (\(end))")
        self.start = start
        self.end = end
    }
}

// MARK: - Codable

extension AudioTimeRange: Codable {
    private enum CodingKeys: String, CodingKey {
        case start, end
    }

    public init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let decodedStart = try c.decode(TimeInterval.self, forKey: .start)
        let decodedEnd = try c.decode(TimeInterval.self, forKey: .end)
        guard decodedStart >= 0 else {
            throw DecodingError.dataCorruptedError(
                forKey: .start, in: c,
                debugDescription: "start (\(decodedStart)) must be >= 0"
            )
        }
        guard decodedStart < decodedEnd else {
            throw DecodingError.dataCorruptedError(
                forKey: .end, in: c,
                debugDescription: "start (\(decodedStart)) must be < end (\(decodedEnd))"
            )
        }
        start = decodedStart
        end = decodedEnd
    }

    public func encode(to encoder: any Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(start, forKey: .start)
        try c.encode(end, forKey: .end)
    }
}

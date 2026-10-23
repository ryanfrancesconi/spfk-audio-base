// Copyright Ryan Francesconi. All Rights Reserved. Revision History at https://github.com/ryanfrancesconi/spfk-audio-base

import AVFoundation
import Foundation
import SPFKBase

/// Which signal a mono channel operation keeps.
public enum MonoSource: String, Codable, Sendable, CaseIterable {
    /// (L + R) / 2
    case average
    case left
    case right
}

/// A pending operation on a stereo file's two channels.
///
/// Formulas, shared by the render and the real-time preview:
/// - swap: L′ = R, R′ = L
/// - mono: (L + R) / 2, L or R, written as one channel
/// - M/S decode: L′ = M + w·S, R′ = M − w·S, where M and S are the input's first and second channel
/// - M/S encode: M = (L + R) / 2, S = (L − R) / 2
public enum ChannelOperation: Hashable, Sendable {
    case none
    case swap
    case mono(MonoSource)
    /// `width` is 0 ... 2; 1 is the nominal image and 0 is M on both sides.
    case midSideDecode(width: Float)
    case midSideEncode

    public static let widthRange: ClosedRange<Float> = 0 ... 2

    /// The operation playback and display apply: a pending one wins, otherwise a mid/side file is
    /// decoded at the nominal width.
    public static func effective(pending: ChannelOperation, isMidSide: Bool) -> ChannelOperation {
        if pending != .none { return pending }
        return isMidSide ? .midSideDecode(width: 1) : .none
    }

    /// The channel count this operation writes for an input of `inputChannels`.
    public func outputChannelCount(forInput inputChannels: AVAudioChannelCount) -> AVAudioChannelCount {
        if case .mono = self { return 1 }
        return inputChannels
    }

    /// Lane or track names after this operation, from the input's two names. Any other count is
    /// returned unchanged.
    public func laneNames(from names: [String]) -> [String] {
        guard names.count == 2 else { return names }

        switch self {
        case .none: return names
        case .swap: return [names[1], names[0]]
        case .mono(.average): return ["Mono"]
        case .mono(.left): return [names[0]]
        case .mono(.right): return [names[1]]
        case .midSideDecode: return ["L", "R"]
        case .midSideEncode: return ["M", "S"]
        }
    }
}

// MARK: - Storage

extension ChannelOperation {
    /// On-disk names, shared by `Codable` and SQL. A rename is a migration.
    public enum Kind: String, Sendable, CaseIterable {
        case none
        case swap
        case monoAverage = "mono_average"
        case monoLeft = "mono_left"
        case monoRight = "mono_right"
        case midSideDecode = "ms_decode"
        case midSideEncode = "ms_encode"
    }

    public var kind: Kind {
        switch self {
        case .none: .none
        case .swap: .swap
        case .mono(.average): .monoAverage
        case .mono(.left): .monoLeft
        case .mono(.right): .monoRight
        case .midSideDecode: .midSideDecode
        case .midSideEncode: .midSideEncode
        }
    }

    public init(kind: Kind, width: Float = 1) {
        switch kind {
        case .none: self = .none
        case .swap: self = .swap
        case .monoAverage: self = .mono(.average)
        case .monoLeft: self = .mono(.left)
        case .monoRight: self = .mono(.right)
        case .midSideDecode: self = .midSideDecode(width: width)
        case .midSideEncode: self = .midSideEncode
        }
    }

    /// `kind`'s raw value. An unknown name reads as `.none` and is logged.
    public var kindName: String {
        get { kind.rawValue }
        set {
            guard let kind = Kind(rawValue: newValue) else {
                Log.error("Unknown channel operation '\(newValue)', reading as none")
                self = .none
                return
            }
            self = ChannelOperation(kind: kind, width: width)
        }
    }

    /// The M/S decode width, 1 for every other case. Setting it changes only a decode, so a
    /// reader must set `kindName` first.
    public var width: Float {
        get {
            if case let .midSideDecode(width) = self { return width }
            return 1
        }
        set {
            if case .midSideDecode = self { self = .midSideDecode(width: newValue) }
        }
    }
}

extension ChannelOperation: Codable {
    private enum CodingKeys: String, CodingKey {
        case kind, width
    }

    public init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let width = try c.decodeIfPresent(Float.self, forKey: .width) ?? 1
        self = .none
        kindName = try c.decode(String.self, forKey: .kind)
        self.width = width
    }

    public func encode(to encoder: any Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(kind.rawValue, forKey: .kind)
        if case let .midSideDecode(width) = self {
            try c.encode(width, forKey: .width)
        }
    }
}

// Copyright Ryan Francesconi. All Rights Reserved. Revision History at https://github.com/ryanfrancesconi/spfk-audio-base

import AudioToolbox
import Foundation
import SPFKBase

public struct AudioUnitInsert: Sendable, Hashable, Equatable, Codable {
    public var uid: String
    public var index: Int
    public var isBypassed: Bool
    public var name: String?
    public var fullStatePlistData: Data?
    public var isWindowVisible: Bool
    public var windowFrame: CG.Rect?

    public init(
        uid: String,
        index: Int,
        isBypassed: Bool,
        name: String? = nil,
        fullStatePlistData: Data? = nil,
        isWindowVisible: Bool = false,
        windowFrame: CG.Rect? = nil
    ) {
        self.uid = uid
        self.index = index
        self.isBypassed = isBypassed
        self.name = name
        self.fullStatePlistData = fullStatePlistData
        self.isWindowVisible = isWindowVisible
        self.windowFrame = windowFrame
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        uid = try container.decode(String.self, forKey: .uid)
        index = try container.decodeIfPresent(Int.self, forKey: .index) ?? 0
        isBypassed = try container.decodeIfPresent(Bool.self, forKey: .isBypassed) ?? false
        name = try container.decodeIfPresent(String.self, forKey: .name)
        fullStatePlistData = try container.decodeIfPresent(Data.self, forKey: .fullStatePlistData)
        isWindowVisible = try container.decodeIfPresent(Bool.self, forKey: .isWindowVisible) ?? false
        windowFrame = try container.decodeIfPresent(CG.Rect.self, forKey: .windowFrame)
    }
}

extension AudioUnitInsert {
    public var componentDescription: AudioComponentDescription? {
        AudioComponentDescription(uid: uid)
    }

    public var fullStateDictionary: [String: Any]? {
        guard let fullStatePlistData else { return nil }
        var format: PropertyListSerialization.PropertyListFormat = .xml
        return try? PropertyListSerialization.propertyList(
            from: fullStatePlistData,
            options: .mutableContainersAndLeaves,
            format: &format
        ) as? [String: Any]
    }
}

public struct AudioUnitChainState: Sendable, Hashable, Equatable, Codable {
    public var insertCount: Int
    public var inserts: [AudioUnitInsert]

    public init(insertCount: Int, inserts: [AudioUnitInsert]) {
        self.insertCount = insertCount
        self.inserts = inserts
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        insertCount = try container.decodeIfPresent(Int.self, forKey: .insertCount) ?? 0
        inserts = try container.decodeIfPresent([AudioUnitInsert].self, forKey: .inserts) ?? []
    }
}

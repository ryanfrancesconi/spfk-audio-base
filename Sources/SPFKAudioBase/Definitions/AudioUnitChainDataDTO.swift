// Copyright Ryan Francesconi. All Rights Reserved. Revision History at https://github.com/ryanfrancesconi/spfk-audio-base

import AudioToolbox
import Foundation
import SPFKBase

public struct AudioUnitInsertDTO: Sendable, Hashable, Equatable, Codable {
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
}

extension AudioUnitInsertDTO {
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

public struct AudioUnitChainDataDTO: Sendable, Hashable, Equatable, Codable {
    public var insertCount: Int
    public var inserts: [AudioUnitInsertDTO]

    public init(insertCount: Int, inserts: [AudioUnitInsertDTO]) {
        self.insertCount = insertCount
        self.inserts = inserts
    }
}

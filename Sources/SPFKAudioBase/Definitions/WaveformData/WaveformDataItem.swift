// Copyright Ryan Francesconi. All Rights Reserved. Revision History at https://github.com/ryanfrancesconi/spfk-audio-base

import Foundation
import SPFKBase

public struct WaveformDataItem: Sendable, Hashable, Codable, Equatable {
    public static func == (lhs: WaveformDataItem, rhs: WaveformDataItem) -> Bool {
        lhs.url == rhs.url
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(url)
    }

    public let url: URL
    public let modificationDate: Date?
    public let fileSize: Int?
    public let waveformData: WaveformData

    public init(
        url: URL,
        modificationDate: Date? = nil,
        fileSize: Int? = nil,
        waveformData: WaveformData
    ) {
        self.url = url
        self.modificationDate = modificationDate ?? url.modificationDate
        self.fileSize = fileSize ?? url.fileSize
        self.waveformData = waveformData
    }

    /// Returns true if the cached data no longer matches the file on disk
    public func isFresh(comparedTo url: URL) -> Bool {
        modificationDate == url.modificationDate && fileSize == url.fileSize
    }
}

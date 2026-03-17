// Copyright Ryan Francesconi. All Rights Reserved. Revision History at https://github.com/ryanfrancesconi

import Foundation

/// Specify whether to copy or ignore metadata when converting files from one format to another
public enum MetadataCopyScheme: Codable, Sendable, CaseIterable {
    /// Copy all metadata including any metadata image
    case copyAll

    /// Copy just text based metatadata such as ID3 tags, includes Wave BEXT, Wave iXML, and XMP
    case copyText

    /// Ignore text metadata but copy markers
    case copyMarkers

    /// Copy both text and markers
    case copyTextAndMarkers

    /// Ignore all metadata
    case ignore

    public var displayName: String {
        switch self {
        case .copyAll:
            "Copy All"

        case .copyText:
            "Copy Text Based"

        case .copyMarkers:
            "Copy Markers"

        case .copyTextAndMarkers:
            "Copy Text and Markers"

        case .ignore:
            "Ignore"
        }
    }
}

// TODO: CLAUDE add explicit Codable defs for SwiftData

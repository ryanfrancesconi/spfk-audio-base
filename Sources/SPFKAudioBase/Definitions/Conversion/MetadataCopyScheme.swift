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
            String(localized: "Copy All", bundle: .module)

        case .copyText:
            String(localized: "Copy Text Based", bundle: .module)

        case .copyMarkers:
            String(localized: "Copy Markers", bundle: .module)

        case .copyTextAndMarkers:
            String(localized: "Copy Text and Markers", bundle: .module)

        case .ignore:
            String(localized: "Ignore", bundle: .module)
        }
    }

    /// Whether this scheme includes text-based metadata (tags, BEXT, iXML, XMP).
    public var includesText: Bool {
        switch self {
        case .copyAll, .copyText, .copyTextAndMarkers: true
        case .copyMarkers, .ignore: false
        }
    }

    /// Whether this scheme includes markers (RIFF cue points, ID3 chapters).
    public var includesMarkers: Bool {
        switch self {
        case .copyAll, .copyMarkers, .copyTextAndMarkers: true
        case .copyText, .ignore: false
        }
    }

    /// Whether this scheme includes embedded artwork.
    public var includesImage: Bool {
        self == .copyAll
    }
}

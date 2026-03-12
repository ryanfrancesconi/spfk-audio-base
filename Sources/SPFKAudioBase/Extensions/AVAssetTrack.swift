// Copyright Ryan Francesconi. All Rights Reserved. Revision History at https://github.com/ryanfrancesconi/spfk-utils

import AVFoundation

extension AVAssetTrack {
    public struct SimpleMediaFormat {
        public var type: String
        public var subType: String
    }

    public var mediaFormats: [SimpleMediaFormat] {
        get async throws {
            var formats = [SimpleMediaFormat]()

            let descriptions = try await load(.formatDescriptions)

            for formatDesc in descriptions {
                // Get String representation of media type (vide, soun, sbtl, etc.)
                let type = CMFormatDescriptionGetMediaType(formatDesc).fourCC

                // Get String representation media subtype (avc1, aac, tx3g, etc.)
                let subType = CMFormatDescriptionGetMediaSubType(formatDesc).fourCC

                formats.append(SimpleMediaFormat(type: type, subType: subType))
            }
            return formats
        }
    }
}

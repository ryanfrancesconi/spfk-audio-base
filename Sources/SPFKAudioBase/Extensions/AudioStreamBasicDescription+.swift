// Copyright Ryan Francesconi. All Rights Reserved. Revision History at https://github.com/ryanfrancesconi/spfk-audio-base

import AudioToolbox

extension AudioStreamBasicDescription {
    /// The bit depth of the audio this stream carries, or `nil` for a codec that has none.
    ///
    /// FLAC and Apple Lossless report 0 in `mBitsPerChannel` and state their source depth in
    /// `mFormatFlags` instead; any other codec's flags mean something else.
    public var sourceBitsPerChannel: Int? {
        if mBitsPerChannel > 0 { return Int(mBitsPerChannel) }

        guard mFormatID == kAudioFormatAppleLossless || mFormatID == kAudioFormatFLAC else { return nil }

        switch mFormatFlags {
        case kAppleLosslessFormatFlag_16BitSourceData: return 16
        case kAppleLosslessFormatFlag_20BitSourceData: return 20
        case kAppleLosslessFormatFlag_24BitSourceData: return 24
        case kAppleLosslessFormatFlag_32BitSourceData: return 32
        default: return nil
        }
    }
}

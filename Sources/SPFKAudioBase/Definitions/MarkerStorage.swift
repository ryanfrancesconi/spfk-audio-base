// Copyright Ryan Francesconi. All Rights Reserved. Revision History at https://github.com/ryanfrancesconi/spfk-audio-base

import Foundation

/// How a container stores markers. Every marker read and write dispatches on
/// ``AudioFileType/markerStorage``, so each format's mechanism is stated once.
public enum MarkerStorage: Sendable, Hashable {
    /// `cue ` and `LIST`/`adtl` chunks: WAV, RF64, BW64.
    case riffCues
    /// The `MARK` chunk: AIFF and AIFF-C.
    case aiffMarks
    /// ID3v2 `CHAP` frames.
    case id3Chapters
    /// A QuickTime chapter track, with Nero `chpl` read as a fallback.
    case mp4Chapters
    /// Vorbis comment `CHAPTERnnn` fields.
    case xiphChapters
    /// Core Audio's marker list, which a metadata save does not write.
    case coreAudio
}

extension AudioFileType {
    /// Where this container keeps markers; nil when it has nowhere to (an ADTS `.aac` among them).
    public var markerStorage: MarkerStorage? {
        switch self {
        case .wav: .riffCues
        case .aiff, .aifc: .aiffMarks
        case .mp3: .id3Chapters
        case .m4a, .m4b, .m4v, .mov, .mp4: .mp4Chapters
        case .flac, .ogg, .opus: .xiphChapters
        case .w64: .coreAudio
        case .aac, .au, .caf, .mka, .mkv, .mxf, .snd, .ts, .webm: nil
        }
    }
}

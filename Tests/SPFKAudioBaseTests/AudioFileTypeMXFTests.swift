// Copyright Ryan Francesconi. All Rights Reserved. Revision History at https://github.com/ryanfrancesconi/spfk-audio-base

import Foundation
import Testing

@testable import SPFKAudioBase

/// MXF is admitted for its audio and video and nothing else: no tag store can open it, and
/// `AVAudioFile` cannot either. Each membership below is that decision.
@Suite("AudioFileType MXF")
struct AudioFileTypeMXFTests {
    private let mxf = AudioFileType.mxf

    @Test("Resolves from a path extension")
    func resolvesFromPathExtension() {
        #expect(AudioFileType(pathExtension: "mxf") == .mxf)
        #expect(AudioFileType(pathExtension: "MXF") == .mxf)
    }

    /// Neither TagLib nor the Adobe XMP toolkit has an MXF handler, so a row for one carries no
    /// writable metadata at all.
    @Test("Claims no metadata support")
    func claimsNoMetadataSupport() {
        #expect(mxf.supportsMetadata == false)
        #expect(mxf.supportsXMP == false)
        #expect(mxf.supportsBEXT == false)
        #expect(mxf.supportsIXML == false)
    }

    /// The route decision for every audio read: false sends a caller to an `AVAsset`-backed source
    /// instead. Matroska is the other member and is asserted alongside so the two stay one answer.
    @Test("AVAudioFile cannot read it")
    func isNotAVAudioFileReadable() {
        #expect(mxf.isAVAudioFileReadable == false)
        #expect(AudioFileType.mkv.isAVAudioFileReadable == false)
        #expect(AudioFileType.wav.isAVAudioFileReadable)
        #expect(AudioFileType.mov.isAVAudioFileReadable)
    }

    /// MXF routinely carries separate mono stems, so a picker has a real choice to offer.
    @Test("Offers a choice of audio track")
    func supportsMultipleAudioTracks() {
        #expect(mxf.supportsMultipleAudioTracks)
    }

    /// Answered by UTType conformance rather than a list — `org.smpte.mxf` conforms to
    /// `public.movie` whether or not anything can read the file.
    @Test("Reports itself a video container")
    func isVideo() {
        #expect(mxf.isVideo)
        #expect(mxf.isMatroska == false)
    }

    /// No AudioToolbox identity exists for MXF, and inventing one would route a conversion into a
    /// stack that cannot open the file.
    @Test("Carries no CoreAudio or AVFoundation identity")
    func hasNoToolboxIdentity() {
        #expect(mxf.avFileType == nil)
        #expect(mxf.audioFileTypeID == nil)
        #expect(mxf.audioFormatID == nil)
        #expect(mxf.isAVAudioFileWritable == false)
    }
}

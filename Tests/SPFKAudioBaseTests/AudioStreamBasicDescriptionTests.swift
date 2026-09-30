// Copyright Ryan Francesconi. All Rights Reserved. Revision History at https://github.com/ryanfrancesconi/spfk-audio-base

import AVFoundation
import Foundation
import SPFKAudioBase
import SPFKTesting
import Testing

struct AudioStreamBasicDescriptionTests {
    private func description(formatID: AudioFormatID, flags: AudioFormatFlags, bits: UInt32 = 0) -> AudioStreamBasicDescription {
        var description = AudioStreamBasicDescription()
        description.mFormatID = formatID
        description.mFormatFlags = flags
        description.mBitsPerChannel = bits
        description.mSampleRate = 48000
        description.mChannelsPerFrame = 2
        return description
    }

    @Test func losslessDepthComesFromTheFlags() {
        #expect(description(formatID: kAudioFormatFLAC, flags: kAppleLosslessFormatFlag_16BitSourceData)
            .sourceBitsPerChannel == 16)
        #expect(description(formatID: kAudioFormatFLAC, flags: kAppleLosslessFormatFlag_24BitSourceData)
            .sourceBitsPerChannel == 24)
        #expect(description(formatID: kAudioFormatAppleLossless, flags: kAppleLosslessFormatFlag_20BitSourceData)
            .sourceBitsPerChannel == 20)
        #expect(description(formatID: kAudioFormatAppleLossless, flags: kAppleLosslessFormatFlag_32BitSourceData)
            .sourceBitsPerChannel == 32)
    }

    /// The flag values are only a depth for the two lossless codecs; any other codec's flags mean
    /// something else.
    @Test func otherCodecsFlagsAreNotADepth() {
        #expect(description(formatID: kAudioFormatMPEG4AAC, flags: kAppleLosslessFormatFlag_24BitSourceData)
            .sourceBitsPerChannel == nil)
        #expect(description(formatID: kAudioFormatMPEGLayer3, flags: 0).sourceBitsPerChannel == nil)
    }

    @Test func pcmDepthIsItsOwn() {
        let pcm = description(
            formatID: kAudioFormatLinearPCM,
            flags: kLinearPCMFormatFlagIsSignedInteger | kLinearPCMFormatFlagIsPacked,
            bits: 24
        )
        #expect(pcm.sourceBitsPerChannel == 24)
    }

    @Test func realFiles() throws {
        func depth(_ url: URL) throws -> Int? {
            // Held, since `streamDescription` points into the format.
            let format = try AVAudioFile(forReading: url).fileFormat
            return withExtendedLifetime(format) { format.streamDescription.pointee.sourceBitsPerChannel }
        }

        #expect(try depth(TestBundleResources.shared.tabla_flac) == 24)
        #expect(try depth(TestBundleResources.shared.tabla_wav) == 24)
        #expect(try depth(TestBundleResources.shared.tabla_m4a) == nil)
    }
}

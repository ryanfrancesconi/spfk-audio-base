import AVFoundation
import Foundation
import SPFKAudioBase
import SPFKBase
import SPFKTesting
import Testing

// Note, more tests in SPFKMetadataTests

@Suite(.serialized, .tags(.file))
class AudioFileTypeTests: BinTestCase {
    @Test func getFileTypeName() throws {
        let ids = [
            kAudioFile3GP2Type,
            kAudioFile3GPType,
            kAudioFileAAC_ADTSType,
            kAudioFileAC3Type,
            kAudioFileAIFCType,
            kAudioFileAIFFType,
            kAudioFileAMRType,
            kAudioFileBW64Type,
            kAudioFileCAFType,
            kAudioFileFLACType,
            kAudioFileM4AType,
            kAudioFileM4BType,
            kAudioFileMP1Type,
            kAudioFileMP2Type,
            kAudioFileMP3Type,
            kAudioFileMPEG4Type,
            kAudioFileNextType,
            kAudioFileRF64Type,
            kAudioFileSoundDesigner2Type,
            kAudioFileWave64Type,
            kAudioFileWAVEType,
        ]

        let names = ids.compactMap {
            try? AudioFileType.getFileTypeName(propertyId: $0)
        }

        #expect(names.count == ids.count)

        Log.debug(names)
    }

    @Test func videoTypes() throws {
        #expect(AudioFileType.mov.isVideo)
        #expect(AudioFileType.m4v.isVideo)
        #expect(AudioFileType.mp4.isVideo)

        #expect(!AudioFileType.wav.isVideo)
        #expect(AudioFileType.wav.isAudio)
        #expect(AudioFileType.wav.isPCM)

        // it could be but this returns false
        // #expect(AudioFileType.mp4.isPCM)
    }
}

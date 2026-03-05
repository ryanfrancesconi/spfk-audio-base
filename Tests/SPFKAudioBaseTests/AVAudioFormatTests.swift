import AVFoundation
@testable import SPFKAudioBase
import Testing

@Suite("AVAudioFormat Extensions")
struct AVAudioFormatTests {
    @Test("channelCountReadableDescription mono")
    func monoDescription() {
        let format = AVAudioFormat(standardFormatWithSampleRate: 44100, channels: 1)!
        #expect(format.channelCountReadableDescription == "Mono")
    }

    @Test("channelCountReadableDescription stereo")
    func stereoDescription() {
        let format = AVAudioFormat(standardFormatWithSampleRate: 44100, channels: 2)!
        #expect(format.channelCountReadableDescription == "Stereo")
    }

    @Test("channelCountReadableDescription multichannel")
    func multichannelDescription() {
        guard let layout = AVAudioChannelLayout(layoutTag: kAudioChannelLayoutTag_MPEG_5_1_A) else { return }
        let format = AVAudioFormat(standardFormatWithSampleRate: 44100, channelLayout: layout)
        #expect(format.channelCountReadableDescription == "6 Channel")
    }

    @Test("readableDescription includes sample rate and channel info")
    func readableDescription() {
        let format = AVAudioFormat(standardFormatWithSampleRate: 48000, channels: 2)!
        let desc = format.readableDescription
        #expect(desc.contains("48000"))
        #expect(desc.contains("Stereo"))
    }

    @Test("bitsPerChannel for standard format")
    func bitsPerChannel() {
        let format = AVAudioFormat(standardFormatWithSampleRate: 44100, channels: 2)!
        #expect(format.bitsPerChannel == 32) // standard format is Float32
    }

    @Test("bitRate for standard stereo")
    func bitRate() {
        let format = AVAudioFormat(standardFormatWithSampleRate: 44100, channels: 2)!
        // 44100 * 32 * 2 = 2822400
        #expect(format.bitRate == 2_822_400)
    }

    @Test("createPCMFormat with valid parameters")
    func createPCMFormat() {
        let format = AVAudioFormat.createPCMFormat(
            bitsPerChannel: 16,
            channels: 2,
            sampleRate: 44100
        )
        #expect(format != nil)
        #expect(format?.sampleRate == 44100)
        #expect(format?.channelCount == 2)
        #expect(format?.bitsPerChannel == 16)
    }

    @Test("commonFormatReadableDescription for known formats")
    func commonFormatDescription() {
        let float32 = AVAudioFormat(commonFormat: .pcmFormatFloat32, sampleRate: 44100, channels: 2, interleaved: false)!
        #expect(float32.commonFormatReadableDescription != nil)

        let int16 = AVAudioFormat(commonFormat: .pcmFormatInt16, sampleRate: 44100, channels: 2, interleaved: false)!
        #expect(int16.commonFormatReadableDescription != nil)
    }
}

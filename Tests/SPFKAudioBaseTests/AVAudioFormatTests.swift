import AVFoundation
@testable import SPFKAudioBase
import Testing

@Suite("AVAudioFormat Extensions")
struct AVAudioFormatTests {
    @Test("readableDescription includes sample rate and channel info")
    func readableDescription() {
        let format = AVAudioFormat(standardFormatWithSampleRate: 48000, channels: 2)!
        let desc = format.readableDescription
        #expect(desc.contains("48000"))
        #expect(desc.contains("Stereo"))
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
}

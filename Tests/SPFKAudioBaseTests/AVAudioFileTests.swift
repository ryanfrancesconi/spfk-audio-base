import AVFoundation
@testable import SPFKAudioBase
import SPFKBase
import SPFKTesting
import Testing

@Suite(.tags(.file))
struct AVAudioFileTests {
    @Test("duration calculated correctly")
    func duration() throws {
        let url = TestBundleResources.shared.cowbell_wav
        let file = try AVAudioFile(forReading: url)
        #expect(file.duration > 0)
    }

    @Test("audioStreamBasicDescription is non-nil for wav")
    func audioStreamBasicDescription() throws {
        let url = TestBundleResources.shared.cowbell_wav
        let file = try AVAudioFile(forReading: url)
        #expect(file.audioStreamBasicDescription != nil)
    }

    @Test("dataRate for PCM file")
    func dataRate() throws {
        let url = TestBundleResources.shared.cowbell_wav
        let file = try AVAudioFile(forReading: url)
        let rate = file.dataRate
        #expect(rate != nil)
        #expect(rate! > 0)
    }

    @Test("toAVAudioPCMBuffer reads entire file")
    func toBuffer() throws {
        let url = TestBundleResources.shared.cowbell_wav
        let file = try AVAudioFile(forReading: url)
        let buffer = try file.toAVAudioPCMBuffer()
        #expect(buffer.frameLength == AVAudioFrameCount(file.length))
    }

    @Test("toAVAudioPCMBuffer with maxDuration limits frames")
    func toBufferMaxDuration() throws {
        let url = TestBundleResources.shared.cowbell_wav
        let file = try AVAudioFile(forReading: url)

        guard file.duration > 1.0 else { return }

        let buffer = try file.toAVAudioPCMBuffer(maxDuration: 1.0)
        let expectedFrames = AVAudioFrameCount(1.0 * file.fileFormat.sampleRate)
        #expect(buffer.frameLength == expectedFrames)
    }

    @Test("convenience init writes buffer to file")
    func convenienceInitWrite() throws {
        let url = TestBundleResources.shared.cowbell_wav
        let buffer = try AVAudioFile(forReading: url).toAVAudioPCMBuffer()

        let output = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("spfk_avfile_test_\(UUID().uuidString).wav")
        defer { try? FileManager.default.removeItem(at: output) }

        let written = try AVAudioFile(url: output, fromBuffer: buffer)
        #expect(written.length == Int64(buffer.frameLength))
    }
}

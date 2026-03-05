import AVFoundation
@testable import SPFKAudioBase
import SPFKBase
import SPFKTesting
import Testing

@Suite(.tags(.file))
struct AVAudioPCMBufferTests {
    let stereoFormat = AVAudioFormat(standardFormatWithSampleRate: 44100, channels: 2)!
    let monoFormat = AVAudioFormat(standardFormatWithSampleRate: 44100, channels: 1)!

    // MARK: - Duration

    @Test("duration calculation")
    func duration() {
        let buffer = AVAudioPCMBuffer(pcmFormat: stereoFormat, frameCapacity: 44100)!
        buffer.frameLength = 44100
        #expect(buffer.duration == 1.0)
    }

    // MARK: - floatData

    @Test("floatData copies channel data")
    func floatData() {
        let buffer = AVAudioPCMBuffer(pcmFormat: monoFormat, frameCapacity: 10)!
        buffer.frameLength = 10

        if let data = buffer.floatChannelData {
            for i in 0 ..< 10 {
                data[0][i] = Float(i)
            }
        }

        let floatData = buffer.floatData
        #expect(floatData != nil)
        #expect(floatData?.count == 1)
        #expect(floatData?[0].count == 10)
        #expect(floatData?[0][5] == 5.0)
    }

    // MARK: - RMS

    @Test("rmsValue of silence is zero")
    func rmsValueSilence() {
        let buffer = AVAudioPCMBuffer(pcmFormat: stereoFormat, frameCapacity: 1024)!
        buffer.frameLength = 1024
        #expect(buffer.rmsValue == 0)
    }

    // MARK: - isSilent

    @Test("isSilent for empty buffer")
    func isSilentEmpty() {
        let buffer = AVAudioPCMBuffer(pcmFormat: stereoFormat, frameCapacity: 100)!
        buffer.frameLength = 100
        #expect(buffer.isSilent)
    }

    @Test("isSilent false for non-silent buffer")
    func isSilentFalse() {
        let buffer = AVAudioPCMBuffer(pcmFormat: monoFormat, frameCapacity: 10)!
        buffer.frameLength = 10

        if let data = buffer.floatChannelData {
            data[0][5] = 0.5
        }

        #expect(!buffer.isSilent)
    }

    // MARK: - Copy

    @Test("copy from buffer")
    func copyFromBuffer() throws {
        let src = AVAudioPCMBuffer(pcmFormat: monoFormat, frameCapacity: 100)!
        src.frameLength = 100

        if let data = src.floatChannelData {
            for i in 0 ..< 100 { data[0][i] = Float(i) / 100.0 }
        }

        let dst = AVAudioPCMBuffer(pcmFormat: monoFormat, frameCapacity: 200)!
        let copied = try dst.copy(from: src)
        #expect(copied == 100)
        #expect(dst.frameLength == 100)
    }

    @Test("copy with readOffset")
    func copyWithOffset() throws {
        let src = AVAudioPCMBuffer(pcmFormat: monoFormat, frameCapacity: 100)!
        src.frameLength = 100

        if let data = src.floatChannelData {
            for i in 0 ..< 100 { data[0][i] = Float(i) }
        }

        let dst = AVAudioPCMBuffer(pcmFormat: monoFormat, frameCapacity: 50)!
        let copied = try dst.copy(from: src, readOffset: 50, frames: 50)
        #expect(copied == 50)
        #expect(dst.frameLength == 50)

        if let dstData = dst.floatChannelData {
            #expect(dstData[0][0] == 50.0)
        }
    }

    // MARK: - copyFrom / copyTo

    @Test("copyFrom startSample")
    func copyFromStart() throws {
        let src = AVAudioPCMBuffer(pcmFormat: monoFormat, frameCapacity: 100)!
        src.frameLength = 100

        if let data = src.floatChannelData {
            for i in 0 ..< 100 { data[0][i] = Float(i) }
        }

        let result = try src.copyFrom(startSample: 50)
        #expect(result != nil)
        #expect(result!.frameLength == 50)
    }

    @Test("copyTo count")
    func copyToCount() throws {
        let src = AVAudioPCMBuffer(pcmFormat: monoFormat, frameCapacity: 100)!
        src.frameLength = 100

        let result = try src.copyTo(count: 30)
        #expect(result != nil)
        #expect(result!.frameLength == 30)
    }

    // MARK: - Extract

    @Test("extract time range")
    func extractRange() throws {
        let src = AVAudioPCMBuffer(pcmFormat: monoFormat, frameCapacity: 44100)!
        src.frameLength = 44100

        let extracted = try src.extract(from: 0.0, to: 0.5)
        #expect(extracted.frameLength == 22050)
    }

    @Test("extract invalid range throws")
    func extractInvalidRange() {
        let src = AVAudioPCMBuffer(pcmFormat: monoFormat, frameCapacity: 100)!
        src.frameLength = 100

        #expect(throws: (any Error).self) {
            _ = try src.extract(from: 0.5, to: 0.5)
        }
    }

    // MARK: - Loop

    @Test("loop creates duplicated buffer")
    func loop() throws {
        let src = AVAudioPCMBuffer(pcmFormat: monoFormat, frameCapacity: 100)!
        src.frameLength = 100

        if let data = src.floatChannelData {
            for i in 0 ..< 100 { data[0][i] = 0.5 }
        }

        let looped = try src.loop(numberOfDuplicates: 3)
        #expect(looped.frameLength == 300)
    }

    // MARK: - MD5

    @Test("md5 produces consistent hash")
    func md5Consistent() {
        let buffer = AVAudioPCMBuffer(pcmFormat: monoFormat, frameCapacity: 100)!
        buffer.frameLength = 100

        let hash1 = buffer.md5
        let hash2 = buffer.md5
        #expect(hash1 == hash2)
        #expect(hash1.count == 32) // MD5 hex string length
    }

    // MARK: - Read from file

    @Test("init from URL")
    func initFromURL() throws {
        let url = TestBundleResources.shared.cowbell_wav
        let buffer = try AVAudioPCMBuffer(url: url)
        #expect(buffer != nil)
        #expect(buffer!.frameLength > 0)
    }

    // MARK: - Write to file

    @Test("write and read back")
    func writeAndRead() throws {
        let url = TestBundleResources.shared.cowbell_wav
        let original = try AVAudioPCMBuffer(url: url)!

        let output = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("spfk_buffer_write_\(UUID().uuidString).wav")
        defer { try? FileManager.default.removeItem(at: output) }

        try original.write(to: output)

        let readBack = try AVAudioPCMBuffer(url: output)
        #expect(readBack != nil)
        #expect(readBack!.frameLength == original.frameLength)
    }
}

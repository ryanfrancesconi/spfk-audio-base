// Copyright Ryan Francesconi. All Rights Reserved.

import Foundation
import Testing

@testable import SPFKAudioBase

struct AudioFormatConverterOptionsTests {
    // MARK: - Static Ranges

    @Test func bitsPerChannelRange() {
        #expect(AudioFormatConverterOptions.bitsPerChannelRange == 16 ... 32)
    }

    @Test func bitRateRange() {
        #expect(AudioFormatConverterOptions.bitRateRange == 64000 ... 320_000)
    }

    @Test func supportedOutputFormatsContainsExpected() {
        let formats = AudioFormatConverterOptions.supportedOutputFormats
        #expect(formats.contains(.wav))
        #expect(formats.contains(.mp3))
        #expect(formats.contains(.flac))
        #expect(formats.contains(.m4a))
        #expect(formats.contains(.ogg))
    }

    // MARK: - Format Validation

    @Test func unsupportedFormatRejectsToNil() {
        var options = AudioFormatConverterOptions()
        options.format = .mp4 // Not in supportedOutputFormats
        #expect(options.format == nil)
    }

    @Test func supportedFormatAccepted() {
        var options = AudioFormatConverterOptions()
        options.format = .wav
        #expect(options.format == .wav)
    }

    // MARK: - Bit Depth Clamping

    @Test func bitsPerChannelClampedToLower() {
        var options = AudioFormatConverterOptions()
        options.bitsPerChannel = 8 // Below min of 16
        #expect(options.bitsPerChannel == 16)
    }

    @Test func bitsPerChannelClampedToUpper() {
        var options = AudioFormatConverterOptions()
        options.bitsPerChannel = 64 // Above max of 32
        #expect(options.bitsPerChannel == 32)
    }

    @Test func bitsPerChannelValidValue() {
        var options = AudioFormatConverterOptions()
        options.bitsPerChannel = 24
        #expect(options.bitsPerChannel == 24)
    }

    @Test func bitsPerChannelNil() {
        let options = AudioFormatConverterOptions()
        #expect(options.bitsPerChannel == nil)
    }

    // MARK: - Bit Rate Clamping

    @Test func bitRateClampedToLower() {
        var options = AudioFormatConverterOptions()
        options.bitRate = 1000 // Below min of 64000
        #expect(options.bitRate == 64000)
    }

    @Test func bitRateClampedToUpper() {
        var options = AudioFormatConverterOptions()
        options.bitRate = 1_000_000 // Above max of 320000
        #expect(options.bitRate == 320_000)
    }

    @Test func bitRateDefault() {
        let options = AudioFormatConverterOptions()
        #expect(options.bitRate == 256_000)
    }

    // MARK: - PCM Format Init

    @Test func pcmFormatInitWav() throws {
        let options = try AudioFormatConverterOptions(
            pcmFormat: .wav,
            sampleRate: 44100,
            bitsPerChannel: 24,
            channels: 2
        )

        #expect(options.format == .wav)
        #expect(options.sampleRate == 44100)
        #expect(options.bitsPerChannel == 24)
        #expect(options.channels == 2)
    }

    @Test func pcmFormatInitRejectsNonPCM() {
        #expect(throws: Error.self) {
            try AudioFormatConverterOptions(pcmFormat: .mp3)
        }
    }

    // MARK: - BitDepthRule

    @Test func bitDepthRuleDefault() {
        let options = AudioFormatConverterOptions()
        #expect(options.bitDepthRule == .any)
    }

    @Test func bitDepthRuleCodableRoundTrip() throws {
        for rule in [BitDepthRule.lessThanOrEqual, BitDepthRule.any] {
            let data = try JSONEncoder().encode(rule)
            let decoded = try JSONDecoder().decode(BitDepthRule.self, from: data)
            #expect(decoded == rule)
        }
    }

    // MARK: - Codable

    @Test func codableRoundTrip() throws {
        var original = AudioFormatConverterOptions()
        original.format = .wav
        original.sampleRate = 48000
        original.bitsPerChannel = 24
        original.bitRate = 320_000
        original.channels = 2
        original.isInterleaved = true
        original.eraseFile = false
        original.bitDepthRule = .lessThanOrEqual

        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(AudioFormatConverterOptions.self, from: data)

        #expect(decoded == original)
    }

    @Test func codableNilOptionals() throws {
        let original = AudioFormatConverterOptions()

        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(AudioFormatConverterOptions.self, from: data)

        #expect(decoded.format == nil)
        #expect(decoded.sampleRate == nil)
        #expect(decoded.bitsPerChannel == nil)
        #expect(decoded.channels == nil)
        #expect(decoded.isInterleaved == nil)
    }

    // MARK: - Equatable / Hashable

    @Test func equalityByValue() {
        var a = AudioFormatConverterOptions()
        a.format = .wav
        a.sampleRate = 44100

        var b = AudioFormatConverterOptions()
        b.format = .wav
        b.sampleRate = 44100

        #expect(a == b)
    }

    @Test func inequalityDifferentFormat() {
        var a = AudioFormatConverterOptions()
        a.format = .wav

        var b = AudioFormatConverterOptions()
        b.format = .mp3

        #expect(a != b)
    }

    // MARK: - Init with format

    @Test func initWithFormat() {
        let options = AudioFormatConverterOptions(format: .flac)
        #expect(options.format == .flac)
    }

    // MARK: - Default init

    @Test func defaultInit() {
        let options = AudioFormatConverterOptions()
        #expect(options.format == nil)
        #expect(options.sampleRate == nil)
        #expect(options.bitsPerChannel == nil)
        #expect(options.bitRate == 256_000)
        #expect(options.bitDepthRule == .any)
        #expect(options.channels == nil)
        #expect(options.isInterleaved == nil)
        #expect(options.eraseFile == true)
    }
}

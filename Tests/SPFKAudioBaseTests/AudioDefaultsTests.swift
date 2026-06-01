
import AVFoundation
import Foundation
@testable import SPFKAudioBase
import SPFKBase
import SPFKTesting
import Testing

@Suite(.serialized, .tags(.file))
class AudioDefaultsTests {
    @Test func setters() async throws {
        #expect(await AudioDefaults.shared.sampleRate == 48000)

        await AudioDefaults.shared.update(systemFormat: AVAudioFormat(standardFormatWithSampleRate: 44100, channels: 2)!)
        #expect(await AudioDefaults.shared.sampleRate == 44100)

        await AudioDefaults.shared.update(enforceMinimumSampleRate: true)
        await AudioDefaults.shared.update(systemFormat: AVAudioFormat(standardFormatWithSampleRate: 11025, channels: 2)!)
        #expect(await AudioDefaults.shared.sampleRate == 44100)

        await AudioDefaults.shared.update(enforceMinimumSampleRate: false)
        await AudioDefaults.shared.update(minimumSampleRateSupported: 11025)
        await AudioDefaults.shared.update(systemFormat: AVAudioFormat(standardFormatWithSampleRate: 11025, channels: 2)!)
        #expect(await AudioDefaults.shared.sampleRate == 11025)

        await AudioDefaults.shared.update(enforceMinimumSampleRate: true)
        await AudioDefaults.shared.update(systemFormat: AVAudioFormat(standardFormatWithSampleRate: AudioDefaults.defaultFormat.sampleRate, channels: 2)!)
        #expect(await AudioDefaults.shared.sampleRate == 48000)
    }
}

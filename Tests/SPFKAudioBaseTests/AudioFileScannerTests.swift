import Accelerate
import AVFoundation
import Foundation
import Numerics
import SPFKBase
import SPFKTesting
import Testing

@testable import SPFKAudioBase

@Suite(.tags(.file))
struct AudioFileScannerTests {
    @Test func scan() async throws {
        let url = TestBundleResources.shared.cowbell_wav

        let scanner = AudioFileScanner(
            bufferDuration: 0.2,
            sendPeriodicProgressEvery: 1,
            eventHandler: eventHandler(_:)
        )

        try await scanner.process(url: url)
    }

    func eventHandler(_ event: AudioFileScannerEvent) async {
        switch event {
        case let .progress(url: url, value: value):
            Log.debug("progress \(url.lastPathComponent) \(value)")

        case let .periodicProgress(url: url, value: value):
            Log.debug("▶ periodicProgress \(url.lastPathComponent) \(value)")

        case let .data(format: format, length: length, samples: samples):
            let channelCount = Int(format.channelCount)
            var rms: Float = 0.0

            // do something with the samples...
            for n in 0 ..< channelCount {
                var channelRms: Float = 0.0
                vDSP_rmsqv(samples[n], 1, &channelRms, vDSP_Length(length))
                rms += abs(channelRms)
            }

            let value = rms / Float(channelCount)

            Log.debug("RMS \(value)")

        case let .complete(url: url):
            Log.debug("✅ \(url.lastPathComponent)")
        }
    }
}

// Copyright Ryan Francesconi. All Rights Reserved. Revision History at https://github.com/ryanfrancesconi

import AVFoundation
import Foundation
import SPFKBase
import Testing

@testable import SPFKAudioBase

@Suite
final class ChannelOperationTests {
    private let left: [Float] = [0.5, -0.25, 1, 0, 0.125]
    private let right: [Float] = [0.25, 0.75, -1, 0.5, 0]

    private func makeBuffer(_ channels: [[Float]]) throws -> AVAudioPCMBuffer {
        let layout = try #require(AVAudioChannelLayout(layoutTag: kAudioChannelLayoutTag_DiscreteInOrder | AudioChannelLayoutTag(channels.count)))
        let format = AVAudioFormat(standardFormatWithSampleRate: 48000, channelLayout: layout)
        let buffer = try #require(AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(channels[0].count)))
        buffer.frameLength = AVAudioFrameCount(channels[0].count)
        let data = try #require(buffer.floatChannelData)
        for (ch, samples) in channels.enumerated() {
            for (i, sample) in samples.enumerated() {
                data[ch][i] = sample
            }
        }
        return buffer
    }

    private func samples(_ buffer: AVAudioPCMBuffer) -> [[Float]] {
        guard let data = buffer.floatChannelData else { return [] }
        return (0 ..< Int(buffer.format.channelCount)).map { ch in
            Array(UnsafeBufferPointer(start: data[ch], count: Int(buffer.frameLength)))
        }
    }

    private func apply(_ operation: ChannelOperation) throws -> [[Float]] {
        try samples(makeBuffer([left, right]).applyingChannelOperation(operation))
    }

    // MARK: - Formulas

    @Test func swapExchangesChannels() throws {
        #expect(try apply(.swap) == [right, left])
    }

    @Test func monoAverageIsHalfTheSum() throws {
        #expect(try apply(.mono(.average)) == [zip(left, right).map { ($0 + $1) / 2 }])
    }

    @Test func monoLeftAndRightKeepOneChannel() throws {
        #expect(try apply(.mono(.left)) == [left])
        #expect(try apply(.mono(.right)) == [right])
    }

    @Test func monoCasesReturnOneChannel() throws {
        for source in MonoSource.allCases {
            let output = try makeBuffer([left, right]).applyingChannelOperation(.mono(source))
            #expect(output.format.channelCount == 1)
            #expect(output.frameLength == AVAudioFrameCount(left.count))
        }
    }

    @Test func encodeIsHalfSumAndHalfDifference() throws {
        #expect(try apply(.midSideEncode) == [
            zip(left, right).map { ($0 + $1) / 2 },
            zip(left, right).map { ($0 - $1) / 2 },
        ])
    }

    @Test func decodeAppliesWidthToSide() throws {
        let w: Float = 1.5
        #expect(try apply(.midSideDecode(width: w)) == [
            zip(left, right).map { $0 + w * $1 },
            zip(left, right).map { $0 - w * $1 },
        ])
    }

    @Test func decodeAtZeroWidthIsMidOnBothSides() throws {
        #expect(try apply(.midSideDecode(width: 0)) == [left, left])
    }

    @Test func encodeThenDecodeAtUnitWidthIsIdentity() throws {
        let encoded = try makeBuffer([left, right]).applyingChannelOperation(.midSideEncode)
        let decoded = try samples(encoded.applyingChannelOperation(.midSideDecode(width: 1)))
        #expect(decoded == [left, right])
    }

    @Test func noneReturnsSelfForAnyWidth() throws {
        let mono = try makeBuffer([left])
        #expect(try mono.applyingChannelOperation(.none) === mono)
    }

    @Test(arguments: [ChannelOperation.swap, .mono(.average), .midSideEncode, .midSideDecode(width: 1)])
    func nonStereoBufferThrows(operation: ChannelOperation) throws {
        let mono = try makeBuffer([left])
        #expect(throws: (any Error).self) { try mono.applyingChannelOperation(operation) }
        let three = try makeBuffer([left, right, left])
        #expect(throws: (any Error).self) { try three.applyingChannelOperation(operation) }
    }

    // MARK: - Pipeline

    @Test func sourceStagesApplyChannelsAfterTrim() throws {
        let buffer = try makeBuffer([left, right])
        let frame = 1 / buffer.format.sampleRate
        let edit = AudioEditDescription(trim: TrimDescription(inPoint: frame, outPoint: 4 * frame), channels: .swap)
        #expect(try samples(buffer.applyingSourceStages(edit)) == [Array(right[1 ..< 4]), Array(left[1 ..< 4])])
    }

    @Test func monoEditRendersOneChannelThroughApplying() throws {
        let edit = AudioEditDescription(channels: .mono(.right), normalize: NormalizeDescription(gain: 2))
        #expect(try samples(makeBuffer([left, right]).applying(edit)) == [right.map { $0 * 2 }])
    }

    // MARK: - Description

    @Test func isEmptyCoversChannels() {
        #expect(AudioEditDescription().isEmpty)
        #expect(!AudioEditDescription(channels: .swap).isEmpty)
        #expect(AudioEditDescription(channels: .swap).needsCeiling)
        #expect(!AudioEditDescription(normalize: NormalizeDescription(gain: 4)).needsCeiling)
    }

    @Test func descriptionWithoutChannelsDecodesNone() throws {
        let json = #"{"trim":{"inPoint":1,"outPoint":2}}"#
        let decoded = try JSONDecoder().decode(AudioEditDescription.self, from: Data(json.utf8))
        #expect(decoded.channels == .none)
        #expect(decoded.trim.inPoint == 1)
    }

    @Test(arguments: [
        ChannelOperation.none, .swap, .mono(.average), .mono(.left), .mono(.right),
        .midSideDecode(width: 0.35), .midSideEncode,
    ])
    func codableRoundTrip(operation: ChannelOperation) throws {
        let edit = AudioEditDescription(channels: operation)
        let data = try JSONEncoder().encode(edit)
        #expect(try JSONDecoder().decode(AudioEditDescription.self, from: data) == edit)

        var stored = ChannelOperation.none
        stored.kindName = operation.kindName
        stored.width = operation.width
        #expect(stored == operation)
    }

    @Test func unknownKindReadsAsNone() throws {
        var operation = ChannelOperation.swap
        operation.kindName = "quadraphonic"
        #expect(operation == .none)

        let json = #"{"kind":"quadraphonic"}"#
        #expect(try JSONDecoder().decode(ChannelOperation.self, from: Data(json.utf8)) == .none)
    }

    @Test func pendingOperationWinsOverMidSide() {
        #expect(ChannelOperation.effective(pending: .none, isMidSide: false) == .none)
        #expect(ChannelOperation.effective(pending: .none, isMidSide: true) == .midSideDecode(width: 1))
        #expect(ChannelOperation.effective(pending: .midSideDecode(width: 0.5), isMidSide: true) == .midSideDecode(width: 0.5))
        #expect(ChannelOperation.effective(pending: .mono(.left), isMidSide: true) == .mono(.left))
    }

    // MARK: - Lane names

    @Test func laneNamesFollowEachOperation() {
        let names = ["Boom", "Lav"]
        #expect(ChannelOperation.none.laneNames(from: names) == names)
        #expect(ChannelOperation.swap.laneNames(from: names) == ["Lav", "Boom"])
        #expect(ChannelOperation.mono(.average).laneNames(from: names) == ["Mono"])
        #expect(ChannelOperation.mono(.left).laneNames(from: names) == ["Boom"])
        #expect(ChannelOperation.mono(.right).laneNames(from: names) == ["Lav"])
        #expect(ChannelOperation.midSideDecode(width: 1).laneNames(from: names) == ["L", "R"])
        #expect(ChannelOperation.midSideEncode.laneNames(from: names) == ["M", "S"])
        #expect(ChannelOperation.swap.laneNames(from: ["A", "B", "C"]) == ["A", "B", "C"])
    }

    // MARK: - Render settings

    @Test func renderSettingsMissingFieldDecodesDefault() throws {
        #expect(try JSONDecoder().decode(AudioRenderSettings.self, from: Data("{}".utf8)) == AudioRenderSettings())
        let limit = AudioRenderSettings(ceiling: .limit)
        #expect(try JSONDecoder().decode(AudioRenderSettings.self, from: JSONEncoder().encode(limit)) == limit)
    }
}

// Copyright Ryan Francesconi. All Rights Reserved. Revision History at https://github.com/ryanfrancesconi/spfk-audio-base

import Foundation
import SPFKBase
import Testing

@testable import SPFKAudioBase

@Suite(.tags(.automation))
struct TimelineMappingTests {
    private let rate: Double = 48000

    @Test func rejectsInvalidMappings() {
        #expect(throws: TimelineMapping.ValidationError.invalidRate) {
            try TimelineMapping(renderAnchor: .sample(0), sourceAnchor: 0, rate: 0, renderSampleRate: rate)
        }
        #expect(throws: TimelineMapping.ValidationError.invalidSampleRate) {
            try TimelineMapping(renderAnchor: .sample(0), sourceAnchor: 0, renderSampleRate: .nan)
        }
        #expect(throws: TimelineMapping.ValidationError.invalidSourceAnchor) {
            try TimelineMapping(renderAnchor: .sample(0), sourceAnchor: .infinity, renderSampleRate: rate)
        }
        #expect(throws: TimelineMapping.ValidationError.invalidLoop) {
            try TimelineMapping(renderAnchor: .sample(0), sourceAnchor: 0, loop: 1 ..< 1, renderSampleRate: rate)
        }
    }

    @Test func forwardFromTheAnchorAndHeldBeforeIt() throws {
        let mapping = try TimelineMapping(renderAnchor: .sample(1000), sourceAnchor: 2.5, rate: 1.5, renderSampleRate: rate)

        #expect(mapping.position(atRenderSample: 0) == 2.5)
        #expect(mapping.position(atRenderSample: 1000) == 2.5)
        #expect(mapping.position(atRenderSample: 1000 + 48000) == 4)
    }

    @Test func reverseRunsBackwards() throws {
        let mapping = try TimelineMapping(renderAnchor: .sample(0), sourceAnchor: 3, direction: .reverse, renderSampleRate: rate)
        #expect(mapping.position(atRenderSample: 24000) == 2.5)
    }

    @Test func anchorsOnlyTheRenderThreadBindsHaveNoPositionHere() throws {
        let host = try TimelineMapping(renderAnchor: .host(123), sourceAnchor: 0, renderSampleRate: rate)
        let adoption = try TimelineMapping(renderAnchor: .atAdoption, sourceAnchor: 0, renderSampleRate: rate)

        #expect(host.position(atRenderSample: 10) == nil)
        #expect(adoption.position(atRenderSample: 10) == nil)
        #expect(host.position(atRenderSample: 48000, anchorSample: 0) == 1)
    }

    /// One mapping covers every iteration, so the position after many is exact rather than drifted.
    @Test func forwardLoopWrapsOnEveryIteration() throws {
        let loop = 1.0 ..< 1.5
        let mapping = try TimelineMapping(renderAnchor: .sample(0), sourceAnchor: 1.2, loop: loop, renderSampleRate: rate)

        #expect(abs((mapping.position(atRenderSample: 14399) ?? 0) - (1.2 + 14399 / rate)) < 1e-12)
        #expect(mapping.position(atRenderSample: 14400) == 1.0)

        let iterations: Int64 = 10000
        let sample = 14400 + iterations * 24000 + 4800
        #expect(abs((mapping.position(atRenderSample: sample) ?? 0) - 1.1) < 1e-9)

        for s in stride(from: Int64(0), to: 200_000, by: 997) {
            let position = mapping.position(atRenderSample: s) ?? -1
            #expect(loop.contains(position), "sample \(s) at \(position)")
        }
    }

    @Test func reverseLoopWrapsBelowItsStart() throws {
        let loop = 1.0 ..< 1.5
        let mapping = try TimelineMapping(
            renderAnchor: .sample(0), sourceAnchor: 1.2, direction: .reverse, loop: loop, renderSampleRate: rate
        )

        #expect(abs((mapping.position(atRenderSample: 9600) ?? 0) - 1.0) < 1e-12)
        #expect(abs((mapping.position(atRenderSample: 9601) ?? 0) - (1.5 - 1 / rate)) < 1e-9)
        #expect(mapping.position(atRenderSample: 9600 + 24000) == 1.0)

        for s in stride(from: Int64(0), to: 200_000, by: 997) {
            let position = mapping.position(atRenderSample: s) ?? -1
            #expect(loop.contains(position), "sample \(s) at \(position)")
        }
    }
}

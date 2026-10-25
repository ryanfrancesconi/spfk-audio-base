// Copyright Ryan Francesconi. All Rights Reserved. Revision History at https://github.com/ryanfrancesconi/spfk-audio-base

@preconcurrency import AVFoundation
import Foundation
import SPFKBase

extension AVAudioPCMBuffer {
    /// Apply an `AudioEditDescription` to this buffer, returning a new processed buffer.
    ///
    /// The composition of `applyingSourceStages` and `applyingOutputStages`.
    /// Returns `self` unchanged when `edit.isEmpty` is true. Throws for a non-empty `timePitch`: the
    /// stretch runs between the two stages, in `SPFKTempo`, which this package cannot reach.
    /// - Parameter isPreTrimmed: the buffer already holds exactly `edit.trim`'s window, so the
    ///   extract is skipped while the boundaries still get their de-click. For a caller that read
    ///   only the window from disk rather than the whole file.
    public func applying(_ edit: AudioEditDescription, isPreTrimmed: Bool = false) throws -> AVAudioPCMBuffer {
        guard edit.timePitch.isEmpty else {
            throw NSError(description: "A time/pitch edit must be rendered between the source and output stages")
        }
        guard !edit.isEmpty else { return self }

        return try applyingSourceStages(edit, isPreTrimmed: isPreTrimmed)
            .applyingOutputStages(edit)
    }

    /// The stages that select what is rendered: trim, channels, then reverse.
    public func applyingSourceStages(_ edit: AudioEditDescription, isPreTrimmed: Bool = false) throws -> AVAudioPCMBuffer {
        var buffer = self

        if !edit.trim.isEmpty, !isPreTrimmed {
            let start = edit.trim.inPoint
            let end = edit.trim.outPoint > 0 ? edit.trim.outPoint : Double(buffer.frameLength) / buffer.format.sampleRate
            buffer = try buffer.extract(from: start, to: end)
        }

        buffer = try buffer.applyingChannelOperation(edit.channels)
        return edit.isReversed ? try buffer.reverse() : buffer
    }

    /// The stages that shape the rendered signal: normalize gain, then fades.
    ///
    /// A non-empty trim adds a 5 ms de-click at both boundaries, so this stage expects the buffer
    /// `applyingSourceStages` produced for the same edit.
    /// - Parameter timeScale: the rate the buffer was stretched by. Fade times are source seconds, so
    ///   they are divided by it to cover the same material; the de-click stays 5 ms of output.
    ///   A reversed edit applies ``FadeDescription/mirroredForReverse(regionDuration:)``, so each fade
    ///   stays on the material it covered in the source.
    public func applyingOutputStages(_ edit: AudioEditDescription, timeScale: Double = 1) throws -> AVAudioPCMBuffer {
        let deClick: TimeInterval = 0.005

        var buffer = self

        if !edit.normalize.isEmpty {
            buffer = try buffer.gain(edit.normalize.gain)
        }

        // Skipped for buffers too short for non-overlapping de-click fades, which the fade guard would refuse.
        let deClickSamples = Int(buffer.format.sampleRate * deClick)
        let canDeClick = !edit.trim.isEmpty && deClickSamples > 0 && deClickSamples * 2 <= Int(buffer.frameLength)

        let bufferDuration = Double(buffer.frameLength) / buffer.format.sampleRate
        let fade = edit.isReversed
            ? edit.fade.mirroredForReverse(regionDuration: bufferDuration * timeScale)
            : edit.fade

        let scaledIn = fade.inTime / timeScale
        let scaledOut = fade.outTime / timeScale
        var fadeIn = canDeClick ? max(scaledIn, deClick) : scaledIn
        var fadeOut = canDeClick ? max(scaledOut, deClick) : scaledOut

        if fadeIn > 0 || fadeOut > 0 {
            // De-click expansion can push a small fade past the buffer's duration.
            let safe = AudioEditDescription.clampedFades(inTime: fadeIn, outTime: fadeOut, duration: bufferDuration)
            fadeIn = safe.inTime
            fadeOut = safe.outTime
            if fadeIn > 0 || fadeOut > 0 {
                buffer = try buffer.fade(inTime: fadeIn, outTime: fadeOut, inTaper: fade.inTaper, outTaper: fade.outTaper)
            }
        }

        return buffer
    }
}

// Copyright Ryan Francesconi. All Rights Reserved. Revision History at https://github.com/ryanfrancesconi/spfk-audio-base

@preconcurrency import AVFoundation
import Foundation
import SPFKBase

extension AVAudioPCMBuffer {
    /// Apply an `AudioEditDescription` to this buffer, returning a new processed buffer.
    ///
    /// The composition of `applyingSourceStages` and `applyingOutputStages`.
    /// Returns `self` unchanged when `edit.isEmpty` is true.
    /// - Parameter isPreTrimmed: the buffer already holds exactly `edit.trim`'s window, so the
    ///   extract is skipped while the boundaries still get their de-click. For a caller that read
    ///   only the window from disk rather than the whole file.
    public func applying(_ edit: AudioEditDescription, isPreTrimmed: Bool = false) throws -> AVAudioPCMBuffer {
        guard !edit.isEmpty else { return self }

        return try applyingSourceStages(edit, isPreTrimmed: isPreTrimmed)
            .applyingOutputStages(edit)
    }

    /// The stages that select what is rendered: trim.
    public func applyingSourceStages(_ edit: AudioEditDescription, isPreTrimmed: Bool = false) throws -> AVAudioPCMBuffer {
        var buffer = self

        if !edit.trim.isEmpty, !isPreTrimmed {
            let start = edit.trim.inPoint
            let end = edit.trim.outPoint > 0 ? edit.trim.outPoint : Double(buffer.frameLength) / buffer.format.sampleRate
            buffer = try buffer.extract(from: start, to: end)
        }

        return buffer
    }

    /// The stages that shape the rendered signal: normalize gain, then fades.
    ///
    /// A non-empty trim adds a 5 ms de-click at both boundaries, so this stage expects the buffer
    /// `applyingSourceStages` produced for the same edit.
    public func applyingOutputStages(_ edit: AudioEditDescription) throws -> AVAudioPCMBuffer {
        let deClick: TimeInterval = 0.005

        var buffer = self

        if !edit.normalize.isEmpty {
            buffer = try buffer.gain(edit.normalize.gain)
        }

        // Skipped for buffers too short for non-overlapping de-click fades, which the fade guard would refuse.
        let deClickSamples = Int(buffer.format.sampleRate * deClick)
        let canDeClick = !edit.trim.isEmpty && deClickSamples > 0 && deClickSamples * 2 <= Int(buffer.frameLength)

        var fadeIn = canDeClick ? max(edit.fade.inTime, deClick) : edit.fade.inTime
        var fadeOut = canDeClick ? max(edit.fade.outTime, deClick) : edit.fade.outTime

        if fadeIn > 0 || fadeOut > 0 {
            // De-click expansion can push a small fade past the buffer's duration.
            let bufferDuration = Double(buffer.frameLength) / buffer.format.sampleRate
            let safe = AudioEditDescription.clampedFades(inTime: fadeIn, outTime: fadeOut, duration: bufferDuration)
            fadeIn = safe.inTime
            fadeOut = safe.outTime
            if fadeIn > 0 || fadeOut > 0 {
                buffer = try buffer.fade(inTime: fadeIn, outTime: fadeOut, inTaper: edit.fade.inTaper, outTaper: edit.fade.outTaper)
            }
        }

        return buffer
    }
}

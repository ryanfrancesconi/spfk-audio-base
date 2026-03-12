// Originally borrowed from AudioKit.
// Copyright AudioKit. All Rights Reserved. Revision History at http://github.com/AudioKit/AudioKit/

import AVFoundation

// TODO: write unit tests.

extension AVAudioTime {
    /// AVAudioTime.extrapolateTime fails for host time valid times, use
    /// extrapolateTimeShimmed instead. https://bugreport.apple.com/web/?problemID=34249528
    /// - Parameter anchorTime: AVAudioTIme
    public func extrapolateTimeShimmed(fromAnchor anchorTime: AVAudioTime) -> AVAudioTime {
        guard ((isSampleTimeValid && sampleRate == anchorTime.sampleRate) || isHostTimeValid) &&
            !(isSampleTimeValid && isHostTimeValid) &&
            anchorTime.isSampleTimeValid && anchorTime.isHostTimeValid
        else {
            return self
        }

        if isHostTimeValid && anchorTime.isHostTimeValid {
            let secondsDiff = Double(hostTime.safeSubtract(anchorTime.hostTime)) * machTimeSecondsPerTick
            let sampleTime = anchorTime.sampleTime + AVAudioFramePosition(round(secondsDiff * anchorTime.sampleRate))
            let audioTime = AVAudioTime(hostTime: hostTime, sampleTime: sampleTime, atRate: anchorTime.sampleRate)
            return audioTime

        } else {
            let secondsDiff = Double(sampleTime - anchorTime.sampleTime) / anchorTime.sampleRate
            let hostTime = anchorTime.hostTime + secondsDiff / machTimeSecondsPerTick
            return AVAudioTime(hostTime: hostTime, sampleTime: sampleTime, atRate: anchorTime.sampleRate)
        }
    }

    /// An AVAudioTime with a valid hostTime representing now.
    public static func now() -> AVAudioTime {
        AVAudioTime(hostTime: mach_absolute_time())
    }

    /// Returns an AVAudioTime offset by seconds.
    public func offset(seconds: TimeInterval) -> AVAudioTime {
        if isSampleTimeValid && isHostTimeValid {
            return AVAudioTime(hostTime: hostTime + seconds / machTimeSecondsPerTick,
                               sampleTime: sampleTime + AVAudioFramePosition(seconds * sampleRate),
                               atRate: sampleRate)
        } else if isHostTimeValid {
            return AVAudioTime(hostTime: hostTime + seconds / machTimeSecondsPerTick)

        } else if isSampleTimeValid {
            return AVAudioTime(sampleTime: sampleTime + AVAudioFramePosition(seconds * sampleRate),
                               atRate: sampleRate)
        }
        return self
    }

    /// The time in seconds between receiver and otherTime.
    public func timeIntervalSince(otherTime: AVAudioTime) -> Double? {
        if isHostTimeValid, otherTime.isHostTimeValid {
            return Double(hostTime.safeSubtract(otherTime.hostTime)) * machTimeSecondsPerTick
        }
        if isSampleTimeValid, otherTime.isSampleTimeValid {
            return Double(sampleTime - otherTime.sampleTime) / sampleRate
        }
        if isSampleTimeValid, isHostTimeValid {
            let completeTime = otherTime.extrapolateTimeShimmed(fromAnchor: self)
            return Double(sampleTime - completeTime.sampleTime) / sampleRate
        }
        if otherTime.isHostTimeValid, otherTime.isSampleTimeValid {
            let completeTime = extrapolateTimeShimmed(fromAnchor: otherTime)
            return Double(completeTime.sampleTime - otherTime.sampleTime) / sampleRate
        }
        return nil
    }

    /// Convert an AVAudioTime object to seconds with a hostTime reference
    public func toSeconds(hostTime time: UInt64) -> Double {
        guard isHostTimeValid else { return 0 }
        return AVAudioTime.seconds(forHostTime: hostTime - time)
    }

    /// Convert seconds to AVAudioTime with a hostTime reference -- time must be > 0
    @objc open class func secondsToAudioTime(hostTime: UInt64, time: Double) -> AVAudioTime {
        // Find the conversion factor from host ticks to seconds
        var timebaseInfo = mach_timebase_info()
        mach_timebase_info(&timebaseInfo)
        let hostTimeToSecFactor = Double(timebaseInfo.numer) / Double(timebaseInfo.denom) / Double(NSEC_PER_SEC)
        let out = AVAudioTime(hostTime: hostTime + UInt64(time / hostTimeToSecFactor))
        return out
    }
}

/// Addition
/// - Parameters:
///   - left: Left Hand Side
///   - right: Right Hand Side
public func + (left: AVAudioTime, right: TimeInterval) -> AVAudioTime {
    left.offset(seconds: right)
}

/// Addition
/// - Parameters:
///   - left: Left Hand Side
///   - right: Right Hand Side
public func + (left: AVAudioTime, right: Int) -> AVAudioTime {
    left.offset(seconds: TimeInterval(right))
}

/// Subtraction
/// - Parameters:
///   - left: Left Hand Side
///   - right: Right Hand Side
public func - (left: AVAudioTime, right: TimeInterval) -> AVAudioTime {
    left.offset(seconds: -right)
}

/// Subtraction
/// - Parameters:
///   - left: Left Hand Side
///   - right: Right Hand Side
public func - (left: AVAudioTime, right: Int) -> AVAudioTime {
    left.offset(seconds: TimeInterval(-right))
}

extension UInt64 {
    fileprivate func safeSubtract(_ other: UInt64) -> Int64 {
        self > other ? Int64(self - other) : -Int64(other - self)
    }

    fileprivate static func + (left: UInt64, right: Double) -> UInt64 {
        right >= 0 ? left + UInt64(right) : left - UInt64(-right)
    }
}

import AudioToolbox
import AVFoundation
@testable import SPFKAudioBase
import Testing

@Suite("AudioComponentDescription Extensions")
struct AudioComponentDescriptionTests {
    @Test("wildcard has all zero fields")
    func wildcard() {
        let w = AudioComponentDescription.wildcard
        #expect(w.componentType == 0)
        #expect(w.componentSubType == 0)
        #expect(w.componentManufacturer == 0)
    }

    @Test("matches compares type, subType, manufacturer")
    func matches() {
        let a = AudioComponentDescription(
            componentType: kAudioUnitType_Effect,
            componentSubType: 0x64656c79, // 'dely'
            componentManufacturer: 0x6170706c, // 'appl'
            componentFlags: 0,
            componentFlagsMask: 0
        )
        let b = AudioComponentDescription(
            componentType: kAudioUnitType_Effect,
            componentSubType: 0x64656c79,
            componentManufacturer: 0x6170706c,
            componentFlags: 1, // different flags
            componentFlagsMask: 1
        )
        #expect(a.matches(b))
    }

    @Test("matches returns false for different types")
    func matchesDifferent() {
        let a = AudioComponentDescription(
            componentType: kAudioUnitType_Effect,
            componentSubType: 0x64656c79,
            componentManufacturer: 0x6170706c,
            componentFlags: 0,
            componentFlagsMask: 0
        )
        let b = AudioComponentDescription(
            componentType: kAudioUnitType_Generator,
            componentSubType: 0x64656c79,
            componentManufacturer: 0x6170706c,
            componentFlags: 0,
            componentFlagsMask: 0
        )
        #expect(!a.matches(b))
    }

    @Test("isEffect for effect types")
    func isEffect() {
        let effect = AudioComponentDescription(
            componentType: kAudioUnitType_Effect,
            componentSubType: 0, componentManufacturer: 0,
            componentFlags: 0, componentFlagsMask: 0
        )
        #expect(effect.isEffect)
        #expect(effect.supportsIO)
        #expect(!effect.isMusicDevice)
        #expect(!effect.isGenerator)
    }

    @Test("isMusicDevice")
    func isMusicDevice() {
        let synth = AudioComponentDescription(
            componentType: kAudioUnitType_MusicDevice,
            componentSubType: 0, componentManufacturer: 0,
            componentFlags: 0, componentFlagsMask: 0
        )
        #expect(synth.isMusicDevice)
        #expect(!synth.isEffect)
    }

    @Test("isGenerator")
    func isGenerator() {
        let gen = AudioComponentDescription(
            componentType: kAudioUnitType_Generator,
            componentSubType: 0, componentManufacturer: 0,
            componentFlags: 0, componentFlagsMask: 0
        )
        #expect(gen.isGenerator)
        #expect(!gen.isEffect)
    }

    @Test("isFormatConverter")
    func isFormatConverter() {
        let conv = AudioComponentDescription(
            componentType: kAudioUnitType_FormatConverter,
            componentSubType: 0, componentManufacturer: 0,
            componentFlags: 0, componentFlagsMask: 0
        )
        #expect(conv.isFormatConverter)
        #expect(conv.supportsIO)
    }

    // MARK: - UID

    @Test("uid produces 24-character hex string")
    func uid() {
        let desc = AudioComponentDescription(
            componentType: 0x61756678, // 'aufx'
            componentSubType: 0x64656c79, // 'dely'
            componentManufacturer: 0x6170706c, // 'appl'
            componentFlags: 0,
            componentFlagsMask: 0
        )
        #expect(desc.uid.count == 24)
    }

    @Test("uid round-trip")
    func uidRoundTrip() {
        let original = AudioComponentDescription(
            componentType: 0x61756678,
            componentSubType: 0x64656c79,
            componentManufacturer: 0x6170706c,
            componentFlags: 0,
            componentFlagsMask: 0
        )

        let uid = original.uid
        let restored = AudioComponentDescription(uid: uid)
        #expect(restored != nil)
        #expect(restored!.matches(original))
    }

    @Test("init from uid with 0x prefix")
    func initFromUIDWithPrefix() {
        let desc = AudioComponentDescription(uid: "0x617566786170706c6170706c")
        #expect(desc != nil)
    }

    @Test("init from uid with label prefix")
    func initFromUIDWithLabel() {
        let desc = AudioComponentDescription(uid: "AudioUnit: 0x617566786170706c6170706c")
        #expect(desc != nil)
    }

    @Test("init from invalid uid returns nil")
    func initInvalidUID() {
        #expect(AudioComponentDescription(uid: "short") == nil)
        #expect(AudioComponentDescription(uid: "zzzzzzzzzzzzzzzzzzzzzzzz") == nil)
    }
}

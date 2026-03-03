import Foundation
@testable import SPFKAudioBase
import SPFKBase
import Testing

@Suite("Constants")
struct ConstantsTests {
    @Test("FourCharCode constants are non-zero")
    func fourCharCodeConstants() {
        #expect(kAudioUnitManufacturer_Spongefork != 0)
        #expect(kAudioUnitManufacturer_AudioKit != 0)
    }
}

import Foundation
@testable import SPFKAudioBase
import Testing

@Suite("URLProgressEvent")
struct URLProgressEventTests {
    @Test("progress case returns value")
    func progressValue() {
        let url = URL(fileURLWithPath: "/tmp/test.wav")
        let event = URLProgressEvent.progress(url: url, value: 0.5)
        #expect(event.progress == 0.5)
    }

    @Test("complete case returns 1")
    func completeValue() {
        let url = URL(fileURLWithPath: "/tmp/test.wav")
        let event = URLProgressEvent.complete(url: url)
        #expect(event.progress == 1)
    }
}

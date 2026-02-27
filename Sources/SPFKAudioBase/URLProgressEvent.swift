import Foundation
import SPFKBase

public typealias URLProgressEventHandler = @Sendable (URLProgressEvent) async -> Void

public enum URLProgressEvent: Sendable {
    case progress(url: URL, value: UnitInterval)
    case complete(url: URL)

    public var progress: UnitInterval {
        switch self {
        case let .progress(url: _, value: progress):
            progress

        case .complete:
            1
        }
    }
}

import Foundation

public enum FileConflictScheme: Int, Codable, Hashable, Sendable, CaseIterable {
    /// delete the existing file
    case overwrite = 0

    /// rename the new file with a unique suffix such as _1
    case unique

    /// throws an error indicating the file exists
    case error

    public var displayName: String {
        switch self {
        case .overwrite: String(localized: "Overwrite Files", bundle: .module)
        case .error: String(localized: "Show Errors", bundle: .module)
        case .unique: String(localized: "Rename Uniquely", bundle: .module)
        }
    }

    public init?(displayName: String) {
        for item in Self.allCases where item.displayName == displayName {
            self = item
            return
        }

        return nil
    }
}

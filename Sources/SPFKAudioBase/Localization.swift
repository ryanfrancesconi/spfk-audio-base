// Copyright Ryan Francesconi. All Rights Reserved.

import Foundation

/// Looks up a localized string from the default (Localizable) table in this module's bundle.
func localized(_ key: String.LocalizationValue) -> String {
    String(localized: key, bundle: .module)
}

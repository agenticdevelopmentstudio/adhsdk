import Foundation
import AgenticDeveloperHubSDKCore

@MainActor
extension UserSettings {

    /// How many days an archived notation is kept before a reconcile may
    /// delete it — and then only once no ref with its branch name and fork
    /// point exists, locally or on origin.
    public static let notationsArchivedRetentionDays = UserSetting<Int>(
        "notations.archived_retention_days", default: 30)
}

/// The range Settings accepts for `UserSettings.notationsArchivedRetentionDays`.
public enum NotationsRetention {
    public static let range = 1...3_650
}

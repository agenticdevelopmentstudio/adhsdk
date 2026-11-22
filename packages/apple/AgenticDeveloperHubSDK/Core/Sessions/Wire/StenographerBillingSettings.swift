import Foundation

extension Sessions {

    /// Stenographer's half of the shared billing feature: the one value both of
    /// its processes must agree on. The app writes its billing knobs under this
    /// prefix and pushes them; the daemon reads its settings table under it.
    /// Everything else about billing — the DTOs, the keys built from the prefix,
    /// the logic — is in `AgenticDeveloperHubSDKCore`.
    public enum StenographerBilling {
        /// `BillingSettingsKeys(prefix:)` for Stenographer's settings table.
        public static let settingsKeyPrefix = "stenographer_billing_"
    }
}

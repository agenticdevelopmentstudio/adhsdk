import Foundation
import AgenticDeveloperHubSDKCore

extension ComposableSettings {

    /// The back/forward trail behind the `‹ ›` control in the settings toolbar:
    /// the shared `NavigationHistory`, walking panel *indices*.
    public typealias SettingsNavigationHistory = NavigationHistory<Int>
}

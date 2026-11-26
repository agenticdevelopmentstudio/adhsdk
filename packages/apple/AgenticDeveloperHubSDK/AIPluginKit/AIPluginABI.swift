import Foundation

/// The binary contract between a host and the `.aiplugin` bundles it loads.
///
/// A plugin links the host's one copy of AIPluginKit, which is not built for
/// library evolution, so a plugin built against other type layouts can crash
/// the host the first time a shared type crosses between them. Each plugin's
/// build therefore writes `version` into its Info.plist under `infoPlistKey`
/// (`AIPlugins/tools/stamp_plugin_abi.py` reads it from this file), and the
/// plugin manager refuses a bundle whose stamp is missing or different before
/// it loads any of its code.
///
/// Bump `version` whenever a type a plugin shares with the host changes shape:
/// `AIPlugin`, `AIRequestSpec`, `AIStreamEvent`, `AIChatContext`,
/// `AIPluginConfig`, the descriptor types. The stamp script parses the
/// `version` line below, so keep it a plain integer literal.
public enum AIPluginABI {

    /// The ABI this build of AIPluginKit has.
    public static let version = 1

    /// The Info.plist key a plugin's ABI stamp is written under.
    public static let infoPlistKey = "AIPluginKitABIVersion"

    /// Why a bundle cannot be loaded by this host, or nil when its stamp
    /// matches. Reads the bundle's Info.plist only; no code is loaded.
    /// - Parameter name: how the message names the plugin.
    public static func incompatibility(of bundle: Bundle, name: String) -> String? {
        incompatibility(stamp: bundle.object(forInfoDictionaryKey: infoPlistKey), name: name)
    }

    /// The message for an Info.plist value read under `infoPlistKey`, or nil
    /// when it is an integer equal to `version`.
    public static func incompatibility(stamp: Any?, name: String) -> String? {
        guard let number = stamp as? NSNumber, CFGetTypeID(number) == CFNumberGetTypeID(),
              let built = Int(exactly: number.doubleValue) else {
            return "Plugin '\(name)' has no AIPluginKit ABI stamp (\(infoPlistKey)); "
                + "rebuild it against this AIPluginKit"
        }
        guard built == version else {
            return "Plugin '\(name)' was built against AIPluginKit ABI \(built), "
                + "but this host has ABI \(version); rebuild the plugin"
        }
        return nil
    }

    #if DEBUG
    /// Test-only: writes `stamp` (nil removes it) under `infoPlistKey` into the
    /// `Contents/Info.plist` of the bundle at `url`, creating the file when it
    /// is absent and keeping its other keys, so a fixture bundle passes (or
    /// fails) the stamp check the way a built plugin would.
    public static func stampForTesting(bundleAt url: URL, stamp: Int? = version) throws {
        let contents = url.appendingPathComponent("Contents", isDirectory: true)
        try FileManager.default.createDirectory(at: contents, withIntermediateDirectories: true)
        let plistURL = contents.appendingPathComponent("Info.plist")
        var plist: [String: Any] = [:]
        if let data = try? Data(contentsOf: plistURL),
           let existing = try PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any] {
            plist = existing
        }
        plist[infoPlistKey] = stamp
        try PropertyListSerialization.data(fromPropertyList: plist, format: .xml, options: 0).write(to: plistURL)
    }
    #endif
}

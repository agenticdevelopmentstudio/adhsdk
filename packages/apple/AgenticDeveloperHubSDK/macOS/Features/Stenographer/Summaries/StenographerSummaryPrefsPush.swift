import Foundation
import OSLog
import AgenticDeveloperHubSDKCore

/// The single owner of the "AI summaries → daemon" contract.
///
/// Each feature that summarizes (``SummaryFeature``) has its own AI Summaries
/// pane, editing its own ``SummaryFeatureSettings``: the switch, the provider
/// selection and seven tuning prefs. One set of observers per feature lives
/// here; on any change, at startup and on every daemon reconnect that feature's
/// full idempotent snapshot is pushed through `POST /preferences/summaries`
/// with the feature named. The engine is Core's `SettingsSnapshotPush`.
///
/// AI Conversations and Coding Projects start as a copy of Sessions' settings
/// (``SummaryFeatureSettings/seed(from:)``), taken once, before their first push.
///
/// **The first push is preceded by a one-time seed.** The daemon holds the only
/// copy of what the user chose before these panes moved to a new app, so a store
/// that has not yet been seeded reads `GET /preferences/summaries` and writes
/// every field into its settings before the observers are installed and the
/// first snapshot goes out. If the daemon is down, nothing is pushed until a
/// reconnect lets the seed run.
@MainActor
public enum StenographerSummaryPrefsPush {

    private static var pushes: [SettingsSnapshotPush] = []

    /// Installs the observers and reconciles the daemon now and on every
    /// reconnect. Call once at startup.
    public static func startObserving(service: any StenographerDaemonService) {
        guard pushes.isEmpty else {
            logger.warning("startObserving called more than once; ignoring the repeat call")
            return
        }
        for settings in SummaryFeatureSettings.all {
            pushes.append(startPush(settings, service: service))
        }
    }

    private static func startPush(
        _ settings: SummaryFeatureSettings, service: any StenographerDaemonService
    ) -> SettingsSnapshotPush {
        let sessions = SummaryFeatureSettings.for(.sessions)
        let engine = SettingsSnapshotPush(
            label: "Summary prefs (\(settings.feature.rawValue))",
            logger: logger,
            snapshot: { currentBody(settings) },
            send: { body in
                guard let request = try? StenographerWire.decoder().decode(
                    SummaryPreferenceRequest.self, from: body
                ) else { return false }
                return await service.setSummaryPreferences(request)
            },
            registerReconnect: { service.onReconnect($0) },
            seed: {
                if settings.feature == .sessions { return await seedFromDaemon(service: service) }
                // Sessions' own values come from the daemon first, so the copy is of them.
                guard await seedFromDaemon(service: service) else { return false }
                settings.seed(from: sessions)
                return true
            }
        )
        engine.start { onChange -> [AnyObject] in
            let strings: [AnyObject] = [settings.prompt, settings.providerConfigId, settings.model]
                .map { setting in UserSettingObserver(setting) { _ in onChange() } }
            let bools: [AnyObject] = [UserSettingObserver(settings.enabled) { _ in onChange() }]
            let ints: [AnyObject] = [
                settings.maxWords, settings.activityLines, settings.detailChars,
                settings.intervalMinutes, settings.maxPerRun, settings.timeoutSeconds
            ].map { setting in UserSettingObserver(setting) { _ in onChange() } }
            return strings + bools + ints
        }
        return engine
    }

    /// Takes the daemon's stored values into the local settings once (marker
    /// `stenographerAISummariesSeededFromDaemon`). True when the store is now
    /// current or needs no seeding; false when the daemon could not be reached.
    static func seedFromDaemon(service: any StenographerDaemonService) async -> Bool {
        if UserSettings.stenographerAISummariesSeededFromDaemon.value { return true }
        guard let stored = await service.summaryPreferences() else { return false }
        // An older daemon's reply carries neither; leave the local value as it is then.
        if let enabled = stored.enabled { UserSettings.stenographerAISummariesEnabled.value = enabled }
        if let selected = stored.selectedConfigId {
            UserSettings.stenographerAISummariesProviderConfigId.value = selected
        }
        if let model = stored.model { UserSettings.stenographerAISummariesModel.value = model }
        // An unmodified (or never configured) prompt stays at the default, which
        // is not stored, so a later release's wording still applies.
        if stored.prompt.isEmpty || stored.prompt == SummaryDefaults.prompt {
            UserSettings.stenographerAISummaryPrompt.remove()
        } else {
            UserSettings.stenographerAISummaryPrompt.value = stored.prompt
        }
        UserSettings.stenographerAISummaryMaxWords.value = stored.maxWords
        UserSettings.stenographerAISummaryActivityLines.value = stored.activityLines
        UserSettings.stenographerAISummaryDetailChars.value = stored.detailChars
        UserSettings.stenographerAISummaryIntervalMinutes.value = stored.intervalMinutes
        UserSettings.stenographerAISummaryMaxPerRun.value = stored.maxPerRun
        UserSettings.stenographerAISummaryTimeoutSeconds.value = stored.timeoutSeconds
        UserSettings.stenographerAISummariesSeededFromDaemon.value = true
        return true
    }

    /// Tears the observers down (test isolation; production installs once).
    public static func stopObserving() {
        pushes.forEach { $0.stop() }
        pushes = []
    }

    /// Awaits the most recent push of every feature (test-only determinism hook).
    public static func awaitPendingPush() async {
        for push in pushes { await push.awaitPendingPush() }
    }

    /// The full snapshot the daemon receives — pure so it is unit-testable.
    /// Values travel as the user set them; the daemon clamps through `SummaryLimits`.
    static func makeRequest(
        enabled: Bool, selectedConfigId: String, prompt: String, maxWords: Int, activityLines: Int,
        detailChars: Int, intervalMinutes: Int, maxPerRun: Int, timeoutSeconds: Int, model: String = "",
        feature: SummaryFeature? = nil
    ) -> SummaryPreferenceRequest {
        SummaryPreferenceRequest(
            enabled: enabled, selectedConfigId: selectedConfigId, prompt: prompt, maxWords: maxWords,
            activityLines: activityLines, detailChars: detailChars, intervalMinutes: intervalMinutes,
            maxPerRun: maxPerRun, timeoutSeconds: timeoutSeconds, model: model,
            // Sessions travels without the field, which every daemon reads as Sessions.
            feature: feature == .sessions ? nil : feature)
    }

    private static func currentBody(_ settings: SummaryFeatureSettings) -> Data? {
        // An unmodified prompt travels blank: the daemon reads a blank prompt as
        // "never configured" and uses its own `SummaryDefaults.prompt`, so a
        // future release's wording applies instead of this build's copy being
        // pinned on the daemon side forever.
        let prompt = settings.prompt.value
        let request = makeRequest(
            enabled: settings.enabled.value,
            selectedConfigId: settings.providerConfigId.value,
            prompt: prompt == SummaryDefaults.prompt ? "" : prompt,
            maxWords: settings.maxWords.value,
            activityLines: settings.activityLines.value,
            detailChars: settings.detailChars.value,
            intervalMinutes: settings.intervalMinutes.value,
            maxPerRun: settings.maxPerRun.value,
            timeoutSeconds: settings.timeoutSeconds.value,
            model: settings.model.value,
            feature: settings.feature
        )
        return try? StenographerWire.encoder().encode(request)
    }
}

extension StenographerSummaryPrefsPush: Loggable {
    public static nonisolated let logger = makeLogger()
}

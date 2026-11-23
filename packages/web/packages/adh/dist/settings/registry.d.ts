import { type Topic } from "@adh-sdk/account";
import { type SettingsTopicId } from "@adh-sdk/adh/settings/topics";
/** The settings sections (Account, Subscription, Profile) as master-detail
 *  topics — each leads with a gold title and carries its own panel + button bar.
 *  Shared by hub's /settings route and the User Settings overlay every site mounts.
 *  `hidden` leaves sections out of the rail; `useSettingsTopics` is the live answer. */
export declare function buildSettingsTopics({ hidden }?: {
    hidden?: ReadonlySet<SettingsTopicId>;
}): Topic[];
/**
 * The settings topics, less any section the backend says is not there. Today that is Support
 * access alone: hidden when `/v1/account/support/grants` answers 404, which is the backend's
 * `consented_access` switch being off. Shown while the read is in flight or failed any other
 * way, so the tab is never hidden by a slow or broken network, and the pane then says what failed.
 */
export declare function useSettingsTopics(): Topic[];
/**
 * The topic to show: `id` while it is among `topics`, else the default. A hidden topic (Support
 * access with its switch off) can still be asked for, by `/settings/support-access` or by the
 * overlay having been on it when the read answered 404; SettingsLayout finds no topic for that
 * id and renders an empty pane, so the caller lands on the default instead.
 */
export declare function visibleTopicId(topics: readonly Topic[], id: string): string;
/**
 * The User Settings tab, rendered as a routed page — used by hub's own /settings, and
 * kept available here for any other host that wants a standalone route rather than the
 * overlay. Builds its own SettingsDirtyProvider so a dirty panel is caught even under no
 * workspace chrome; the overlay (UserSettingsOverlay.tsx) wraps its own instance around
 * this same buildSettingsTopics() list instead of rendering this component, so the dirty
 * registry and the dialog frame are scoped to one mount.
 */
export declare function SettingsTab({ activeTopic }: {
    activeTopic?: string;
}): import("react").JSX.Element;
//# sourceMappingURL=registry.d.ts.map
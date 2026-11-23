// @adh-sdk/ai-settings — the AI Settings feature: a workspace's AI service connections
// (connect, refresh models, edit, delete) and a per-model Available switch. Carved out of
// @adh-sdk/personas in phase 8; the personas package re-exports ServicesSection,
// useUserServices and PERSONA_SERVICES_CACHE_KEY from here until Cleanup removes them.
export { AiSettingsSection } from "./AiSettingsSection";
export { ServicesSection } from "./ServicesSection";
// The caller's services, one cache entry shared with the persona editor's service picker. The
// key keeps its name and its value "persona-services": the admin config-set services hook
// writes the same entry without this hook.
export { PERSONA_SERVICES_CACHE_KEY, useUserServices } from "./useUserServices";

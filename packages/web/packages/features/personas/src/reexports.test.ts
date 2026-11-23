// The services screen moved to @adh-sdk/ai-settings in phase 8; personas re-exports it until
// Cleanup, so existing imports keep working. The re-exports must be the SAME objects, not copies,
// and the cache key keeps its value: the admin config-set services hook writes "persona-services"
// on its own (recipe adhsdk.ingredient.adh.hub.personas, services-cache-key-unchanged).
import { describe, it, expect } from "vitest";
import * as aiSettings from "@adh-sdk/ai-settings";
import * as personas from "./index";

describe("personas re-exports the AI Settings services screen", () => {
  it("hands out the same objects as @adh-sdk/ai-settings", () => {
    expect(personas.ServicesSection).toBe(aiSettings.ServicesSection);
    expect(personas.useUserServices).toBe(aiSettings.useUserServices);
    expect(personas.PERSONA_SERVICES_CACHE_KEY).toBe(aiSettings.PERSONA_SERVICES_CACHE_KEY);
  });

  it("keeps the services cache key's value", () => {
    expect(aiSettings.PERSONA_SERVICES_CACHE_KEY).toBe("persona-services");
  });
});

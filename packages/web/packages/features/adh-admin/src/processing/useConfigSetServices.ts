"use client";

import { useResourceList, type ResourceList } from "@adh-sdk/data";
import { api, type UserService } from "@adh-sdk/data/personas";

/**
 * The signed-in admin's own LLM services — the pick list for a config set's "service".
 *
 * The same read, under the same cache key, as the personas feature's `useUserServices` (the
 * persona editor's service picker): a service created in one place appears in the other without a
 * second request. It is re-declared rather than imported because `@adh-sdk/personas` is a
 * sibling feature, and features do not depend on features; `@adh-sdk/data` is the lower
 * tier both read the list from.
 */
const PERSONA_SERVICES_CACHE_KEY = "persona-services";

const loadServices = (): Promise<UserService[]> => api.services.list();

export function useConfigSetServices(): ResourceList<UserService> {
  return useResourceList<UserService>(PERSONA_SERVICES_CACHE_KEY, loadServices);
}

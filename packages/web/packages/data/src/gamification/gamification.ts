"use client";

// Owner/admin-scoped gamification REALM config for ONE ecosystem (the "realm"). Backs the
// per-product Gamification panes — the hub's single settings pane and the gamification
// site's four-topic rail alike. Wired to the backend's /v1/gamification/* routes (the realm
// rides as the `ecosystem` query/body field) through the host BFF's /api/:path* proxy.
//
// GET returns the realm's config (defaults when unset). POST is a partial update; raising a
// realm's mode from 'none' to either 'gamification' or 'game' triggers a retroactive replay,
// so its response may carry `replayed`.
//
// The types come from ./wire, this module's own transcription of the backend's
// `Gamification*` schemas — NOT from `@adh-sdk/adh-api-types`. Every other client
// in this package follows that rule (see ecosystems/wire.ts): a generic data client does
// not take a dependency on adh's generated product vocabulary.

import { enc } from "../client-helpers";
import { authedJson, listAllV1, unixToIso, withV1Query } from "../http";
import type {
  CatalogBadge,
  CatalogLevel,
  CatalogLevelWire,
  RealmBadgeWire,
  RealmConfigInputWire,
  RealmConfigWire,
  RealmEventTypeWire,
  ReplayResultWire,
  Seasons,
  SeasonsWire,
  RealmConfig,
  RealmConfigInput,
  RealmConfigUpdate,
  RealmCatalog,
  RealmBadge,
  RealmBadgeInput,
  RealmLevelsInput,
  RealmLevelsUpdate,
  LevelRung,
  ReplayResult,
  RealmEventType,
  RealmEventTypeInput,
} from "./wire";

export type {
  RealmConfig,
  RealmConfigInput,
  RealmConfigUpdate,
  RealmCatalog,
  CatalogBadge,
  CatalogLevel,
  RealmBadge,
  RealmBadgeInput,
  RealmLevelsInput,
  RealmLevelsUpdate,
  LevelRung,
  ReplayResult,
  RealmEventType,
  RealmEventTypeInput,
  Seasons,
  GamingMode,
} from "./wire";

const BASE = "/api/v1/gamification";
const configPath = () => `${BASE}/config`;
const catalogPath = () => `${BASE}/catalog`;
const badgesPath = () => `${BASE}/badges`;
const badgePath = (id: string) => `${BASE}/badges/${enc(id)}`;
const levelsPath = () => `${BASE}/levels`;
const replayPath = () => `${BASE}/events/replay`;
const eventTypesPath = () => `${BASE}/event_types`;
const eventTypePath = (id: string) => `${BASE}/event_types/${enc(id)}`;

const toSeasons = (w: SeasonsWire | undefined): Seasons =>
  w ? { anchor: w.anchor, lengthDays: w.length_days } : null;
const seasonsToWire = (s: Seasons): SeasonsWire => (s ? { anchor: s.anchor, length_days: s.lengthDays } : null);

const toConfig = (w: RealmConfigWire): RealmConfig => ({
  ecosystemId: w.ecosystem_id,
  mode: w.mode,
  skin: w.skin,
  surfaces: w.surfaces,
  seasons: toSeasons(w.seasons),
  timezone: w.timezone,
});

const configInputToWire = (i: RealmConfigInput): RealmConfigInputWire => ({
  ...(i.mode !== undefined ? { mode: i.mode } : {}),
  ...(i.skin !== undefined ? { skin: i.skin } : {}),
  ...(i.surfaces !== undefined ? { surfaces: i.surfaces } : {}),
  ...(i.seasons !== undefined ? { seasons: seasonsToWire(i.seasons) } : {}),
  ...(i.timezone !== undefined ? { timezone: i.timezone } : {}),
});

const toReplay = (w: ReplayResultWire): ReplayResult => ({
  subjects: w.subjects,
  badges: w.badges,
  ...(w.xp_gained !== undefined ? { xpGained: w.xp_gained } : {}),
});

const toBadge = (w: RealmBadgeWire): RealmBadge => ({
  id: w.id,
  name: w.name,
  description: w.description,
  icon: w.icon,
  ...(w.stat_key !== undefined ? { statKey: w.stat_key } : {}),
  ...(w.comparator !== undefined ? { comparator: w.comparator } : {}),
  ...(w.threshold !== undefined ? { threshold: w.threshold } : {}),
  ...(w.badge_line !== undefined ? { badgeLine: w.badge_line } : {}),
  ...(w.tier !== undefined ? { tier: w.tier } : {}),
  pointValue: w.point_value,
  ...(w.hidden !== undefined ? { hidden: w.hidden } : {}),
  ...(w.active !== undefined ? { active: w.active } : {}),
  ...(w.subject_type !== undefined ? { subjectType: w.subject_type } : {}),
  ...(w.ecosystem_id !== undefined ? { ecosystemId: w.ecosystem_id } : {}),
});

const toCatalogBadge = (w: RealmBadgeWire): CatalogBadge => ({
  ...toBadge(w),
  source: w.source ?? "default",
});

const toLevel = (w: CatalogLevelWire): CatalogLevel => ({
  name: w.name,
  minPoints: w.min_points,
  source: w.source,
});

const badgeInputToWire = (i: RealmBadgeInput) => ({
  name: i.name,
  description: i.description,
  icon: i.icon,
  stat_key: i.statKey,
  comparator: i.comparator,
  threshold: i.threshold,
  badge_line: i.badgeLine,
  tier: i.tier,
  point_value: i.pointValue,
  hidden: i.hidden,
});

const toEventType = (w: RealmEventTypeWire): RealmEventType => ({
  id: w.id,
  ecosystemId: w.ecosystem_id,
  name: w.name,
  statKey: w.stat_key,
  ...(w.created !== undefined ? { createdAt: unixToIso(w.created) } : {}),
  ...(w.updated !== undefined ? { updatedAt: unixToIso(w.updated) } : {}),
});

const post = <T>(url: string, body: unknown) =>
  authedJson<T>(url, { method: "POST", body: JSON.stringify(body) });
const del = (url: string) =>
  authedJson<{ id: string | null; deleted: boolean }>(url, { method: "DELETE" });

export const gamificationApi = {
  /** Read a realm's gamification config (admin/owner-gated). */
  async getRealmConfig(ecoId: string): Promise<RealmConfig> {
    return toConfig(
      await authedJson<RealmConfigWire>(withV1Query(configPath(), { ecosystem: ecoId })),
    );
  },

  /** Update a realm's gamification config (partial). Enabling it replays retroactively. */
  async updateRealmConfig(ecoId: string, input: RealmConfigInput): Promise<RealmConfigUpdate> {
    const w = await post<{ config: RealmConfigWire; replayed?: ReplayResultWire }>(configPath(), {
      ...configInputToWire(input),
      ecosystem: ecoId,
    });
    return {
      config: toConfig(w.config),
      ...(w.replayed ? { replayed: toReplay(w.replayed) } : {}),
    };
  },

  /** Read a realm's effective catalog — source-tagged defaults + realm overrides. */
  async getCatalog(ecoId: string): Promise<RealmCatalog> {
    const w = await authedJson<{ badges: RealmBadgeWire[]; levels: CatalogLevelWire[] }>(
      withV1Query(catalogPath(), { ecosystem: ecoId }),
    );
    return { badges: w.badges.map(toCatalogBadge), levels: w.levels.map(toLevel) };
  },

  /** Author a realm badge (overrides the same (badgeLine, tier) default). 400 on bad input. */
  async createRealmBadge(ecoId: string, input: RealmBadgeInput): Promise<RealmBadge> {
    return toBadge(
      await post<RealmBadgeWire>(badgesPath(), { ...badgeInputToWire(input), ecosystem: ecoId }),
    );
  },

  /** Update a realm-owned badge (404 for a platform default). 400 on bad input. */
  async updateRealmBadge(ecoId: string, id: string, input: RealmBadgeInput): Promise<RealmBadge> {
    return toBadge(
      await post<RealmBadgeWire>(badgePath(id), { ...badgeInputToWire(input), ecosystem: ecoId }),
    );
  },

  /** Delete a realm-owned badge (clears its holdings first; 404 for a default). */
  async deleteRealmBadge(ecoId: string, id: string): Promise<{ deleted: string }> {
    await del(withV1Query(badgePath(id), { ecosystem: ecoId }));
    return { deleted: id };
  },

  /** Replace the realm's level ladder wholesale (must start at 0, strictly increasing). 400 otherwise. */
  async putRealmLevels(ecoId: string, rungs: LevelRung[]): Promise<RealmLevelsUpdate> {
    const w = await post<{ levels: CatalogLevelWire[]; replay_hint: string }>(levelsPath(), {
      rungs: rungs.map((r) => ({ name: r.name, min_points: r.minPoints })),
      ecosystem: ecoId,
    });
    return { levels: w.levels.map(toLevel), replayHint: w.replay_hint };
  },

  /** Retroactively backfill the whole realm from telemetry already earned. */
  async replayRealm(ecoId: string): Promise<ReplayResult> {
    return toReplay(await post<ReplayResultWire>(replayPath(), { ecosystem_id: ecoId }));
  },

  /** List a realm's custom event types, name-ordered. */
  async listEventTypes(ecoId: string): Promise<RealmEventType[]> {
    const rows = await listAllV1<RealmEventTypeWire>(
      withV1Query(eventTypesPath(), { ecosystem: ecoId }),
    );
    return rows.map(toEventType);
  },

  /** Register a realm custom event type. 400 on a bad input; 409 on a duplicate name. */
  async createEventType(ecoId: string, input: RealmEventTypeInput): Promise<RealmEventType> {
    return toEventType(
      await post<RealmEventTypeWire>(eventTypesPath(), {
        name: input.name,
        stat_key: input.statKey,
        ecosystem: ecoId,
      }),
    );
  },

  /** Update a realm event type. 404 for a foreign realm's row; 409 on a colliding rename. */
  async updateEventType(
    ecoId: string,
    id: string,
    input: RealmEventTypeInput,
  ): Promise<RealmEventType> {
    return toEventType(
      await post<RealmEventTypeWire>(eventTypePath(id), {
        name: input.name,
        stat_key: input.statKey,
        ecosystem: ecoId,
      }),
    );
  },

  /** Delete a realm event type (404 for a foreign realm's row or an unknown id). */
  async deleteEventType(ecoId: string, id: string): Promise<{ deleted: string }> {
    await del(withV1Query(eventTypePath(id), { ecosystem: ecoId }));
    return { deleted: id };
  },
};

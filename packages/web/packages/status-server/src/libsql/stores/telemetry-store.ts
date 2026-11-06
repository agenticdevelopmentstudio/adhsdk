import { and, desc, eq, gte, inArray, lt, notInArray, sql, type SQL } from "drizzle-orm";
import type { Db } from "../client";
import { analyticsMetrics, errors, runtimeErrors, runtimeLogCursors } from "../schema";
import type { Store } from "../../telemetry/ports";
import {
  advanceCursor,
  groupRuntimeEntries,
  levelRank,
  RUNTIME_ERROR_RETENTION_MS,
  RUNTIME_LEVELS,
  unseenEntries,
  type RuntimeCursor,
} from "../../telemetry/runtime-errors";
import type { AnalyticsMetricDTO, ErrorDTO, RuntimeErrorGroup, RuntimeLogEntry } from "../../telemetry/types";
import type { RuntimeErrorsStore, TelemetryStore } from "../../storage/ports";

// SQLite/libSQL adapter of TelemetryStore — the ONLY place that knows the
// errors/analytics streams live in a database. Each closes over `db` so nothing
// above this module ever sees a connection.

function toDate(s: string | null): Date | null {
  if (!s) return null;
  const d = new Date(s);
  return Number.isNaN(d.getTime()) ? null : d;
}

function rowToErrorDTO(r: typeof errors.$inferSelect): ErrorDTO {
  return {
    id: r.id,
    issueKey: r.issueKey,
    project: r.project,
    title: r.title,
    culprit: r.culprit,
    level: r.level,
    count: r.count,
    userCount: r.userCount,
    firstSeen: r.firstSeen?.toISOString() ?? null,
    lastSeen: r.lastSeen?.toISOString() ?? null,
    permalink: r.permalink,
  };
}

async function upsertErrors(db: Db, items: ErrorDTO[]): Promise<void> {
  await db
    .insert(errors)
    .values(
      items.map((i) => ({
        issueKey: i.issueKey,
        project: i.project,
        title: i.title,
        culprit: i.culprit,
        level: i.level,
        count: i.count,
        userCount: i.userCount,
        firstSeen: toDate(i.firstSeen),
        lastSeen: toDate(i.lastSeen),
        permalink: i.permalink,
        resolved: false,
      })),
    )
    .onConflictDoUpdate({
      target: errors.issueKey,
      set: {
        title: sql`excluded.title`,
        culprit: sql`excluded.culprit`,
        level: sql`excluded.level`,
        count: sql`excluded.count`,
        userCount: sql`excluded.user_count`,
        lastSeen: sql`excluded.last_seen`,
        permalink: sql`excluded.permalink`,
        // `project` is REFRESHED, unlike `firstSeen` below it, because this branch
        // promoted it from a display field into an IDENTITY: the board mints
        // `errors|<project>` from it. The conflict target is `issueKey`, so a stored slug
        // that stopped tracking the provider's would keep deriving a target no fact
        // mentions — its ledger row unclosable — while issues under the new slug opened a
        // second, simultaneous problem for the same app. Renames, an issue moved between
        // projects, and a payload that starts supplying `slug` where it used to fall back
        // to `name` all produce exactly that.
        project: sql`excluded.project`,
        // REOPENS a row that had been swept: `excluded.resolved` is the `false` the
        // values list above always carries, so an issue that comes back in a later
        // poll returns to the board instead of staying invisible behind its old
        // resolution. Spelled through `excluded` rather than a literal so it keeps
        // tracking the inserted value if that ever stops being a constant.
        resolved: sql`excluded.resolved`,
        fetchedAt: sql`(unixepoch())`,
      },
    });
}

/**
 * Mark every unresolved row NOT in this poll as resolved — the other half of the
 * reconciliation, and the only writer of `resolved = true` in the system.
 *
 * `notInArray` is given a non-empty list or skipped entirely: drizzle compiles an
 * empty one to `not in ()`, which SQLite rejects. The empty case is not an edge to
 * tolerate but the most important one to get right — it is a GlitchTip with a clean
 * board, and it must resolve everything.
 */
async function resolveVanished(db: Db, seen: string[]): Promise<void> {
  const stillOpen = eq(errors.resolved, false);
  await db
    .update(errors)
    .set({ resolved: true })
    // `fetchedAt` is deliberately NOT restamped: it records when a row was last SEEN
    // in a poll, and this row's defining property is that it wasn't.
    .where(seen.length === 0 ? stillOpen : and(stillOpen, notInArray(errors.issueKey, seen)));
}

function createErrorsStore(db: Db): Store<ErrorDTO> {
  return {
    // `save` is a RECONCILIATION, not an append. The fetcher asks GlitchTip for
    // `is:unresolved`, so each poll delivers the COMPLETE current set — an issue
    // that is absent has been resolved (or deleted) upstream, and the only way to
    // learn that is its absence. See git history for the two preconditions
    // (poll succeeded, answer whole) that make the sweep below safe.
    async save(items: ErrorDTO[], opts?: { complete?: boolean }): Promise<void> {
      // NOT an early return on an empty set — "GlitchTip has nothing unresolved" is
      // exactly the state that must resolve every row we are still holding, and
      // returning here is what made a cleared error board permanent.
      if (items.length > 0) await upsertErrors(db, items);
      // Default TRUE: a caller that says nothing is a whole-answer fetcher (the only
      // other shape in this codebase), and defaulting the other way would silently
      // disable the sweep for every one of them.
      if (opts?.complete ?? true) {
        await resolveVanished(
          db,
          items.map((i) => i.issueKey),
        );
      } else {
        // Deliberately loud and deliberately per-poll: this is the state in which the
        // store stops closing rows, and a board that quietly stopped resolving would
        // look exactly like a board with nothing to resolve. Nothing goes stale-red as
        // a result — the fold's own recency window drops any row whose `lastSeen` stops
        // advancing.
        console.warn(
          `[telemetry] GlitchTip returned a full page (${items.length}); the unresolved set is truncated, so no rows were swept this poll`,
        );
      }
    },

    async load(): Promise<ErrorDTO[]> {
      const rows = await db
        .select()
        .from(errors)
        .where(eq(errors.resolved, false))
        .orderBy(desc(errors.lastSeen))
        .limit(100);
      return rows.map(rowToErrorDTO);
    },
  };
}

function createAnalyticsStore(db: Db): Store<AnalyticsMetricDTO> {
  return {
    async save(items: AnalyticsMetricDTO[]): Promise<void> {
      if (items.length === 0) return;
      await db.insert(analyticsMetrics).values(
        items.map((i) => ({
          metric: i.metric,
          window: i.window,
          scope: i.scope,
          value: i.value,
          capturedAt: new Date(i.capturedAt),
        })),
      );
    },

    async load(): Promise<AnalyticsMetricDTO[]> {
      const rows = await db
        .select()
        .from(analyticsMetrics)
        .orderBy(desc(analyticsMetrics.capturedAt))
        .limit(100);

      // Reduce to the latest snapshot per (metric, window, scope).
      const latest = new Map<string, typeof analyticsMetrics.$inferSelect>();
      for (const r of rows) {
        const key = `${r.metric}|${r.window}|${r.scope}`;
        if (!latest.has(key)) latest.set(key, r);
      }
      return Array.from(latest.values()).map((r) => ({
        metric: r.metric,
        window: r.window,
        scope: r.scope,
        value: r.value,
        capturedAt: r.capturedAt.toISOString(),
      }));
    },
  };
}

/** Rows per multi-row INSERT, well under SQLite's bound-variable limit. */
const INSERT_CHUNK = 200;

function chunks<T>(items: T[], size: number): T[][] {
  const out: T[][] = [];
  for (let i = 0; i < items.length; i += size) out.push(items.slice(i, i + size));
  return out;
}

/** The SQL twin of `levelRank`, built from the same level list so the two cannot disagree. */
function levelRankSql(level: SQL): SQL {
  const arms = RUNTIME_LEVELS.map((l) => `WHEN '${l}' THEN ${levelRank(l)}`).join(" ");
  return sql`(CASE ${level} ${sql.raw(arms)} ELSE ${levelRank(null)} END)`;
}

function rowToRuntimeGroup(r: typeof runtimeErrors.$inferSelect): RuntimeErrorGroup {
  return {
    key: r.key,
    project: r.project,
    deploymentId: r.deploymentId,
    domain: r.domain,
    source: r.source,
    method: r.method,
    path: r.path,
    status: r.status,
    level: r.level,
    message: r.message,
    count: r.count,
    firstSeen: r.firstSeen.toISOString(),
    lastSeen: r.lastSeen.toISOString(),
    sampleRowId: r.sampleRowId,
  };
}

function createRuntimeErrorsStore(db: Db): RuntimeErrorsStore {
  return {
    // APPENDING, never reconciling: a group absent from this read just was not seen again, so
    // `complete` is ignored. Each line counts once per deployment, against that deployment's
    // cursor, so reading the same stream twice adds nothing.
    async save(entries: RuntimeLogEntry[], opts?: { nowMs?: number }): Promise<void> {
      const nowMs = opts?.nowMs ?? Date.now();
      const cutoffMs = nowMs - RUNTIME_ERROR_RETENTION_MS;
      const fresh = entries.filter((e) => e.timestampMs >= cutoffMs);

      const byDeployment = new Map<string, RuntimeLogEntry[]>();
      for (const e of fresh) {
        const list = byDeployment.get(e.deploymentId);
        if (list) list.push(e);
        else byDeployment.set(e.deploymentId, [e]);
      }
      const ids = [...byDeployment.keys()];
      const prior = new Map<string, RuntimeCursor>();
      for (const part of chunks(ids, INSERT_CHUNK)) {
        const rows = await db.select().from(runtimeLogCursors).where(inArray(runtimeLogCursors.deploymentId, part));
        for (const r of rows) prior.set(r.deploymentId, { lastTimestampMs: r.lastTimestampMs, lastRowIds: r.lastRowIds });
      }

      const counted: RuntimeLogEntry[] = [];
      const cursors: (typeof runtimeLogCursors.$inferInsert)[] = [];
      for (const [deploymentId, list] of byDeployment) {
        const unseen = unseenEntries(list, prior.get(deploymentId));
        if (unseen.length === 0) continue;
        counted.push(...unseen);
        const next = advanceCursor(prior.get(deploymentId), unseen)!;
        cursors.push({ deploymentId, project: unseen[0]!.project, ...next, updatedAt: new Date(nowMs) });
      }

      const deltas = groupRuntimeEntries(counted);
      const queries = [];
      const newer = sql`excluded.last_seen >= ${runtimeErrors.lastSeen}`;
      for (const part of chunks(deltas, INSERT_CHUNK)) {
        queries.push(
          db
            .insert(runtimeErrors)
            .values(
              part.map(({ firstSeenMs, lastSeenMs, ...g }) => ({
                ...g,
                firstSeen: new Date(firstSeenMs),
                lastSeen: new Date(lastSeenMs),
              })),
            )
            .onConflictDoUpdate({
              target: runtimeErrors.key,
              set: {
                count: sql`${runtimeErrors.count} + excluded.count`,
                firstSeen: sql`min(${runtimeErrors.firstSeen}, excluded.first_seen)`,
                lastSeen: sql`max(${runtimeErrors.lastSeen}, excluded.last_seen)`,
                level: sql`CASE WHEN ${levelRankSql(sql`excluded.level`)} > ${levelRankSql(sql`${runtimeErrors.level}`)} THEN excluded.level ELSE ${runtimeErrors.level} END`,
                // The newest line speaks for where the group lives now.
                deploymentId: sql`CASE WHEN ${newer} THEN excluded.deployment_id ELSE ${runtimeErrors.deploymentId} END`,
                domain: sql`CASE WHEN ${newer} THEN coalesce(excluded.domain, ${runtimeErrors.domain}) ELSE coalesce(${runtimeErrors.domain}, excluded.domain) END`,
                sampleRowId: sql`CASE WHEN ${newer} THEN excluded.sample_row_id ELSE ${runtimeErrors.sampleRowId} END`,
              },
            }),
        );
      }
      for (const part of chunks(cursors, INSERT_CHUNK)) {
        queries.push(
          db
            .insert(runtimeLogCursors)
            .values(part)
            .onConflictDoUpdate({
              target: runtimeLogCursors.deploymentId,
              set: {
                project: sql`excluded.project`,
                lastTimestampMs: sql`excluded.last_timestamp_ms`,
                lastRowIds: sql`excluded.last_row_ids`,
                updatedAt: sql`excluded.updated_at`,
              },
            }),
        );
      }
      // Retention: a group not seen for 7 days goes, and so does a cursor past it — any line it
      // guards is older than retention and is dropped above before counting.
      queries.push(db.delete(runtimeErrors).where(lt(runtimeErrors.lastSeen, new Date(cutoffMs))));
      queries.push(db.delete(runtimeLogCursors).where(lt(runtimeLogCursors.lastTimestampMs, cutoffMs)));
      // One batch is one transaction: the counts and the cursors that make them exact move together.
      const [first, ...rest] = queries;
      await db.batch([first!, ...rest]);
    },

    async load(opts?: { sinceMs?: number }): Promise<RuntimeErrorGroup[]> {
      const base = db.select().from(runtimeErrors);
      const rows = await (opts?.sinceMs === undefined
        ? base
        : base.where(gte(runtimeErrors.lastSeen, new Date(opts.sinceMs)))
      ).orderBy(desc(runtimeErrors.lastSeen));
      return rows.map(rowToRuntimeGroup);
    },
  };
}

export function createTelemetryStore(db: Db): TelemetryStore {
  return {
    errors: createErrorsStore(db),
    analytics: createAnalyticsStore(db),
    runtimeErrors: createRuntimeErrorsStore(db),
  };
}

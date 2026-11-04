import { mapLimit } from "@adh-sdk/deploy-platform/util";

// A stale-while-revalidate cache for a dashboard made of independently slow sections.
//
// Why not `cachedSingleFlight` and an awaited request: the Analytics topic's PostHog queries
// run one at a time (the API 503s under concurrency) and take 2–30s each, so a cold dashboard
// can take a minute. That is past Next's rewrite proxy, and it would hold a request open for
// nothing when most sections could already be on screen. So `read` NEVER waits: it answers
// with what is known and kicks off a refresh if one is due; each section publishes as it
// finishes, and the client polls while `refreshing` to watch them fill in.
//
// Refreshes are driven by reads, not timers, so an idle dashboard costs no provider quota.
// Keys must come from a bounded enum: state is kept per key, forever.

export interface DashboardSection<T> {
  /** The last good answer. Survives a later failure, so stale data stays on screen. */
  data: T | null;
  /** Why the latest attempt failed; null if it succeeded or none has finished. */
  error: string | null;
  /** When `data` was fetched. */
  updatedAt: string | null;
}

export type DashboardSections<S> = { [N in keyof S]: DashboardSection<S[N]> };
export type DashboardLoaders<S> = { [N in keyof S]: () => Promise<S[N]> };

export interface DashboardRead<S> {
  refreshing: boolean;
  sections: DashboardSections<S>;
}

export interface SectionedDashboard<K extends string, S> {
  read(key: K): DashboardRead<S>;
}

export interface SectionedDashboardOptions<K extends string, S> {
  /** How long a fully successful refresh is good for. */
  ttlMs: number;
  /** How soon to retry when any section failed: a blip shouldn't cost a whole TTL. */
  retryMs?: number;
  /** 1 runs sections strictly one after another. */
  concurrency?: number;
  sections: readonly (keyof S & string)[];
  /** Built per refresh, so a loader computes its time window from "now". */
  loaders: (key: K) => DashboardLoaders<S>;
  now?: () => number;
}

interface KeyState<S> {
  sections: DashboardSections<S>;
  refreshing: boolean;
  finishedAt: number | null;
  anyFailed: boolean;
}

const DEFAULT_RETRY_MS = 60_000;

/** All sections in their "nothing yet" state: what an unconfigured provider answers with. */
export function emptySections<S>(names: readonly (keyof S & string)[]): DashboardSections<S> {
  const out = {} as DashboardSections<S>;
  for (const name of names) out[name] = { data: null, error: null, updatedAt: null };
  return out;
}

export function sectionedDashboard<K extends string, S>(
  opts: SectionedDashboardOptions<K, S>,
): SectionedDashboard<K, S> {
  const now = opts.now ?? Date.now;
  const retryMs = Math.min(opts.retryMs ?? DEFAULT_RETRY_MS, opts.ttlMs);
  const states = new Map<K, KeyState<S>>();

  async function refresh(key: K, state: KeyState<S>): Promise<void> {
    state.refreshing = true;
    let anyFailed = false;
    try {
      const loaders = opts.loaders(key);
      await mapLimit([...opts.sections], opts.concurrency ?? 1, async (name) => {
        const prior = state.sections[name];
        try {
          const data = await loaders[name]();
          state.sections[name] = { data, error: null, updatedAt: new Date(now()).toISOString() };
        } catch (err) {
          anyFailed = true;
          const error = err instanceof Error ? err.message : String(err);
          state.sections[name] = { ...prior, error };
          console.warn(`[telemetry] dashboard section ${name} (${key}) failed: ${error}`);
        }
      });
    } catch (err) {
      anyFailed = true;
      console.warn(`[telemetry] dashboard refresh (${key}) failed: ${err instanceof Error ? err.message : String(err)}`);
    } finally {
      state.anyFailed = anyFailed;
      state.finishedAt = now();
      state.refreshing = false;
    }
  }

  return {
    read(key: K): DashboardRead<S> {
      let state = states.get(key);
      if (!state) {
        state = { sections: emptySections<S>(opts.sections), refreshing: false, finishedAt: null, anyFailed: false };
        states.set(key, state);
      }
      const age = state.finishedAt === null ? Infinity : now() - state.finishedAt;
      if (!state.refreshing && age >= (state.anyFailed ? retryMs : opts.ttlMs)) void refresh(key, state);
      return { refreshing: state.refreshing, sections: { ...state.sections } };
    },
  };
}

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
//
// Each section keeps its own schedule. A refresh re-runs only the sections that are due, so
// one failing section is retried on its own rather than dragging every healthy one back to
// the provider with it, and its retries back off (see `retryMs`) rather than hitting a
// provider that keeps failing once a minute for as long as it fails.

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
  /**
   * Wait for the refresh in flight for `key` to finish, but no longer than `timeoutMs`.
   * Resolves true when nothing is refreshing any more, false when the deadline passed first.
   * Never STARTS a refresh: `read` does that, so a caller that wants a warm answer reads,
   * settles, and reads again. For a server-side reader (`/report`) that must not push the
   * polling `read` implies onto its own client.
   */
  settle(key: K, timeoutMs: number): Promise<boolean>;
}

export interface SectionedDashboardOptions<K extends string, S> {
  /** How long a fully successful refresh is good for. */
  ttlMs: number;
  /**
   * How soon to retry a section that failed or came back short: a blip shouldn't cost a whole
   * TTL. Doubles with each further failure in a row, up to `ttlMs`; a full success resets it.
   */
  retryMs?: number;
  /** 1 runs sections strictly one after another. */
  concurrency?: number;
  sections: readonly (keyof S & string)[];
  /** Built per refresh, so a loader computes its time window from "now". */
  loaders: (key: K) => DashboardLoaders<S>;
  /**
   * True for an answer that is shown but known to be short (some of its calls failed). It is kept
   * as a success, with no error, but retried after `retryMs` like a failure rather than held for
   * the whole TTL.
   */
  incomplete?: (name: keyof S & string, data: S[keyof S]) => boolean;
  now?: () => number;
}

interface SectionSchedule {
  /** Epoch ms from which the section may be fetched again; 0 = never fetched. */
  dueAt: number;
  /** Failed (or short) attempts in a row, for the backoff. */
  failures: number;
}

interface KeyState<S> {
  sections: DashboardSections<S>;
  refreshing: boolean;
  schedule: Record<keyof S & string, SectionSchedule>;
  /** The refresh in flight, while `refreshing`: what `settle` waits on. */
  inflight: Promise<void> | null;
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

  /** Schedule a section's next fetch from how this attempt went. */
  function settle(state: KeyState<S>, name: keyof S & string, ok: boolean): void {
    const s = state.schedule[name];
    s.failures = ok ? 0 : s.failures + 1;
    const wait = ok ? opts.ttlMs : Math.min(retryMs * 2 ** (s.failures - 1), opts.ttlMs);
    s.dueAt = now() + wait;
  }

  async function refresh(key: K, state: KeyState<S>, due: readonly (keyof S & string)[]): Promise<void> {
    state.refreshing = true;
    const settled = new Set<keyof S & string>();
    try {
      const loaders = opts.loaders(key);
      await mapLimit([...due], opts.concurrency ?? 1, async (name) => {
        const prior = state.sections[name];
        try {
          const data = await loaders[name]();
          state.sections[name] = { data, error: null, updatedAt: new Date(now()).toISOString() };
          settle(state, name, !opts.incomplete?.(name, data));
        } catch (err) {
          const error = err instanceof Error ? err.message : String(err);
          state.sections[name] = { ...prior, error };
          settle(state, name, false);
          console.warn(`[telemetry] dashboard section ${name} (${key}) failed: ${error}`);
        }
        settled.add(name);
      });
    } catch (err) {
      console.warn(`[telemetry] dashboard refresh (${key}) failed: ${err instanceof Error ? err.message : String(err)}`);
    } finally {
      // A refresh that died before reaching a section (a `loaders` builder that threw) counts
      // as a failure of that section, so it is retried rather than left due on every read.
      for (const name of due) if (!settled.has(name)) settle(state, name, false);
      state.refreshing = false;
    }
  }

  return {
    read(key: K): DashboardRead<S> {
      let state = states.get(key);
      if (!state) {
        const schedule = {} as Record<keyof S & string, SectionSchedule>;
        for (const name of opts.sections) schedule[name] = { dueAt: 0, failures: 0 };
        state = { sections: emptySections<S>(opts.sections), refreshing: false, schedule, inflight: null };
        states.set(key, state);
      }
      if (!state.refreshing) {
        const t = now();
        const { schedule } = state;
        const due = opts.sections.filter((name) => schedule[name].dueAt <= t);
        if (due.length > 0) {
          const current = state;
          const run = refresh(key, current, due);
          current.inflight = run;
          void run.finally(() => {
            if (current.inflight === run) current.inflight = null;
          });
        }
      }
      return { refreshing: state.refreshing, sections: { ...state.sections } };
    },

    async settle(key: K, timeoutMs: number): Promise<boolean> {
      const state = states.get(key);
      const inflight = state?.inflight;
      if (!state || !inflight) return true;
      let timer: ReturnType<typeof setTimeout> | undefined;
      const deadline = new Promise<void>((resolve) => {
        timer = setTimeout(resolve, Math.max(0, timeoutMs));
      });
      try {
        await Promise.race([inflight, deadline]);
      } finally {
        clearTimeout(timer);
      }
      return !state.refreshing;
    },
  };
}

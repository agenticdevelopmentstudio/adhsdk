import { useEffect, useState } from "react";
import { keepPreviousData, useQuery } from "@tanstack/react-query";
import { useStatusApi, type StatusApiClient } from "../api/client";
import type { Board } from "../lib/board-types";
import { subscribeLiveFrames } from "./use-live-snapshot";
import { useNow } from "./use-now";

/** How often to re-read the board before the first read has said (`freshness.pollIntervalMs`). */
const FIRST_POLL_MS = 60_000;

async function fetchBoard(api: StatusApiClient, envKey: string | null): Promise<Board> {
  const q = envKey === null ? "" : `?${new URLSearchParams({ environments: envKey })}`;
  const res = await api.fetch(`/board${q}`, { headers: { accept: "application/json" } });
  if (!res.ok) throw new Error(`board fetch failed: ${res.status}`);
  return res.json();
}

/**
 * Why {@link UseBoardResult.board} is null; always null itself when `board` isn't.
 *
 * `stale`, `frozen` and `no-data` are three different failures and are deliberately not
 * one word: `stale` means the READ stopped arriving (the board's own `generatedAt` went
 * old), `frozen` means the read keeps arriving on time over FACTS that stopped moving (a
 * wedged monitor), and `no-data` means the board rests on no observation at all. They
 * fold to the same null board — none of them can back a claim — but a human staring at
 * the wallboard needs to know whether to look at the API, at the monitor process, or at
 * the config.
 *
 * `no-data` is split out for Fix Round 2 item C3: it is the NORMAL state of a roster with
 * nothing configured to observe, and reporting it as a wedged monitor sent a fresh
 * install to debug a monitor that was working perfectly. Still null, still never green —
 * only worded, and ordered against `blind`, by the consumer that can tell which it is.
 */
export type BoardUnavailableReason = "loading" | "unavailable" | "stale" | "frozen" | "no-data";

export interface UseBoardResult {
  /**
   * Null whenever the board CANNOT BACK A CURRENT CLAIM — {@link BoardUnavailableReason}
   * is the list of ways that happens, and is the only place it is spelled out (Fix
   * Round 2 item C4: every comment that re-listed the causes went stale the round a
   * cause was added). Never merely "arrived once, however long ago", and never merely
   * "arrived".
   * Fix Round 3 item 1: this is folded in HERE, the ONE place, rather than left for
   * every consumer to re-derive by also judging staleness itself. Three
   * separate rounds produced three separate instances of exactly one bug — a
   * consumer that checked `board === null` but not whether a present board had gone
   * stale, and rendered a confident verdict off a frozen read — because `board`
   * used to mean only "hasn't arrived", leaving the second question optional. It no
   * longer is: every consumer gets the right answer by construction, not by
   * remembering to ask.
   */
  board: Board | null;
  /** Why `board` is null right now, for a caller that wants to word its own message
   *  differently per cause; always null when `board` itself is non-null. This is the
   *  ONLY loading/unavailability signal on this hook — a separate `isLoading` would be
   *  a second way to ask one question, which is the shape that caused the three-round
   *  bug above. A caller wanting the spinner tests `reason === "loading"`. */
  reason: BoardUnavailableReason | null;
  /**
   * True while `board` is the PREVIOUS environment choice's read, kept on screen until
   * the new choice's own read lands. Its `problems` are unscoped, so lists filtered from
   * it are still right; its `scope` (indicator, problem count, "N/M healthy") was judged
   * over the old environments and must not be shown as this view's headline. Always
   * false when `board` is null.
   */
  scopePending: boolean;
  error: Error | null;
  refetch: () => void;
}

/**
 * The client's ONE source for the board. It fetches and renders; it does not derive,
 * accumulate, or persist. There is deliberately no localStorage here: the durable
 * client store is what let a fixed problem survive on one browser tab forever, because
 * a server-side fix had no way to reach into a tab's saved state and clear it.
 *
 * A problem that stops being derived server-side is simply absent from the next read.
 */
export function useBoard(opts: { environments?: readonly string[] | null } = {}): UseBoardResult {
  const api = useStatusApi();
  // The environments the reader chose, for `board.scope` — the SERVER judges the headline
  // over them. Null (every environment) shares one cache entry with every other reader.
  const environments = opts.environments ?? null;
  const envKey = environments === null ? null : [...environments].sort().join(",");
  // When this reader picked the current environment choice. A read for it that is older
  // than that, and that has not yet been answered or refused since, is whatever the cache
  // kept from an earlier visit to the same choice, not a sign that reads stopped arriving.
  const [chosen, setChosen] = useState(() => ({ envKey, at: Date.now() }));
  if (chosen.envKey !== envKey) setChosen({ envKey, at: Date.now() });
  const chosenAt = chosen.envKey === envKey ? chosen.at : Date.now();
  const q = useQuery<Board>({
    queryKey: ["board", envKey],
    queryFn: () => fetchBoard(api, envKey),
    // A new environment choice keeps the last board on screen until its own read lands,
    // rather than flashing the loading panel on every filter toggle.
    placeholderData: keepPreviousData,
    // The server says how often to re-read it — the same number its `staleAt` assumes.
    refetchInterval: (query) => query.state.data?.freshness?.pollIntervalMs ?? FIRST_POLL_MS,
    // Fix Round 2 item 5: matches useLiveSnapshot's own `retry: 1` (use-live-snapshot.ts),
    // the sibling feed that gates the SAME OverviewTab loading screen. Board and live
    // already poll on their own cadence regardless, so React
    // Query's default (3 retries with growing backoff) only delays surfacing a genuinely
    // down backend behind a longer spinner — it doesn't make the eventual read any more
    // likely to succeed, and it is the auto-retry-loop-over-a-down-backend the sibling
    // hook's own comment explicitly avoids. One retry still absorbs a single transient
    // blip without the multi-second wait.
    retry: 1,
  });
  // The stream is the fast path; the poll above is the floor if it's down.
  useEffect(() => subscribeLiveFrames(() => void q.refetch()), [q.refetch]);

  // Every verdict here is the server's (`board.freshness`): whether the facts behind the
  // board are current, frozen, or absent, and the instant after which this read is too
  // old to back a claim. The one thing only this client can see is that reads have
  // STOPPED arriving — React Query keeps the last good `data` forever while `/board`
  // fails — so the client's clock is compared to the server's deadline, and an
  // unparseable deadline fails closed. All of it folds into `board === null` here, in
  // one place, so no consumer can render a verdict off a board that cannot back one.
  // A board from a backend older than `freshness` carries no deadline at all: it reads as
  // stale (no deadline parses), the same fail-closed path as an unreadable one.
  //
  // Each environment choice has its own cache entry, so going back to a choice used earlier
  // can hand over that choice's expired board while its first read is still in flight. That
  // board says nothing about whether reads stopped: until a read made since the choice
  // answers or fails, it is loading. A read that then fails leaves it stale, as before.
  const nowMs = useNow();
  const data = q.data ?? null;
  const expired = data != null && !(nowMs <= Date.parse(data.freshness?.staleAt ?? ""));
  const leftOver = expired && q.isFetching && q.dataUpdatedAt < chosenAt && q.errorUpdatedAt < chosenAt;
  const reason: BoardUnavailableReason | null =
    data == null ? (q.isLoading ? "loading" : "unavailable")
    : leftOver ? "loading"
    : expired ? "stale"
    : data.freshness.state === "current" ? null
    : data.freshness.state === "no-data" ? "no-data"
    : "frozen";

  return {
    board: reason == null ? data : null,
    reason,
    scopePending: reason == null && q.isPlaceholderData,
    error: (q.error as Error | null) ?? null,
    refetch: () => void q.refetch(),
  };
}

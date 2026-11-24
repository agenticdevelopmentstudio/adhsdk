"use client";

import { useCallback, useMemo } from "react";
import { useInfiniteQuery } from "@tanstack/react-query";
import { listV1Page, withV1Query } from "./http";

/**
 * One `/v1` page as a window page: `limit` rows after the cursor. The one place a windowed list
 * turns its `(after, pageSize)` into a request, so no caller assembles `starting_after` itself.
 */
export async function fetchV1WindowPage<T>(
  url: string,
  after: string | undefined,
  pageSize: number,
): Promise<WindowPage<T>> {
  const { data, hasMore } = await listV1Page<T>(
    withV1Query(url, { limit: pageSize, starting_after: after }),
  );
  return { items: data, hasMore };
}

/** One server page of an append-only log. `/v1` collections carry `has_more`, never a total. */
export interface WindowPage<T> {
  items: T[];
  hasMore: boolean;
}

export interface UseWindowedListOptions<T> {
  /** React Query key for the whole window. Must not contain anything the operator types. */
  key: readonly unknown[];
  /**
   * Fetch one server page. `after` is the id of the last row already held (the `/v1`
   * `starting_after` cursor), `undefined` for the first page.
   */
  fetchPage: (after: string | undefined, pageSize: number) => Promise<WindowPage<T>>;
  /** How many rows one fetch brings back. */
  pageSize: number;
  /**
   * A row's stable identity, used to keep the window free of duplicates.
   *
   * Required, not optional, because the duplicate is not a rare case. Growing this window is
   * a log that is still being written to: a row can reappear on a later page, so the operator would
   * see it twice. React would then see two rows with the same key, and the list's selection would
   * count one row as two. It is also the cursor the next page is asked to start after.
   */
  getRowId: (item: T) => string;
}

export interface WindowedList<T> {
  /** Every row fetched so far, oldest fetch first — i.e. the window, in server order. */
  rows: T[];
  isLoading: boolean;
  isFetchingMore: boolean;
  /** The server has rows beyond the window. */
  hasMore: boolean;
  loadMore: () => void;
  error: unknown;
}

/**
 * A GROWING WINDOW over an append-only log, for the lists whose population has no end.
 *
 * Most admin lists are bounded — every feature flag, every provider, every reserved name — so they
 * are fetched whole and narrowed in the browser, and `EditableList` has no pager for the same
 * reason it has no page size. An audit trail or a message log is different in kind: it grows
 * forever, so "fetch it all" is a promise the client cannot keep.
 *
 * A pager is still the wrong answer, and not because of taste. A pager and a filter are two ways
 * to not see a row, and the pager silently defeats the filter: the operator types a term, the
 * server returns page one of the matches, and the twenty-six-through-forty they were looking for
 * are behind a control most of them never press. What this does instead is APPEND. The window only
 * ever grows, every row in it stays filterable and sortable, and "load more" adds rows rather than
 * exchanging one set for another — so a filter is never narrowing a slice it cannot see past.
 *
 * The window is the newest N, because these logs are read newest-first and an operator looking for
 * something older narrows rather than walks.
 */
export function useWindowedList<T>({
  key,
  fetchPage,
  pageSize,
  getRowId,
}: UseWindowedListOptions<T>): WindowedList<T> {
  const query = useInfiniteQuery({
    queryKey: [...key, pageSize],
    queryFn: ({ pageParam }) => fetchPage(pageParam, pageSize),
    initialPageParam: undefined as string | undefined,
    // The NEXT page is asked for only while the server says `has_more`, starting after the last
    // row held. Offering "load more" at the end of the log gives the operator a button that
    // fetches nothing.
    getNextPageParam: (last) => {
      const tail = last.items.at(-1);
      return last.hasMore && tail !== undefined ? getRowId(tail) : undefined;
    },
  });

  // FIRST SIGHTING WINS. A row that reappears on a later page because the log grew underneath the
  // window is the same row, already on screen, in the position the operator saw it in — replacing
  // it would make the list reorder itself under a scroll they did not ask to move.
  const rows = useMemo(() => {
    const seen = new Set<string>();
    const out: T[] = [];
    for (const page of query.data?.pages ?? []) {
      for (const item of page.items) {
        const id = getRowId(item);
        if (seen.has(id)) continue;
        seen.add(id);
        out.push(item);
      }
    }
    return out;
  }, [query.data, getRowId]);

  const { fetchNextPage } = query;
  const loadMore = useCallback(() => {
    void fetchNextPage();
  }, [fetchNextPage]);

  return {
    rows,
    isLoading: query.isLoading,
    isFetchingMore: query.isFetchingNextPage,
    hasMore: query.hasNextPage,
    loadMore,
    error: query.error,
  };
}

// Shared `fetch` stub for the /v1 client tests: the real `authedJson` / `listAllV1` run (paging
// included), and only the network is faked. Not a test file itself (no `.test.`), so vitest
// does not collect it.
import { vi } from "vitest";

export const fetchMock = vi.fn();

export const v1List = (data: unknown[], has_more = false) => ({ object: "list", data, has_more, url: "" });

const response = (body: unknown, status = 200) => ({
  ok: status >= 200 && status < 300,
  status,
  json: async () => body,
  text: async () => (body === undefined ? "" : JSON.stringify(body)),
});

/** Every call answers `body`. */
export const respondWith = (body: unknown, status = 200) => fetchMock.mockResolvedValue(response(body, status));
/** The next call answers `body` (queue several for a paged read). */
export const respondOnce = (body: unknown, status = 200) => fetchMock.mockResolvedValueOnce(response(body, status));

export function installFetch(): void {
  fetchMock.mockReset();
  respondWith(v1List([]));
  vi.stubGlobal("fetch", fetchMock);
}

export const urlAt = (n = 0) => String(fetchMock.mock.calls[n]![0]);
export const initAt = (n = 0) => (fetchMock.mock.calls[n]![1] ?? {}) as RequestInit;
export const pathAt = (n = 0) => new URL(urlAt(n), "http://x").pathname;
export const paramsAt = (n = 0) => new URL(urlAt(n), "http://x").searchParams;
export const bodyAt = (n = 0) => JSON.parse(String(initAt(n).body));

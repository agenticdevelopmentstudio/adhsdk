// @vitest-environment jsdom
// Recipe: adhsdk ecosystem-config, sync-tables topic (vector ecosystem-config-036).
import { type ReactNode } from "react";
import { act, renderHook } from "@testing-library/react";
import { QueryClient, QueryClientProvider } from "@tanstack/react-query";
import { describe, expect, it, vi } from "vitest";

const { setOverride, clearOverride, get } = vi.hoisted(() => ({
  setOverride: vi.fn(),
  clearOverride: vi.fn(),
  get: vi.fn(),
}));
vi.mock("@adh-sdk/data/ecosystem-config", () => ({
  syncTablesApi: () => ({ get, setOverride, clearOverride }),
}));

import { syncTablesKey, useSetSyncOverride } from "./sync-tables-hooks";

const row = (resource: string, enabled: boolean) => ({
  resource,
  scope: "owner",
  pushMode: "generic",
  defaultEnabled: true,
  enabled,
  overridden: true,
});

describe("a sync-tables write", () => {
  it("ecosystem-config-036: replaces the cached catalog with the one the write returned, then refetches once it settles", async () => {
    const qc = new QueryClient({ defaultOptions: { queries: { retry: false }, mutations: { retry: false } } });
    const key = syncTablesKey("ecosystem", "eco-1");
    qc.setQueryData(key, [row("content.notes", false)]);
    const returned = [row("content.notes", true), row("content.feed", true)];
    setOverride.mockResolvedValueOnce(returned);
    const order: string[] = [];
    const setData = vi.spyOn(qc, "setQueryData");
    const invalidate = vi.spyOn(qc, "invalidateQueries").mockImplementation((async () => {
      // By the time the refetch is requested, the returned catalog is already in the cache.
      order.push("invalidate");
      expect(qc.getQueryData(key)).toEqual(returned);
    }) as never);
    setData.mockImplementation(((k: unknown, d: unknown) => {
      order.push("set");
      return QueryClient.prototype.setQueryData.call(qc, k as never, d as never);
    }) as never);
    const wrapper = ({ children }: { children: ReactNode }) => (
      <QueryClientProvider client={qc}>{children}</QueryClientProvider>
    );
    const { result } = renderHook(() => useSetSyncOverride("ecosystem", "eco-1"), { wrapper });
    await act(async () => {
      await result.current.mutateAsync({ resource: "content.notes", enabled: true });
    });
    expect(setOverride).toHaveBeenCalledWith("eco-1", "content.notes", true);
    expect(setData).toHaveBeenCalledWith(key, returned);
    expect(invalidate).toHaveBeenCalledTimes(1);
    expect(invalidate).toHaveBeenCalledWith({ queryKey: key });
    expect(order).toEqual(["set", "invalidate"]);
  });
});

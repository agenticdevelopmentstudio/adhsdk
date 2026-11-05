// @vitest-environment jsdom
import { afterEach, describe, expect, it, vi } from "vitest";
import type { ReactElement } from "react";
import { act, cleanup, render } from "@testing-library/react";
import { QueryClient, QueryClientProvider, useQuery } from "@tanstack/react-query";
import { useRefreshAll } from "./use-refresh-all";

afterEach(cleanup);

function Watch({ queryKey, fn }: { queryKey: string[]; fn: () => Promise<number> }): null {
  useQuery({ queryKey, queryFn: fn });
  return null;
}

describe("useRefreshAll", () => {
  it("refetches only what is on screen, and leaves the self-polling queries to themselves", async () => {
    const client = new QueryClient({ defaultOptions: { queries: { staleTime: Infinity } } });
    const onScreen = vi.fn(async () => 1);
    const cached = vi.fn(async () => 1);
    const dashboard = vi.fn(async () => 1);
    // A range the visitor opened earlier and left: cached, with no observer any more.
    await client.prefetchQuery({ queryKey: ["analytics-dashboard", "7d"], queryFn: cached });
    await client.prefetchQuery({ queryKey: ["uptime-old"], queryFn: cached });

    let refresh = (): void => {};
    function Board(): ReactElement {
      refresh = useRefreshAll(3_600_000).refreshAll;
      return (
        <>
          <Watch queryKey={["uptime"]} fn={onScreen} />
          <Watch queryKey={["errors-dashboard"]} fn={dashboard} />
        </>
      );
    }
    render(
      <QueryClientProvider client={client}>
        <Board />
      </QueryClientProvider>,
    );
    await vi.waitFor(() => expect(onScreen).toHaveBeenCalledTimes(1));
    await vi.waitFor(() => expect(dashboard).toHaveBeenCalledTimes(1));
    cached.mockClear();

    await act(async () => {
      refresh();
    });
    await vi.waitFor(() => expect(onScreen).toHaveBeenCalledTimes(2));
    expect(dashboard).toHaveBeenCalledTimes(1);
    expect(cached).not.toHaveBeenCalled();
  });
});

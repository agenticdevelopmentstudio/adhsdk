// @vitest-environment jsdom
import { describe, it, expect, vi, afterEach } from "vitest";
import { render, screen, fireEvent, cleanup, waitFor } from "@testing-library/react";
import { QueryClient, QueryClientProvider } from "@tanstack/react-query";
import type { StaleMonitor } from "../lib/live-types";
import { StaleMonitorsBanner } from "./StaleMonitorsBanner";

const deleteEndpoint = vi.hoisted(() => vi.fn(async () => {}));
vi.mock("../api/monitored-sites", () => ({ deleteEndpoint }));

// The SERVER picks the retire candidates (`/live`'s `staleMonitors`); the banner renders them.
const monitors = vi.hoisted(() => ({ current: [] as StaleMonitor[], older: false }));
vi.mock("../hooks/use-live-snapshot", () => ({
  useLiveSnapshot: () => ({
    // `older`: a snapshot from a backend that predates `staleMonitors`.
    snapshot: monitors.older ? {} : { staleMonitors: { thresholdDays: 7, monitors: monitors.current } },
  }),
}));

afterEach(() => {
  cleanup(); // no vitest globals → RTL's auto-cleanup never registers
  deleteEndpoint.mockClear();
  monitors.current = [];
  monitors.older = false;
});

// jsdom has no ResizeObserver; the Popover primitive observes its content size.
class ResizeObserverStub {
  observe(): void {}
  unobserve(): void {}
  disconnect(): void {}
}
(globalThis as { ResizeObserver?: unknown }).ResizeObserver ??= ResizeObserverStub;

const svc = (over: Partial<StaleMonitor> = {}): StaleMonitor => ({
  slug: "ep-1",
  name: "docs.example.com",
  url: "https://docs.example.com",
  environment: "production",
  detail: "HTTP 500",
  dnsOk: true,
  downSince: new Date(Date.now() - 21 * 86_400_000).toISOString(),
  ageMs: 21 * 86_400_000,
  ...over,
});

function banner(list: StaleMonitor[]) {
  monitors.current = list;
  const client = new QueryClient({ defaultOptions: { queries: { retry: false } } });
  return render(
    <QueryClientProvider client={client}>
      <StaleMonitorsBanner />
    </QueryClientProvider>,
  );
}

const open = () =>
  fireEvent.click(screen.getByRole("button", { name: "Review monitors that have been down long enough to retire" }));

// The no-auto-delete rule, pinned once. It is what separates the ambiguous case from the
// conclusive one: nothing offered here may be removed without the operator confirming THAT
// row, because nothing offered here is provably dead — a monitor that IS provably dead is
// deleted by the backend cycle and never reaches this component at all.
describe("StaleMonitorsBanner", () => {
  it("renders nothing when there is nothing to retire", () => {
    const { container } = banner([]);
    expect(container.firstChild).toBeNull();
  });

  it("renders nothing, rather than throwing, for a backend older than staleMonitors", () => {
    monitors.older = true;
    const { container } = banner([]);
    expect(container.firstChild).toBeNull();
  });

  it("arms a confirm instead of deleting; only confirming calls the API", async () => {
    banner([svc()]);
    open();

    fireEvent.click(await screen.findByRole("button", { name: "Retire" }));
    expect(deleteEndpoint).not.toHaveBeenCalled(); // armed, not executed
    expect(screen.getByText("Retire the monitor for docs.example.com?")).toBeTruthy();

    // The modal's own Retire button (the row's is the other one).
    const buttons = screen.getAllByRole("button", { name: "Retire" });
    fireEvent.click(buttons[buttons.length - 1]!);
    await waitFor(() => expect(deleteEndpoint).toHaveBeenCalledWith(expect.anything(), "ep-1"));
  });

  it("Cancel closes the confirm without deleting", async () => {
    banner([svc()]);
    open();
    fireEvent.click(await screen.findByRole("button", { name: "Retire" }));

    fireEvent.click(screen.getByRole("button", { name: "Cancel" }));

    expect(deleteEndpoint).not.toHaveBeenCalled();
    expect(screen.queryByText("Retire the monitor for docs.example.com?")).toBeNull();
  });

  it("renders the identical banner whether or not the host resolves", async () => {
    // The chip used to branch on DNS ("STILL RESOLVING" vs "NOTHING RESOLVES") because DNS
    // decided whether the backend would delete the row. It no longer does, so there is one
    // banner saying one thing: down this long, and nothing said it was deleted.
    for (const dnsOk of [true, false]) {
      banner([svc({ dnsOk, detail: dnsOk ? "HTTP 500" : "DNS: does not resolve" })]);
      expect(screen.getByText(/🗑 RETIRE: 1 stale monitor down 7d\+/)).toBeTruthy();
      open();
      expect(await screen.findByRole("button", { name: "Retire" })).toBeTruthy();
      cleanup();
    }
  });

  it("the confirm EXPLAINS the DNS result without claiming it decides anything", async () => {
    banner([svc()]);
    open();
    fireEvent.click(await screen.findByRole("button", { name: "Retire" }));
    expect(screen.getByText(/It still resolves, but has been down/)).toBeTruthy();
    cleanup();

    // A dead name is the operator's call too, and the copy has to say why: not resolving is
    // not proof the deployment is gone, and nothing is going to remove this row for them.
    banner([svc({ dnsOk: false, detail: "DNS: does not resolve" })]);
    open();
    fireEvent.click(await screen.findByRole("button", { name: "Retire" }));
    expect(screen.getByText(/has not resolved for/)).toBeTruthy();
    expect(screen.getByText(/only removed automatically once no platform project claims it/)).toBeTruthy();
  });
});

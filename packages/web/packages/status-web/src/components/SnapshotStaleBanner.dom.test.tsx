// @vitest-environment jsdom
import { describe, it, expect, vi, afterEach } from "vitest";
import { render, screen, cleanup } from "@testing-library/react";
import { SnapshotStaleBanner } from "./SnapshotStaleBanner";

// The SERVER judges the lag (`/live`'s `freshness`); the banner only renders the verdict.
const live = vi.hoisted(() => ({ snapshot: null as Record<string, unknown> | null }));
vi.mock("../hooks/use-live-snapshot", () => ({ useLiveSnapshot: () => ({ snapshot: live.snapshot }) }));

afterEach(() => {
  cleanup(); // no vitest globals → RTL's auto-cleanup never registers
  live.snapshot = null;
});

const NOW = "2026-11-06T12:00:00.000Z";
const AS_OF = "2026-11-06T11:30:00.000Z";

describe("SnapshotStaleBanner", () => {
  it("announces the pause the server judged", () => {
    live.snapshot = { generatedAt: NOW, freshness: { state: "very-stale", asOf: AS_OF } };
    render(<SnapshotStaleBanner />);
    expect(screen.getByRole("status").textContent).toContain("MONITORING PAUSED");
  });

  it("stays silent on a fresh verdict", () => {
    live.snapshot = { generatedAt: NOW, freshness: { state: "fresh", asOf: AS_OF } };
    const { container } = render(<SnapshotStaleBanner />);
    expect(container.firstChild).toBeNull();
  });

  it("stays silent, rather than throwing, for a backend older than freshness", () => {
    live.snapshot = { generatedAt: NOW };
    const { container } = render(<SnapshotStaleBanner />);
    expect(container.firstChild).toBeNull();
  });
});

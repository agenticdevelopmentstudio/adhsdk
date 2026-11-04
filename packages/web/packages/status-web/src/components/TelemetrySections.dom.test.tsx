// @vitest-environment jsdom
import { describe, it, expect, vi, afterEach } from "vitest";
import { render, screen, cleanup } from "@testing-library/react";
import { ErrorsCard, TrafficCard } from "./TelemetrySections";
import { StatusHostProvider } from "./StatusHost";

// The cards' deep links come from the HOST (StatusHostProvider), never from an
// environment variable or a built-in hostname — the package must not know where a
// deployment's GlitchTip or PostHog live. Both cards, both directions.

const telemetry = vi.hoisted(() => ({ errors: [] as unknown[] }));

vi.mock("../hooks/use-telemetry", () => ({
  useTelemetry: () => ({ errors: telemetry.errors, analytics: [], stale: false, offline: false }),
}));

afterEach(() => {
  cleanup();
  telemetry.errors = [];
});

function issue(id: string, level: string, hoursAgo: number, count: number): unknown {
  const seen = new Date(Date.now() - hoursAgo * 3_600_000).toISOString();
  return { id, issueKey: id, project: "adh", title: `Issue ${id}`, culprit: null, level, count, userCount: 0, firstSeen: seen, lastSeen: seen, permalink: null };
}

describe("the Errors card", () => {
  it("stays calm over a backlog: old issues are counted but raise no alarm", () => {
    telemetry.errors = [issue("old", "error", 72, 500), issue("warn", "warning", 1, 40)];
    render(<ErrorsCard />);
    expect(screen.getByText("✓ No errors in the last 24h")).toBeTruthy();
    expect(screen.queryByText("Issue old")).toBeNull();
    expect(screen.getByText("backlog").parentElement?.textContent).toContain("2");
    expect(screen.getByText("active · 24h").parentElement?.textContent).toContain("0");
  });

  it("lists only what is active, largest first", () => {
    telemetry.errors = [issue("small", "error", 1, 3), issue("big", "fatal", 2, 30), issue("old", "error", 72, 500)];
    render(<ErrorsCard />);
    expect(screen.queryByText("✓ No errors in the last 24h")).toBeNull();
    expect(screen.queryByText("Issue old")).toBeNull();
    const big = screen.getByText("Issue big");
    const small = screen.getByText("Issue small");
    expect(big.compareDocumentPosition(small) & Node.DOCUMENT_POSITION_FOLLOWING).toBeTruthy();
    expect(screen.getByText("active · 24h").parentElement?.textContent).toContain("2");
  });

  it("always leads to the Errors topic", () => {
    render(<ErrorsCard />);
    expect(screen.getByRole("link", { name: /All errors/ }).getAttribute("href")).toBe("/errors");
  });
});

describe("telemetry card deep links", () => {
  it("link to the host-supplied GlitchTip and PostHog URLs", () => {
    render(
      <StatusHostProvider settings={{ glitchtipUrl: "https://errors.example.test/org", posthogUrl: "https://analytics.example.test" }}>
        <ErrorsCard />
        <TrafficCard />
      </StatusHostProvider>,
    );
    expect(screen.getByRole("link", { name: /GlitchTip/ }).getAttribute("href")).toBe("https://errors.example.test/org");
    expect(screen.getByRole("link", { name: /PostHog/ }).getAttribute("href")).toBe("https://analytics.example.test");
  });

  it("render no deep link when the host supplies none", () => {
    render(
      <>
        <ErrorsCard />
        <TrafficCard />
      </>,
    );
    expect(screen.queryByRole("link", { name: /GlitchTip/ })).toBeNull();
    expect(screen.queryByRole("link", { name: /PostHog/ })).toBeNull();
    // The cards themselves still render — a missing link never hides the data.
    expect(screen.queryByText("Errors")).not.toBeNull();
    expect(screen.queryByText("Traffic")).not.toBeNull();
  });
});

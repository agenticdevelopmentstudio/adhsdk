/// <reference types="@testing-library/jest-dom/vitest" />
//
// THE HUB-DATA ECOSYSTEM ID: the workspace's live personal/organization child, else the default
// (infrastructure) ecosystem it held its data in before the move. The fallback is what keeps hub
// reads working for a user the move has not reached.
import type { ReactElement } from "react";
import { render, screen, cleanup, waitFor } from "@testing-library/react";
import { afterEach, describe, expect, it, vi } from "vitest";
import { QueryClientProvider } from "@tanstack/react-query";

vi.mock("../../http", async (importOriginal) => ({
  ...(await importOriginal<typeof import("../../http")>()),
  authedJson: vi.fn(),
}));

import { useWorkspaceHubEcosystemId, useWorkspaceHubScope } from "../use-workspace-hub-ecosystem";
import { isHubDataEcosystem, toEcosystem } from "../ecosystems";
import { getToolkitQueryClient } from "../../query";
import { authedJson } from "../../http";

const mockedJson = vi.mocked(authedJson);
const qc = getToolkitQueryClient();

const row = (id: string, extra: Record<string, unknown> = {}) => ({
  id,
  name: id,
  slug: id,
  isDefault: false,
  createdAt: "",
  updatedAt: "",
  ...extra,
});

/** Answers the two reads the hook makes: the workspace's owned list, and the infrastructure row. */
function serve(owned: unknown[] | Error, infra: unknown[]) {
  mockedJson.mockImplementation(async (url: string) => {
    if (String(url).includes("infrastructure=true")) return infra;
    if (owned instanceof Error) throw owned;
    return owned;
  });
}

function Probe({ slug }: { slug: string }): ReactElement {
  const id = useWorkspaceHubEcosystemId(slug);
  return <div data-testid="probe">{id === undefined ? "pending" : (id ?? "none")}</div>;
}

const mount = (slug: string) =>
  render(
    <QueryClientProvider client={qc}>
      <Probe slug={slug} />
    </QueryClientProvider>,
  );

afterEach(() => {
  cleanup();
  qc.clear();
  vi.clearAllMocks();
});

describe("useWorkspaceHubEcosystemId", () => {
  it("is pending until both answers are in", () => {
    mockedJson.mockImplementation(() => new Promise(() => {}));
    mount("acme");
    expect(screen.getByTestId("probe").textContent).toBe("pending");
  });

  it("returns the live personal/organization child", async () => {
    serve([row("p-1", { type: "container" }), row("hub-1", { type: "personal" })], [row("infra-1")]);
    mount("acme-hub");
    await waitFor(() => expect(screen.getByTestId("probe").textContent).toBe("hub-1"));
  });

  it("falls back to the default ecosystem when the workspace has no hub-data child", async () => {
    serve([row("p-1", { type: "container" })], [row("infra-2", { canManage: true })]);
    mount("acme-old");
    await waitFor(() => expect(screen.getByTestId("probe").textContent).toBe("infra-2"));
  });

  it("falls back when the owned list is from a backend that sends no type", async () => {
    serve([row("p-1")], [row("infra-3")]);
    mount("acme-untyped");
    await waitFor(() => expect(screen.getByTestId("probe").textContent).toBe("infra-3"));
  });

  it("falls back when the owned list read fails", async () => {
    serve(new Error("boom"), [row("infra-4")]);
    mount("acme-err");
    await waitFor(() => expect(screen.getByTestId("probe").textContent).toBe("infra-4"));
  });

  it("is null when the workspace has neither", async () => {
    serve([], []);
    mount("acme-none");
    await waitFor(() => expect(screen.getByTestId("probe").textContent).toBe("none"));
  });
});

function ScopeProbe({ slug }: { slug: string }): ReactElement {
  const s = useWorkspaceHubScope(slug);
  return (
    <div data-testid="scope">
      {`${s.isPending ? "pending" : (s.ecosystemId ?? "none")}|${s.canManage ? "manage" : "view"}`}
    </div>
  );
}

describe("useWorkspaceHubScope", () => {
  const mountScope = (slug: string) =>
    render(
      <QueryClientProvider client={qc}>
        <ScopeProbe slug={slug} />
      </QueryClientProvider>,
    );

  it("is the hub-data id with the workspace's management flag", async () => {
    serve([row("hub-9", { type: "organization" })], [row("infra-9", { canManage: false })]);
    mountScope("acme-scope");
    await waitFor(() => expect(screen.getByTestId("scope").textContent).toBe("hub-9|view"));
  });

  it("falls back to the default ecosystem before the move", async () => {
    serve([], [row("infra-8")]);
    mountScope("acme-scope-old");
    await waitFor(() => expect(screen.getByTestId("scope").textContent).toBe("infra-8|manage"));
  });

  it("stays pending while the workspace read is in flight even when the child id is known", async () => {
    mockedJson.mockImplementation(async (url: string) => {
      if (String(url).includes("infrastructure=true")) return new Promise(() => {});
      return [row("hub-7", { type: "personal" })];
    });
    mountScope("acme-scope-partial");
    await waitFor(() => expect(mockedJson).toHaveBeenCalledTimes(2));
    await new Promise((r) => setTimeout(r, 50));
    expect(screen.getByTestId("scope").textContent).toBe("pending|manage");
  });

  it("is pending while the lookups are in flight", () => {
    mockedJson.mockImplementation(() => new Promise(() => {}));
    mountScope("acme-scope-wait");
    expect(screen.getByTestId("scope").textContent).toBe("pending|manage");
  });
});

describe("isHubDataEcosystem", () => {
  it("is true for personal and organization only; a missing type is not hub data", () => {
    expect(isHubDataEcosystem({ type: "personal" })).toBe(true);
    expect(isHubDataEcosystem({ type: "organization" })).toBe(true);
    for (const type of ["workspace", "persona", "container", "product"]) {
      expect(isHubDataEcosystem({ type })).toBe(false);
    }
    expect(isHubDataEcosystem({})).toBe(false);
    expect(isHubDataEcosystem(null)).toBe(false);
  });

  it("survives the wire mapper, and omits type when the wire does", () => {
    expect(toEcosystem(row("a", { type: "personal" }) as never).type).toBe("personal");
    expect("type" in toEcosystem(row("b") as never)).toBe(false);
  });
});

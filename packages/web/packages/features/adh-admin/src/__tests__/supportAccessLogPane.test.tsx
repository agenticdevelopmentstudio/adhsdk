// @vitest-environment jsdom
// The Support Access Log pane: nothing is read until a grant id is applied, a non-uuid is refused
// beside the field, the reads list with method and path, paging, and the switch off. Mocks only
// the hook.
import { cleanup, fireEvent, render, screen, within } from "@testing-library/react";
import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";

const hooks = vi.hoisted(() => ({ useOperatorSupportAccess: vi.fn() }));

vi.mock("@adh-sdk/data/support", async (importOriginal) => ({
  ...(await importOriginal<typeof import("@adh-sdk/data/support")>()),
  useOperatorSupportAccess: hooks.useOperatorSupportAccess,
}));

import { AuthHttpError } from "@adh-sdk/auth/client";
import type { SupportAccess } from "@adh-sdk/data/support";
import { SupportAccessLogPane } from "../panes/SupportAccessLogPane";

const GRANT = "5f0e1d2c-3b4a-4958-8776-655443322110";

const read = (id: string, path: string): SupportAccess => ({
  id,
  grantId: GRANT,
  granteeName: null,
  route: "/support/grants/:id/data/:schema/:table",
  path,
  method: "GET",
  at: "2026-11-20T12:00:00.000Z",
});

const logIs = (items: SupportAccess[] | undefined, nextCursor: string | null = null, error: unknown = null) =>
  hooks.useOperatorSupportAccess.mockImplementation((f: { grantId?: string }) =>
    f.grantId
      ? { data: items ? { items, nextCursor } : undefined, error, isLoading: false }
      : { data: undefined, error: null, isLoading: false },
  );

const apply = (id: string) => {
  fireEvent.change(screen.getByLabelText("Grant id"), { target: { value: id } });
  fireEvent.click(screen.getByRole("button", { name: "Show reads" }));
};

beforeEach(() => {
  hooks.useOperatorSupportAccess.mockReset();
  logIs([read("r1", `/v1/support/grants/${GRANT}/data/content/notes`), read("r2", `/v1/support/grants/${GRANT}/data/content/tasks`)]);
});
afterEach(cleanup);

describe("SupportAccessLogPane", () => {
  it("asks for a grant id before reading", () => {
    render(<SupportAccessLogPane />);
    expect(hooks.useOperatorSupportAccess).toHaveBeenLastCalledWith({ grantId: undefined, cursor: undefined });
    expect(screen.getByText(/Enter a grant id/)).toBeTruthy();
  });

  it("refuses a grant id that is not a uuid", () => {
    render(<SupportAccessLogPane />);
    apply("not-a-grant");
    expect(screen.getByRole("alert").textContent).toMatch(/uuid/);
    expect(hooks.useOperatorSupportAccess).toHaveBeenLastCalledWith({ grantId: undefined, cursor: undefined });
  });

  it("lists the reads under the grant applied", () => {
    render(<SupportAccessLogPane />);
    apply(` ${GRANT.toUpperCase()} `);
    expect(hooks.useOperatorSupportAccess).toHaveBeenLastCalledWith({ grantId: GRANT, cursor: undefined });
    const rows = within(screen.getByRole("table", { name: "Reads" })).getAllByRole("row");
    expect(rows).toHaveLength(3);
    expect(rows[1]!.textContent).toContain("GET");
    expect(rows[1]!.textContent).toContain("/content/notes");
  });

  it("pages by the next cursor", () => {
    logIs([read("r1", "/v1/x")], "r1");
    render(<SupportAccessLogPane />);
    apply(GRANT);
    fireEvent.click(screen.getByRole("button", { name: "Next" }));
    expect(hooks.useOperatorSupportAccess).toHaveBeenLastCalledWith({ grantId: GRANT, cursor: "r1" });
  });

  it("says when there are no reads", () => {
    logIs([]);
    render(<SupportAccessLogPane />);
    apply(GRANT);
    expect(screen.getByText("No reads under this grant.")).toBeTruthy();
  });

  it("says when the log answers 404", () => {
    logIs(undefined, null, new AuthHttpError(404, "Not found"));
    render(<SupportAccessLogPane />);
    apply(GRANT);
    expect(screen.getByText(/not turned on/)).toBeTruthy();
  });
});

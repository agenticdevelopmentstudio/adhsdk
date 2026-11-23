// @vitest-environment jsdom
// The operator's Support Grants pane: every grant, filtered by status and consent, break-glass
// listed apart and a revoked break-glass drawn in red, revoke on a live grant, and the request on
// someone's behalf with its checks and the step-up refusal. Mocks only the data boundary (the
// hooks); the rules (grantState, supportRequestProblem, isStepUpRequired) are the real ones.
import { cleanup, fireEvent, render, screen, waitFor, within } from "@testing-library/react";
import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";

const hooks = vi.hoisted(() => ({
  useOperatorSupportGrants: vi.fn(),
  request: vi.fn(),
  revoke: vi.fn(),
}));

vi.mock("@adh-sdk/data/support", async (importOriginal) => ({
  ...(await importOriginal<typeof import("@adh-sdk/data/support")>()),
  useOperatorSupportGrants: hooks.useOperatorSupportGrants,
  useOperatorRequestGrant: () => ({ mutateAsync: hooks.request, isPending: false }),
  useOperatorRevokeGrant: () => ({ mutateAsync: hooks.revoke, isPending: false }),
}));

import { AuthHttpError } from "@adh-sdk/auth/client";
import type { SupportAdminGrant } from "@adh-sdk/data/support";
import { SupportGrantsAdminPane } from "../panes/SupportGrantsAdminPane";

const HOUR = 3600 * 1000;
const ago = (ms: number) => new Date(Date.now() - ms).toISOString();
const ahead = (ms: number) => new Date(Date.now() + ms).toISOString();
const TARGET = "11111111-1111-4111-8111-111111111111";
const ECO = "22222222-2222-4222-8222-222222222222";
const REASON = "The sync for this account stalled and I need to see why.";

const grant = (over: Partial<SupportAdminGrant> & { id: string }): SupportAdminGrant => ({
  ecosystemId: ECO,
  granteeKind: "operator",
  granteeName: "Ops",
  granteeRole: "Operator",
  reason: REASON,
  consent: "customer",
  requestedFor: 24,
  requestedAt: ago(HOUR),
  decision: "approved",
  decidedAt: ago(HOUR),
  expiresAt: ahead(10 * HOUR),
  revokedAt: null,
  targetId: TARGET,
  targetName: "Sam",
  ...over,
});

const LIVE = grant({ id: "g-live", targetName: "Sam" });
const BG_REVOKED = grant({
  id: "g-bg-revoked",
  targetName: "Kai",
  consent: "break_glass",
  requestedFor: 2,
  revokedAt: ago(HOUR / 2),
});
const BG_LIVE = grant({ id: "g-bg-live", targetName: "Lee", consent: "break_glass", requestedFor: 1 });
const DENIED = grant({ id: "g-denied", targetName: "Ann", decision: "denied", expiresAt: null });

const listIs = (items: SupportAdminGrant[] | undefined, nextCursor: string | null = null, error: unknown = null) =>
  hooks.useOperatorSupportGrants.mockReturnValue({
    data: items ? { items, nextCursor } : undefined,
    error,
    isLoading: !items && !error,
  });

const form = () => screen.getByRole("form", { name: "Ask for consent" });
const fill = (over: Partial<Record<"kind" | "target" | "ecosystem" | "reason" | "hours", string>> = {}) => {
  const f = form();
  if (over.kind) fireEvent.change(within(f).getByLabelText("Whose content"), { target: { value: over.kind } });
  fireEvent.change(within(f).getByLabelText("Target id"), { target: { value: over.target ?? TARGET } });
  const eco = within(f).queryByLabelText("Product (ecosystem id)");
  if (eco) fireEvent.change(eco, { target: { value: over.ecosystem ?? ECO } });
  fireEvent.change(within(f).getByLabelText("Reason"), { target: { value: over.reason ?? REASON } });
  fireEvent.change(within(f).getByLabelText("Hours"), { target: { value: over.hours ?? "24" } });
};
const send = () => fireEvent.click(within(form()).getByRole("button", { name: "Ask for consent" }));

beforeEach(() => {
  hooks.request.mockReset().mockResolvedValue(LIVE);
  hooks.revoke.mockReset().mockResolvedValue(undefined);
  listIs([LIVE, BG_REVOKED, BG_LIVE, DENIED]);
});
afterEach(cleanup);

describe("SupportGrantsAdminPane: the list", () => {
  it("lists break-glass grants apart from consented ones", () => {
    render(<SupportGrantsAdminPane />);
    const bg = screen.getByRole("region", { name: "Break-glass grants" });
    const consented = screen.getByRole("region", { name: "Consented grants" });
    expect(within(bg).getAllByRole("article").map((a) => a.getAttribute("aria-label"))).toEqual([
      "Support grant for Kai",
      "Support grant for Lee",
    ]);
    expect(within(consented).getAllByRole("article")).toHaveLength(2);
  });

  it("draws a revoked break-glass grant in red, and no other", () => {
    render(<SupportGrantsAdminPane />);
    const revoked = screen.getByRole("article", { name: "Support grant for Kai" });
    expect(revoked.getAttribute("data-revoked-break-glass")).toBe("true");
    expect(revoked.className).toContain("border-apt-red");
    expect(revoked.className).not.toContain("opacity-60");
    expect(within(revoked).getByText("Revoked").className).toContain("text-apt-red");
    for (const name of ["Support grant for Lee", "Support grant for Sam", "Support grant for Ann"]) {
      const card = screen.getByRole("article", { name });
      expect(card.getAttribute("data-revoked-break-glass")).toBeNull();
      expect(card.className).not.toContain("border-apt-red");
    }
    // An ordinary ended grant is greyed, not red.
    expect(screen.getByRole("article", { name: "Support grant for Ann" }).className).toContain("opacity-60");
  });

  it("revokes a live grant, and offers revoke on live grants only", async () => {
    render(<SupportGrantsAdminPane />);
    expect(within(screen.getByRole("article", { name: "Support grant for Kai" })).queryByRole("button")).toBeNull();
    expect(within(screen.getByRole("article", { name: "Support grant for Ann" })).queryByRole("button")).toBeNull();
    fireEvent.click(screen.getByRole("button", { name: "Revoke the grant for Lee" }));
    await waitFor(() => expect(hooks.revoke).toHaveBeenCalledWith("g-bg-live"));
  });

  it("filters by status and consent", () => {
    render(<SupportGrantsAdminPane />);
    fireEvent.change(screen.getByLabelText("Status"), { target: { value: "revoked" } });
    expect(hooks.useOperatorSupportGrants).toHaveBeenLastCalledWith({
      status: "revoked",
      consent: undefined,
      cursor: undefined,
    });
    fireEvent.change(screen.getByLabelText("Consent"), { target: { value: "break_glass" } });
    expect(hooks.useOperatorSupportGrants).toHaveBeenLastCalledWith({
      status: "revoked",
      consent: "break_glass",
      cursor: undefined,
    });
  });

  it("pages by the next cursor", () => {
    listIs([LIVE], "g-live");
    render(<SupportGrantsAdminPane />);
    fireEvent.click(screen.getByRole("button", { name: "Next" }));
    expect(hooks.useOperatorSupportGrants).toHaveBeenLastCalledWith({
      status: undefined,
      consent: undefined,
      cursor: "g-live",
    });
  });

  it("says support access is off when the list answers 404", () => {
    listIs(undefined, null, new AuthHttpError(404, "Not found"));
    render(<SupportGrantsAdminPane />);
    expect(screen.getByText("Support access is not turned on.")).toBeTruthy();
    expect(screen.queryByRole("form")).toBeNull();
  });
});

describe("SupportGrantsAdminPane: asking on someone's behalf", () => {
  it("sends a customer's request with the product", async () => {
    render(<SupportGrantsAdminPane />);
    fill({ hours: "48" });
    send();
    await waitFor(() =>
      expect(hooks.request).toHaveBeenCalledWith({
        targetKind: "customer",
        targetId: TARGET,
        ecosystemId: ECO,
        reason: REASON,
        hours: 48,
      }),
    );
  });

  it("sends a hub user's request with no product", async () => {
    render(<SupportGrantsAdminPane />);
    fill({ kind: "account" });
    expect(within(form()).queryByLabelText("Product (ecosystem id)")).toBeNull();
    send();
    await waitFor(() =>
      expect(hooks.request).toHaveBeenCalledWith({
        targetKind: "account",
        targetId: TARGET,
        ecosystemId: undefined,
        reason: REASON,
        hours: 24,
      }),
    );
  });

  it.each([
    ["a target that is not a uuid", { target: "sam" }, /target id must be a uuid/],
    ["a customer with no product", { ecosystem: "" }, /ecosystem id/],
    ["a short reason", { reason: "short" }, /at least 10/],
    ["more than seven days", { hours: "169" }, /1 to 168/],
  ])("refuses %s before sending", (_n, over, text) => {
    render(<SupportGrantsAdminPane />);
    fill(over);
    send();
    expect(within(form()).getByRole("alert").textContent).toMatch(text);
    expect(hooks.request).not.toHaveBeenCalled();
  });

  it("says to sign in again on step_up_required", async () => {
    hooks.request.mockRejectedValueOnce(new AuthHttpError(403, "x", "step_up_required"));
    render(<SupportGrantsAdminPane />);
    fill();
    send();
    expect((await within(form()).findByRole("alert")).textContent).toMatch(/second factor/);
  });
});

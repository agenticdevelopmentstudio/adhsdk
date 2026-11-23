// @vitest-environment jsdom
// The person's view of support access: grants in order (pending, live, ended), approve, deny and
// revoke, the break-glass mark, the read log grouped by table and day, the switch off, and a
// refusal shown as the backend's message. Mocks only the data boundary (the hooks); the rules
// (grantState, groupAccess, isSupportOff) are the real ones.
import { cleanup, fireEvent, render, screen, waitFor, within } from "@testing-library/react";
import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";

const hooks = vi.hoisted(() => ({
  useSupportGrants: vi.fn(),
  useSupportAccess: vi.fn(),
  decide: vi.fn(),
  useDecideSupportGrant: vi.fn(),
}));

vi.mock("@adh-sdk/data/support", async (importOriginal) => {
  const real = await importOriginal<typeof import("@adh-sdk/data/support")>();
  return {
    grantState: real.grantState,
    groupAccess: real.groupAccess,
    isSupportOff: real.isSupportOff,
    useSupportGrants: hooks.useSupportGrants,
    useSupportAccess: hooks.useSupportAccess,
    useDecideSupportGrant: (side: string) => {
      hooks.useDecideSupportGrant(side);
      return { mutateAsync: hooks.decide, isPending: false };
    },
  };
});

import { AuthHttpError } from "@adh-sdk/auth/client";
import type { SupportAccess, SupportGrant } from "@adh-sdk/data/support";
import { dayPhrase, describeAccess } from "../AccessLogList";
import { hoursPhrase } from "../GrantCard";
import { SupportAccessPane } from "../SupportAccessPane";

const HOUR = 3600 * 1000;
const ago = (ms: number) => new Date(Date.now() - ms).toISOString();
const ahead = (ms: number) => new Date(Date.now() + ms).toISOString();

const grant = (over: Partial<SupportGrant> & { id: string }): SupportGrant => ({
  ecosystemId: "eco-1",
  granteeKind: "product_admin",
  granteeName: "Ana",
  granteeRole: "Support",
  reason: "Your export failed and I need to see the notes it skipped.",
  consent: "customer",
  requestedFor: 24,
  requestedAt: ago(HOUR),
  decision: null,
  decidedAt: null,
  expiresAt: null,
  revokedAt: null,
  ...over,
});

const PENDING = grant({ id: "g-pending", granteeName: "Ana" });
const LIVE = grant({
  id: "g-live",
  granteeName: "Ben",
  requestedAt: ago(3 * HOUR),
  decision: "approved",
  decidedAt: ago(2 * HOUR),
  expiresAt: ahead(20 * HOUR),
});
const ENDED = grant({
  id: "g-ended",
  granteeName: "Cleo",
  requestedAt: ago(50 * HOUR),
  decision: "denied",
  decidedAt: ago(49 * HOUR),
});

const read = (id: string, at: string, table = "notes"): SupportAccess => ({
  id,
  grantId: LIVE.id,
  granteeName: "Ben",
  route: "/support/grants/:id/data/:schema/:table",
  path: `/v1/support/grants/${LIVE.id}/data/content/${table}`,
  method: null,
  at,
});

const grantsAre = (data: SupportGrant[] | undefined, error: unknown = null) =>
  hooks.useSupportGrants.mockReturnValue({ data, error, isPending: data === undefined && !error });

const logIs = (pages: SupportAccess[][], more = false, fetchNextPage = vi.fn()) =>
  hooks.useSupportAccess.mockReturnValue({
    data: { pages: pages.map((items, i) => ({ items, nextCursor: i === pages.length - 1 && more ? "c" : null })) },
    error: null,
    isPending: false,
    hasNextPage: more,
    isFetchingNextPage: false,
    fetchNextPage,
  });

beforeEach(() => {
  vi.clearAllMocks();
  hooks.decide.mockResolvedValue(undefined);
  grantsAre([ENDED, LIVE, PENDING]);
  logIs([[]]);
});

afterEach(cleanup);

const cards = () => screen.getAllByRole("article");

describe("SupportAccessPane", () => {
  it("reads the grants of the side it is given", () => {
    render(<SupportAccessPane side="account" />);
    expect(hooks.useSupportGrants).toHaveBeenCalledWith("account");
    expect(hooks.useDecideSupportGrant).toHaveBeenCalledWith("account");
  });

  it("lists pending first, then live, then ended", () => {
    render(<SupportAccessPane side="customer" />);
    expect(cards().map((c) => c.getAttribute("data-state"))).toEqual(["pending", "live", "ended"]);
    expect(cards()[0]).toHaveTextContent("Ana");
    expect(cards()[2]).toHaveClass("opacity-60");
  });

  it("offers approve and deny on a pending grant, revoke on a live one, nothing on an ended one", () => {
    render(<SupportAccessPane side="customer" />);
    const [pending, live, ended] = cards();
    expect(within(pending!).getByRole("button", { name: "Approve Ana's request" })).toBeInTheDocument();
    expect(within(pending!).getByRole("button", { name: "Deny Ana's request" })).toBeInTheDocument();
    expect(within(pending!).queryByRole("button", { name: /Revoke/ })).toBeNull();
    expect(within(live!).getByRole("button", { name: "Revoke Ben's access" })).toBeInTheDocument();
    expect(within(live!).queryByRole("button", { name: /Approve|Deny/ })).toBeNull();
    expect(within(ended!).queryByRole("button")).toBeNull();
    expect(within(ended!).getByText("Denied")).toBeInTheDocument();
  });

  it.each([
    ["Approve Ana's request", PENDING.id, "approve"],
    ["Deny Ana's request", PENDING.id, "deny"],
    ["Revoke Ben's access", LIVE.id, "revoke"],
  ])("%s calls the decision with the grant's id", async (name, id, action) => {
    render(<SupportAccessPane side="customer" />);
    fireEvent.click(screen.getByRole("button", { name }));
    await waitFor(() => expect(hooks.decide).toHaveBeenCalledWith({ id, action }));
  });

  it("shows a refusal as the backend's message", async () => {
    hooks.decide.mockRejectedValueOnce(new AuthHttpError(409, "This request has already been decided."));
    render(<SupportAccessPane side="customer" />);
    fireEvent.click(screen.getByRole("button", { name: "Approve Ana's request" }));
    expect(await screen.findByText("This request has already been decided.")).toBeInTheDocument();
  });

  it("marks a break-glass grant", () => {
    grantsAre([{ ...LIVE, consent: "break_glass", granteeKind: "operator" }]);
    render(<SupportAccessPane side="account" />);
    expect(screen.getByText("Emergency access")).toBeInTheDocument();
    expect(screen.getByText(/Opened without asking you, in an emergency/)).toBeInTheDocument();
    expect(screen.getByRole("button", { name: "Revoke Ben's access" })).toBeInTheDocument();
  });

  it("says so when no one has asked", () => {
    grantsAre([]);
    render(<SupportAccessPane side="account" />);
    expect(screen.getByText("No one has asked to see your content.")).toBeInTheDocument();
  });

  it("renders nothing while the switch is off", () => {
    grantsAre(undefined, new AuthHttpError(404, "Not found"));
    const { container } = render(<SupportAccessPane side="account" />);
    expect(container).toBeEmptyDOMElement();
  });

  it("shows any other load failure", () => {
    grantsAre(undefined, new AuthHttpError(500, "Server error"));
    render(<SupportAccessPane side="account" />);
    expect(screen.getByText("Couldn't load support access: Server error")).toBeInTheDocument();
  });

  it("shows the log only under a grant that was approved, for that grant", () => {
    render(<SupportAccessPane side="customer" />);
    expect(hooks.useSupportAccess).toHaveBeenCalledTimes(1);
    expect(hooks.useSupportAccess).toHaveBeenCalledWith("customer", LIVE.id);
  });

  it("groups the log by table and day, one sentence a group", () => {
    const today = new Date();
    today.setHours(10, 0, 0, 0);
    const at = (h: number) => new Date(today.getTime() + h * HOUR).toISOString();
    logIs([[read("r1", at(0)), read("r2", at(1)), read("r3", at(2)), read("r4", at(0), "chat_messages")]]);
    grantsAre([LIVE]);
    render(<SupportAccessPane side="customer" />);
    const log = screen.getByRole("list", { name: "What Ben viewed" });
    const lines = within(log)
      .getAllByRole("listitem")
      .map((li) => li.textContent);
    expect(lines).toEqual([
      "Ben from Support viewed your notes, 3 times today",
      "Ben from Support viewed your chat messages, once today",
    ]);
  });

  it("pages the log by its cursor", () => {
    const fetchNextPage = vi.fn();
    logIs([[read("r1", new Date().toISOString())]], true, fetchNextPage);
    grantsAre([LIVE]);
    render(<SupportAccessPane side="customer" />);
    fireEvent.click(screen.getByRole("button", { name: "Show more" }));
    expect(fetchNextPage).toHaveBeenCalledTimes(1);
  });
});

describe("the log's words", () => {
  // Saturday 21 November 2026, local time.
  const NOW = new Date(2026, 10, 21, 15, 0, 0);

  it("names the day as a person would", () => {
    expect(dayPhrase("2026-11-21", NOW)).toBe("today");
    expect(dayPhrase("2026-11-20", NOW)).toBe("yesterday");
    expect(dayPhrase("2026-11-17", NOW)).toBe("on Tuesday");
    expect(dayPhrase("2026-11-12", NOW)).toBe("on 12 Nov");
    expect(dayPhrase("2025-12-30", NOW)).toBe("on 30 Dec 2025");
  });

  it("reads 'Ana from Support viewed your notes, 3 times on Tuesday'", () => {
    expect(
      describeAccess(
        {
          grantId: "g",
          granteeName: "Ana",
          schema: "content",
          table: "notes",
          day: "2026-11-17",
          count: 3,
          latestAt: "2026-11-17T12:00:00",
        },
        { name: "Ana", role: "Support" },
        NOW,
      ),
    ).toBe("Ana from Support viewed your notes, 3 times on Tuesday");
  });

  it("says how long in hours, then days", () => {
    expect(hoursPhrase(1)).toBe("1 hour");
    expect(hoursPhrase(24)).toBe("24 hours");
    expect(hoursPhrase(48)).toBe("2 days");
    expect(hoursPhrase(36)).toBe("1 day and 12 hours");
  });
});

// @vitest-environment jsdom
import { describe, it, expect, afterEach, beforeEach, vi } from "vitest";
import { render, screen, cleanup, fireEvent } from "@testing-library/react";
import type { SupportAccess, SupportAdminGrant } from "@adh-sdk/data/support";

// Only the transport is stubbed: the state helpers (grantState, accessTable) stay real, so the
// labels the page shows are the ones every other support surface computes.
const api = vi.hoisted(() => ({
  get: vi.fn(),
  deny: vi.fn(),
  revoke: vi.fn(),
  sendCode: vi.fn(),
  approve: vi.fn(),
}));
vi.mock("@adh-sdk/data/support", async (importOriginal) => {
  const actual = await importOriginal<typeof import("@adh-sdk/data/support")>();
  return { ...actual, publicSupportApi: api };
});

import { HostedSupportGrant, INVALID_LINK, NO_READS, readsByDay, stateLabel } from "../HostedSupportGrant";

/** An error shaped as the SDK throws it: a status and the backend's code. */
function httpError(status: number, code?: string): Error {
  return Object.assign(new Error(`HTTP ${status}`), { status, code });
}

const HOUR = 3_600_000;
const now = Date.now();

function grant(over: Partial<SupportAdminGrant> = {}): SupportAdminGrant {
  return {
    id: "g-1",
    ecosystemId: "eco-1",
    granteeKind: "product_admin",
    granteeName: "Ana",
    granteeRole: "Support at Acme",
    reason: "Checking why your export failed",
    consent: "customer",
    requestedFor: 24,
    requestedAt: new Date(now - HOUR).toISOString(),
    decision: null,
    decidedAt: null,
    expiresAt: null,
    revokedAt: null,
    targetId: "cust-1",
    targetName: null,
    ...over,
  };
}

const pending = (): SupportAdminGrant => grant();
const live = (): SupportAdminGrant =>
  grant({
    decision: "approved",
    decidedAt: new Date(now - HOUR).toISOString(),
    expiresAt: new Date(now + 23 * HOUR).toISOString(),
  });

function read(id: string, at: string, table = "notes"): SupportAccess {
  return {
    id,
    grantId: "g-1",
    granteeName: "Ana",
    route: "/support/grants/:id/data/:schema/:table",
    path: `/support/grants/g-1/data/content/${table}`,
    method: null,
    at,
  };
}

afterEach(cleanup);
beforeEach(() => {
  for (const fn of Object.values(api)) fn.mockReset();
});

describe("HostedSupportGrant", () => {
  it("shows the invalid-link sentence and makes no call when the query is missing", () => {
    render(<HostedSupportGrant grantId={null} token={null} />);
    expect(screen.getByText(INVALID_LINK)).toBeTruthy();
    expect(api.get).not.toHaveBeenCalled();
  });

  it("shows the invalid-link sentence and makes no call when only the token is missing", () => {
    render(<HostedSupportGrant grantId="g-1" token="" />);
    expect(screen.getByText(INVALID_LINK)).toBeTruthy();
    expect(api.get).not.toHaveBeenCalled();
  });

  it.each([404, 403, 410])("a %i on load shows only the invalid-link sentence", async (status) => {
    api.get.mockRejectedValue(httpError(status));
    render(<HostedSupportGrant grantId="g-1" token="bad" />);
    await screen.findByText(INVALID_LINK);
    expect(api.get).toHaveBeenCalledTimes(1);
    expect(api.get).toHaveBeenCalledWith("g-1", "bad");
    expect(screen.queryByRole("button")).toBeNull();
    expect(screen.queryByText("Ana, Support at Acme")).toBeNull();
  });

  it("a network failure on load is retryable, not the invalid-link sentence", async () => {
    api.get.mockRejectedValueOnce(new TypeError("Failed to fetch"));
    api.get.mockResolvedValueOnce({ grant: pending(), reads: [] });
    render(<HostedSupportGrant grantId="g-1" token="tok" />);
    await screen.findByRole("alert");
    expect(screen.queryByText(INVALID_LINK)).toBeNull();
    fireEvent.click(screen.getByRole("button", { name: "Try again" }));
    await screen.findByText("Pending");
    expect(api.get).toHaveBeenCalledTimes(2);
  });

  it("a 409 on load says the request is settled, with no actions", async () => {
    api.get.mockRejectedValue(httpError(409, "decided"));
    render(<HostedSupportGrant grantId="g-1" token="tok" />);
    await screen.findByText(/already been answered/);
    expect(screen.queryByRole("button")).toBeNull();
  });

  it("takes the token out of the address bar and keeps the grant", async () => {
    window.history.replaceState(null, "", "/support?grant=g-1&token=tok");
    api.get.mockResolvedValue({ grant: pending(), reads: [] });
    render(<HostedSupportGrant grantId="g-1" token="tok" />);
    await screen.findByText("Pending");
    const params = new URLSearchParams(window.location.search);
    expect(params.has("token")).toBe(false);
    expect(params.get("grant")).toBe("g-1");
    // The props still carry it: the actions work after the address is cleaned.
    expect(api.get).toHaveBeenCalledWith("g-1", "tok");
    window.history.replaceState(null, "", "/");
  });

  it("shows who asked, why, for how long, the state and the empty log", async () => {
    api.get.mockResolvedValue({ grant: pending(), reads: [] });
    render(<HostedSupportGrant grantId="g-1" token="tok" />);
    await screen.findByText("Pending");
    expect(screen.getByText("Ana, Support at Acme")).toBeTruthy();
    expect(screen.getByText("Checking why your export failed")).toBeTruthy();
    expect(screen.getByText("1 day")).toBeTruthy();
    expect(screen.getByText(NO_READS)).toBeTruthy();
    expect(api.get).toHaveBeenCalledTimes(1);
  });

  it("deny calls the deny path with the token and no code, and shows Denied", async () => {
    api.get.mockResolvedValue({ grant: pending(), reads: [] });
    api.deny.mockResolvedValue(grant({ decision: "denied", decidedAt: new Date().toISOString() }));
    render(<HostedSupportGrant grantId="g-1" token="tok" />);
    await screen.findByText("Pending");

    fireEvent.click(screen.getByRole("button", { name: "Deny" }));

    await screen.findByText("Denied");
    expect(api.deny).toHaveBeenCalledTimes(1);
    expect(api.deny).toHaveBeenCalledWith("g-1", "tok");
    expect(api.sendCode).not.toHaveBeenCalled();
    expect(api.approve).not.toHaveBeenCalled();
    expect(screen.queryByRole("button", { name: /Deny|Approve|Revoke/ })).toBeNull();
  });

  it("approve without a code sends the code and shows the field, and does not call approve", async () => {
    api.get.mockResolvedValue({ grant: pending(), reads: [] });
    api.sendCode.mockResolvedValue({ ok: true });
    render(<HostedSupportGrant grantId="g-1" token="tok" />);
    await screen.findByText("Pending");

    fireEvent.click(screen.getByRole("button", { name: "Approve" }));

    const field = await screen.findByLabelText("Code");
    expect(api.sendCode).toHaveBeenCalledWith("g-1", "tok");
    // An empty code cannot be submitted, by the button or by Enter.
    const submit = screen.getByRole("button", { name: "Approve with code" }) as HTMLButtonElement;
    expect(submit.disabled).toBe(true);
    fireEvent.submit(field.closest("form") as HTMLFormElement);
    expect(api.approve).not.toHaveBeenCalled();
  });

  it("approve with a code calls approve with it, and shows Live from its answer with no refetch", async () => {
    api.get.mockResolvedValueOnce({ grant: pending(), reads: [] });
    // A refetch would be refused: the approval must not depend on one.
    api.get.mockRejectedValue(httpError(429));
    api.sendCode.mockResolvedValue({ ok: true });
    api.approve.mockResolvedValue(live());
    render(<HostedSupportGrant grantId="g-1" token="tok" />);
    await screen.findByText("Pending");

    fireEvent.click(screen.getByRole("button", { name: "Approve" }));
    const field = await screen.findByLabelText("Code");
    fireEvent.change(field, { target: { value: " 123456 " } });
    // Enter in the field submits the form.
    fireEvent.submit(field.closest("form") as HTMLFormElement);

    await screen.findByText("Live");
    expect(api.approve).toHaveBeenCalledWith("g-1", "tok", "123456");
    expect(api.get).toHaveBeenCalledTimes(1);
    expect(screen.getByRole("button", { name: "Revoke" })).toBeTruthy();
  });

  it("a wrong code keeps the field open with a one-line error", async () => {
    api.get.mockResolvedValue({ grant: pending(), reads: [] });
    api.sendCode.mockResolvedValue({ ok: true });
    api.approve.mockRejectedValue(httpError(403, "code_invalid"));
    render(<HostedSupportGrant grantId="g-1" token="tok" />);
    await screen.findByText("Pending");

    fireEvent.click(screen.getByRole("button", { name: "Approve" }));
    const field = await screen.findByLabelText("Code");
    fireEvent.change(field, { target: { value: "000000" } });
    fireEvent.click(screen.getByRole("button", { name: "Approve with code" }));

    const alert = await screen.findByRole("alert");
    expect(alert.textContent).toMatch(/not accepted/);
    expect(screen.getByLabelText("Code")).toBeTruthy();
    expect(screen.getByText("Pending")).toBeTruthy();
    expect(api.get).toHaveBeenCalledTimes(1);
  });

  it("a live grant shows Revoke only", async () => {
    api.get.mockResolvedValue({ grant: live(), reads: [] });
    render(<HostedSupportGrant grantId="g-1" token="tok" />);
    await screen.findByText("Live");
    const buttons = screen.getAllByRole("button").map((b) => b.textContent);
    expect(buttons).toEqual(["Revoke"]);
  });

  it("revoke calls the revoke path with the token and shows Revoked with the log kept", async () => {
    const reads = [read("r-1", new Date(now - 10 * 60_000).toISOString())];
    api.get.mockResolvedValue({ grant: live(), reads });
    api.revoke.mockResolvedValue({ ...live(), revokedAt: new Date().toISOString() });
    render(<HostedSupportGrant grantId="g-1" token="tok" />);
    await screen.findByText("Live");

    fireEvent.click(screen.getByRole("button", { name: "Revoke" }));

    await screen.findByText("Revoked");
    expect(api.revoke).toHaveBeenCalledWith("g-1", "tok");
    expect(screen.queryByRole("button")).toBeNull();
    expect(screen.getAllByTestId("support-read")).toHaveLength(1);
  });

  it("an action refused for rate limiting keeps the state and says so in one line", async () => {
    api.get.mockResolvedValue({ grant: live(), reads: [] });
    api.revoke.mockRejectedValue(httpError(429, "rate_limited"));
    render(<HostedSupportGrant grantId="g-1" token="tok" />);
    await screen.findByText("Live");

    fireEvent.click(screen.getByRole("button", { name: "Revoke" }));

    const alert = await screen.findByRole("alert");
    expect(alert.textContent).toMatch(/Too many attempts/);
    expect(screen.getByText("Live")).toBeTruthy();
    expect(screen.getByRole("button", { name: "Revoke" })).toBeTruthy();
  });

  it("an action the grant has moved past refetches instead of showing an error", async () => {
    api.get.mockResolvedValueOnce({ grant: pending(), reads: [] });
    api.get.mockRejectedValueOnce(httpError(409, "decided"));
    api.deny.mockRejectedValue(httpError(409, "decided"));
    render(<HostedSupportGrant grantId="g-1" token="tok" />);
    await screen.findByText("Pending");

    fireEvent.click(screen.getByRole("button", { name: "Deny" }));

    await screen.findByText(/already been answered/);
    expect(api.get).toHaveBeenCalledTimes(2);
  });
});

describe("HostedSupportGrant on a product site (ecosystemId)", () => {
  it("the host's own ecosystem, in another case, renders the grant and its actions", async () => {
    api.get.mockResolvedValue({ grant: pending(), reads: [] });
    render(<HostedSupportGrant grantId="g-1" token="tok" ecosystemId="ECO-1" />);
    await screen.findByText("Pending");
    expect(screen.getByText("Ana, Support at Acme")).toBeTruthy();
    expect(screen.getByRole("button", { name: "Deny" })).toBeTruthy();
    expect(screen.getByRole("button", { name: "Approve" })).toBeTruthy();
    expect(screen.queryByText(INVALID_LINK)).toBeNull();
  });

  it("another product's grant shows the invalid-link sentence and no button", async () => {
    api.get.mockResolvedValue({ grant: pending(), reads: [] });
    render(<HostedSupportGrant grantId="g-1" token="tok" ecosystemId="eco-2" />);
    await screen.findByText(INVALID_LINK);
    expect(api.get).toHaveBeenCalledTimes(1);
    expect(screen.queryByRole("button")).toBeNull();
    expect(screen.queryByText("Ana, Support at Acme")).toBeNull();
  });

  it.each([
    ["undefined", undefined],
    ["null", null],
  ])("a grant whose ecosystem is %s fails closed to the invalid-link sentence", async (_name, eco) => {
    const g = { ...pending(), ecosystemId: eco } as unknown as SupportAdminGrant;
    api.get.mockResolvedValue({ grant: g, reads: [] });
    render(<HostedSupportGrant grantId="g-1" token="tok" ecosystemId="eco-1" />);
    await screen.findByText(INVALID_LINK);
    expect(screen.queryByRole("button", { name: "Deny" })).toBeNull();
    expect(screen.queryByRole("button", { name: "Approve" })).toBeNull();
    expect(screen.queryByText(/connection/)).toBeNull();
  });

  it("no ecosystemId renders a grant of any ecosystem, as on the hub", async () => {
    api.get.mockResolvedValue({ grant: grant({ ecosystemId: "eco-9" }), reads: [] });
    render(<HostedSupportGrant grantId="g-1" token="tok" />);
    await screen.findByText("Pending");
    expect(screen.getByText("Ana, Support at Acme")).toBeTruthy();
    expect(screen.getByRole("button", { name: "Deny" })).toBeTruthy();
  });
});

describe("stateLabel", () => {
  it("names each state with the shared labels", () => {
    expect(stateLabel(pending())).toBe("Pending");
    expect(stateLabel(live())).toBe("Live");
    expect(stateLabel(grant({ decision: "denied" }))).toBe("Denied");
    expect(stateLabel({ ...live(), revokedAt: new Date().toISOString() })).toBe("Revoked");
    expect(
      stateLabel(
        grant({ decision: "approved", expiresAt: new Date(now - HOUR).toISOString() }),
        new Date(now),
      ),
    ).toBe("Expired");
  });
});

describe("readsByDay", () => {
  it("groups by local day, newest day first and newest read first", () => {
    const d1 = new Date(2026, 10, 20, 9, 0).toISOString();
    const d1b = new Date(2026, 10, 20, 15, 0).toISOString();
    const d2 = new Date(2026, 10, 22, 11, 0).toISOString();
    const groups = readsByDay([read("a", d1), read("b", d2), read("c", d1b)]);
    expect(groups.map((g) => g.day)).toEqual(["2026-11-22", "2026-11-20"]);
    expect(groups[1]?.reads.map((r) => r.id)).toEqual(["c", "a"]);
  });

  it("is empty for no reads", () => {
    expect(readsByDay([])).toEqual([]);
  });
});

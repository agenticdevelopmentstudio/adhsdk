// @vitest-environment jsdom
// The Break Glass pane: aal 2 shown as required, the attestation of at least 40 characters, the
// reference, 1 to 4 hours, the body it sends, and the step-up refusal. Mocks only the hook.
import { cleanup, fireEvent, render, screen, waitFor } from "@testing-library/react";
import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";

const hooks = vi.hoisted(() => ({ breakGlass: vi.fn() }));

vi.mock("@adh-sdk/data/support", async (importOriginal) => ({
  ...(await importOriginal<typeof import("@adh-sdk/data/support")>()),
  useBreakGlass: () => ({ mutateAsync: hooks.breakGlass, isPending: false }),
}));

import { AuthHttpError } from "@adh-sdk/auth/client";
import { BreakGlassPane } from "../panes/BreakGlassPane";

const TARGET = "11111111-1111-4111-8111-111111111111";
const ECO = "22222222-2222-4222-8222-222222222222";
const REASON = "Data loss reported on a live incident.";
const ATTESTATION = "Incident 42: the customer's data is being destroyed and they cannot be reached.";

function fill(over: Partial<Record<"target" | "ecosystem" | "reason" | "hours" | "attestation" | "reference", string>> = {}) {
  fireEvent.change(screen.getByLabelText("Target id"), { target: { value: over.target ?? TARGET } });
  fireEvent.change(screen.getByLabelText("Product (ecosystem id)"), { target: { value: over.ecosystem ?? ECO } });
  fireEvent.change(screen.getByLabelText("Reason"), { target: { value: over.reason ?? REASON } });
  fireEvent.change(screen.getByLabelText("Hours"), { target: { value: over.hours ?? "2" } });
  fireEvent.change(screen.getByLabelText("Attestation"), { target: { value: over.attestation ?? ATTESTATION } });
  fireEvent.change(screen.getByLabelText("Reference"), { target: { value: over.reference ?? "INC-42" } });
}
const send = () => fireEvent.click(screen.getByRole("button", { name: "Break glass" }));

beforeEach(() => {
  hooks.breakGlass.mockReset().mockResolvedValue({ id: "g-1", expiresAt: "2026-11-23T12:00:00.000Z" });
});
afterEach(cleanup);

describe("BreakGlassPane", () => {
  it("says aal 2 is required", () => {
    render(<BreakGlassPane />);
    expect(screen.getByTestId("aal-required").textContent).toMatch(/aal 2/);
  });

  it("starts at 1 hour", () => {
    render(<BreakGlassPane />);
    expect((screen.getByLabelText("Hours") as HTMLInputElement).value).toBe("1");
  });

  it("breaks glass with the attestation and the reference", async () => {
    render(<BreakGlassPane />);
    fill();
    send();
    await waitFor(() =>
      expect(hooks.breakGlass).toHaveBeenCalledWith({
        targetKind: "customer",
        targetId: TARGET,
        ecosystemId: ECO,
        reason: REASON,
        hours: 2,
        attestation: ATTESTATION,
        attestationRef: "INC-42",
      }),
    );
    expect(await screen.findByText(/Opened\. The grant is live/)).toBeTruthy();
  });

  it("refuses an attestation under 40 characters, counted trimmed", () => {
    render(<BreakGlassPane />);
    fill({ attestation: `  ${"x".repeat(39)}  ` });
    send();
    expect(screen.getByRole("alert").textContent).toMatch(/at least 40 characters/);
    expect(hooks.breakGlass).not.toHaveBeenCalled();
  });

  it("takes an attestation of exactly 40 characters", async () => {
    render(<BreakGlassPane />);
    fill({ attestation: "x".repeat(40) });
    send();
    await waitFor(() => expect(hooks.breakGlass).toHaveBeenCalledTimes(1));
  });

  it.each([
    ["no reference", { reference: "  " }, /reference/],
    ["more than 4 hours", { hours: "5" }, /1 to 4/],
    ["zero hours", { hours: "0" }, /1 to 4/],
    ["a short reason", { reason: "fire" }, /at least 10/],
    ["a target that is not a uuid", { target: "kai" }, /uuid/],
  ])("refuses %s", (_n, over, text) => {
    render(<BreakGlassPane />);
    fill(over);
    send();
    expect(screen.getByRole("alert").textContent).toMatch(text);
    expect(hooks.breakGlass).not.toHaveBeenCalled();
  });

  it("says to sign in again on step_up_required", async () => {
    hooks.breakGlass.mockRejectedValueOnce(new AuthHttpError(403, "x", "step_up_required"));
    render(<BreakGlassPane />);
    fill();
    send();
    expect((await screen.findByRole("alert")).textContent).toMatch(/second factor/);
  });

  it("shows any other refusal as the backend's message", async () => {
    hooks.breakGlass.mockRejectedValueOnce(new AuthHttpError(422, "the target is not a live customer"));
    render(<BreakGlassPane />);
    fill();
    send();
    expect((await screen.findByRole("alert")).textContent).toBe("the target is not a live customer");
  });
});

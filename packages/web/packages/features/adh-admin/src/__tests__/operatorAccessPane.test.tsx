// @vitest-environment jsdom
// The Operator access pane: renders the log's rows (who by email, the request, the target
// ecosystem, the request id) and sends a filter only when it is applied.
import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";
import { QueryClient, QueryClientProvider } from "@tanstack/react-query";
import {
  cleanup,
  fireEvent,
  render,
  screen,
  waitFor,
} from "@testing-library/react";

const { listV1Page, listAllV1 } = vi.hoisted(() => ({
  listV1Page: vi.fn(),
  listAllV1: vi.fn(),
}));
vi.mock("../api/http", async (importOriginal) => ({
  ...(await importOriginal<typeof import("../api/http")>()),
  listV1Page,
  listAllV1,
}));

import { OperatorAccessPane } from "../panes/OperatorAccessPane";

const OP = "11111111-1111-4111-8111-111111111111";
const OP2 = "33333333-3333-4333-8333-333333333333";
const ECO = "22222222-2222-4222-8222-222222222222";

const row = {
  id: "row-1",
  object: "system.operator_access",
  at: "2026-11-21 10:00:00.123+00",
  operator_account_id: OP,
  token_id: null,
  method: "POST",
  path: "/v1/ecosystems/abc/members",
  route: "/v1/ecosystems/:id/members",
  target_ecosystem_id: ECO,
  request_id: "req-abcdef1234",
  ip: null,
  user_agent: null,
};

beforeEach(() => {
  listV1Page.mockReset();
  listV1Page.mockResolvedValue({ data: [row], hasMore: false });
  listAllV1.mockReset();
  listAllV1.mockImplementation(async (url: string) =>
    url === "/api/v1/auth/capabilities/operators"
      ? [
          {
            id: OP,
            email: "root@example.com",
            name: "Root",
            created: 1790812800,
            holds_admin: true,
          },
          {
            id: OP2,
            email: "second@example.com",
            name: "Second",
            created: 1790812800,
            holds_admin: false,
          },
        ]
      : [],
  );
});
afterEach(cleanup);

function mount() {
  const client = new QueryClient({
    defaultOptions: { queries: { retry: false } },
  });
  render(
    <QueryClientProvider client={client}>
      <OperatorAccessPane />
    </QueryClientProvider>,
  );
}

function lastQuery(): URLSearchParams {
  const url = String(listV1Page.mock.calls.at(-1)?.[0]);
  return new URLSearchParams(url.slice(url.indexOf("?") + 1));
}

describe("OperatorAccessPane", () => {
  it("renders who, the request, the target ecosystem and the request id", async () => {
    mount();
    expect(
      await screen.findByText("POST /v1/ecosystems/abc/members"),
    ).toBeTruthy();
    // Who resolves to the operator's email once the operator list arrives.
    await waitFor(() =>
      expect(
        screen
          .getAllByText("root@example.com")
          .some((el) => el.tagName === "SPAN"),
      ).toBe(true),
    );
    expect(screen.getByText(ECO.slice(0, 8))).toBeTruthy();
    expect(screen.getByText("req-abcd")).toBeTruthy();
  });

  it("sends the operator and ecosystem filters only when applied, and clears them", async () => {
    mount();
    await screen.findByText("POST /v1/ecosystems/abc/members");
    expect(lastQuery().has("operator_account_id")).toBe(false);

    await screen.findByRole("option", { name: "second@example.com" });
    const before = listV1Page.mock.calls.length;
    fireEvent.change(screen.getByLabelText("Operator"), {
      target: { value: OP2 },
    });
    fireEvent.change(screen.getByLabelText("Ecosystem id"), {
      target: { value: ` ${ECO} ` },
    });
    // Editing alone asks for nothing new: the window is keyed on the applied filters.
    await new Promise((r) => setTimeout(r, 20));
    expect(listV1Page.mock.calls.length).toBe(before);

    fireEvent.click(screen.getByRole("button", { name: "Apply filters" }));
    await waitFor(() =>
      expect(lastQuery().get("operator_account_id")).toBe(OP2),
    );
    expect(lastQuery().get("target_ecosystem_id")).toBe(ECO);
    expect(lastQuery().get("limit")).toBe("100");

    fireEvent.click(screen.getByRole("button", { name: "Clear" }));
    await waitFor(() =>
      expect(lastQuery().has("operator_account_id")).toBe(false),
    );
    expect(lastQuery().has("target_ecosystem_id")).toBe(false);
  });

  it("at the gateway's 200-row cap, says to narrow rather than calling it the whole log", async () => {
    const rows = Array.from({ length: 200 }, (_, i) => ({ ...row, id: `row-${i}` }));
    listV1Page.mockResolvedValue({ data: rows, hasMore: true });
    mount();
    await screen.findAllByText("POST /v1/ecosystems/abc/members");
    const caption = await screen.findByText(/200 entries/);
    expect(caption.textContent).not.toContain("the whole log");
    expect(caption.textContent).toContain("narrow them to reach older entries");
    expect(screen.queryByRole("button", { name: "Load older entries" })).toBeNull();
  });

  it("offers a former operator seen in the rows as a filter", async () => {
    const FORMER = "44444444-4444-4444-8444-444444444444";
    listV1Page.mockResolvedValue({
      data: [row, { ...row, id: "row-2", operator_account_id: FORMER }],
      hasMore: false,
    });
    mount();
    await screen.findByRole("option", { name: "second@example.com" });
    const option = await screen.findByRole("option", {
      name: "44444444 (not a current operator)",
    });
    expect(option.getAttribute("value")).toBe(FORMER);
    fireEvent.change(screen.getByLabelText("Operator"), {
      target: { value: FORMER },
    });
    fireEvent.click(screen.getByRole("button", { name: "Apply filters" }));
    await waitFor(() =>
      expect(lastQuery().get("operator_account_id")).toBe(FORMER),
    );
  });

  it("marks edits that are not applied yet, until Apply", async () => {
    mount();
    await screen.findByText("POST /v1/ecosystems/abc/members");
    await screen.findByRole("option", { name: "second@example.com" });
    expect(screen.queryByText(/Not applied yet/)).toBeNull();
    fireEvent.change(screen.getByLabelText("Operator"), {
      target: { value: OP2 },
    });
    expect(screen.getByText(/Not applied yet/)).toBeTruthy();
    fireEvent.click(screen.getByRole("button", { name: "Apply filters" }));
    await waitFor(() => expect(screen.queryByText(/Not applied yet/)).toBeNull());
  });

  it("says so when the operator list fails to load", async () => {
    listAllV1.mockRejectedValue(new Error("boom"));
    mount();
    await screen.findByText("POST /v1/ecosystems/abc/members");
    expect(
      (await screen.findByText(/load the operator list/)).textContent,
    ).toMatch(/short account/);
  });

  it("re-reads the log when the filters in force are applied again", async () => {
    mount();
    await screen.findByText("POST /v1/ecosystems/abc/members");
    const before = listV1Page.mock.calls.length;
    fireEvent.click(screen.getByRole("button", { name: "Apply filters" }));
    await waitFor(() =>
      expect(listV1Page.mock.calls.length).toBeGreaterThan(before),
    );
    expect(lastQuery().has("operator_account_id")).toBe(false);
  });

  it("refuses a partial ecosystem id beside the field, keeping the list", async () => {
    mount();
    await screen.findByText("POST /v1/ecosystems/abc/members");
    const before = listV1Page.mock.calls.length;
    fireEvent.change(screen.getByLabelText("Ecosystem id"), {
      target: { value: "22222222" },
    });
    fireEvent.click(screen.getByRole("button", { name: "Apply filters" }));
    expect((await screen.findByRole("alert")).textContent).toMatch(
      /whole ecosystem id/,
    );
    expect(
      screen.getByLabelText("Ecosystem id").getAttribute("aria-invalid"),
    ).toBe("true");
    await new Promise((r) => setTimeout(r, 20));
    expect(listV1Page.mock.calls.length).toBe(before);
    expect(screen.getByText("POST /v1/ecosystems/abc/members")).toBeTruthy();
  });

  it("refuses a From at or after To", async () => {
    mount();
    await screen.findByText("POST /v1/ecosystems/abc/members");
    const before = listV1Page.mock.calls.length;
    fireEvent.change(screen.getByLabelText("From"), {
      target: { value: "2026-11-21T10:00" },
    });
    fireEvent.change(screen.getByLabelText("To"), {
      target: { value: "2026-11-01T10:00" },
    });
    fireEvent.click(screen.getByRole("button", { name: "Apply filters" }));
    expect((await screen.findByRole("alert")).textContent).toBe(
      "From must be earlier than To.",
    );
    await new Promise((r) => setTimeout(r, 20));
    expect(listV1Page.mock.calls.length).toBe(before);
  });

  it("sends a time range as ISO text", async () => {
    mount();
    await screen.findByText("POST /v1/ecosystems/abc/members");
    fireEvent.change(screen.getByLabelText("From"), {
      target: { value: "2026-11-01T09:30" },
    });
    fireEvent.click(screen.getByRole("button", { name: "Apply filters" }));
    await waitFor(() => expect(lastQuery().has("from")).toBe(true));
    expect(lastQuery().get("from")).toBe(
      new Date("2026-11-01T09:30").toISOString(),
    );
    expect(lastQuery().has("to")).toBe(false);
  });
});

// The ecosystem invitation hooks speak the /v1 wire the platform-admin hooks speak, scoped to one
// ecosystem: reads are /v1 LISTS paged through listAllV1 (a bare-array read threw on `.map` and
// left every pane on "Failed to load"), writes are POSTs with snake_case bodies naming the
// ecosystem.
import type { ReactNode } from "react";
import { renderHook, waitFor, act } from "@testing-library/react";
import { afterEach, describe, expect, it, vi } from "vitest";
import { QueryClient, QueryClientProvider } from "@tanstack/react-query";

vi.mock("../../http", async (importOriginal) => ({
  ...(await importOriginal<typeof import("../../http")>()),
  authedJson: vi.fn(),
  authedRequest: vi.fn(),
  listAllV1: vi.fn(),
}));

import {
  useEcoInvitationRequests,
  useEcoPendingUsers,
  useEcoInvites,
  useEcoRowNotes,
  useEcoRowHistory,
  useEcoSaveNotes,
  useEcoSendInvitations,
  useEcoAddPendingUsers,
} from "../ecosystem-invitations";
import { authedJson, listAllV1 } from "../../http";

const mockedList = vi.mocked(listAllV1);
const mockedJson = vi.mocked(authedJson);
const RDID = "ecosystem.acme";

function wrapper({ children }: { children: ReactNode }) {
  const qc = new QueryClient({ defaultOptions: { queries: { retry: false } } });
  return <QueryClientProvider client={qc}>{children}</QueryClientProvider>;
}

afterEach(() => vi.clearAllMocks());

describe("ecosystem invitation reads", () => {
  it("pages the pending users list and maps its rows", async () => {
    mockedList.mockResolvedValueOnce([
      {
        id: "p1",
        name: "Jo",
        email: "jo@acme.com",
        phone: null,
        invited_count: 0,
        request_count: 1,
        last_request_at: null,
        last_invite_sent_at: null,
        first_requested_at: "2026-07-01T00:00:00Z",
        last_source: null,
        last_note: null,
      },
    ]);
    const { result } = renderHook(() => useEcoPendingUsers(RDID), { wrapper });
    await waitFor(() => expect(result.current.isSuccess).toBe(true));
    expect(mockedList).toHaveBeenCalledWith("/api/v1/pending_users?ecosystem=ecosystem.acme");
    expect(result.current.data?.[0]).toMatchObject({ id: "p1", email: "jo@acme.com", requestCount: 1 });
  });

  it("reads requests, invites, notes and history as /v1 lists", async () => {
    mockedList.mockResolvedValue([]);
    const hooks: Array<() => { isSuccess: boolean }> = [
      () => useEcoInvitationRequests(RDID),
      () => useEcoInvites(RDID),
      () => useEcoRowNotes(RDID, "pending_users", "p1"),
      () => useEcoRowHistory(RDID, "pending_users", "p1"),
    ];
    for (const hook of hooks) {
      const { result } = renderHook(hook, { wrapper });
      await waitFor(() => expect(result.current.isSuccess).toBe(true));
    }
    expect(mockedList.mock.calls.map((c) => c[0])).toEqual([
      "/api/v1/invitation_requests?ecosystem=ecosystem.acme",
      "/api/v1/invitations?ecosystem=ecosystem.acme",
      "/api/v1/admin_notes?subject_table=pending_users&subject_id=p1&ecosystem=ecosystem.acme",
      "/api/v1/entity_history?subject_table=pending_users&subject_id=p1&ecosystem=ecosystem.acme",
    ]);
    expect(mockedJson).not.toHaveBeenCalled();
  });
});

describe("ecosystem invitation writes", () => {
  const sent = () => {
    const [url, init] = mockedJson.mock.calls[0] as [string, RequestInit];
    return { url, method: init.method, body: JSON.parse(init.body as string) };
  };

  it("adds pending users with a POST naming the ecosystem", async () => {
    mockedJson.mockResolvedValueOnce({});
    const { result } = renderHook(() => useEcoAddPendingUsers(RDID), { wrapper });
    await act(() => result.current.mutateAsync([{ name: "Jo", email: "jo@acme.com" }]));
    expect(sent()).toEqual({
      url: "/api/v1/pending_users",
      method: "POST",
      body: { users: [{ name: "Jo", email: "jo@acme.com" }], ecosystem: RDID },
    });
  });

  it("sends invitations with snake_case ids", async () => {
    mockedJson.mockResolvedValueOnce({});
    const { result } = renderHook(() => useEcoSendInvitations(RDID), { wrapper });
    await act(() => result.current.mutateAsync({ pendingUserIds: ["p1"], email: { note: "hi" } }));
    expect(sent()).toEqual({
      url: "/api/v1/invitations",
      method: "POST",
      body: { pending_user_ids: ["p1"], email: { note: "hi" }, ecosystem: RDID },
    });
  });

  it("saves notes with a POST, not a PUT", async () => {
    mockedJson.mockResolvedValueOnce({});
    const { result } = renderHook(() => useEcoSaveNotes(RDID), { wrapper });
    await act(() =>
      result.current.mutateAsync({ subjectTable: "pending_users", subjectId: "p1", notes: [{ content: "n" }] }),
    );
    expect(sent()).toEqual({
      url: "/api/v1/admin_notes",
      method: "POST",
      body: { subject_table: "pending_users", subject_id: "p1", notes: [{ content: "n" }], ecosystem: RDID },
    });
  });
});

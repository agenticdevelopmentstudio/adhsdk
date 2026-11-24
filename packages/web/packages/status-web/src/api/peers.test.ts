import { describe, expect, it, vi } from "vitest";
import { createStatusApiClient } from "./client";
import { createPeer, updatePeer } from "./peers";

const clientWith = (fetchMock: ReturnType<typeof vi.fn>) =>
  createStatusApiClient({ fetch: fetchMock as unknown as typeof fetch });

const bodyOf = (fetchMock: ReturnType<typeof vi.fn>): string =>
  (fetchMock.mock.calls[0] as unknown as [string, RequestInit])[1].body as string;

describe("status peers client", () => {
  it("status-web-api-004 createPeer rejects with method, url and status only when the error body is not JSON", async () => {
    const fetchMock = vi.fn(async () => new Response("<html>oops</html>", { status: 500 }));
    const body = { label: "L", baseUrl: "https://p", isActive: true };
    await expect(createPeer(clientWith(fetchMock), body)).rejects.toThrow(/^POST \/api\/config\/peers → 500$/);
  });

  it("status-web-api-012 updatePeer without a token serializes no token key", async () => {
    const fetchMock = vi.fn(async () => new Response(JSON.stringify({ id: "p" }), { status: 200 }));
    await updatePeer(clientWith(fetchMock), "p", { label: "New" });
    expect(fetchMock.mock.calls[0]).toEqual(["/api/config/peers/p", expect.objectContaining({ method: "PATCH" })]);
    const parsed = JSON.parse(bodyOf(fetchMock));
    expect(parsed).toEqual({ label: "New" });
    expect("token" in parsed).toBe(false);
  });

  it("status-web-api-013 updatePeer with token null serializes token: null", async () => {
    const fetchMock = vi.fn(async () => new Response(JSON.stringify({ id: "p" }), { status: 200 }));
    await updatePeer(clientWith(fetchMock), "p", { token: null });
    expect(bodyOf(fetchMock)).toContain('"token":null');
  });
});

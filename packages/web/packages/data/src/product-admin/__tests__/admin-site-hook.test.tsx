// Recipe: adhsdk data, the product admin clients (admin-site-hooks).
import type { ReactNode } from "react";
import { renderHook, waitFor, cleanup } from "@testing-library/react";
import { afterEach, describe, expect, it, vi } from "vitest";
import { QueryClient, QueryClientProvider } from "@tanstack/react-query";

// Only the transport, so the hook's own retry rule is the one under test.
vi.mock("../../http", async (importOriginal) => ({
  ...(await importOriginal<typeof import("../../http")>()),
  authedJson: vi.fn(),
  authedRequest: vi.fn(),
}));

import { useAdminSite } from "..";
import { authedJson } from "../../http";

const mockedJson = vi.mocked(authedJson);

/** A status-carrying HTTP error, the shape `isNotFound` duck-types on. */
const httpError = (status: number) => Object.assign(new Error(`HTTP ${status}`), { status });

afterEach(() => {
  cleanup();
  vi.clearAllMocks();
});

// The provider's own default, retry once, with no delay so a retry lands inside the test.
function wrapper({ children }: { children: ReactNode }) {
  const qc = new QueryClient({ defaultOptions: { queries: { retry: 1, retryDelay: 0 } } });
  return <QueryClientProvider client={qc}>{children}</QueryClientProvider>;
}

describe("useAdminSite", () => {
  // A workspace ecosystem has no admin site, and AllDataPane asks about it anyway.
  it("asks once when the ecosystem answers 404", async () => {
    mockedJson.mockRejectedValue(httpError(404));
    const { result } = renderHook(() => useAdminSite("eco-1"), { wrapper });
    await waitFor(() => expect(result.current.isError).toBe(true));
    expect(mockedJson).toHaveBeenCalledTimes(1);
  });

  it("still retries any other failure once", async () => {
    mockedJson.mockRejectedValue(httpError(500));
    const { result } = renderHook(() => useAdminSite("eco-1"), { wrapper });
    await waitFor(() => expect(result.current.isError).toBe(true));
    expect(mockedJson).toHaveBeenCalledTimes(2);
  });
});

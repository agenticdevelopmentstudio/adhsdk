// @vitest-environment jsdom
//
// The models table's Available column (recipe adhsdk.ingredient.adh.hub.ai-settings, vectors
// ai-settings-016, -017, -018, -026, -027 and -031). Rendered through the real ServicesSection so the
// change goes the whole way: the data client call, the services cache revalidation, and the list's
// re-read landing back in the table. Only the `@adh-sdk/data/personas` transport is mocked;
// `revalidateResources` and `reportUnexpectedAuthError` are spies that keep their real behaviour
// (the auth one is silenced), so the assertions see the calls and the cache still re-reads.
//
// The clientWidth patch forces the wide layout, as ServicesSection.test.tsx explains.
import { describe, it, expect, vi, beforeEach, afterEach, afterAll } from "vitest";
import { render, screen, fireEvent, waitFor, cleanup } from "@testing-library/react";

vi.mock("@adh-sdk/data/personas", () => ({
  api: {
    templates: vi.fn(),
    services: {
      list: vi.fn(),
      create: vi.fn(),
      patch: vi.fn(),
      delete: vi.fn(),
      connect: vi.fn(),
      refreshModels: vi.fn(),
      setModelAvailability: vi.fn(),
    },
  },
}));

vi.mock("@adh-sdk/data", async (importOriginal) => {
  const actual = await importOriginal<typeof import("@adh-sdk/data")>();
  return { ...actual, revalidateResources: vi.fn(actual.revalidateResources) };
});

vi.mock("@adh-sdk/auth", async (importOriginal) => {
  const actual = await importOriginal<typeof import("@adh-sdk/auth")>();
  return { ...actual, reportUnexpectedAuthError: vi.fn() };
});

import { ServicesSection } from "./ServicesSection";
import { PERSONA_SERVICES_CACHE_KEY } from "./useUserServices";
import { api, type ModelInfo, type UserService } from "@adh-sdk/data/personas";
import { revalidateResources } from "@adh-sdk/data";
import { reportUnexpectedAuthError } from "@adh-sdk/auth";

const list = vi.mocked(api.services.list);
const setModelAvailability = vi.mocked(api.services.setModelAvailability);
const revalidate = vi.mocked(revalidateResources);
const report = vi.mocked(reportUnexpectedAuthError);

const SERVICE: UserService = {
  id: "svc_1",
  templateId: null,
  providerKind: "openai",
  name: "My OpenAI",
  baseUrl: "https://api.openai.com/v1",
  hasApiKey: true,
  connectStatus: "connected",
  connectError: null,
  lastConnectedAt: null,
  documentationUrl: null,
  statusUrl: null,
  models: [],
  modelsFetchedAt: null,
};

function withModels(models: Partial<ModelInfo>[]): UserService {
  // Entries may omit `available`/`offered`, as a fixture cast past the decoder would.
  return { ...SERVICE, models: models as ModelInfo[] };
}

const originalClientWidth = Object.getOwnPropertyDescriptor(HTMLElement.prototype, "clientWidth");
Object.defineProperty(HTMLElement.prototype, "clientWidth", {
  configurable: true,
  get: () => 1200,
});

beforeEach(() => {
  vi.clearAllMocks();
});

afterEach(cleanup);

afterAll(() => {
  if (originalClientWidth) {
    Object.defineProperty(HTMLElement.prototype, "clientWidth", originalClientWidth);
  } else {
    delete (HTMLElement.prototype as { clientWidth?: unknown }).clientWidth;
  }
});

function renderSection() {
  render(<ServicesSection urlSelection={{ serviceId: SERVICE.id, onSelectService: vi.fn() }} />);
}

function box(name: string) {
  return screen.getByRole("checkbox", { name: `Available: ${name}` });
}

describe("ModelsTable Available column", () => {
  it("puts Available last, after Caps", async () => {
    list.mockResolvedValue([withModels([{ id: "m1", available: true, offered: true }])]);
    renderSection();
    await screen.findByRole("checkbox", { name: "Available: m1" });
    const headers = screen.getAllByRole("columnheader").map((h) => h.textContent);
    expect(headers.slice(-2)).toEqual(["Caps", "Available"]);
  });

  // ai-settings-016
  it("ticks the box exactly when the model is available, and reads a missing value as available", async () => {
    list.mockResolvedValue([
      withModels([
        { id: "m1", available: true, offered: true },
        { id: "m2", available: false, offered: true },
        { id: "m3" },
      ]),
    ]);
    renderSection();
    await screen.findByRole("checkbox", { name: "Available: m1" });
    expect(box("m1")).toHaveAttribute("aria-checked", "true");
    expect(box("m2")).toHaveAttribute("aria-checked", "false");
    expect(box("m3")).toHaveAttribute("aria-checked", "true");
  });

  it("names each box after the model's display name", async () => {
    list.mockResolvedValue([withModels([{ id: "m1", displayName: "Model One", available: true }])]);
    renderSection();
    expect(await screen.findByRole("checkbox", { name: "Available: Model One" })).toBeInTheDocument();
  });

  // ai-settings-017
  it("unticking calls setModelAvailability and revalidates the services cache", async () => {
    const before = withModels([{ id: "m1", available: true, offered: true }]);
    const after = withModels([{ id: "m1", available: false, offered: true }]);
    list.mockResolvedValue([before]);
    setModelAvailability.mockResolvedValue(after);
    renderSection();

    fireEvent.click(await screen.findByRole("checkbox", { name: "Available: m1" }));

    await waitFor(() => expect(setModelAvailability).toHaveBeenCalledWith("svc_1", "m1", false));
    await waitFor(() => expect(revalidate).toHaveBeenCalledTimes(1));
    const match = revalidate.mock.calls[0]![0];
    expect(match(PERSONA_SERVICES_CACHE_KEY)).toBe(true);
    expect(match("personas")).toBe(false);
    await waitFor(() => expect(box("m1")).toHaveAttribute("aria-checked", "false"));
  });

  // ai-settings-018
  it("shows a no-longer-offered model with the text and an unticked box", async () => {
    list.mockResolvedValue([
      withModels([
        { id: "m1", available: true, offered: true },
        { id: "m9", available: false, offered: false },
      ]),
    ]);
    renderSection();
    await screen.findByRole("checkbox", { name: "Available: m9" });
    expect(box("m9")).toHaveAttribute("aria-checked", "false");
    expect(screen.getAllByText("No longer offered")).toHaveLength(1);
    // The appended entry keeps its place after the listed models.
    const names = screen.getAllByRole("checkbox").map((c) => c.getAttribute("aria-label"));
    expect(names).toEqual(["Available: m1", "Available: m9"]);
  });

  // ai-settings-026
  it("a failed change is reported, shows the message, and leaves the box at its last known state", async () => {
    list.mockResolvedValue([withModels([{ id: "m1", available: true, offered: true }])]);
    setModelAvailability.mockRejectedValue(new Error("boom"));
    renderSection();

    fireEvent.click(await screen.findByRole("checkbox", { name: "Available: m1" }));

    expect(await screen.findByText("m1: boom")).toBeInTheDocument();
    expect(report).toHaveBeenCalledWith(expect.any(Error), {
      feature: "services",
      step: "setModelAvailability",
    });
    expect(box("m1")).toHaveAttribute("aria-checked", "true");
    expect(revalidate).not.toHaveBeenCalled();
  });

  // ai-settings-031
  it("two overlapping changes on different models each keep their own box disabled until their own request settles", async () => {
    const both = withModels([
      { id: "m1", available: true, offered: true },
      { id: "m2", available: true, offered: true },
    ]);
    list.mockResolvedValue([both]);
    const settle: Record<string, { resolve: (s: UserService) => void; reject: (e: Error) => void }> =
      {};
    setModelAvailability.mockImplementation(
      (_service, model) =>
        new Promise<UserService>((resolve, reject) => {
          settle[model] = { resolve, reject };
        }),
    );
    renderSection();

    fireEvent.click(await screen.findByRole("checkbox", { name: "Available: m1" }));
    fireEvent.click(box("m2"));

    await waitFor(() => expect(setModelAvailability).toHaveBeenCalledTimes(2));
    expect(setModelAvailability).toHaveBeenNthCalledWith(1, "svc_1", "m1", false);
    expect(setModelAvailability).toHaveBeenNthCalledWith(2, "svc_1", "m2", false);
    await waitFor(() => expect(box("m1")).toHaveAttribute("data-disabled"));
    expect(box("m2")).toHaveAttribute("data-disabled");

    // The first request answers: only its own box comes back; m2's is still in flight.
    settle.m1!.resolve(both);
    await waitFor(() => expect(box("m1")).not.toHaveAttribute("data-disabled"));
    expect(box("m2")).toHaveAttribute("data-disabled");

    // The second fails: reported, shown inline, its box re-enabled at the last known state.
    settle.m2!.reject(new Error("m2 failed"));
    expect(await screen.findByText("m2: m2 failed")).toBeInTheDocument();
    await waitFor(() => expect(box("m2")).not.toHaveAttribute("data-disabled"));
    expect(box("m2")).toHaveAttribute("aria-checked", "true");
    expect(report).toHaveBeenCalledWith(expect.any(Error), {
      feature: "services",
      step: "setModelAvailability",
    });
  });

  it("one model's failure stays on screen while another model changes, until its own retry", async () => {
    const both = withModels([
      { id: "m1", available: true, offered: true },
      { id: "m2", available: true, offered: true },
    ]);
    list.mockResolvedValue([both]);
    setModelAvailability.mockRejectedValueOnce(new Error("m1 failed")).mockResolvedValue(both);
    renderSection();

    fireEvent.click(await screen.findByRole("checkbox", { name: "Available: m1" }));
    expect(await screen.findByText("m1: m1 failed")).toBeInTheDocument();

    fireEvent.click(box("m2"));
    await waitFor(() => expect(setModelAvailability).toHaveBeenCalledTimes(2));
    await waitFor(() => expect(box("m2")).not.toHaveAttribute("data-disabled"));
    expect(screen.getByText("m1: m1 failed")).toBeInTheDocument();

    fireEvent.click(box("m1"));
    await waitFor(() => expect(screen.queryByText("m1: m1 failed")).toBeNull());
  });

  it("answers that arrive out of order each change only their own model", async () => {
    const both = withModels([
      { id: "m1", available: true, offered: true },
      { id: "m2", available: true, offered: true },
    ]);
    // The re-read after each answer fails, so only the answers themselves can move the boxes.
    list.mockResolvedValueOnce([both]).mockRejectedValue(new Error("re-read failed"));
    const settle: Record<string, (s: UserService) => void> = {};
    setModelAvailability.mockImplementation(
      (_service, model) =>
        new Promise<UserService>((resolve) => {
          settle[model] = resolve;
        }),
    );
    renderSection();

    fireEvent.click(await screen.findByRole("checkbox", { name: "Available: m1" }));
    fireEvent.click(box("m2"));
    await waitFor(() => expect(setModelAvailability).toHaveBeenCalledTimes(2));

    // m2's write answers first; m1's answer, committed earlier, arrives last with m2 still on.
    settle.m2!(
      withModels([
        { id: "m1", available: false, offered: true },
        { id: "m2", available: false, offered: true },
      ]),
    );
    await waitFor(() => expect(box("m2")).toHaveAttribute("aria-checked", "false"));
    settle.m1!(
      withModels([
        { id: "m1", available: false, offered: true },
        { id: "m2", available: true, offered: true },
      ]),
    );
    await waitFor(() => expect(box("m1")).toHaveAttribute("aria-checked", "false"));
    expect(box("m2")).toHaveAttribute("aria-checked", "false");
  });

  // ai-settings-027
  it("re-enabling a no-longer-offered model calls through, and the re-read list drops its row", async () => {
    const before = withModels([
      { id: "m1", available: true, offered: true },
      { id: "m9", available: false, offered: false },
    ]);
    const after = withModels([{ id: "m1", available: true, offered: true }]);
    list.mockResolvedValueOnce([before]).mockResolvedValue([after]);
    setModelAvailability.mockResolvedValue(after);
    renderSection();

    const m9 = await screen.findByRole("checkbox", { name: "Available: m9" });
    expect(m9).not.toHaveAttribute("data-disabled");
    expect(m9).not.toHaveAttribute("aria-disabled", "true");
    fireEvent.click(m9);

    await waitFor(() => expect(setModelAvailability).toHaveBeenCalledWith("svc_1", "m9", true));
    await waitFor(() =>
      expect(screen.queryByRole("checkbox", { name: "Available: m9" })).toBeNull(),
    );
    expect(screen.queryByText("No longer offered")).toBeNull();
    expect(box("m1")).toBeInTheDocument();
  });
});

// @vitest-environment jsdom
// JobTemplatePane's "Offered by" boxes: each one's accessible name is exactly "Offered by <set>".
// The box sits inside a label that shows the set's name; an aria-label on the box as well made
// Base UI read both, "Offered by Pro Pro". Mocks the jobs and sets data clients.
import { cleanup, screen } from "@testing-library/react";
import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";

import type { JobTemplate } from "@adh-sdk/data/jobs";

const api = vi.hoisted(() => ({ get: vi.fn(), setOffers: vi.fn() }));
const sets = vi.hoisted(() => ({ list: vi.fn() }));

vi.mock("@adh-sdk/data/jobs", async (importOriginal) => {
  const actual = await importOriginal<typeof import("@adh-sdk/data/jobs")>();
  return { ...actual, jobTemplatesApi: { ...actual.jobTemplatesApi, ...api } };
});
vi.mock("@adh-sdk/data/sets", async (importOriginal) => {
  const actual = await importOriginal<typeof import("@adh-sdk/data/sets")>();
  return { ...actual, setsApi: { ...actual.setsApi, ...sets } };
});

import { JobTemplatePane } from "../JobTemplatePane";
import { renderWithQuery } from "./fixtures";

const T0 = "2026-11-20T10:00:00.000Z";

const template = (over: Partial<JobTemplate> = {}): JobTemplate =>
  ({
    id: "tpl-1",
    key: "digest",
    name: "Digest",
    description: null,
    status: "published",
    latestVersion: 1,
    latestHasScript: false,
    latestPublishedAt: T0,
    offeredSetIds: ["set-pro"],
    createdAt: T0,
    updatedAt: T0,
    draft: null,
    ...over,
  }) as JobTemplate;

beforeEach(() => {
  api.get.mockReset().mockResolvedValue(template());
  api.setOffers.mockReset();
  sets.list.mockReset().mockResolvedValue([
    { id: "set-pro", name: "Pro" },
    { id: "set-team", name: "Team" },
  ]);
});
afterEach(cleanup);

describe("JobTemplatePane: Offered by", () => {
  it("names each box exactly 'Offered by <set>', checked for the sets it is offered by", async () => {
    renderWithQuery(<JobTemplatePane ecosystemId="eco-1" templateId="tpl-1" />);
    const pro = await screen.findByRole("checkbox", { name: "Offered by Pro" });
    expect(pro.getAttribute("aria-checked")).toBe("true");
    const team = screen.getByRole("checkbox", { name: "Offered by Team" });
    expect(team.getAttribute("aria-checked")).toBe("false");
    // Exact, not a prefix: nothing doubles the set's name.
    expect(screen.queryByRole("checkbox", { name: /Pro Pro|Team Team/ })).toBeNull();
  });
});

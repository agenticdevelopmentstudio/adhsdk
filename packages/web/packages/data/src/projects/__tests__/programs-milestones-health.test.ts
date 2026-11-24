// URL/method/body contract tests for the three clients that carry a PLAN — programs, milestones
// and status updates — plus the two mappings those added to existing entities (a project's lead
// and derived health, a card's milestone).
//
// Same arrangement as `projects.test.ts`: single reads/writes mock `authedJson`, list reads stub
// `fetch` under the real /v1 pager, so the mappers, `compact`, the camel->snake body mapping and
// the query-building run for real. /v1 updates are POSTs with snake_case bodies. What is worth pinning here is narrower than
// "does it call the right URL", and each case says which of these it is:
//
//   1. an explicit null that must SURVIVE `compact` (clearing a date, detaching a milestone,
//      dropping a lead) — the difference between "leave it alone" and "unset it";
//   2. a null the mapper must NOT flatten into a zero or a default (`counts`, `health`), because
//      "not reported" and "reported as nothing" are different claims;
//   3. the pairing rule on a lead, which the backend guarantees and this client re-asserts
//      rather than trusting a half-row.
import { describe, expect, it, vi, beforeEach } from "vitest";

vi.mock("../../http", async (importOriginal) => ({
  ...(await importOriginal<typeof import("../../http")>()),
  authedJson: vi.fn(),
  authedRequest: vi.fn(),
}));

import { projectsApi, toProject } from "../projects";
import { projectProgramsApi } from "../programs";
import { milestoneProgress, projectMilestonesApi, toMilestone } from "../milestones";
import { projectStatusUpdatesApi } from "../status-updates";
import { projectWorkItemsApi, toWorkItem } from "../work-items";
import type { MilestoneRow, ProjectRow, WorkItemRow } from "../wire";
import { authedJson, authedRequest } from "../../http";
import { fetchMock, installFetch, paramsAt, pathAt, respondWith, v1List } from "../../__tests__/v1-fetch";

const mockedJson = vi.mocked(authedJson);
const mockedRequest = vi.mocked(authedRequest);

beforeEach(() => {
  mockedJson.mockReset();
  mockedRequest.mockReset();
  installFetch();
});

/** A minimal project row — every field the mapper reads, none of the ones under test. */
const projectRow = (extra: Partial<ProjectRow> = {}): ProjectRow => ({
  id: "p1",
  name: "Alpha",
  description: "",
  status: "active",
  color: "#000",
  keyPrefix: "ALP",
  ecosystemId: "eco",
  createdAt: "c",
  updatedAt: "u",
  ...extra,
});

/** A project as /v1 sends it: snake_case, unix `created`/`updated`. */
const wireProject = (extra: Record<string, unknown> = {}) => ({
  object: "project",
  id: "p1",
  name: "Alpha",
  description: "",
  status: "active",
  color: "#000",
  key_prefix: "ALP",
  ecosystem_id: "eco",
  created: 1767225600,
  updated: 1767225600,
  ...extra,
});

const milestoneRow = (extra: Partial<MilestoneRow> = {}): MilestoneRow => ({
  id: "m1",
  projectId: "p1",
  name: "Beta cut",
  description: "",
  ecosystemId: "eco",
  createdAt: "c",
  updatedAt: "u",
  ...extra,
});

/* ── projectProgramsApi ───────────────────────────────────────────────── */

describe("projectProgramsApi", () => {
  it("lists off the workspace stem, not under a project", async () => {
    // The route shape IS the design: a program groups boards, so it cannot hang off one of
    // them. Getting this wrong would compile and 404 only at runtime.
    await projectProgramsApi.list({ workspace: "acme" });
    expect(pathAt(0)).toBe("/api/v1/programs");
    expect(paramsAt(0).get("workspace")).toBe("acme");
  });

  it("creates with a compacted body against the workspace query", async () => {
    mockedJson.mockResolvedValueOnce({
      id: "g1",
      name: "Platform",
      description: "",
      color: "#007AFF",
      ownerKind: "customer",
      ownerId: "o",
      ecosystemId: "eco",
      createdAt: "c",
      updatedAt: "u",
    });
    await projectProgramsApi.create(
      { name: "Platform", description: undefined, targetDate: "2026-12-31" },
      { workspace: "acme" },
    );
    expect(mockedJson).toHaveBeenCalledWith("/api/v1/programs?workspace=acme", {
      method: "POST",
      body: JSON.stringify({ name: "Platform", target_date: "2026-12-31" }),
    });
  });

  it("keeps an explicit null on a date so a patch can CLEAR one", async () => {
    // (1) — `start_date: null` unsets the start; `undefined` would mean "leave it". Dropping the
    // null here would silently turn every clear into a no-op the UI reports as success.
    mockedJson.mockResolvedValueOnce({
      id: "g1",
      name: "Platform",
      description: "",
      color: "#007AFF",
      ownerKind: "customer",
      ownerId: "o",
      ecosystemId: "eco",
      createdAt: "c",
      updatedAt: "u",
    });
    await projectProgramsApi.update("g1", { startDate: null, name: undefined });
    expect(mockedJson).toHaveBeenCalledWith("/api/v1/programs/g1", {
      method: "POST",
      body: JSON.stringify({ start_date: null }),
    });
  });

  it("deletes at the program's id, and claims no count of un-assigned boards", async () => {
    // /v1 answers a DELETE with a tombstone `{id, object, deleted}` — the legacy `{unassigned}`
    // count does not survive the gateway, so the result must not invent one (a guessed 0 would
    // tell the UI nothing was detached).
    const out = await projectProgramsApi.remove("g1");
    expect(mockedRequest).toHaveBeenCalledWith("/api/v1/programs/g1", { method: "DELETE" });
    expect(out.unassigned).toBeUndefined();
  });

  it("returns the member boards with their OWN healths, unfolded", async () => {
    // The whole reason this is a list and not a rollup: two boards reporting differently have no
    // single honest colour, so the client must be able to show both.
    respondWith(
      v1List([
        { ...wireProject({ id: "p1" }), health: "at_risk" },
        { ...wireProject({ id: "p2", name: "Beta" }), health: null },
      ]),
    );
    const out = await projectProgramsApi.projects("g1");
    expect(pathAt(0)).toBe("/api/v1/projects");
    expect(paramsAt(0).get("program")).toBe("g1");
    expect(out.map((p) => p.health)).toEqual(["at_risk", null]);
  });
});

/* ── project plan fields on the project itself ────────────────────────── */

describe("a project's plan and reported health", () => {
  it("maps a null health to null, NEVER to on_track", async () => {
    // (2) — the defect this exists to stop: "nobody has reported" rendered as reassurance.
    expect(toProject(projectRow()).health).toBeNull();
    expect(toProject(projectRow({ health: null })).health).toBeNull();
    expect(toProject(projectRow({ health: "off_track" })).health).toBe("off_track");
  });

  it("carries the health's AS-OF date beside it", async () => {
    const p = toProject(projectRow({ health: "on_track", healthUpdatedAt: "2026-08-01T00:00:00Z" }));
    expect(p.healthUpdatedAt).toBe("2026-08-01T00:00:00Z");
    // No report, no date — not the project's own updatedAt, which would date the claim wrong.
    expect(toProject(projectRow()).healthUpdatedAt).toBeNull();
  });

  it("treats HALF a lead as no lead", async () => {
    // (3) — the backend refuses to write one half, so a half-row is an OLD backend, not a
    // partial lead. Rendering a kind with no id would put an unnamed avatar on the board.
    expect(toProject(projectRow({ leadKind: "customer", leadId: "u1" })).leadId).toBe("u1");
    const halfKind = toProject(projectRow({ leadKind: "customer", leadId: null }));
    expect([halfKind.leadKind, halfKind.leadId]).toEqual([null, null]);
    const halfId = toProject(projectRow({ leadKind: null, leadId: "u1" }));
    expect([halfId.leadKind, halfId.leadId]).toEqual([null, null]);
  });

  it("sends both halves of a lead, and both nulls to clear it", async () => {
    mockedJson.mockResolvedValueOnce(projectRow());
    await projectsApi.update("p1", { leadKind: "team", leadId: "t1" });
    expect(mockedJson).toHaveBeenCalledWith("/api/v1/projects/p1", {
      method: "POST",
      body: JSON.stringify({ lead_kind: "team", lead_id: "t1" }),
    });
    mockedJson.mockResolvedValueOnce(projectRow());
    await projectsApi.update("p1", { leadKind: null, leadId: null });
    expect(mockedJson).toHaveBeenCalledWith("/api/v1/projects/p1", {
      method: "POST",
      body: JSON.stringify({ lead_kind: null, lead_id: null }),
    });
  });

  it("keeps an explicit null when detaching a board from its program", async () => {
    mockedJson.mockResolvedValueOnce(projectRow());
    await projectsApi.update("p1", { programId: null });
    expect(mockedJson).toHaveBeenCalledWith("/api/v1/projects/p1", {
      method: "POST",
      body: JSON.stringify({ program_id: null }),
    });
  });
});

/* ── projectMilestonesApi ─────────────────────────────────────────────── */

describe("projectMilestonesApi", () => {
  it("lists under the OWNING project, encoding the id", async () => {
    await projectMilestonesApi.list("a/b");
    expect(pathAt(0)).toBe("/api/v1/projects/a%2Fb/milestones");
  });

  it("creates with a compacted body", async () => {
    mockedJson.mockResolvedValueOnce(milestoneRow({ targetDate: "2026-09-30" }));
    await projectMilestonesApi.create("p1", { name: "Beta cut", targetDate: "2026-09-30" });
    expect(mockedJson).toHaveBeenCalledWith("/api/v1/projects/p1/milestones", {
      method: "POST",
      body: JSON.stringify({ name: "Beta cut", target_date: "2026-09-30" }),
    });
  });

  it("keeps an explicit null so a dated milestone can go back to undated", async () => {
    // (1) again — and here the two readings differ visibly: undated milestones sort LAST.
    mockedJson.mockResolvedValueOnce(milestoneRow());
    await projectMilestonesApi.update("p1", "m1", { targetDate: null });
    expect(mockedJson).toHaveBeenCalledWith("/api/v1/projects/p1/milestones/m1", {
      method: "POST",
      body: JSON.stringify({ target_date: null }),
    });
  });

  it("distinguishes counts that did not TRAVEL from counts that are zero", async () => {
    // (2) — a PATCH answers with the bare row, so `counts` is genuinely absent there. Reading
    // that as zeros would show a milestone someone just renamed as empty.
    expect(toMilestone(milestoneRow()).counts).toBeNull();
    const withCounts = toMilestone(
      milestoneRow({ counts: { backlog: 0, todo: 2, in_progress: 1, done: 3, canceled: 4 } }),
    );
    expect(withCounts.counts?.done).toBe(3);
  });

  it("deletes at the milestone's id, and claims no count of detached cards", async () => {
    // The /v1 tombstone carries no `unassigned`; a guessed 0 would say nothing was detached.
    const out = await projectMilestonesApi.remove("p1", "m1");
    expect(mockedRequest).toHaveBeenCalledWith("/api/v1/projects/p1/milestones/m1", {
      method: "DELETE",
    });
    expect(out.unassigned).toBeUndefined();
  });
});

describe("milestoneProgress", () => {
  it("excludes canceled from BOTH halves", async () => {
    // The one product answer this package commits to. Counting a canceled card as outstanding
    // would leave a finished plan reading as permanently stalled.
    const m = toMilestone(
      milestoneRow({ counts: { backlog: 1, todo: 1, in_progress: 1, done: 1, canceled: 96 } }),
    );
    expect(milestoneProgress(m)).toEqual({ done: 1, total: 4, ratio: 0.25 });
  });

  it("reports an empty milestone as 0 %, not NaN and not complete", async () => {
    const m = toMilestone(
      milestoneRow({ counts: { backlog: 0, todo: 0, in_progress: 0, done: 0, canceled: 0 } }),
    );
    expect(milestoneProgress(m)).toEqual({ done: 0, total: 0, ratio: 0 });
  });

  it("returns null — not a zeroed bar — when the counts did not travel", async () => {
    expect(milestoneProgress(toMilestone(milestoneRow()))).toBeNull();
  });
});

/* ── projectStatusUpdatesApi ──────────────────────────────────────────── */

describe("projectStatusUpdatesApi", () => {
  const updateRow = {
    id: "s1",
    projectId: "p1",
    health: "at_risk" as const,
    body: "vendor slipped",
    createdAt: "c",
    updatedAt: "u",
  };

  it("lists under the project", async () => {
    respondWith(
      v1List([
        { object: "status_update", id: "s1", project_id: "p1", health: "at_risk", body: "vendor slipped", created: 1767225600, updated: 1767225600 },
      ]),
    );
    const out = await projectStatusUpdatesApi.list("p1");
    expect(pathAt(0)).toBe("/api/v1/projects/p1/status_updates");
    expect(fetchMock).toHaveBeenCalledTimes(1);
    expect(out[0]!.health).toBe("at_risk");
    // Unsigned rows exist (an admin-written one); null, never "".
    expect(out[0]!.createdBy).toBeNull();
  });

  it("posts both halves — a health and its explanation", async () => {
    mockedJson.mockResolvedValueOnce(updateRow);
    await projectStatusUpdatesApi.create("p1", { health: "at_risk", body: "vendor slipped" });
    expect(mockedJson).toHaveBeenCalledWith("/api/v1/projects/p1/status_updates", {
      method: "POST",
      body: JSON.stringify({ health: "at_risk", body: "vendor slipped" }),
    });
  });

  it("patches only what was sent, so a typo fix does not restate the health", async () => {
    mockedJson.mockResolvedValueOnce(updateRow);
    await projectStatusUpdatesApi.update("p1", "s1", { body: "vendor slipped a week" });
    expect(mockedJson).toHaveBeenCalledWith("/api/v1/projects/p1/status_updates/s1", {
      method: "POST",
      body: JSON.stringify({ body: "vendor slipped a week" }),
    });
  });

  it("retracts through authedRequest — the route answers 204, with no row", async () => {
    mockedRequest.mockResolvedValueOnce(undefined);
    await projectStatusUpdatesApi.remove("p1", "s1");
    expect(mockedRequest).toHaveBeenCalledWith("/api/v1/projects/p1/status_updates/s1", {
      method: "DELETE",
    });
  });
});

/* ── a card's milestone ───────────────────────────────────────────────── */

describe("a work item's milestone", () => {
  const itemRow = (extra: Partial<WorkItemRow> = {}): WorkItemRow => ({
    id: "w1",
    projectId: "p1",
    itemKey: "ALP-1",
    title: "T",
    description: "",
    statusId: "st1",
    priority: 0,
    labels: [],
    rank: "a0",
    createdAt: "c",
    updatedAt: "u",
    ...extra,
  });

  it("maps an absent milestone to null", async () => {
    expect(toWorkItem(itemRow()).milestoneId).toBeNull();
    expect(toWorkItem(itemRow({ milestoneId: "m1" })).milestoneId).toBe("m1");
  });

  it("sends an explicit null to detach a card from the plan", async () => {
    // (1) — same idiom as the iteration's backlog null, and the same failure if it were dropped.
    mockedJson.mockResolvedValueOnce(itemRow());
    await projectWorkItemsApi.update("w1", { milestoneId: null });
    expect(mockedJson).toHaveBeenCalledWith("/api/v1/work_items/w1", {
      method: "POST",
      body: JSON.stringify({ milestone_id: null }),
    });
  });

  it("can create a card straight onto a milestone", async () => {
    mockedJson.mockResolvedValueOnce(itemRow({ milestoneId: "m1" }));
    await projectWorkItemsApi.create("p1", { title: "T", milestoneId: "m1" });
    expect(mockedJson).toHaveBeenCalledWith("/api/v1/work_items", {
      method: "POST",
      body: JSON.stringify({ project: "p1", title: "T", milestone_id: "m1" }),
    });
  });
});

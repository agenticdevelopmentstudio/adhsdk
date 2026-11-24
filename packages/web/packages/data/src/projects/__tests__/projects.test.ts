// URL/method/body contract tests for the Projects clients, on the /v1 wire. Single reads and
// writes mock the transport (`authedJson`/`authedRequest`); list reads stub `fetch` under the
// real /v1 pager. The mappers, `compact`, the camel->snake body mapping and query-building run
// for real, so these pin the wire contract that the Projects UI is built on. Emphasis on: an
// update (a POST on /v1) with a compacted snake_case body, a work-item update that CLEARS an
// assignee (explicit null must survive), the activity keyset query + `nextBefore`, and the
// participant DELETE carrying `?kind=`.
import { describe, expect, it, vi, beforeEach } from "vitest";

// Stub only the transport; client-helpers (compact/enc/sortByText) stay real.
vi.mock("../../http", async (importOriginal) => ({
  ...(await importOriginal<typeof import("../../http")>()),
  authedJson: vi.fn(),
  authedRequest: vi.fn(),
}));

import { projectsApi, validateKeyPrefix } from "../projects";
import { compareRank, projectWorkItemsApi } from "../work-items";
import { projectActivityApi } from "../activity";
import { projectArtifactsApi } from "../artifacts";
import { projectCommentsApi, threadOf, type ProjectComment } from "../comments";
import type { ProjectCommentRow } from "../wire";
import { authedJson, authedRequest } from "../../http";
import { fetchMock, installFetch, paramsAt, pathAt, respondOnce, respondWith, v1List } from "../../__tests__/v1-fetch";

const mockedJson = vi.mocked(authedJson);
const mockedRequest = vi.mocked(authedRequest);

beforeEach(() => {
  mockedJson.mockReset();
  mockedRequest.mockReset();
  installFetch();
});

/** The query of a call to the mocked `authedJson` (single reads carry their params in the URL). */
const paramsOf = (call: number) => new URL(String(mockedJson.mock.calls[call]![0]), "http://x").searchParams;

/* ── projectsApi ──────────────────────────────────────────────────────── */

describe("projectsApi", () => {
  it("list GETs the base URL and sorts by name", async () => {
    const wire = (id: string, name: string) => ({ object: "project", id, name, description: "", status: "active", color: "#000", ecosystem_id: "o", created: 1767225600, updated: 1767225600 });
    respondWith(v1List([wire("2", "Beta"), wire("1", "Alpha")]));
    const out = await projectsApi.list();
    expect(pathAt(0)).toBe("/api/v1/projects");
    expect(out.map((p) => p.name)).toEqual(["Alpha", "Beta"]);
  });

  it("get encodes the id and returns null on a thrown 404", async () => {
    mockedJson.mockRejectedValueOnce(new Error("not found"));
    expect(await projectsApi.get("a/b")).toBeNull();
    expect(mockedJson).toHaveBeenCalledWith("/api/v1/projects/a%2Fb", undefined);
  });

  it("create POSTs a compacted body (undefined optionals dropped)", async () => {
    mockedJson.mockResolvedValueOnce({ id: "1", name: "P", description: "", status: "active", color: "#000", ecosystemId: "o", createdAt: "c", updatedAt: "u" });
    await projectsApi.create({ name: "P", color: "#fff" });
    expect(mockedJson).toHaveBeenCalledWith("/api/v1/projects", {
      method: "POST",
      body: JSON.stringify({ name: "P", color: "#fff" }),
    });
  });

  it("update POSTs a compacted snake_case body, dropping undefined but KEEPING explicit null (un-archive)", async () => {
    mockedJson.mockResolvedValueOnce({ id: "1", name: "P", description: "", status: "active", color: "#000", ecosystemId: "o", createdAt: "c", updatedAt: "u" });
    await projectsApi.update("1", { name: "Renamed", description: undefined, archivedAt: null });
    expect(mockedJson).toHaveBeenCalledWith("/api/v1/projects/1", {
      method: "POST",
      body: JSON.stringify({ name: "Renamed", archived_at: null }),
    });
  });

  it("delete DELETEs via authedRequest", async () => {
    await projectsApi.delete("1");
    expect(mockedRequest).toHaveBeenCalledWith("/api/v1/projects/1", { method: "DELETE" });
  });
});

/* ── statuses sub-resource ────────────────────────────────────────────── */

describe("projectsApi.statuses", () => {
  it("create POSTs to the project's statuses collection", async () => {
    mockedJson.mockResolvedValueOnce({ id: "s1", projectId: "p1", key: "todo", label: "To do", category: "todo", position: 0, createdAt: "c" });
    await projectsApi.statuses.create("p1", { key: "todo", label: "To do", category: "todo" });
    expect(mockedJson).toHaveBeenCalledWith("/api/v1/projects/p1/statuses", {
      method: "POST",
      body: JSON.stringify({ key: "todo", label: "To do", category: "todo" }),
    });
  });

  it("update POSTs the status by id with a compacted body", async () => {
    mockedJson.mockResolvedValueOnce({ id: "s1", projectId: "p1", key: "todo", label: "Doing", category: "in_progress", position: 1, createdAt: "c" });
    await projectsApi.statuses.update("p1", "s1", { label: "Doing", category: "in_progress" });
    expect(mockedJson).toHaveBeenCalledWith("/api/v1/projects/p1/statuses/s1", {
      method: "POST",
      body: JSON.stringify({ label: "Doing", category: "in_progress" }),
    });
  });

  it("remove DELETEs the status by id", async () => {
    await projectsApi.statuses.remove("p1", "s1");
    expect(mockedRequest).toHaveBeenCalledWith("/api/v1/projects/p1/statuses/s1", { method: "DELETE" });
  });
});

/* ── participants sub-resource ────────────────────────────────────────── */

describe("projectsApi.participants", () => {
  it("add POSTs the (kind, id) pair", async () => {
    mockedJson.mockResolvedValueOnce({ id: "pp1", projectId: "p1", participantKind: "customer", participantId: "cust1", role: "member", addedBy: null, addedAt: "a" });
    await projectsApi.participants.add("p1", { participantKind: "customer", participantId: "cust1" });
    expect(mockedJson).toHaveBeenCalledWith("/api/v1/projects/p1/participants", {
      method: "POST",
      body: JSON.stringify({ participant_kind: "customer", participant_id: "cust1" }),
    });
  });

  it("remove addresses by actor id and REQUIRES the ?kind= query", async () => {
    await projectsApi.participants.remove("p1", "cust1", "customer");
    expect(mockedRequest).toHaveBeenCalledWith(
      "/api/v1/projects/p1/participants/cust1?kind=customer",
      { method: "DELETE" },
    );
  });
});

/* ── projectWorkItemsApi ──────────────────────────────────────────────── */

const WORK_ITEM = {
  id: "w1",
  ecosystemId: "o",
  projectId: "p1",
  title: "Task",
  description: "",
  statusId: "s1",
  assigneeKind: "customer" as const,
  assigneeId: "cust1",
  priority: 0,
  labels: [],
  rank: "V0",
  createdAt: "c",
  updatedAt: "u",
};

/** The same card as /v1 sends it (snake_case, unix-second timestamps) for list reads. */
const WIRE_ITEM = {
  object: "work_item",
  id: "w1",
  ecosystem_id: "o",
  project_id: "p1",
  title: "Task",
  description: "",
  status_id: "s1",
  assignee_kind: "customer",
  assignee_id: "cust1",
  priority: 0,
  labels: [],
  rank: "V0",
  created: 1767225600,
  updated: 1767225600,
};

describe("compareRank", () => {
  it("sorts by BYTES, so a capital letter sorts before every lower-case one", () => {
    // The half a locale comparator gets wrong: `localeCompare` treats case as a tertiary weight
    // and answers "aZ" > "az", while the backend's `COLLATE \"C\"` column answers the opposite.
    // A client that disagreed with the server here would render its own list out of order.
    expect(compareRank("aZ", "az")).toBeLessThan(0);
    expect("aZ".localeCompare("az")).toBeGreaterThan(0);
  });

  it("orders the keys the backend actually mints", () => {
    // 'V0' is the first key; appends grow the integer part, and an insert lengthens the fraction.
    const minted = ["V1", "V0", "V0V", "V2"];
    expect([...minted].sort(compareRank)).toEqual(["V0", "V0V", "V1", "V2"]);
    expect(compareRank("V0", "V0")).toBe(0);
  });
});

describe("projectWorkItemsApi", () => {
  it("listForProject GETs the per-project collection", async () => {
    respondWith(v1List([WIRE_ITEM]));
    const out = await projectWorkItemsApi.listForProject("p1");
    expect(pathAt(0)).toBe("/api/v1/work_items");
    expect(paramsAt(0).get("project")).toBe("p1");
    // Accepted cards only unless asked: the escape is a separate, explicit parameter.
    expect(paramsAt(0).has("include_untriaged")).toBe(false);
    expect(paramsAt(0).has("includeUntriaged")).toBe(false);
    expect(out[0]?.assigneeId).toBe("cust1");
    expect(out[0]?.createdAt).toBe("2026-01-01T00:00:00.000Z");
  });

  it("create POSTs a compacted body to the collection, naming the project in it", async () => {
    mockedJson.mockResolvedValueOnce(WORK_ITEM);
    await projectWorkItemsApi.create("p1", { title: "Task", statusId: "s1" });
    expect(mockedJson).toHaveBeenCalledWith("/api/v1/work_items", {
      method: "POST",
      body: JSON.stringify({ project: "p1", title: "Task", status_id: "s1" }),
    });
  });

  it("update clearing an assignee sends assigneeKind:null, assigneeId:null (NOT stripped)", async () => {
    mockedJson.mockResolvedValueOnce({ ...WORK_ITEM, assigneeKind: null, assigneeId: null });
    await projectWorkItemsApi.update("w1", {
      assigneeKind: null,
      assigneeId: null,
      dueDate: null,
      parentId: null,
      title: undefined, // an omitted field is still stripped
    });
    expect(mockedJson).toHaveBeenCalledWith("/api/v1/work_items/w1", {
      method: "POST",
      body: JSON.stringify({ assignee_kind: null, assignee_id: null, due_date: null, parent_id: null }),
    });
  });

  it("update setting values keeps only defined fields", async () => {
    mockedJson.mockResolvedValueOnce(WORK_ITEM);
    await projectWorkItemsApi.update("w1", { title: "New", priority: 3 });
    expect(mockedJson).toHaveBeenCalledWith("/api/v1/work_items/w1", {
      method: "POST",
      body: JSON.stringify({ title: "New", priority: 3 }),
    });
  });

  it("move POSTs the named neighbour to the item's move stem", async () => {
    mockedJson.mockResolvedValueOnce({ ...WORK_ITEM, rank: "V05" });
    const out = await projectWorkItemsApi.move("w1", { beforeId: "w2" });
    expect(mockedJson).toHaveBeenCalledWith("/api/v1/work_items/w1/move", {
      method: "POST",
      body: JSON.stringify({ before_id: "w2" }),
    });
    // The moved card comes back carrying its NEW key — that is what lets a caller re-sort the
    // list it already holds instead of refetching it.
    expect(out.rank).toBe("V05");
  });

  it("move to an END sends an explicit null rather than stripping it", async () => {
    // `{ afterId: null }` is "to the top" and `{}` is "you didn't say where" — a 400. So the
    // null has to survive `compact`, exactly as the PATCH clears do.
    mockedJson.mockResolvedValueOnce(WORK_ITEM);
    await projectWorkItemsApi.move("w1", { afterId: null, beforeId: undefined });
    expect(mockedJson).toHaveBeenCalledWith("/api/v1/work_items/w1/move", {
      method: "POST",
      body: JSON.stringify({ after_id: null }),
    });
  });

  it("remove DELETEs the item by id", async () => {
    await projectWorkItemsApi.remove("w1");
    expect(mockedRequest).toHaveBeenCalledWith("/api/v1/work_items/w1", { method: "DELETE" });
  });

  it("children lists the collection filtered to the parent", async () => {
    respondWith(v1List([WIRE_ITEM]));
    await projectWorkItemsApi.children("w1");
    expect(pathAt(0)).toBe("/api/v1/work_items");
    expect(paramsAt(0).get("parent")).toBe("w1");
  });

  it("getValues reads the item with its fields included", async () => {
    mockedJson.mockResolvedValueOnce({
      id: "w1",
      fields: { object: "list", data: [], items: [{ field_id: "f1", key: "sev", label: "Severity", type: "number", value: 3 }] },
    });
    const out = await projectWorkItemsApi.getValues("w1");
    expect(mockedJson).toHaveBeenCalledWith("/api/v1/work_items/w1?include[]=fields", undefined);
    expect(out[0]?.value).toBe(3);
  });

  it("setValues POSTs the batch as the item's `fields` member", async () => {
    mockedJson.mockResolvedValueOnce({ id: "w1", fields: { items: [] } });
    await projectWorkItemsApi.setValues("w1", { values: [{ fieldId: "f1", value: null }] });
    expect(mockedJson).toHaveBeenCalledWith("/api/v1/work_items/w1", {
      method: "POST",
      body: JSON.stringify({ fields: { values: [{ field_id: "f1", value: null }] } }),
    });
  });

  it("dependencies.add POSTs the dependsOnId edge", async () => {
    mockedJson.mockResolvedValueOnce({ id: "d1", ecosystemId: "o", workItemId: "w1", dependsOnId: "w2", createdAt: "c" });
    await projectWorkItemsApi.dependencies.add("w1", "w2");
    expect(mockedJson).toHaveBeenCalledWith("/api/v1/work_items/w1/dependencies", {
      method: "POST",
      body: JSON.stringify({ depends_on_id: "w2" }),
    });
  });

  it("dependencies.remove DELETEs the edge", async () => {
    await projectWorkItemsApi.dependencies.remove("w1", "w2");
    expect(mockedRequest).toHaveBeenCalledWith("/api/v1/work_items/w1/dependencies/w2", { method: "DELETE" });
  });
});

/* ── projectActivityApi ───────────────────────────────────────────────── */

// An activity row as /v1 sends it: snake_case, `created` in unix SECONDS.
const T0 = 1767225600;
const iso = (unix: number) => new Date(unix * 1000).toISOString();
const activityRow = (id: string, created: number) => ({
  object: "activity",
  id,
  ecosystem_id: "o",
  project_id: "p1",
  work_item_id: null,
  actor_kind: null,
  actor_id: null,
  actor_label: null,
  action: "project.updated",
  detail: null,
  created,
});

describe("projectActivityApi", () => {
  it("projectActivity threads limit+before into the query and derives nextBefore from a full page", async () => {
    respondWith(v1List([activityRow("a1", T0), activityRow("a2", T0 + 60)]));
    const page = await projectActivityApi.projectActivity("p1", {
      limit: 2,
      before: "2026-01-02T00:00:00.000Z",
    });
    expect(pathAt(0)).toBe("/api/v1/projects/p1/activity");
    expect(paramsAt(0).get("limit")).toBe("2");
    expect(paramsAt(0).get("before")).toBe("2026-01-02T00:00:00.000Z");
    // Full page (rows === limit) -> nextBefore is a COMPOSITE cursor token "<createdAt>|<id>" (the
    // id tiebreaker that closes the tie gap). /v1 timestamps are whole seconds, so the time half
    // is the NEXT second up: the legacy keyset compares `< before`, and the page is trimmed to
    // the cursor row on the way back in.
    expect(page.nextBefore).toBe(`${iso(T0 + 61)}|a2`);
    expect(page.rows).toHaveLength(2);
    expect(page.rows[1]!.createdAt).toBe(iso(T0 + 60));
  });

  it("projectActivity splits a composite before token into before + before_id query params", async () => {
    respondWith(v1List([activityRow("a3", T0)]));
    await projectActivityApi.projectActivity("p1", { limit: 2, before: "t2|a2" });
    // The opaque "<createdAt>|<id>" token -> before=<createdAt>&before_id=<id> for the keyset.
    expect(paramsAt(0).get("limit")).toBe("2");
    expect(paramsAt(0).get("before")).toBe("t2");
    expect(paramsAt(0).get("before_id")).toBe("a2");
  });

  it("projectActivity drops the rows up to and including the cursor row, so a second-wide tie is not repeated", async () => {
    // The cursor is rounded UP to the next second, so the page can start with rows already shown.
    respondWith(v1List([activityRow("a1", T0 + 60), activityRow("a2", T0 + 60), activityRow("a3", T0)]));
    const page = await projectActivityApi.projectActivity("p1", { limit: 5, before: `${iso(T0 + 61)}|a2` });
    expect(page.rows.map((r) => r.id)).toEqual(["a3"]);
    expect(page.nextBefore).toBeNull();
  });

  it("projectActivity returns nextBefore=null on a short (last) page", async () => {
    respondWith(v1List([activityRow("a1", T0)]));
    const page = await projectActivityApi.projectActivity("p1", { limit: 2 });
    expect(paramsAt(0).get("limit")).toBe("2");
    expect(paramsAt(0).has("before")).toBe(false);
    expect(page.nextBefore).toBeNull();
  });

  it("projectActivity with no options sends only the default page size and nextBefore=null", async () => {
    respondWith(v1List([activityRow("a1", T0), activityRow("a2", T0 + 60)]));
    const page = await projectActivityApi.projectActivity("p1");
    expect(pathAt(0)).toBe("/api/v1/projects/p1/activity");
    expect(paramsAt(0).get("limit")).toBe("50");
    expect(paramsAt(0).has("before")).toBe(false);
    expect(paramsAt(0).has("before_id")).toBe(false);
    expect(page.nextBefore).toBeNull();
  });

  it("workItemActivity hits the work-item stem with the keyset query", async () => {
    respondWith(v1List([activityRow("a1", T0)]));
    await projectActivityApi.workItemActivity("w1", { limit: 1, before: "cur" });
    expect(pathAt(0)).toBe("/api/v1/work_items/w1/activity");
    expect(paramsAt(0).get("limit")).toBe("1");
    expect(paramsAt(0).get("before")).toBe("cur");
  });
});

/* ── projectCommentsApi ───────────────────────────────────────────────── */

// Writing a comment used to live on the activity client, back when a comment WAS an activity
// row. These pin the two things that separation has to get right: a comment reads and writes
// through its OWN stems (the card's for list/add, the comment's own for edit/remove), and
// `threadOf` reconstructs a conversation from the flat list without ever losing a reply.
describe("projectCommentsApi", () => {
  const commentRow = (
    id: string,
    over: Partial<ProjectCommentRow> = {},
  ): ProjectCommentRow => ({
    id,
    projectId: "p1",
    workItemId: "w1",
    parentId: null,
    authorKind: "customer",
    authorId: "cust-1",
    authorLabel: "Ada",
    body: `body ${id}`,
    editedAt: null,
    createdAt: `t-${id}`,
    updatedAt: `t-${id}`,
    ...over,
  });

  const wireComment = (id: string, over: Record<string, unknown> = {}) => ({
    object: "comment",
    id,
    project_id: "p1",
    work_item_id: "w1",
    parent_id: null,
    author_kind: "customer",
    author_id: "cust-1",
    author_label: "Ada",
    body: `body ${id}`,
    edited_at: null,
    created: 1767225600,
    updated: 1767225600,
    ...over,
  });

  it("list GETs the CARD's comments stem and keeps the server's order", async () => {
    // Oldest-first is the server's order and it is load-bearing — a conversation only reads
    // correctly forward — so the client must not sort it into something else.
    respondWith(v1List([wireComment("c1"), wireComment("c2")]));
    const out = await projectCommentsApi.list("w1");
    expect(pathAt(0)).toBe("/api/v1/work_items/w1/comments");
    expect(out.map((c) => c.id)).toEqual(["c1", "c2"]);
  });

  it("add POSTs to the card, and omits parentId entirely when it is a top-level comment", async () => {
    mockedJson.mockResolvedValueOnce(commentRow("c1"));
    await projectCommentsApi.add("w1", "hello");
    expect(mockedJson).toHaveBeenCalledWith("/api/v1/work_items/w1/comments", {
      method: "POST",
      body: JSON.stringify({ body: "hello" }),
    });
  });

  it("add carries parentId when replying", async () => {
    mockedJson.mockResolvedValueOnce(commentRow("c2", { parentId: "c1" }));
    const out = await projectCommentsApi.add("w1", "me too", "c1");
    expect(mockedJson).toHaveBeenCalledWith("/api/v1/work_items/w1/comments", {
      method: "POST",
      body: JSON.stringify({ body: "me too", parent_id: "c1" }),
    });
    expect(out.parentId).toBe("c1");
  });

  it("edit and remove address the COMMENT, not the card that holds it", async () => {
    // The card is how you find a comment; the comment is how you change one. Sending either of
    // these to the work-item stem would edit nothing and report success.
    mockedJson.mockResolvedValueOnce(commentRow("c1", { body: "fixed", editedAt: "t9" }));
    const out = await projectCommentsApi.edit("c1", "fixed");
    expect(mockedJson).toHaveBeenCalledWith("/api/v1/comments/c1", {
      method: "POST",
      body: JSON.stringify({ body: "fixed" }),
    });
    expect(out.editedAt).toBe("t9");

    await projectCommentsApi.remove("c1");
    expect(mockedRequest).toHaveBeenCalledWith("/api/v1/comments/c1", { method: "DELETE" });
  });

  it("maps an unknown authorKind to `customer` rather than inventing a principal", async () => {
    // A bundle older than the backend must not let an unrecognised kind pose as an agent —
    // "a plain author with a label" is the reading that claims the least.
    respondWith(v1List([wireComment("c1", { author_kind: "martian" })]));
    const [c] = await projectCommentsApi.list("w1");
    expect(c?.authorKind).toBe("customer");
  });
});

describe("threadOf", () => {
  const comment = (id: string, parentId: string | null = null): ProjectComment => ({
    id,
    projectId: "p1",
    workItemId: "w1",
    parentId,
    authorKind: "customer",
    authorId: "cust-1",
    authorLabel: "Ada",
    body: `body ${id}`,
    editedAt: null,
    createdAt: `t-${id}`,
    updatedAt: `t-${id}`,
  });

  it("files each reply under its root, keeping both orders", async () => {
    const threads = threadOf([
      comment("c1"),
      comment("c2", "c1"),
      comment("c3"),
      comment("c4", "c1"),
    ]);
    expect(threads.map((t) => t.comment.id)).toEqual(["c1", "c3"]);
    expect(threads[0]?.replies.map((r) => r.id)).toEqual(["c2", "c4"]);
    expect(threads[1]?.replies).toEqual([]);
  });

  it("promotes a reply whose parent is missing instead of dropping it", async () => {
    // Real case: the parent was withdrawn while this reply stands. Losing someone's words to a
    // grouping detail is strictly worse than showing them a level too high.
    const threads = threadOf([comment("c1"), comment("orphan", "gone")]);
    expect(threads.map((t) => t.comment.id)).toEqual(["c1", "orphan"]);
  });
});

/* ── projectArtifactsApi ──────────────────────────────────────────────── */

// The artifacts client's whole job is addressing: a link is identified by ITS id while the
// thing it points at is identified by a (kind, id) pair, and the two are easy to confuse
// because both are called "id" one level up. These pin which one reaches which URL, plus the
// two envelope unwraps (`{ items }`) and the query the picker builds.
describe("projectArtifactsApi", () => {
  const descriptor = (id: string, kind = "content.markdown") => ({
    kind,
    id,
    title: `Doc ${id}`,
    subtitle: null,
    url: null,
  });

  const artifactRow = (id: string) => ({
    object: "project_artifact",
    id,
    project_id: "p1",
    direction: "ingested" as const,
    target_kind: "content.markdown",
    target_id: "d1",
    target: descriptor("d1"),
    created: 1767225600,
  });

  it("list unwraps the /v1 list envelope and keeps the server's order", async () => {
    respondWith(v1List([artifactRow("a2"), artifactRow("a1")]));
    const out = await projectArtifactsApi.list("p1");
    expect(pathAt(0)).toBe("/api/v1/projects/p1/artifacts");
    expect(paramsAt(0).has("direction")).toBe(false);
    // Not re-sorted: the endpoint returns newest-first and a client re-sort would silently
    // disagree with the pagination the endpoint is built for.
    expect(out.map((a) => a.id)).toEqual(["a2", "a1"]);
  });

  it("list narrows to one direction when asked", async () => {
    await projectArtifactsApi.list("p1", { direction: "produced" });
    expect(pathAt(0)).toBe("/api/v1/projects/p1/artifacts");
    expect(paramsAt(0).get("direction")).toBe("produced");
  });

  it("list keeps an unresolvable pointer as a row with a null target", async () => {
    respondWith(v1List([{ ...artifactRow("a1"), target: null }]));
    const [row] = await projectArtifactsApi.list("p1");
    expect(row?.target).toBeNull();
    // The pointer itself survives, so a renderer can still say WHAT is missing.
    expect(row?.targetKind).toBe("content.markdown");
    expect(row?.targetId).toBe("d1");
  });

  it("attachable builds the picker query on the project's `attachable` include and unwraps the envelope", async () => {
    mockedJson.mockResolvedValueOnce({
      attachable: { items: [descriptor("d1"), descriptor("d2"), descriptor("d3")] },
    });
    const out = await projectArtifactsApi.attachable("p1", {
      kind: "content.urls",
      query: "road map",
      limit: 2,
    });
    expect(String(mockedJson.mock.calls[0]![0])).toMatch(/^\/api\/v1\/projects\/p1\?/);
    expect(paramsOf(0).get("include[]")).toBe("attachable");
    expect(paramsOf(0).get("kind")).toBe("content.urls");
    expect(paramsOf(0).get("q")).toBe("road map");
    // /v1 has no limit on an include, so the cap is applied here.
    expect(out.map((d) => d.id)).toEqual(["d1", "d2"]);
  });

  it("attachable sends only the include when nothing narrows it", async () => {
    mockedJson.mockResolvedValueOnce({ attachable: [] });
    await projectArtifactsApi.attachable("p1");
    expect([...paramsOf(0).keys()]).toEqual(["include[]"]);
  });

  it("attachable defaults `url`/`subtitle` to null rather than leaving them undefined", async () => {
    mockedJson.mockResolvedValueOnce({ attachable: { items: [{ kind: "k", id: "i", title: "T" }] } });
    const [d] = await projectArtifactsApi.attachable("p1");
    expect(d?.subtitle).toBeNull();
    expect(d?.url).toBeNull();
  });

  it("link POSTs the (direction, kind, id) triple and maps the created row", async () => {
    mockedJson.mockResolvedValueOnce(artifactRow("a1"));
    const out = await projectArtifactsApi.link("p1", {
      direction: "ingested",
      targetKind: "content.markdown",
      targetId: "d1",
    });
    expect(mockedJson).toHaveBeenCalledWith("/api/v1/projects/p1/artifacts", {
      method: "POST",
      body: JSON.stringify({
        direction: "ingested",
        target_kind: "content.markdown",
        target_id: "d1",
      }),
    });
    expect(out.target?.title).toBe("Doc d1");
  });

  it("unlink addresses the LINK's id, not the target's, and encodes both segments", async () => {
    mockedRequest.mockResolvedValueOnce(undefined);
    await projectArtifactsApi.unlink("p/1", "a/1");
    expect(mockedRequest).toHaveBeenCalledWith(
      "/api/v1/projects/p%2F1/artifacts/a%2F1",
      { method: "DELETE" },
    );
  });
});

/* ── work-item keys ───────────────────────────────────────────────────── */

// A key (`WEB-42`) is TWO stored halves — the project's prefix and the item's number —
// rendered by the backend into one string. The client never assembles one; what it owes
// is (a) a total field even when the backend omits it, so no view has to guard, and
// (b) the same shape rule the backend enforces, so a doomed prefix is refused before a
// round trip rather than after a 400.
describe("work-item keys", () => {
  it("defaults a project's keyPrefix to \"\" when the backend omits it", async () => {
    // An older backend — or a project created before the column existed — sends no
    // keyPrefix. `undefined` would reach an <Input value=…> and make it uncontrolled.
    mockedJson.mockResolvedValueOnce({ id: "1", name: "P", description: "", status: "active", color: "#000", ecosystemId: "o", createdAt: "c", updatedAt: "u" });
    const p = await projectsApi.get("1");
    expect(p?.keyPrefix).toBe("");
  });

  it("carries the keyPrefix through when the backend sends one", async () => {
    mockedJson.mockResolvedValueOnce({ id: "1", name: "P", description: "", status: "active", color: "#000", keyPrefix: "WEB", ecosystemId: "o", createdAt: "c", updatedAt: "u" });
    const p = await projectsApi.get("1");
    expect(p?.keyPrefix).toBe("WEB");
  });

  it("defaults a work item's itemKey to \"\" when the backend omits it", async () => {
    respondWith(v1List([WIRE_ITEM]));
    const [w] = await projectWorkItemsApi.listForProject("p1");
    expect(w?.itemKey).toBe("");
  });

  it("carries the rendered itemKey through when the backend sends one", async () => {
    // `item_key` is not a declared /v1 property, so the gateway passes it through camelCase;
    // both spellings must land on `itemKey`.
    respondWith(v1List([{ ...WIRE_ITEM, item_key: "WEB-42" }]));
    const [w] = await projectWorkItemsApi.listForProject("p1");
    expect(w?.itemKey).toBe("WEB-42");
  });

  it("update POSTs a key_prefix like any other field", async () => {
    mockedJson.mockResolvedValueOnce({ id: "1", name: "P", description: "", status: "active", color: "#000", keyPrefix: "WEB", ecosystemId: "o", createdAt: "c", updatedAt: "u" });
    await projectsApi.update("1", { keyPrefix: "WEB" });
    expect(mockedJson).toHaveBeenCalledWith("/api/v1/projects/1", {
      method: "POST",
      body: JSON.stringify({ key_prefix: "WEB" }),
    });
  });
});

describe("validateKeyPrefix", () => {
  it("accepts 2–8 characters starting with a letter", () => {
    for (const ok of ["AB", "WEB", "ADH2", "A1B2C3D4"]) {
      expect(validateKeyPrefix(ok)).toBeNull();
    }
  });

  it("accepts lower case and surrounding space — the caller upper-cases on the way out", () => {
    expect(validateKeyPrefix(" web ")).toBeNull();
  });

  it("says a prefix is required rather than silently allowing an empty one", () => {
    expect(validateKeyPrefix("")).toMatch(/required/i);
    expect(validateKeyPrefix("   ")).toMatch(/required/i);
  });

  it("refuses a single character, a 9th character, a leading digit, and punctuation", () => {
    for (const bad of ["A", "ABCDEFGHI", "1AB", "A-B", "A B", "AB!"]) {
      expect(validateKeyPrefix(bad)).not.toBeNull();
    }
  });
});

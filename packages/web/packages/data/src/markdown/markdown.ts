// Research documents API client — wired to the backend's papers surface
// (`/v1/papers`, `/v1/paper_categories`, `/v1/paper_tags`, reached through the hub's `/api`
// forward). That is the sole surface for a user's markdown research papers
// (list/search, CRUD, publish/unpublish). The wire is snake_case with unix-second
// timestamps; the camelCase app rows below are mapped at this boundary. Row/body shapes live in
// ./wire.ts, narrowed from the generated OpenAPI schema (@adh-sdk/adh-api-types) —
// a generic data client must not import that adh-specific package, so a backend contract
// change is only caught by keeping wire.ts in sync, not by the build.
import { authedJson, authedRequest, isConflict, listAllV1, withV1Query } from "../http";
import { enc } from "../client-helpers";
import type {
  MarkdownDocumentRow,
  MarkdownDocumentSummaryRow,
  MarkdownCreateBody,
  MarkdownUpdateBody,
  MarkdownPublishBody,
  MarkdownRouteAvailability,
  StringListBody,
  MarkdownCategoryNode,
  MarkdownCategoryTreeBody,
  MarkdownCategoryCreateBody,
  MarkdownKeywordNode,
  MarkdownTagSetBody,
  PaperCategoriesWire,
  PaperCategoryWire,
  PaperTagsWire,
  PaperWire,
} from "./wire";

/** A full document, body included (GET /content/markdown/:id, and the create /
 *  update / publish responses). */
export type ResearchDocument = MarkdownDocumentRow;
/** Document metadata only — no body (the list/search rows). */
export type ResearchSummary = MarkdownDocumentSummaryRow;

export type CreateMarkdownBody = MarkdownCreateBody;
export type UpdateMarkdownBody = MarkdownUpdateBody;

/** Whether a public route is free for a document's author. */
export type { MarkdownRouteAvailability } from "./wire";

/** One category as this surface exposes it — id, name, and the parent pointer that
 *  makes the set a tree. Re-exported (not aliased) because a hierarchical consumer
 *  passes these rows around, not just their names. */
export type { MarkdownCategoryNode, MarkdownCategoryCreateBody, MarkdownCategoryEdge } from "./wire";

/** One tag as this surface exposes it — the label, and the id that addresses it. Re-exported
 *  for the same reason as {@link MarkdownCategoryNode}: a management UI passes the rows
 *  around, not just their text. */
export type { MarkdownKeywordNode } from "./wire";

/** Caller-scoped list filters, all wired to the backend's query params: `q`
 *  (free-text across title/body/category/tags), `category` (exact), `tag` (set
 *  membership). Absent/blank filters are omitted. */
export interface ResearchFilters {
  q?: string;
  category?: string;
  tag?: string;
}

const BASE = "/api/v1/papers";
const CATEGORIES = "/api/v1/paper_categories";
const TAGS = "/api/v1/paper_tags";

/** List options: the workspace to scope to, and one flag per CORPUS — `noted` for the
 *  owner's notes, `doc` for their docs (the documents in the matching storage bucket).
 *  A `false` is NOT "everything except that corpus" — the backend offers no such set —
 *  it is simply the unfiltered list. */
export interface MarkdownListOptions extends MarkdownScope {
  noted?: boolean;
  doc?: boolean;
  /** Only documents at this visibility — a bucket's Papers table asks for `"public"`, filtered
   *  SERVER side so no page cut can hide a published paper (Mike, 2026-09-25). */
  visibility?: "private" | "public";
}

/** Where an op acts. `workspace` pins it to the workspace's owning principal; `ecosystemId`
 *  names the ONE ecosystem it acts in (backend `?ecosystemId=`, verified against what the caller
 *  manages) — a bucket's markdown rows are that bucket's ecosystem's, never the workspace-wide
 *  list (Mike, 2026-09-25: "an ecosystem shows only its own data"). */
export interface MarkdownScope {
  workspace?: string;
  ecosystemId?: string;
}

/** `url` with the workspace/ecosystem scope appended (`workspace`, `ecosystem_id`). */
function scoped(url: string, opts?: MarkdownScope, extra: Record<string, string | boolean | undefined> = {}): string {
  return withV1Query(url, {
    ...extra,
    workspace: opts?.workspace || undefined,
    ecosystem_id: opts?.ecosystemId || undefined,
  });
}

function listUrl(filters: ResearchFilters, opts?: MarkdownListOptions): string {
  return scoped(BASE, opts, {
    q: filters.q?.trim() || undefined,
    category: filters.category?.trim() || undefined,
    tag: filters.tag?.trim() || undefined,
    noted: opts?.noted ? true : undefined,
    doc: opts?.doc ? true : undefined,
    visibility: opts?.visibility,
  });
}

const toDocument = (w: PaperWire): ResearchDocument =>
  withTags({
    id: w.id,
    title: w.title,
    content: w.content ?? "",
    ...(w.category !== undefined ? { category: w.category } : {}),
    tags: w.tags ?? [],
    visibility: w.visibility,
    ...(w.public_route !== undefined ? { publicRoute: w.public_route } : {}),
  });

const toSummary = (w: PaperWire): ResearchSummary =>
  withTags({
    id: w.id,
    title: w.title,
    ...(w.excerpt !== undefined ? { excerpt: w.excerpt } : {}),
    ...(w.category !== undefined ? { category: w.category } : {}),
    tags: w.tags ?? [],
    visibility: w.visibility,
    ...(w.public_route !== undefined ? { publicRoute: w.public_route } : {}),
  });

const toCreateWire = (b: CreateMarkdownBody) => ({
  content: b.content,
  ...(b.category !== undefined ? { category: b.category } : {}),
  ...(b.tags !== undefined ? { tags: b.tags } : {}),
  ...(b.note !== undefined ? { note: b.note } : {}),
  ...(b.doc !== undefined ? { doc: b.doc } : {}),
});

/** Guarantee `tags` is an array. The generated types mark it required, but a
 *  backend deploy OLDER than this frontend (before the category/tags migration)
 *  omits it — and an unguarded `doc.tags` then crashes the list/detail render
 *  (`tags is not iterable` / reading `length` of undefined). Normalizing once at
 *  the API boundary keeps every consumer (model + pane) free of `?? []` guards.
 *  Exported for the unit test. */
export function withTags<T extends { tags: string[] }>(doc: T): T {
  const tags = (doc as { tags?: unknown }).tags;
  return Array.isArray(tags) ? doc : { ...doc, tags: [] };
}

/** Fold the categories response into the rows a hierarchical consumer walks.
 *
 *  Same skew as `withTags`, one migration later: a backend deploy OLDER than this
 *  frontend (before categories became rows) answers with `items` alone — the flat NAMES —
 *  and an unguarded `res.nodes` crashes the notebook rail. Those names are the entire
 *  category set such a backend HAS, so the degrade rebuilds them as roots instead of
 *  yielding an empty rail. Nothing else about the notebook needs the missing structure:
 *  every use of a category is BY NAME — notes are filtered with `?category=<name>` (an
 *  exact match) and the URL segment is `slugFor(name, id)`.
 *
 *  The id it synthesizes is the name, which is not a fabricated row id: a name is unique
 *  per owner (see {@link MarkdownCategoryTreeBody}), so it is the only identity that
 *  backend has and the one it filters by. It also never travels back — the single write
 *  taking an id is `createCategory({ parentIds })`, and a flat list has no children, so
 *  the rail never publishes a level with a parent to create under (`NotebookPane` breaks
 *  its level loop on `children.length === 0`).
 *
 *  Exported for the unit test. */
export function categoryNodes(res: MarkdownCategoryTreeBody): MarkdownCategoryNode[] {
  if (Array.isArray(res.nodes)) return res.nodes;
  const items = Array.isArray(res.items) ? res.items : [];
  return items.map((name, i) => ({ id: name, name, parentIds: [], sortOrder: i }));
}

/** Fold the tags response into rows — the tag twin of {@link categoryNodes}, and the same
 *  skew: a backend deploy older than this frontend answers `/tags` with `items` alone.
 *
 *  The degrade differs in what it costs, so it is worth being explicit: the synthesized id
 *  is the label, and `/content/keywords/{id}` wants a row id. Listing and filtering still
 *  work (both are by label); a rename or delete 404s and is reported as the failure it is.
 *  It cannot hit the WRONG row — ids are uuids, so a label never collides with one — which
 *  is the property that makes this degrade safe rather than merely convenient.
 *
 *  Exported for the unit test. */
export function tagNodes(res: MarkdownTagSetBody): MarkdownKeywordNode[] {
  if (Array.isArray(res.nodes)) return res.nodes;
  const items = Array.isArray(res.items) ? res.items : [];
  return items.map((label) => ({ id: label, label }));
}

export const markdownApi = {
  // `workspace` on every op pins it to the WORKSPACE'S owning principal (backend
  // `?workspace=<slug>`): list returns only documents that principal OWNS, create
  // stamps it as the owner, and item ops resolve org-owned docs other members
  // created. Without it, ops fall back to the caller's own documents.
  /** List/search the workspace's documents (metadata only), most-recent first. */
  async list(
    filters: ResearchFilters = {},
    opts?: MarkdownListOptions,
  ): Promise<ResearchSummary[]> {
    const rows = await listAllV1<PaperWire>(listUrl(filters, opts));
    return rows.map(toSummary);
  },

  /** Fetch one document WITH its body (the master list omits the body). */
  async get(id: string, opts?: MarkdownScope): Promise<ResearchDocument> {
    return toDocument(await authedJson<PaperWire>(scoped(`${BASE}/${enc(id)}`, opts)));
  },

  async create(
    body: CreateMarkdownBody,
    opts?: MarkdownScope,
  ): Promise<ResearchDocument> {
    return toDocument(
      await authedJson<PaperWire>(scoped(BASE, opts), {
        method: "POST",
        body: JSON.stringify(toCreateWire(body)),
      }),
    );
  },

  async update(
    id: string,
    body: UpdateMarkdownBody,
    opts?: MarkdownScope,
  ): Promise<ResearchDocument> {
    return toDocument(
      await authedJson<PaperWire>(scoped(`${BASE}/${enc(id)}`, opts), {
        method: "POST",
        body: JSON.stringify(body),
      }),
    );
  },

  async remove(id: string, opts?: MarkdownScope): Promise<void> {
    // A tombstone body the caller never reads — authedRequest, not authedJson.
    await authedRequest(scoped(`${BASE}/${enc(id)}`, opts), { method: "DELETE" });
  },

  /** Is this public route free for this document's author? Answers the same question
   *  `publish` would 409 on, but read-only and without claiming anything — so an editor can
   *  ask while the user types. Excludes the document itself: a published paper's own slug is
   *  not taken for it. */
  async routeAvailable(
    id: string,
    route: string,
    opts?: MarkdownScope,
  ): Promise<MarkdownRouteAvailability> {
    // Spelled as a filter on the collection: `route` names the slug, `excluding` the document
    // that may keep it.
    return authedJson<MarkdownRouteAvailability>(scoped(BASE, opts, { route, excluding: id }));
  },

  /** Publish under an author-defined public route. The route is unique per
   *  author: a clash with another of the caller's live papers is a 409, mapped
   *  to a friendly message the form surfaces inline. */
  async publish(
    id: string,
    route: string,
    opts?: MarkdownScope,
  ): Promise<ResearchDocument> {
    try {
      return toDocument(
        await authedJson<PaperWire>(scoped(`${BASE}/${enc(id)}/publish`, opts), {
          method: "POST",
          body: JSON.stringify({ route } satisfies MarkdownPublishBody),
        }),
      );
    } catch (err) {
      if (isConflict(err)) {
        throw new Error(`The route “${route}” is already used by one of your papers.`);
      }
      throw err;
    }
  },

  /** Revert to a private draft and free the public route. */
  async unpublish(id: string, opts?: MarkdownScope): Promise<ResearchDocument> {
    return toDocument(
      await authedJson<PaperWire>(scoped(`${BASE}/${enc(id)}/unpublish`, opts), {
        method: "POST",
      }),
    );
  },

  /** The workspace's existing category NAMES — the autocomplete/browse source for the
   *  category field. The owner's full set (content.categories), distinct + alphabetical
   *  (GET /v1/paper_categories). `workspace` matters: the backend scopes the
   *  vocabulary to the same owner it scopes the documents to, so an org workspace's
   *  autocomplete must ask for the ORG's names, not the caller's own. */
  async categories(opts?: MarkdownScope): Promise<string[]> {
    const res = await authedJson<StringListBody>(scoped(CATEGORIES, opts));
    return res.items;
  },

  /** The same categories WITH their structure — `parentIds` makes them a DAG. The flat
   *  `categories()` above is the autocomplete's view of this one set; a hierarchical
   *  browser needs the ids and parents, which names alone cannot carry.
   *
   *  Against a backend too old to send `nodes`, {@link categoryNodes} rebuilds the flat
   *  names it DID send as roots, so the rail degrades to one level instead of crashing
   *  or emptying. */
  async categoryTree(opts?: MarkdownScope): Promise<MarkdownCategoryNode[]> {
    const res = await authedJson<PaperCategoriesWire>(scoped(CATEGORIES, opts));
    const tree: MarkdownCategoryTreeBody = {
      items: res.items ?? [],
      // Left absent (not `[]`) when the response has none, so `categoryNodes` can tell skew
      // from a legitimately empty workspace.
      nodes: (Array.isArray(res.nodes)
        ? res.nodes.map((n) => ({ id: n.id, name: n.name, parentIds: n.parent_ids, sortOrder: n.sort_order }))
        : undefined) as MarkdownCategoryTreeBody["nodes"],
    };
    return categoryNodes(tree);
  },

  /** Create a category, optionally under one or more others (POST
   *  /v1/paper_categories). Re-creating an existing name is idempotent when every
   *  parent it asks for is ALREADY one of that category's parents; asking for one it does
   *  not have is a 409 — a name is unique per owner, and this call never re-files an
   *  existing category. Adding a parent to a category that exists is
   *  {@link taxonomyApi.addCategoryParent}, where it is what it says it is. */
  async createCategory(
    body: MarkdownCategoryCreateBody,
    opts?: MarkdownScope,
  ): Promise<MarkdownCategoryNode> {
    try {
      const w = await authedJson<PaperCategoryWire>(scoped(CATEGORIES, opts), {
        method: "POST",
        body: JSON.stringify({
          name: body.name,
          ...(body.parentIds !== undefined ? { parent_ids: body.parentIds } : {}),
        }),
      });
      return { id: w.id, name: w.name, parentIds: w.parent_ids, sortOrder: w.sort_order };
    } catch (err) {
      if (isConflict(err)) {
        throw new Error(`A category named “${body.name}” already exists somewhere else.`);
      }
      throw err;
    }
  },

  /** The workspace's existing tag LABELS — the autocomplete/browse source for the tag
   *  field (GET /v1/paper_tags), same shape + scoping as `categories`. */
  async tags(opts?: MarkdownScope): Promise<string[]> {
    const res = await authedJson<StringListBody>(scoped(TAGS, opts));
    return res.items;
  },

  /** The same tags WITH their row ids — what a manager needs to rename or delete one, and
   *  what `tags()` above cannot carry. One endpoint serves both views, so they can never
   *  disagree about the workspace's vocabulary; see {@link tagNodes} for the older-backend
   *  degrade. */
  async tagSet(opts?: MarkdownScope): Promise<MarkdownKeywordNode[]> {
    const res = await authedJson<PaperTagsWire>(scoped(TAGS, opts));
    const set: MarkdownTagSetBody = {
      items: res.items ?? [],
      nodes: (Array.isArray(res.nodes) ? res.nodes : undefined) as MarkdownTagSetBody["nodes"],
    };
    return tagNodes(set);
  },
};

// The wire boundary for /v1 clients whose app-facing types are camelCase.
//
// /v1 speaks snake_case with unix-second `created` / `updated`. A client that keeps its
// camelCase row types (so every consumer is untouched) maps at the edge with these:
//
//   fromV1   a /v1 object  -> the camelCase row the client was written against
//   toV1Body a camelCase body -> the snake_case body /v1 takes
//
// The gateway only renames properties the legacy spec DECLARES; a property it does not know
// (a work item's `itemKey`, an iteration row's `projectName`) passes through in its original
// camelCase. `fromV1` therefore camelizes IDEMPOTENTLY: `project_id` and `projectId` both
// land on `projectId`.
//
// Free-form maps keep the keys they were stored with and must never be re-cased:
// a saved view's `config`, an activity's `detail`, a template's `body`, a field's `value`, and a
// milestone's `counts` (whose keys are the category names, `in_progress` included).

import { authedJson, listAllV1, listV1Page, unixToIso } from "./http";

const OPAQUE = new Set(["config", "detail", "body", "value", "counts"]);

const camel = (k: string): string => k.replace(/_([a-z0-9])/g, (_, c: string) => c.toUpperCase());
const snake = (k: string): string => k.replace(/[A-Z]/g, (c) => `_${c.toLowerCase()}`);

function mapKeys(v: unknown, rename: (k: string) => string, wire: boolean): unknown {
  if (Array.isArray(v)) return v.map((x) => mapKeys(x, rename, wire));
  if (v === null || typeof v !== "object") return v;
  const out: Record<string, unknown> = {};
  for (const [k, val] of Object.entries(v as Record<string, unknown>)) {
    if (val === undefined) continue; // JSON.stringify would drop it anyway
    if (!wire && k === "object") continue; // the /v1 type tag, not data
    if (!wire && typeof val === "number" && (k === "created" || k === "updated")) {
      out[k === "created" ? "createdAt" : "updatedAt"] = unixToIso(val);
      continue;
    }
    out[rename(k)] = OPAQUE.has(k) ? val : mapKeys(val, rename, wire);
  }
  return out;
}

/** A /v1 object (or array of them) as the camelCase row the client's types describe. */
export function fromV1<T>(wire: unknown): T {
  return mapKeys(wire, camel, false) as T;
}

/** A camelCase request body as /v1 takes it. Explicit `null` is kept (it CLEARS a column);
 *  `undefined` is dropped. */
export function toV1Body(body: unknown): unknown {
  return mapKeys(body, snake, true);
}

/** `JSON.stringify(toV1Body(body))` — the `init` of a /v1 write. */
export function v1Write(method: "POST", body: unknown): RequestInit {
  return { method, body: JSON.stringify(toV1Body(body)) };
}

/** One /v1 object, mapped to its camelCase row. */
export async function v1Json<T>(url: string, init?: RequestInit): Promise<T> {
  return fromV1<T>(await authedJson<unknown>(url, init));
}

/** Every row of a /v1 collection (all pages), mapped to camelCase rows. */
export async function v1List<T>(url: string): Promise<T[]> {
  return fromV1<T[]>(await listAllV1<unknown>(url));
}

/** One page of a /v1 collection, rows mapped to camelCase. */
export async function v1Page<T>(url: string): Promise<{ data: T[]; hasMore: boolean }> {
  const { data, hasMore } = await listV1Page<unknown>(url);
  return { data: fromV1<T[]>(data), hasMore };
}

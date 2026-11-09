// Project activity API client — the audit trail side of `/api/v1/*`.
//
// Both activity trails (project-scoped and work-item-scoped) are newest-first and
// keyset-paginated on `{ limit?, before? }`: `before` is an OPAQUE composite cursor
// token ("<createdAt>|<id>" of the last row you already have), which the client splits
// into the backend's (before, beforeId) keyset so millisecond-tied rows never straddle
// a page boundary. Each list method returns `{ rows, nextBefore }`, where `nextBefore`
// is that token to pass as the NEXT `before` when a full `limit` page came back, else
// null (no more pages, or the caller asked for no limit so there's nothing to page against).
//
// WRITING a comment is not here — `./comments` owns the conversation, because a comment is a
// row of its own that its author can correct or withdraw. Every such act still shows up in this
// trail as a `comment.added` / `.edited` / `.deleted` entry; the trail records the ACT, the
// comment holds the WORDS.

import { withV1Query } from "../http";
import { enc } from "../client-helpers";
import { v1Page } from "../v1-case";
import type { ProjectActivityRow } from "./wire";

const PROJECTS = "/api/v1/projects";
const ITEMS = "/api/v1/work_items";
/** The page the legacy trail returned when no `limit` was named. */
const ACTIVITY_LIMIT_DEFAULT = 50;

export interface ProjectActivity {
  id: string;
  projectId: string;
  /** set when the event is card-scoped. */
  workItemId: string | null;
  actorKind: string | null;
  actorId: string | null;
  actorLabel: string | null;
  /** the event, e.g. project.created, work_item.status_changed, comment.added. */
  action: string;
  /** action-specific payload (jsonb). */
  detail: Record<string, unknown> | null;
  createdAt: string;
}

export function toProjectActivity(r: ProjectActivityRow): ProjectActivity {
  return {
    id: r.id,
    projectId: r.projectId,
    workItemId: r.workItemId ?? null,
    actorKind: r.actorKind ?? null,
    actorId: r.actorId ?? null,
    actorLabel: r.actorLabel ?? null,
    action: r.action,
    detail: r.detail ?? null,
    createdAt: r.createdAt,
  };
}

/** A newest-first keyset page. */
export interface ActivityPage {
  rows: ProjectActivity[];
  /** cursor for the next `before`, or null when there are no more rows. */
  nextBefore: string | null;
}

interface Keyset {
  limit?: number;
  before?: string;
}

/** Build the `?limit=&before=&beforeId=` query for a keyset page (empty when neither set). */
function keysetQuery({ limit, before }: Keyset): Record<string, string | number | undefined> {
  const sep = before === undefined ? -1 : before.lastIndexOf("|");
  return {
    limit: limit ?? ACTIVITY_LIMIT_DEFAULT,
    before: before === undefined ? undefined : sep >= 0 ? before.slice(0, sep) : before,
    before_id: before !== undefined && sep >= 0 && before.slice(sep + 1) ? before.slice(sep + 1) : undefined,
  };
}

async function fetchActivityPage(
  url: string,
  { limit, before }: Keyset,
): Promise<ActivityPage> {
  const q = keysetQuery({ limit, before });
  const page = await v1Page<ProjectActivityRow>(withV1Query(url, q));
  let data = page.data;
  // /v1 carries `created` in whole seconds, so the cursor below is the NEXT second up: the
  // backend then returns every row of the cursor row's second, including ones already shown.
  // They sit ahead of the cursor row in the trail's order, so everything up to and including
  // that row is dropped.
  const cursorId = typeof q.before_id === "string" ? q.before_id : undefined;
  if (cursorId) {
    const at = data.findIndex((r) => r.id === cursorId);
    if (at >= 0) data = data.slice(at + 1);
  }
  const rows = data.map(toProjectActivity);
  const last = rows.at(-1);
  const nextBefore =
    limit !== undefined && page.data.length === limit && last
      ? `${new Date(Date.parse(last.createdAt) + 1000).toISOString()}|${last.id}`
      : null;
  return { rows, nextBefore };
}

export const projectActivityApi = {
  projectActivity(projectId: string, opts: Keyset = {}): Promise<ActivityPage> {
    return fetchActivityPage(`${PROJECTS}/${enc(projectId)}/activity`, opts);
  },

  workItemActivity(workItemId: string, opts: Keyset = {}): Promise<ActivityPage> {
    return fetchActivityPage(`${ITEMS}/${enc(workItemId)}/activity`, opts);
  },
};

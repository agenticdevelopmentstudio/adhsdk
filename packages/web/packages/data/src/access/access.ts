// Workspace roles & permissions API client — the gated /v1/access surface
// (adh/docs/platform/workspace-roles-permissions.md). Every call names the workspace by slug
// (`?workspace=`): a personal workspace's customer slug or an org slug. Reads answer
// 404 to non-members; role definition is admin-only; assignments/restriction need the
// M verb at the target scope (the server enforces no-escalation).

import { authedJson, authedRequest, listAllV1, withV1Query } from "../http";
import { enc } from "../client-helpers";
import type {
  AccessAssignmentWire,
  AccessRoleWire,
  EffectiveAccessWire,
  AccessAssignmentRow,
  AccessFeatureRow,
  AccessGrantRow,
  AccessRoleRow,
  EffectiveAccessRow,
} from "./wire";

export type {
  AccessAssignmentRow,
  AccessFeatureRow,
  AccessGrantRow,
  AccessRoleRow,
  EffectiveAccessRow,
};

const BASE = "/api/v1/access";

const toRole = (w: AccessRoleWire): AccessRoleRow => ({
  id: w.id,
  slug: w.slug,
  name: w.name,
  description: w.description,
  isSystem: w.is_system,
  defaultFor: w.default_for,
  grants: w.grants.map((g) => ({
    feature: g.feature,
    itemVerbs: g.item_verbs,
    subitemVerbs: g.subitem_verbs,
  })),
});

const grantsToWire = (grants: AccessGrantRow[]) =>
  grants.map((g) => ({ feature: g.feature, item_verbs: g.itemVerbs, subitem_verbs: g.subitemVerbs }));

const toAssignment = (w: AccessAssignmentWire): AccessAssignmentRow => ({
  id: w.id,
  subjectKind: w.subject_kind,
  subjectId: w.subject_id,
  scopeFeature: w.scope_feature,
  scopeItemId: w.scope_item_id,
  roleId: w.role_id,
  ...(w.role_slug !== undefined ? { roleSlug: w.role_slug } : {}),
  ...(w.role_name !== undefined ? { roleName: w.role_name } : {}),
  ...(w.granted_by !== undefined ? { grantedBy: w.granted_by } : {}),
  ...(w.granted_at !== undefined ? { grantedAt: w.granted_at } : {}),
});

/**
 * The FALLBACK feature areas the roles matrix edits — used only when the backend cannot tell
 * us its own (see {@link accessApi.listFeatures}).
 *
 * The authoritative registry is per-DEPLOYMENT (backend `lib/feature-areas.ts`) and every
 * submitted grant is refined against it server-side, so this list can never be the source of
 * truth: a product whose backend has grown an area finds it ungrantable, and one whose backend
 * lacks an area listed here 400s the save. It stays as the degraded path for a backend that
 * predates `/v1/access/features`, and holds only the two areas the roles layer shipped with — the
 * intersection every product on this toolkit is known to enforce. Do NOT widen it.
 */
export const ACCESS_FEATURES: ReadonlyArray<AccessFeatureRow> = [
  { key: "projects", label: "Projects" },
  { key: "personas", label: "Personas" },
];

export interface AccessRoleInput {
  slug: string;
  name: string;
  description?: string;
  defaultFor?: "" | "customer" | "persona";
  grants: AccessGrantRow[];
}

export interface AccessAssignmentInput {
  subjectKind: "customer" | "persona" | "team";
  subjectId: string;
  /** Provide feature+itemId together to scope the grant to one item; omit both for workspace-wide. */
  feature?: string;
  itemId?: string;
  roleId: string;
}

/** True when `v` is a well-formed {@link AccessFeatureRow}: an object with a NON-EMPTY string `key`
 *  and a non-empty string `label`. `GET /v1/access/features` is the one response this client cannot
 *  typecheck away — `body.features` was previously returned via a bare cast, so a wrong shape (a
 *  string, an array of bare strings, an object) reached every consumer looking exactly like real
 *  data instead of the error it is. Lives beside `listFeatures` so the guard protects every consumer
 *  of this client, not just the one pane that happens to render the matrix today.
 *
 *  The emptiness checks are the part a `typeof` test misses. `""` is a string, so `{key:"",label:""}`
 *  would pass and travel on as a live row: the key is what a grant is submitted under (so an empty
 *  one revokes at the backend's refinement step, or writes a grant nothing can ever match) and the
 *  label is the only thing identifying the checkbox column to the admin ticking it. Neither has a
 *  sane empty reading, and no real registry produces one — the reference backend derives both from
 *  hardcoded string literals — so this rejects the row rather than rendering a nameless column. */
function isAccessFeatureRow(v: unknown): v is AccessFeatureRow {
  const key = (v as { key?: unknown } | null)?.key;
  const label = (v as { label?: unknown } | null)?.label;
  return (
    typeof v === "object" &&
    v !== null &&
    typeof key === "string" &&
    key.length > 0 &&
    typeof label === "string" &&
    label.length > 0
  );
}

export const accessApi = {
  /**
   * The feature areas THIS backend enforces (key + display label), in registration order.
   * Any workspace member may read it; non-members get the uniform 404.
   *
   * REJECTS on a backend that has no such route (404) — that is the expected answer from a
   * product whose server predates this endpoint, so callers must fall back to
   * {@link ACCESS_FEATURES} rather than render an empty matrix. Also REJECTS (throws) when the
   * body's `data` is not an array of {@link AccessFeatureRow}, so a malformed-but-plausible
   * answer (e.g. a bare string, or an array of feature keys with no `label`) surfaces to the
   * caller as a failure to fall back on rather than a value that crashes downstream `.map()`s.
   */
  async listFeatures(workspace: string): Promise<AccessFeatureRow[]> {
    const body = await authedJson<{ data?: unknown; has_more?: boolean }>(
      withV1Query(`${BASE}/features`, { workspace, limit: 100 }),
    );
    const rows = body.data;
    if (!Array.isArray(rows) || !rows.every(isAccessFeatureRow) || body.has_more === true) {
      throw new Error("GET /v1/access/features returned a malformed feature list");
    }
    return rows.map((r) => ({ key: r.key, label: r.label }));
  },

  async listRoles(workspace: string): Promise<AccessRoleRow[]> {
    const rows = await listAllV1<AccessRoleWire>(withV1Query(`${BASE}/roles`, { workspace }));
    return rows.map(toRole);
  },

  async createRole(workspace: string, input: AccessRoleInput): Promise<AccessRoleRow> {
    const row = await authedJson<AccessRoleWire>(withV1Query(`${BASE}/roles`, { workspace }), {
      method: "POST",
      body: JSON.stringify({
        slug: input.slug,
        name: input.name,
        ...(input.description !== undefined ? { description: input.description } : {}),
        ...(input.defaultFor !== undefined ? { default_for: input.defaultFor } : {}),
        grants: grantsToWire(input.grants),
      }),
    });
    return toRole(row);
  },

  async updateRole(
    workspace: string,
    id: string,
    patch: Partial<Omit<AccessRoleInput, "slug">>,
  ): Promise<AccessRoleRow> {
    const row = await authedJson<AccessRoleWire>(
      withV1Query(`${BASE}/roles/${enc(id)}`, { workspace }),
      {
        method: "POST",
        body: JSON.stringify({
          ...(patch.name !== undefined ? { name: patch.name } : {}),
          ...(patch.description !== undefined ? { description: patch.description } : {}),
          ...(patch.defaultFor !== undefined ? { default_for: patch.defaultFor } : {}),
          ...(patch.grants !== undefined ? { grants: grantsToWire(patch.grants) } : {}),
        }),
      },
    );
    return toRole(row);
  },

  async deleteRole(workspace: string, id: string): Promise<void> {
    await authedRequest(withV1Query(`${BASE}/roles/${enc(id)}`, { workspace }), {
      method: "DELETE",
    });
  },

  /** Workspace-wide listing needs workspace admin; item-scoped needs M on that item.
   *  `restricted` is present on item-scoped listings. */
  async listAssignments(
    workspace: string,
    scope?: { feature: string; itemId: string },
  ): Promise<{ assignments: AccessAssignmentRow[]; restricted?: boolean }> {
    const body = await authedJson<{ assignments: AccessAssignmentWire[]; restricted?: boolean }>(
      withV1Query(`${BASE}/role_assignments`, {
        workspace,
        feature: scope?.feature,
        item_id: scope?.itemId,
      }),
    );
    return {
      assignments: body.assignments.map(toAssignment),
      ...(body.restricted !== undefined ? { restricted: body.restricted } : {}),
    };
  },

  /** Grant (or replace) — one role per subject per scope. */
  async putAssignment(
    workspace: string,
    input: AccessAssignmentInput,
  ): Promise<AccessAssignmentRow> {
    const row = await authedJson<AccessAssignmentWire>(
      withV1Query(`${BASE}/role_assignments`, { workspace }),
      {
        method: "POST",
        body: JSON.stringify({
          subject_kind: input.subjectKind,
          subject_id: input.subjectId,
          ...(input.feature !== undefined ? { feature: input.feature } : {}),
          ...(input.itemId !== undefined ? { item_id: input.itemId } : {}),
          role_id: input.roleId,
        }),
      },
    );
    return toAssignment(row);
  },

  async deleteAssignment(workspace: string, id: string): Promise<void> {
    await authedRequest(withV1Query(`${BASE}/role_assignments/${enc(id)}`, { workspace }), {
      method: "DELETE",
    });
  },

  async restrictItem(workspace: string, feature: string, itemId: string): Promise<void> {
    await authedJson(withV1Query(`${BASE}/items/restrict`, { workspace }), {
      method: "POST",
      body: JSON.stringify({ feature, item_id: itemId }),
    });
  },

  async restoreItem(workspace: string, feature: string, itemId: string): Promise<void> {
    await authedJson(withV1Query(`${BASE}/items/restore`, { workspace }), {
      method: "POST",
      body: JSON.stringify({ feature, item_id: itemId }),
    });
  },

  /** The effective-permission explainer for one subject (requires M at the scope). */
  async effective(
    workspace: string,
    q: { feature: string; subjectKind: "customer" | "persona"; subjectId: string; itemId?: string },
  ): Promise<EffectiveAccessRow> {
    const w = await authedJson<EffectiveAccessWire>(
      withV1Query(`${BASE}/effective_permissions`, {
        workspace,
        feature: q.feature,
        subject_kind: q.subjectKind,
        subject_id: q.subjectId,
        item_id: q.itemId || undefined,
      }),
    );
    return {
      itemVerbs: w.item_verbs,
      subitemVerbs: w.subitem_verbs,
      restricted: w.restricted,
      decidedBy: w.decided_by,
    };
  },
};

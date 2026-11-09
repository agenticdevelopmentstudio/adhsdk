// Project artifacts — the things a project HOLDS, as opposed to the work it tracks.
//
// A project points at content elsewhere in the platform through a polymorphic (kind, id) pair,
// tagged with a DIRECTION: what it INGESTED (the material it works from) and what it PRODUCED
// (the material it made). The pair is deliberately opaque here — this client never learns that
// "content.markdown" means one route and "content.urls" another. The backend's target registry
// owns that mapping and hands back a resolved {@link TargetDescriptor} on every read, which is
// what lets a list render a kind this bundle has never heard of.
//
// That is also why there is no `kinds()` call and no hard-coded kind list: `attachable()` is
// how a picker discovers what a project can hold, so adding a kind is a backend change that a
// deployed client picks up on its next request.

import { authedRequest, withV1Query } from "../http";
import { enc } from "../client-helpers";
import { v1Json, v1List, v1Write } from "../v1-case";
import type {
  ProjectArtifactRow,
  ProjectArtifactLinkBody,
  TargetDescriptorRow,
} from "./wire";

const BASE = "/api/v1/projects";

/** Which side of the project's work a target sits on. */
export type ArtifactDirection = "ingested" | "produced";

/**
 * A resolved pointer — enough to render a row without knowing what kind of thing it is.
 * Uniform across every kind by design (see {@link TargetDescriptorRow}).
 */
export interface TargetDescriptor {
  kind: string;
  id: string;
  title: string;
  subtitle: string | null;
  /** Set only for a target that lives OUTSIDE the platform (a saved URL) — so a renderer can
   *  tell "open this address" from "navigate to this record" without a kind lookup. */
  url: string | null;
}

export function toTargetDescriptor(r: TargetDescriptorRow): TargetDescriptor {
  return {
    kind: r.kind,
    id: r.id,
    title: r.title,
    subtitle: r.subtitle ?? null,
    url: r.url ?? null,
  };
}

export interface ProjectArtifact {
  /** The LINK's id — what a detach addresses. Not the target's id: the same target can be
   *  linked twice (once ingested, once produced), so the target id does not identify a row. */
  id: string;
  projectId: string;
  direction: ArtifactDirection;
  targetKind: string;
  targetId: string;
  /** Null when the pointer no longer resolves — the target was deleted or is out of reach, and
   *  nothing rewrites links. A renderer should say so rather than drop the row: the link is
   *  still a fact about the project. */
  target: TargetDescriptor | null;
  createdAt: string;
}

export function toProjectArtifact(r: ProjectArtifactRow): ProjectArtifact {
  return {
    id: r.id,
    projectId: r.projectId,
    direction: r.direction,
    targetKind: r.targetKind,
    targetId: r.targetId,
    target: r.target ? toTargetDescriptor(r.target) : null,
    createdAt: r.createdAt,
  };
}

export const projectArtifactsApi = {
  /** The project's links, newest first (server order). `direction` narrows to one side. */
  async list(
    projectId: string,
    opts?: { direction?: ArtifactDirection },
  ): Promise<ProjectArtifact[]> {
    const rows = await v1List<ProjectArtifactRow>(
      withV1Query(`${BASE}/${enc(projectId)}/artifacts`, { direction: opts?.direction }),
    );
    return rows.map(toProjectArtifact);
  },

  /**
   * What this project COULD hold — the candidate list a picker reads.
   *
   * Scoped to the project's owner by the same rule the link write checks, so every row here is
   * one {@link link} will accept. `limit` is per KIND, not per response, so no one kind can
   * crowd the others out of the picker.
   */
  async attachable(
    projectId: string,
    opts?: { kind?: string; query?: string; limit?: number },
  ): Promise<TargetDescriptor[]> {
    // `attachable` is an `include[]` of the project itself. `kind` and `q` are not declared on
    // that attachment, so they ride as query parameters the gateway forwards; `limit` belongs to
    // the project read (not the attachment), so it is applied here.
    const project = await v1Json<{ attachable: { items: TargetDescriptorRow[] } | TargetDescriptorRow[] }>(
      withV1Query(`${BASE}/${enc(projectId)}`, {
        "include[]": "attachable",
        kind: opts?.kind || undefined,
        q: opts?.query || undefined,
      }),
    );
    const all = Array.isArray(project.attachable) ? project.attachable : project.attachable.items;
    const items = opts?.limit === undefined ? all : all.slice(0, opts.limit);
    return items.map(toTargetDescriptor);
  },

  /** Link a target. Idempotent per (direction, kind, id) — re-linking returns the existing row
   *  rather than a duplicate, so a double-click cannot litter the list. */
  async link(
    projectId: string,
    input: { direction: ArtifactDirection; targetKind: string; targetId: string },
  ): Promise<ProjectArtifact> {
    const body: ProjectArtifactLinkBody = input;
    return toProjectArtifact(
      await v1Json<ProjectArtifactRow>(`${BASE}/${enc(projectId)}/artifacts`, v1Write("POST", body)),
    );
  },

  /** Un-link by the LINK's id (see {@link ProjectArtifact.id}). The target itself is untouched
   *  — this removes the project's claim on it, never the thing. */
  unlink(projectId: string, artifactId: string): Promise<void> {
    return authedRequest(`${BASE}/${enc(projectId)}/artifacts/${enc(artifactId)}`, {
      method: "DELETE",
    });
  },
};

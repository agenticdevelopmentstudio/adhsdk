// Project programs API client — the roll-up side of the `/api/v1/*` surface.
//
// Its own file and its own route stem, for the reason `iterations.ts` has one: a program does
// not belong to a project. It sits ABOVE several boards and belongs to the WORKSPACE, which is
// what makes rolling them up meaningful — so there is no `/projects/{id}/programs` to call, the
// list is pinned with `?workspace=` exactly as the projects list is, and everything else hangs
// off `/project/programs/{id}`.
//
// `remove` answers with a COUNT rather than the boards it touched, the same disclosure rule the
// iteration sweeps follow: it un-assigns every member board under a workspace-level verb, and
// returning them would report projects the caller may not be allowed to read. `projects()` is
// the opposite — it READS content, so it is reach-filtered.

import { authedRequest, withV1Query } from "../http";
import { compact, enc } from "../client-helpers";
import { v1Json, v1List, v1Write } from "../v1-case";
import { toProject, type Project } from "./projects";
import type {
  ProgramRow,
  ProgramCreateBody,
  ProgramPatchBody,
  ProjectRow,
} from "./wire";

const BASE = "/api/v1/programs";

/** `url` with the optional `?workspace=` pin. */
const scoped = (url: string, opts?: { workspace?: string }): string =>
  withV1Query(url, { workspace: opts?.workspace || undefined });

/* ── Program ──────────────────────────────────────────────────────────── */

export interface Program {
  id: string;
  name: string;
  description: string;
  /** hex accent, same convention as a project's. */
  color: string;
  /** the workspace that owns it. A board may only join a program whose owner matches its own,
   *  which is what keeps a program from spanning two workspaces. */
  ownerKind: string;
  ownerId: string;
  /** the two ends (YYYY-MM-DD), each null when unset and independent of the other: a standing
   *  program ("Platform") has neither, and a delivery program usually knows its target first. */
  startDate: string | null;
  targetDate: string | null;
  ecosystemId: string;
  createdAt: string;
  updatedAt: string;
}

export function toProgram(r: ProgramRow): Program {
  return {
    id: r.id,
    name: r.name,
    description: r.description,
    color: r.color,
    ownerKind: r.ownerKind,
    ownerId: r.ownerId,
    startDate: r.startDate ?? null,
    targetDate: r.targetDate ?? null,
    ecosystemId: r.ecosystemId,
    createdAt: r.createdAt,
    updatedAt: r.updatedAt,
  };
}

/* ── Client ───────────────────────────────────────────────────────────── */

export const projectProgramsApi = {
  /** The workspace's programs, in the server's order (by case-folded name). `workspace` pins the
   *  list to that workspace's owning principal, exactly as `projectsApi.list` does; without it
   *  the caller sees every program their reach admits. */
  async list(opts?: { workspace?: string }): Promise<Program[]> {
    const rows = await v1List<ProgramRow>(scoped(BASE, opts));
    return rows.map(toProgram);
  },

  async get(id: string): Promise<Program | null> {
    try {
      return toProgram(await v1Json<ProgramRow>(`${BASE}/${enc(id)}`));
    } catch {
      // Backend 404s with a thrown error; the UI contract is null-for-missing.
      return null;
    }
  },

  /** Create a program in a workspace. Both dates are optional and independent; a `targetDate`
   *  before a `startDate` is a 400, and a name already used by a live program in the same
   *  workspace is a 409. */
  async create(
    input: {
      name: string;
      description?: string;
      color?: string;
      startDate?: string | null;
      targetDate?: string | null;
    },
    opts?: { workspace?: string },
  ): Promise<Program> {
    const body: ProgramCreateBody = {
      name: input.name,
      ...compact({
        description: input.description,
        color: input.color,
        startDate: input.startDate,
        targetDate: input.targetDate,
      }),
    };
    return toProgram(
      await v1Json<ProgramRow>(scoped(BASE, opts), v1Write("POST", body)),
    );
  },

  /** Rename a program, re-colour it, or move either end. Sending ONE date is the ordinary edit:
   *  the server validates the pair the program will END UP as, not the pair that was sent.
   *  `compact` keeps an explicit null, which is how an end is CLEARED. */
  async update(id: string, patch: ProgramPatchBody): Promise<Program> {
    const body: ProgramPatchBody = compact(patch);
    return toProgram(
      await v1Json<ProgramRow>(`${BASE}/${enc(id)}`, v1Write("POST", body)),
    );
  },

  /**
   * Delete a program, UN-ASSIGNING every board in it. The legacy route counted those boards;
   * /v1 answers a delete with a tombstone, so the count is no longer reported. It never refuses, for the same reason deleting an iteration doesn't: "in no program"
   * is an ordinary state a project is allowed to be in, so the sweep always has a defined
   * outcome. Refetch the affected boards to see the result.
   */
  async remove(id: string): Promise<{ unassigned?: number }> {
    // /v1 answers a delete with a tombstone; the legacy count of un-assigned boards is not
    // carried, so `unassigned` is absent rather than a guessed 0.
    await authedRequest(`${BASE}/${enc(id)}`, { method: "DELETE" });
    return {};
  },

  /**
   * The boards rolled up into this program — each with its OWN health, deliberately not folded
   * into one verdict. Three at-risk boards and one off-track board have no honest single
   * colour, so the API reports the list and leaves any summarising to whoever knows what the
   * summary is for.
   *
   * Unlike {@link remove}, this reads content and is therefore reach-filtered: a board the
   * caller cannot open does not appear here just because they can see the program.
   */
  async projects(id: string): Promise<Project[]> {
    const rows = await v1List<ProjectRow>(withV1Query("/api/v1/projects", { program: id }));
    return rows.map(toProject);
  },
};

// Identifiers API client — rename + availability for reverse-domain ids (rdids).
//
// An rdid lives in `registry.identifiers`, which maps the *mutable* rdid string to
// the *immutable* UUID primary key of the entity it names. Renaming an rdid is a
// POST on this route (NOT the entity's own update — the entity `id` is server-managed
// and can't be re-keyed there); the UUID and every UUID foreign-key reference are
// left untouched. The route is generic across entity types (ecosystem, application,
// persona, namespace, organization).
//
// Route: /api/v1/identifiers/{rdid} (POST rename; GET doubles as the availability probe —
//        a 404 means the rdid is free)

import { authedJson, isNotFound, rethrowConflict } from "../http";
import { enc } from "../client-helpers";
import type { IdentifierRenameBody } from "./wire";

const BASE = "/api/v1/identifiers";

export const identifiersApi = {
  /**
   * Probe whether an rdid is already taken — the live availability check behind
   * create-form indicators. `GET /v1/identifiers/{rdid}` has no `exists` form, so a 404
   * is the "free" answer and any other failure still throws. `registry.identifiers.rdid`
   * is the table PK, so this IS the system-wide uniqueness authority (the same key a
   * create 409s on).
   */
  async exists(rdid: string): Promise<boolean> {
    try {
      await authedJson<unknown>(`${BASE}/${enc(rdid)}`);
      return true;
    } catch (err) {
      if (isNotFound(err)) return false;
      throw err;
    }
  },

  /**
   * Rename an rdid in place. The entity/UUID stays put — only the rdid string
   * changes. Surfaces a 409 (rdid already taken) as a friendly, named error.
   */
  async rename(currentRdid: string, nextRdid: string): Promise<void> {
    const body: IdentifierRenameBody = {
      rdid: nextRdid,
    };
    try {
      await authedJson<unknown>(
        `${BASE}/${enc(currentRdid)}`,
        { method: "POST", body: JSON.stringify(body) },
      );
    } catch (err) {
      rethrowConflict(err, `The identifier "${nextRdid}" is already in use.`);
    }
  },
};

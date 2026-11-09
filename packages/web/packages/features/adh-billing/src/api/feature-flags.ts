import { authedJson } from "@adh-sdk/auth/client";

/** The per-ecosystem feature-flag router — a DIFFERENT backend router from billing's, hence a
 *  different module. See src/api/billing.ts:4-14 on why every path carries `/api`. */
const BASE = "/api/v1/feature_flags";

/** Whether a thrown error carries an HTTP status. `authedJson` throws `AuthHttpError`, which does
 *  (auth/src/client.ts:47); a transport or parse failure does not, and must not be mistaken for
 *  a 404 that would send us on to create a row. */
function statusOf(err: unknown): number | null {
  return typeof err === "object" && err !== null && "status" in err &&
    typeof (err as { status: unknown }).status === "number"
    ? (err as { status: number }).status
    : null;
}

/**
 * Set one ecosystem feature flag — update, and on 404 create.
 *
 * The two-step is not defensive coding; it is the only way to say "turn this on" through routes
 * that are deliberately SPLIT. `POST /v1/feature_flags/{key}` is update-only and 404s when the key
 * has never existed, which is the ordinary state of every ecosystem that has never sold anything —
 * precisely the state an operator flipping this switch is in. `POST /v1/feature_flags` is
 * create-only and 409s on an existing key, so it cannot be used alone either. The split exists
 * so a "New flag" whose key already exists is a visible 409 rather than a silent overwrite; the
 * cost of that guarantee is this sequence, paid once, here.
 *
 * `ecosystem` takes the ecosystem's rdid OR its raw uuid — never a slug. The caller passes
 * `context.ecosystemId`, which is a uuid, as-is. It rides in the body: without it the route is
 * the site-wide table.
 *
 * Any status other than 404 rethrows. A 403 means this caller may not manage the ecosystem, and
 * answering it by creating a row would be trying the same refusal a second way.
 */
export async function setEcosystemFlag(
  ecosystemId: string,
  key: string,
  enabled: boolean,
  description?: string,
): Promise<void> {
  const json = { "content-type": "application/json" };
  try {
    await authedJson<unknown>(`${BASE}/${encodeURIComponent(key)}`, {
      method: "POST",
      body: JSON.stringify({ ecosystem: ecosystemId, enabled }),
      headers: json,
    });
    return;
  } catch (err) {
    if (statusOf(err) !== 404) throw err;
  }
  await authedJson<unknown>(BASE, {
    method: "POST",
    body: JSON.stringify(
      description === undefined
        ? { ecosystem: ecosystemId, key, enabled }
        : { ecosystem: ecosystemId, key, enabled, description },
    ),
    headers: json,
  });
}

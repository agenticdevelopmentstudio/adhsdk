// Self-serve account API — moved from adh's hub
// (frontend/src/sites/hub/src/api/account.ts). Per-category notification
// preferences (/v1/notification_preferences) and contact-method management with
// verification (/v1/account/contacts). Backs the Notifications workspace and the
// Profile/Contact-info panels.
//
// Request/response shapes below are TRANSCRIBED from the backend rather than
// imported from `@adh-sdk/adh-api-types`, unlike hub's original (which typed
// them as `SuccessBody<'/v1/notification_preferences', 'get'>` etc). That package's
// name starts with `@adh-sdk/adh`, which `tools/check_boundaries.py`'s
// `_is_vocabulary` check classifies as the adh VOCABULARY tier — this package is
// MECHANISM tier (see package.json's `comment:tier`) and may never import it. See
// `./auth.ts`'s header for the fuller rationale and the guard evidence.
//
// Fields copied verbatim from `packages/adh-api-types/src/schema.ts` as of this
// move: `components.schemas.NotificationPreference`, the `/v1/notification_preferences`
// POST request body, and `components.schemas.ContactMethod`. Unlike the generated
// SuccessBody/RequestBody helpers, these do NOT auto-track a backend schema change.
import { authedJson, authedRequest, listAllV1, unixToIso } from "@adh-sdk/auth/client";

/** The notification categories the backend recognizes (schema.ts `NotificationPreference.category`). */
type NotificationCategory =
  | "account"
  | "community_reply"
  | "community_mention"
  | "admin_announcement"
  | "direct_message"
  | "project_assigned"
  | "project_mention"
  | "project_comment"
  | "project_status"
  | "project_due";

export interface NotificationPref {
  category: NotificationCategory;
  email: boolean;
  sms: boolean;
  inApp: boolean;
}

// What a SAVE carries, taken from the request body rather than reused from the response. The two
// differ in wire casing today, which is exactly why naming them separately is worth a line:
// the PUT is a whole-row replace, so the day the server starts maintaining a field it will not
// accept back — or accepts one it never returns — the two shapes part company, and a caller typed
// on the response would go on compiling while sending the wrong body.
export interface NotificationPrefInput {
  category: NotificationCategory;
  email: boolean;
  sms: boolean;
  /** In-app (inbox) delivery for this category. Omitted means true — the PUT replaces the row wholesale, so a client that edits only email/sms must send back the value it read. */
  inApp?: boolean;
}

export interface ContactMethod {
  id: string;
  type: "email" | "phone";
  value: string;
  verified: boolean;
  isPrimary: boolean;
  createdAt?: string;
}

export interface AddContactBody {
  type: "email" | "phone";
  value: string;
}

interface V1NotificationPref {
  category: NotificationCategory;
  email: boolean;
  sms: boolean;
  in_app: boolean;
}

interface V1Contact {
  id: string;
  type: "email" | "phone";
  value: string;
  verified: boolean;
  is_primary: boolean;
  created?: number;
}

function prefFromV1(p: V1NotificationPref): NotificationPref {
  return { category: p.category, email: p.email, sms: p.sms, inApp: p.in_app };
}

export async function listPreferences(): Promise<NotificationPref[]> {
  // Rows are keyed by category, not id; the whole set is a handful of rows so one page holds it.
  const rows = await listAllV1<V1NotificationPref>("/api/v1/notification_preferences", {}, {
    cursorOf: (row) => (row as V1NotificationPref).category,
  });
  return rows.map(prefFromV1);
}

export async function savePreferences(
  preferences: NotificationPrefInput[],
): Promise<NotificationPref[]> {
  const res = await authedJson<{ preferences: V1NotificationPref[] }>(
    "/api/v1/notification_preferences",
    {
      method: "POST",
      body: JSON.stringify({
        preferences: preferences.map((p) => ({
          category: p.category,
          email: p.email,
          sms: p.sms,
          ...(p.inApp === undefined ? {} : { in_app: p.inApp }),
        })),
      }),
    },
  );
  return res.preferences.map(prefFromV1);
}

export async function listContacts(): Promise<ContactMethod[]> {
  const rows = await listAllV1<V1Contact>("/api/v1/account/contacts");
  return rows.map((c) => ({
    id: c.id,
    type: c.type,
    value: c.value,
    verified: c.verified,
    isPrimary: c.is_primary,
    ...(c.created === undefined ? {} : { createdAt: unixToIso(c.created) }),
  }));
}

export async function addContact(body: AddContactBody): Promise<void> {
  await authedJson("/api/v1/account/contacts", { method: "POST", body: JSON.stringify(body) });
}

export async function deleteContact(id: string): Promise<void> {
  await authedRequest(`/api/v1/account/contacts/${encodeURIComponent(id)}`, { method: "DELETE" });
}

export async function startContactVerification(id: string): Promise<void> {
  await authedJson(`/api/v1/account/contacts/${encodeURIComponent(id)}/start_verification`, {
    method: "POST",
  });
}

export async function confirmContactVerification(id: string, code: string): Promise<void> {
  await authedJson(`/api/v1/account/contacts/${encodeURIComponent(id)}/verify`, {
    method: "POST",
    body: JSON.stringify({ code }),
  });
}

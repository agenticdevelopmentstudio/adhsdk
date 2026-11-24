// Pure endpoint-path builders for the invitation resources, over the /v1 API. Each
// consumer picks the surface it is authorized for (platform-admin vs. ecosystem-owner)
// and feeds the resulting paths to its own react-query hooks. No fetching here, just paths.
//
// The two surfaces are one set of /v1 routes. An ecosystem owner scopes a call with the
// `ecosystem` parameter (an rdid or uuid), not with a path prefix: a query parameter on a
// read or a delete, a body field on a write. Collections answer `{object:'list', data, ...}`
// (read them with `listAllV1`), updates are POST, and every query parameter is snake_case.

export interface InvitationEndpoints {
  /** The ecosystem rdid scoping this surface, or null for the platform-admin surface. */
  ecosystem: string | null;
  /** GET: the collection. */
  requests: string;
  /** DELETE: one row. */
  requestItem: (id: string) => string;
  pendingUsers: string;
  /** POST: add pending users. Scope through `withEcosystem`, not the URL. */
  pendingUsersCreate: string;
  pendingUserItem: (id: string) => string;
  invitations: string;
  /** POST: send invitations. Scope through `withEcosystem`, not the URL. */
  invitationsSend: string;
  invitationItem: (id: string) => string;
  /** GET: the notes on one subject. */
  adminNotes: (subjectTable: string, subjectId: string) => string;
  /** POST: reconcile the notes on one subject. Scope through `withEcosystem`, not the URL. */
  adminNotesPut: string;
  entityHistory: (subjectTable: string, subjectId: string) => string;
  /** Add the `ecosystem` field to a POST body when this surface is ecosystem-scoped. */
  withEcosystem: <T extends object>(body: T) => T & { ecosystem?: string };
}
const enc = encodeURIComponent;

function surface(ecosystem: string | null): InvitationEndpoints {
  const scope = ecosystem === null ? '' : `ecosystem=${enc(ecosystem)}`;
  const q = (...pairs: string[]): string => {
    const all = [...pairs, scope].filter(Boolean);
    return all.length === 0 ? '' : `?${all.join('&')}`;
  };
  const subject = (t: string, i: string): string => q(`subject_table=${enc(t)}`, `subject_id=${enc(i)}`);
  return {
    ecosystem,
    requests: `/api/v1/invitation_requests${q()}`,
    requestItem: (id) => `/api/v1/invitation_requests/${enc(id)}${q()}`,
    pendingUsers: `/api/v1/pending_users${q()}`,
    pendingUsersCreate: '/api/v1/pending_users',
    pendingUserItem: (id) => `/api/v1/pending_users/${enc(id)}${q()}`,
    invitations: `/api/v1/invitations${q()}`,
    invitationsSend: '/api/v1/invitations',
    invitationItem: (id) => `/api/v1/invitations/${enc(id)}${q()}`,
    adminNotes: (t, i) => `/api/v1/admin_notes${subject(t, i)}`,
    adminNotesPut: '/api/v1/admin_notes',
    entityHistory: (t, i) => `/api/v1/entity_history${subject(t, i)}`,
    withEcosystem: (body) => (ecosystem === null ? body : { ...body, ecosystem }),
  };
}

/** Platform-admin surface: the /v1 invitation, note and history routes, unscoped. */
export function adminInvitationEndpoints(): InvitationEndpoints {
  return surface(null);
}

/** Ecosystem-owner surface: the same routes, scoped to one ecosystem by `ecosystem`. */
export function ecosystemInvitationEndpoints(ecosystemRdid: string): InvitationEndpoints {
  return surface(ecosystemRdid);
}

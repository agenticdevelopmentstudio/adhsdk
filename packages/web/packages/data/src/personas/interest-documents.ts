// The bucket ROWS plane for an interest's research corpus.
//
// Routes: /api/v1/data/{typeId}?bucket= (list/create),
//         /api/v1/data/{typeId}/{rowId} (post/delete).
//
// Unlike every other client here this one names an ACT-AS principal: the rows plane authorizes
// through the bucket ACL, and the holder of the grant on an interest bucket is the PERSONA, not
// the user. So the author fills the corpus by acting as their own persona (`as_type=persona`), and
// the backend checks that the persona is theirs. A call without as_type/as_id is a 400.
import { authedJson, authedRequest, listAllV1, withV1Query } from "../http";
import { enc } from "../client-helpers";

/** A `content.markdown` row as the rows plane returns it — the WHOLE row.
 *
 *  The route selects untyped (`tx.select().from(target.table)` in routes/bucketsData.ts) and
 *  JSON-encodes whatever Drizzle hands back, so every column of `markdownInContent`
 *  (backend/src/adh/src/db/schema/content.ts) is on the wire, not just the handful this feature
 *  reads. Declaring the real shape rather than a convenient subset is deliberate: the previous
 *  five-field version is what made a hand-written array fixture look like the wire and hid the
 *  envelope bug below. The UI uses `id`, `title` and `content`; the rest are declared so a caller
 *  reaching for one gets the truth about its type (and its nullability) from here. */
export interface InterestDocumentRow {
  id: string;
  /** The CREATOR/author stamp — the rows plane stamps it to the calling principal. */
  authorKind: string | null;
  authorId: string | null;
  deletedAt: string | null;
  ecosystemId: string;
  /** The workspace principal the doc belongs to: `customer` or `organization`. */
  ownerKind: string;
  ownerId: string;
  title: string;
  /** Raw markdown, byte-exact. This is what the persona searches. */
  content: string;
  frontmatter: Record<string, unknown> | null;
  visibility: "private" | "public";
  stage: "draft" | "final";
  publicRoute: string | null;
  contentHash: string;
  sizeBytes: number;
  currentVersion: number;
  latestVersionId: string | null;
  createdAt: string;
  updatedAt: string;
  isDeleted: boolean;
  syncVersion: number;
  syncStampedAt: string | null;
  syncTxid: number;
}

export interface InterestDocumentBody {
  title: string;
  content: string;
}

/** `as_type=persona&as_id=<persona rdid or uuid>` — the act-as principal every call on this plane
 *  needs. Either form works: `loadTarget` (routes/bucketsData.ts) resolves an rdid through
 *  `assertActAsOwned` and returns the act-as principal carrying the RESOLVED uuid, which is what
 *  the grant check then matches against `access.group_members.member_id` — the persona uuid
 *  `ensurePersonaReader` stamped into the access group. Pass the rdid: it is what
 *  `GET /v1/personas` returns, and no API surface exposes the uuid at all. */
function actingAs(url: string, personaId: string): string {
  return withV1Query(url, { as_type: "persona", as_id: personaId });
}

/** `/v1/data/{type}` — the typeId is the path's `type`; the bucket travels as the `bucket`
 *  query param on a read/delete and as a `bucket` body field on a write. */
function base(typeId: string): string {
  return `/api/v1/data/${enc(typeId)}`;
}

export const interestDocumentsApi = {
  /** Every document in this interest's corpus, oldest id first.
   *
   *  The collection answers the /v1 list envelope (`{ object: 'list', data, has_more }`), paged
   *  by `starting_after`, and `listAllV1` walks it to the end — an interest holding more than one
   *  page of documents is read whole. Rows are an open bag on the wire (the data plane returns the
   *  table's own columns), so their keys keep the names `InterestDocumentRow` declares. Create and
   *  update answer a bare row. */
  list: (bucketId: string, typeId: string, personaId: string): Promise<InterestDocumentRow[]> =>
    listAllV1<InterestDocumentRow>(
      actingAs(withV1Query(base(typeId), { bucket: bucketId }), personaId),
    ),
  create: (bucketId: string, typeId: string, personaId: string, body: InterestDocumentBody) =>
    authedJson<InterestDocumentRow>(actingAs(base(typeId), personaId), {
      method: "POST",
      body: JSON.stringify({ bucket: bucketId, title: body.title, content: body.content }),
    }),
  update: (
    bucketId: string,
    typeId: string,
    personaId: string,
    rowId: string,
    body: Partial<InterestDocumentBody>,
  ) =>
    authedJson<InterestDocumentRow>(actingAs(`${base(typeId)}/${enc(rowId)}`, personaId), {
      method: "POST",
      body: JSON.stringify({ bucket: bucketId, title: body.title, content: body.content }),
    }),
  delete: (bucketId: string, typeId: string, personaId: string, rowId: string) =>
    authedRequest(
      actingAs(withV1Query(`${base(typeId)}/${enc(rowId)}`, { bucket: bucketId }), personaId),
      { method: "DELETE" },
    ),
};

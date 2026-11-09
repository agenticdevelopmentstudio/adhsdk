// Bucket access-list API client — wired to the real backend access-group routes
// (websites/backend/src/routes/bucketGroups.ts). An access list = a named group
// of principals (members) plus CRUD grants per target. Groups are bucket-scoped.
//
//   GET/POST   /api/v1/bucket_access_groups[?bucket=]         list / create (`bucket` in the body)
//   GET/POST/DELETE /api/v1/bucket_access_groups/{groupId}    detail / rename / delete
//   POST/DELETE      .../{groupId}/members[/{memberRowId}]    add / remove a member
//   POST/DELETE      .../{groupId}/grants[/{grantId}]         upsert / remove a grant
//
// The seeded "everyone" group is undeletable (delete → 409); the backend also
// enforces grant-target validity and the bucket ≥ type ≥ row ceiling.

import { authedJson, authedRequest, listAllV1, rethrowConflict, unixToIso } from "../http";
import { enc } from "../client-helpers";
import type {
  AccessGrantPutBody,
  AccessGrantRow,
  AccessGrantWire,
  AccessGroupCreateBody,
  AccessGroupDetailRow,
  AccessGroupDetailWire,
  AccessGroupMemberAddBody,
  AccessGroupMemberRow,
  AccessGroupMemberWire,
  AccessGroupPatchBody,
  AccessGroupRow,
  AccessGroupWire,
  GrantTargetType,
  MemberType,
} from "./wire";

export type AccessGroup = AccessGroupRow;
export type AccessGroupDetail = AccessGroupDetailRow;
export type AccessGroupMember = AccessGroupMemberRow;
export type AccessGrant = AccessGrantRow;
export type { GrantTargetType, MemberType };

const GROUPS = "/api/v1/bucket_access_groups";

const toGroup = (w: AccessGroupWire): AccessGroup => ({
  id: w.id,
  ecosystemId: w.ecosystem_id,
  bucketId: w.bucket_id,
  name: w.name,
  description: w.description,
  kind: w.kind,
  ...(w.metadata !== undefined ? { metadata: w.metadata } : {}),
  createdAt: unixToIso(w.created),
  updatedAt: unixToIso(w.updated),
});

const toMember = (w: AccessGroupMemberWire): AccessGroupMember => ({
  id: w.id,
  ecosystemId: w.ecosystem_id,
  accessGroupId: w.access_group_id,
  memberType: w.member_type,
  memberId: w.member_id,
  createdAt: unixToIso(w.created),
  updatedAt: unixToIso(w.updated),
});

const toGrant = (w: AccessGrantWire): AccessGrant => ({
  id: w.id,
  ecosystemId: w.ecosystem_id,
  accessGroupId: w.access_group_id,
  targetType: w.target_type,
  targetId: w.target_id,
  crud: w.crud,
  ...(w.granted_by !== undefined ? { grantedBy: w.granted_by } : {}),
  createdAt: unixToIso(w.created),
  updatedAt: unixToIso(w.updated),
});

export const bucketAccessApi = {
  // Every access group the caller can see, across buckets — one call for the
  // cross-bucket Access pane (vs a listGroups fan-out per bucket). The caller joins
  // bucket names locally and filters to the ecosystem it's showing.
  async listAllGroups(): Promise<AccessGroup[]> {
    const rows = await listAllV1<AccessGroupWire>(GROUPS);
    return rows.map(toGroup);
  },

  async getGroup(groupId: string): Promise<AccessGroupDetail> {
    const w = await authedJson<AccessGroupDetailWire>(`${GROUPS}/${enc(groupId)}`);
    return { ...toGroup(w), members: w.members.map(toMember), grants: w.grants.map(toGrant) };
  },

  async createGroup(
    bucketId: string,
    input: { name: string; description?: string },
  ): Promise<AccessGroup> {
    const name = input.name.trim();
    const body: AccessGroupCreateBody = {
      name,
      ...(input.description ? { description: input.description } : {}),
    };
    try {
      return toGroup(
        await authedJson<AccessGroupWire>(GROUPS, {
          method: "POST",
          body: JSON.stringify({ ...body, bucket: bucketId }),
        }),
      );
    } catch (err) {
      rethrowConflict(err, `An access list named "${name}" already exists.`);
    }
  },

  async updateGroup(
    groupId: string,
    patch: { name?: string; description?: string },
  ): Promise<AccessGroup> {
    const body: AccessGroupPatchBody = {};
    if (patch.name !== undefined) body.name = patch.name.trim();
    if (patch.description !== undefined) body.description = patch.description;
    try {
      return toGroup(
        await authedJson<AccessGroupWire>(`${GROUPS}/${enc(groupId)}`, {
          method: "POST",
          body: JSON.stringify(body),
        }),
      );
    } catch (err) {
      rethrowConflict(err, `An access list named "${(patch.name ?? "").trim()}" already exists.`);
    }
  },

  async deleteGroup(groupId: string): Promise<void> {
    await authedRequest(`${GROUPS}/${enc(groupId)}`, { method: "DELETE" });
  },

  async addMember(
    groupId: string,
    input: { memberType: MemberType; memberId: string },
  ): Promise<AccessGroupMember> {
    const body: AccessGroupMemberAddBody = {
      memberType: input.memberType,
      memberId: input.memberId,
    };
    try {
      return toMember(
        await authedJson<AccessGroupMemberWire>(`${GROUPS}/${enc(groupId)}/members`, {
          method: "POST",
          body: JSON.stringify({ member_type: body.memberType, member_id: body.memberId }),
        }),
      );
    } catch (err) {
      rethrowConflict(err, "That member is already in this access list.");
    }
  },

  // `memberRowId` is the membership row's id (AccessGroupMember.id), not the
  // principal id — the backend DELETE matches on the row id.
  async removeMember(groupId: string, memberRowId: string): Promise<void> {
    await authedRequest(`${GROUPS}/${enc(groupId)}/members/${enc(memberRowId)}`, {
      method: "DELETE",
    });
  },

  async upsertGrant(
    groupId: string,
    input: { targetType: GrantTargetType; targetId: string; crud: string },
  ): Promise<AccessGrant> {
    const body: AccessGrantPutBody = {
      targetType: input.targetType,
      targetId: input.targetId,
      crud: input.crud,
    };
    return toGrant(
      await authedJson<AccessGrantWire>(`${GROUPS}/${enc(groupId)}/grants`, {
        method: "POST",
        body: JSON.stringify({ target_type: body.targetType, target_id: body.targetId, crud: body.crud }),
      }),
    );
  },

  async deleteGrant(groupId: string, grantId: string): Promise<void> {
    await authedRequest(`${GROUPS}/${enc(groupId)}/grants/${enc(grantId)}`, {
      method: "DELETE",
    });
  },
};

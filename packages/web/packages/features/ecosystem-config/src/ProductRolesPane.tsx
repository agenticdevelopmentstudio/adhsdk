"use client";

import { useCallback, useMemo, useRef, useState, type ReactNode } from "react";
import { Trash2, UserRound } from "lucide-react";

import { useResourceList } from "@adh-sdk/data";
import {
  accessApi,
  accessTargetKey,
  type AccessAssignmentRow,
  type AccessRoleRow,
} from "@adh-sdk/data/access";
import type { TopicLeaf } from "@adh-sdk/resource";
import { TeamPermissionsPane, ecosystemSubjectsDirectory, type AccessSubject } from "@adh-sdk/teams";
import { FieldGroup } from "@adh-sdk/ui/blocks";
import { Button } from "@adh-sdk/ui/components/button";
import { ErrorText } from "@adh-sdk/ui/components/error-text";
import { List, ListItem } from "@adh-sdk/ui/components/list";
import { Select } from "@adh-sdk/ui/components/select";
import type { PaneCaller } from "./pane-caller";

/**
 * An owner-made ECOSYSTEM's product roles (phase 5): the roles its product users hold, what each
 * one grants over the product's own feature areas, and who holds it.
 *
 * The roles editor is the Teams one, mounted on the ecosystem target, so a product's roles and a
 * workspace's are edited by the same code and cannot drift. What a workspace has and a product
 * does not is the per-role holder list, which rides the editor's `roleFooter` seam: the
 * workspace-wide grants of the selected role, a picker of the realm's product users who do not
 * hold it yet, and revoke. Nobody but the realm's product users is ever offered.
 */
export function ProductRolesPane({
  ecosystemId,
  leaf,
  caller = "manager",
}: {
  ecosystemId?: string;
  /** `product_admin` (the product's own admin site, phase 6): the `admin` role's seats are shown
   *  but not revoked here. The backend refuses a product admin any change to an admin seat
   *  (422 `admin_seat_protected`), so offering the button would only ever fail. */
  caller?: PaneCaller;
  /** Unused: the breadcrumb names the pane (kept for the ScopedPane prop shape). */
  title?: ReactNode;
  /** Unused: the roles editor has no help slot (kept for the ScopedPane prop shape). */
  help?: ReactNode;
  leaf?: TopicLeaf;
}) {
  const roleFooter = useCallback(
    (role: AccessRoleRow) =>
      ecosystemId ? (
        <RoleHolders key={role.id} ecosystemId={ecosystemId} role={role} caller={caller} />
      ) : null,
    [ecosystemId, caller],
  );

  if (!ecosystemId) {
    return (
      <div className="min-h-0 flex-1 overflow-y-auto px-6 py-6">
        <p className="text-sm text-apt-text-muted">No product selected.</p>
      </div>
    );
  }

  return (
    <TeamPermissionsPane
      key={ecosystemId}
      target={{ ecosystem: ecosystemId }}
      leaf={leaf}
      roleFooter={roleFooter}
    />
  );
}

/** The product's `admin` system role: the one that opens the product's admin site. */
export const isAdminRole = (role: Pick<AccessRoleRow, "slug" | "isSystem">) =>
  role.isSystem && role.slug === "admin";

/** Who holds one product role: its workspace-wide grants, a grant picker and revoke. Exported for
 *  the package's own test only. */
export function RoleHolders({
  ecosystemId,
  role,
  caller = "manager",
}: {
  ecosystemId: string;
  role: AccessRoleRow;
  caller?: PaneCaller;
}) {
  const seatsProtected = caller === "product_admin" && isAdminRole(role);
  const target = useMemo(() => ({ ecosystem: ecosystemId }), [ecosystemId]);
  const key = accessTargetKey(target);

  const loadAssignments = useCallback(
    () => accessApi.listAssignments(target).then((r) => r.assignments),
    [target],
  );
  const {
    items: assignments,
    reload,
    error: loadError,
  } = useResourceList<AccessAssignmentRow>(`${key}:access-assignments`, loadAssignments);

  // An unreadable directory and an empty one offer the picker the same nothing.
  const loadSubjects = useCallback(
    () => ecosystemSubjectsDirectory(ecosystemId).catch(() => [] as AccessSubject[]),
    [ecosystemId],
  );
  const { items: subjects } = useResourceList<AccessSubject>(`${key}:access-subjects`, loadSubjects);

  const [pick, setPick] = useState("");
  const [busy, setBusy] = useState(false);
  const busyRef = useRef(false);
  const [error, setError] = useState<string | null>(null);

  // Workspace-wide grants of THIS role (item-scoped grants have no meaning on a product).
  const holders = useMemo(
    () =>
      (assignments ?? []).filter(
        (a) => a.roleId === role.id && a.scopeFeature === "" && a.subjectKind === "customer",
      ),
    [assignments, role.id],
  );
  const labels = useMemo(() => new Map((subjects ?? []).map((s) => [s.id, s.label])), [subjects]);
  const available = useMemo(() => {
    const held = new Set(holders.map((a) => a.subjectId));
    return (subjects ?? []).filter((s) => s.kind === "customer" && !held.has(s.id));
  }, [subjects, holders]);

  const run = async (fn: () => Promise<void>) => {
    if (busyRef.current) return;
    busyRef.current = true;
    setBusy(true);
    setError(null);
    try {
      await fn();
      await reload().catch(() => {});
    } catch (e) {
      setError(e instanceof Error ? e.message : "Something went wrong.");
    } finally {
      busyRef.current = false;
      setBusy(false);
    }
  };

  const onGrant = () => {
    const subject = available.find((s) => s.id === pick);
    if (!subject) return;
    void run(async () => {
      await accessApi.putAssignment(target, {
        subjectKind: "customer",
        subjectId: subject.id,
        roleId: role.id,
      });
      setPick("");
    });
  };

  const onRevoke = (a: AccessAssignmentRow) =>
    void run(() => accessApi.deleteAssignment(target, a.id));

  return (
    <FieldGroup title="Who holds it">
      {seatsProtected && (
        <p className="text-sm text-apt-text-muted">
          Admins are added here and removed by the product&apos;s managers.
        </p>
      )}
      {role.defaultFor === "customer" && (
        <p className="text-sm text-apt-text-muted">
          Every product user holds this role. Grant it here only to keep it if the default changes.
        </p>
      )}
      {loadError ? (
        <ErrorText error={`Couldn't load who holds this role: ${loadError}`} />
      ) : assignments === null ? (
        <p className="text-sm text-apt-text-muted">Loading…</p>
      ) : holders.length === 0 ? (
        <p className="text-sm text-apt-text-muted">No product user has been granted this role.</p>
      ) : (
        <List>
          {holders.map((a) => {
            const label = labels.get(a.subjectId) ?? a.subjectId;
            return (
              <ListItem key={a.id} className="flex items-center gap-3">
                <UserRound size={14} aria-hidden className="text-apt-text-muted" />
                <span className="min-w-0 flex-1 truncate font-mono text-sm text-apt-text">{label}</span>
                {!seatsProtected && (
                  <Button
                    size="sm"
                    variant="destructive-ghost"
                    aria-label={`Revoke ${label}`}
                    disabled={busy}
                    onClick={() => onRevoke(a)}
                  >
                    <Trash2 size={14} aria-hidden />
                  </Button>
                )}
              </ListItem>
            );
          })}
        </List>
      )}
      <div className="flex items-center gap-2">
        <Select
          aria-label="Choose a product user"
          value={pick}
          disabled={busy}
          onChange={(e) => setPick(e.target.value)}
          className="w-56"
        >
          <option value="">Choose a product user…</option>
          {available.map((s) => (
            <option key={s.id} value={s.id}>
              {s.label}
            </option>
          ))}
        </Select>
        <Button size="sm" disabled={busy || !pick} onClick={onGrant}>
          Grant
        </Button>
      </div>
      <ErrorText error={error} />
    </FieldGroup>
  );
}

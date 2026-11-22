"use client";

import { useCallback, useMemo, useRef, useState, type FormEvent, type ReactNode } from "react";
import { Check, Clock, Trash2 } from "lucide-react";

import { useResourceList } from "@adh-sdk/data";
import { accessApi, accessTargetKey, type AccessRoleRow } from "@adh-sdk/data/access";
import { signupListApi, type SignupListEntry } from "@adh-sdk/data/ecosystem-config";
import { setsApi, type SetRow } from "@adh-sdk/data/sets";
import { FieldGroup } from "@adh-sdk/ui/blocks";
import { Button } from "@adh-sdk/ui/components/button";
import { ErrorText } from "@adh-sdk/ui/components/error-text";
import { Input } from "@adh-sdk/ui/components/input";
import { List, ListItem } from "@adh-sdk/ui/components/list";
import { Select } from "@adh-sdk/ui/components/select";
import { signupEmailError } from "./client-auth-model";
import type { PaneCaller } from "./pane-caller";

/** The cache key an ecosystem's sign-up list is read under. */
const signupListKey = (ecosystemId: string) => `signup-list:${ecosystemId}`;

/**
 * An ecosystem's SIGN-UP LIST (phase 5): the emails that may sign in, each with the product role
 * and the set it receives the first time that person proves the address in a session. It replaces the
 * allow-list field the client auth settings had: while "Only listed people" is on, this list is the
 * one sign-in checks (the backend keeps the two equal), and while it is off, an entry still grants
 * its role but turns no one away.
 *
 * Adding an email already listed changes its role and set. Removing an entry never takes back what
 * it already granted; a role is revoked in Product roles, a set in Sets. A granted row says when, and to whom it went is
 * the role's holder list.
 */
export function SignupListPane({
  ecosystemId,
  help,
}: {
  ecosystemId?: string;
  /** Unused: the breadcrumb names the pane (kept for the ScopedPane prop shape). */
  title?: ReactNode;
  help?: ReactNode;
  /** Who is editing. Accepted so the product admin site mounts every moved pane the same way;
   *  the list itself is the same for both, as the backend applies one set of rules to it. */
  caller?: PaneCaller;
}) {
  if (!ecosystemId) {
    return (
      <div className="min-h-0 flex-1 overflow-y-auto px-6 py-6">
        <p className="text-sm text-apt-text-muted">No product selected.</p>
      </div>
    );
  }
  return <SignupList key={ecosystemId} ecosystemId={ecosystemId} help={help} />;
}

function SignupList({ ecosystemId, help }: { ecosystemId: string; help?: ReactNode }) {
  const loadEntries = useCallback(() => signupListApi.list(ecosystemId), [ecosystemId]);
  const {
    items: entries,
    reload,
    error: loadError,
  } = useResourceList<SignupListEntry>(signupListKey(ecosystemId), loadEntries);

  // The roles an entry may carry: the product's own. An unreadable role list offers none, and an
  // entry can still be added without a role.
  const target = useMemo(() => ({ ecosystem: ecosystemId }), [ecosystemId]);
  const loadRoles = useCallback(
    () => accessApi.listRoles(target).catch(() => [] as AccessRoleRow[]),
    [target],
  );
  const { items: roles } = useResourceList<AccessRoleRow>(
    `${accessTargetKey(target)}:access-roles`,
    loadRoles,
  );
  const roleNames = useMemo(() => new Map((roles ?? []).map((r) => [r.id, r.name])), [roles]);

  // The sets an entry may grant, read the same way: an unreadable list offers none.
  const loadSets = useCallback(
    () => setsApi.list(ecosystemId).catch(() => [] as SetRow[]),
    [ecosystemId],
  );
  const { items: sets } = useResourceList<SetRow>(`sets:${ecosystemId}`, loadSets);
  const setNames = useMemo(() => new Map((sets ?? []).map((s) => [s.id, s.name])), [sets]);

  const [email, setEmail] = useState("");
  const [roleId, setRoleId] = useState("");
  const [setId, setSetId] = useState("");
  const [busy, setBusy] = useState(false);
  const busyRef = useRef(false);
  const [error, setError] = useState<string | null>(null);

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

  const onAdd = (e: FormEvent) => {
    e.preventDefault();
    const invalid = signupEmailError(email);
    if (invalid) {
      setError(invalid);
      return;
    }
    void run(async () => {
      await signupListApi.put(ecosystemId, {
        email: email.trim(),
        roleId: roleId || null,
        setId: setId || null,
      });
      setEmail("");
      setRoleId("");
      setSetId("");
    });
  };

  const onRemove = (entry: SignupListEntry) => void run(() => signupListApi.remove(ecosystemId, entry.id));

  return (
    <div className="min-h-0 flex-1 overflow-y-auto px-6 py-6">
      <div className="flex flex-col gap-6">
        {help && <p className="text-sm text-apt-text-muted">{help}</p>}
        <FieldGroup title="Add a person">
          {/* noValidate: the pane says what is wrong in its own words, the same ones as the backend. */}
          <form className="flex flex-wrap items-center gap-2" onSubmit={onAdd} noValidate>
            <Input
              aria-label="Email"
              type="email"
              placeholder="name@example.com"
              value={email}
              disabled={busy}
              onChange={(e) => setEmail(e.target.value)}
              className="w-64"
            />
            <Select
              aria-label="Role"
              value={roleId}
              disabled={busy}
              onChange={(e) => setRoleId(e.target.value)}
              className="w-48"
            >
              <option value="">No role</option>
              {(roles ?? []).map((r) => (
                <option key={r.id} value={r.id}>
                  {r.name}
                </option>
              ))}
            </Select>
            <Select
              aria-label="Set"
              value={setId}
              disabled={busy}
              onChange={(e) => setSetId(e.target.value)}
              className="w-48"
            >
              <option value="">No set</option>
              {(sets ?? []).map((s) => (
                <option key={s.id} value={s.id}>
                  {s.name}
                </option>
              ))}
            </Select>
            <Button type="submit" size="sm" disabled={busy || email.trim() === ""}>
              Add
            </Button>
          </form>
          <p className="text-xs text-apt-text-muted">
            The role and set are granted the first time this person proves the address: a provider
            that verifies it, or a code sent to it. Adding an email already listed changes them.
          </p>
          <ErrorText error={error} />
        </FieldGroup>

        <FieldGroup title="People">
          {loadError ? (
            <ErrorText error={`Couldn't load the sign-up list: ${loadError}`} />
          ) : entries === null ? (
            <p className="text-sm text-apt-text-muted">Loading…</p>
          ) : entries.length === 0 ? (
            <p className="text-sm text-apt-text-muted">No one is on the sign-up list.</p>
          ) : (
            <List>
              {entries.map((entry) => (
                <ListItem key={entry.id} className="flex items-center gap-3">
                  <span className="min-w-0 flex-1 truncate font-mono text-sm text-apt-text">
                    {entry.email}
                  </span>
                  <span className="w-32 truncate text-sm text-apt-text-muted">
                    {entry.roleId ? (roleNames.get(entry.roleId) ?? "Unknown role") : "No role"}
                  </span>
                  <span className="w-32 truncate text-sm text-apt-text-muted">
                    {entry.setId ? (setNames.get(entry.setId) ?? "Unknown set") : "No set"}
                  </span>
                  <EntryStatus entry={entry} />
                  <Button
                    size="sm"
                    variant="destructive-ghost"
                    aria-label={`Remove ${entry.email}`}
                    disabled={busy}
                    onClick={() => onRemove(entry)}
                  >
                    <Trash2 size={14} aria-hidden />
                  </Button>
                </ListItem>
              ))}
            </List>
          )}
        </FieldGroup>
      </div>
    </div>
  );
}

/** Granted (with its date) or waiting for the person's first proven sign-in. */
function EntryStatus({ entry }: { entry: SignupListEntry }) {
  if (entry.grantedAt) {
    return (
      <span className="flex w-36 items-center gap-1 text-xs text-apt-text-muted">
        <Check size={12} aria-hidden />
        Granted {new Date(entry.grantedAt).toLocaleDateString()}
      </span>
    );
  }
  return (
    <span className="flex w-36 items-center gap-1 text-xs text-apt-text-dim">
      <Clock size={12} aria-hidden />
      Waiting
    </span>
  );
}

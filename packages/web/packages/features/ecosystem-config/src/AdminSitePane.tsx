"use client";

import { useCallback, useMemo, useState, type FormEvent, type ReactNode } from "react";

import { revalidateResources, useResourceList } from "@adh-sdk/data";
import { accessApi, accessTargetKey, type AccessRoleRow } from "@adh-sdk/data/access";
import { signupListApi } from "@adh-sdk/data/ecosystem-config";
import { useAdminSite, usePutAdminSite, useRemoveAdminSite } from "@adh-sdk/data/product-admin";
import { FieldGroup } from "@adh-sdk/ui/blocks";
import { AlertModal } from "@adh-sdk/ui/components/alert-modal";
import { Button } from "@adh-sdk/ui/components/button";
import { ErrorText } from "@adh-sdk/ui/components/error-text";
import { Input } from "@adh-sdk/ui/components/input";
import { signupEmailError } from "./client-auth-model";
import { ProductTotalsPane } from "./ProductTotalsPane";
import { RoleHolders, isAdminRole } from "./ProductRolesPane";
import { signupListKey } from "./SignupListPane";

const messageOf = (e: unknown) => (e instanceof Error ? e.message : "Something went wrong.");

/**
 * A product's ADMIN SITE at the hub (phase 6), for its managers: the host the product's own admins
 * sign in at (set up, change, remove), who holds the product's `admin` role and a form to add one,
 * the product's totals, and a link to the site's admin console, at `/admin` on that host (the
 * host's root is the product's public page).
 *
 * Adding an admin writes a sign-up list entry carrying the `admin` role: the person gets the role
 * the first time they prove the address, at the site's own sign-in. It is how the first admin is
 * made, and the developer's way back in if every admin has gone. An address already on the list
 * keeps the set its entry grants; only the role changes.
 */
export function AdminSitePane({
  ecosystemId,
  productName,
  help,
}: {
  ecosystemId?: string;
  /** The product's name, for the pane's sentences. */
  productName?: string;
  help?: ReactNode;
}) {
  if (!ecosystemId) {
    return (
      <div className="min-h-0 flex-1 overflow-y-auto px-6 py-6">
        <p className="text-sm text-apt-text-muted">No product selected.</p>
      </div>
    );
  }
  return <AdminSite key={ecosystemId} ecosystemId={ecosystemId} productName={productName} help={help} />;
}

function AdminSite({
  ecosystemId,
  productName,
  help,
}: {
  ecosystemId: string;
  productName?: string;
  help?: ReactNode;
}) {
  const { data: state, error: loadError } = useAdminSite(ecosystemId);
  const site = state?.site ?? null;

  return (
    <div className="min-h-0 flex-1 overflow-y-auto px-6 py-6">
      <div className="flex flex-col gap-6">
        {help && <p className="text-sm text-apt-text-muted">{help}</p>}
        {loadError ? (
          <ErrorText error={`Couldn't load the admin site: ${loadError.message}`} />
        ) : state === undefined ? (
          <p className="text-sm text-apt-text-muted">Loading…</p>
        ) : (
          <SiteHost
            key={site?.host ?? ""}
            ecosystemId={ecosystemId}
            host={site?.host ?? null}
            productName={productName}
          />
        )}
        <ProductAdmins ecosystemId={ecosystemId} />
        <ProductTotalsPane ecosystemId={ecosystemId} />
      </div>
    </div>
  );
}

function SiteHost({
  ecosystemId,
  host,
  productName,
}: {
  ecosystemId: string;
  host: string | null;
  productName?: string;
}) {
  const put = usePutAdminSite(ecosystemId);
  const remove = useRemoveAdminSite(ecosystemId);
  const [draft, setDraft] = useState(host ?? "");
  const [error, setError] = useState<string | null>(null);
  const busy = put.isPending || remove.isPending;
  const trimmed = draft.trim().toLowerCase();

  const onSave = (e: FormEvent) => {
    e.preventDefault();
    if (trimmed === "") return;
    setError(null);
    // A 409 (the host is another product's, or the product already has an admin-site
    // application) carries the backend's sentence, shown as it is.
    put.mutate(trimmed, { onError: (err) => setError(messageOf(err)) });
  };

  // Removing takes the site down at once (its application and login registration go with it), so
  // it asks first, as every other destructive action in these panes does.
  const [confirmingRemove, setConfirmingRemove] = useState(false);
  const onRemove = () => {
    setError(null);
    remove.mutate(undefined, {
      onError: (err) => setError(messageOf(err)),
      onSettled: () => setConfirmingRemove(false),
    });
  };

  const who = productName ?? "this product";
  return (
    <FieldGroup title="Site">
      {host ? (
        <p className="text-sm text-apt-text">
          {`The admins of ${who} sign in at `}
          <a className="font-mono underline" href={`https://${host}/admin`} target="_blank" rel="noreferrer">
            {`https://${host}/admin`}
          </a>
          .
        </p>
      ) : (
        <p className="text-sm text-apt-text-muted">
          {`${productName ?? "This product"} has no admin site yet. Choose the host its admins will sign in at.`}
        </p>
      )}
      <form className="flex flex-wrap items-center gap-2" onSubmit={onSave} noValidate>
        <Input
          aria-label="Host"
          placeholder="admin.example.com"
          value={draft}
          disabled={busy}
          onChange={(e) => setDraft(e.target.value)}
          className="w-72 font-mono"
        />
        <Button type="submit" size="sm" disabled={busy || trimmed === "" || trimmed === host}>
          {host ? "Change" : "Set up"}
        </Button>
        {host && (
          <Button
            type="button"
            size="sm"
            variant="destructive-ghost"
            disabled={busy}
            onClick={() => setConfirmingRemove(true)}
          >
            Remove
          </Button>
        )}
      </form>
      <ErrorText error={error} />
      <AlertModal
        open={confirmingRemove && host !== null}
        destructive
        title="Remove the admin site?"
        description={`The site at ${host ?? ""} goes offline at once, and the admins of ${who} can no longer sign in to it until it is set up again.`}
        confirmLabel="Remove"
        onConfirm={onRemove}
        cancelLabel="Cancel"
        onCancel={() => setConfirmingRemove(false)}
        busy={remove.isPending}
      />
    </FieldGroup>
  );
}

function ProductAdmins({ ecosystemId }: { ecosystemId: string }) {
  const target = useMemo(() => ({ ecosystem: ecosystemId }), [ecosystemId]);
  const loadRoles = useCallback(() => accessApi.listRoles(target), [target]);
  const { items: roles, error: rolesError } = useResourceList<AccessRoleRow>(
    `${accessTargetKey(target)}:access-roles`,
    loadRoles,
  );
  const adminRole = useMemo(() => (roles ?? []).find(isAdminRole) ?? null, [roles]);

  const [email, setEmail] = useState("");
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [added, setAdded] = useState<string | null>(null);

  const onAdd = async (e: FormEvent) => {
    e.preventDefault();
    if (!adminRole || busy) return;
    const invalid = signupEmailError(email);
    if (invalid) {
      setError(invalid);
      return;
    }
    setBusy(true);
    setError(null);
    setAdded(null);
    try {
      const address = email.trim();
      // The entry is keyed on the address and a write replaces its role AND its set, so an
      // address already listed keeps the set it was going to receive: read it first.
      const listed = (await signupListApi.list(ecosystemId)).find(
        (entry) => entry.email === address.toLowerCase(),
      );
      await signupListApi.put(ecosystemId, {
        email: address,
        roleId: adminRole.id,
        setId: listed?.setId ?? null,
      });
      // The Sign-up list pane reads the same list from the cache: have it read again.
      const listKey = signupListKey(ecosystemId);
      revalidateResources((key) => key === listKey);
      setAdded(address);
      setEmail("");
    } catch (err) {
      setError(messageOf(err));
    } finally {
      setBusy(false);
    }
  };

  return (
    <FieldGroup title="Product admins">
      {rolesError ? (
        <ErrorText error={`Couldn't load the product's roles: ${rolesError}`} />
      ) : roles === null ? (
        <p className="text-sm text-apt-text-muted">Loading…</p>
      ) : !adminRole ? (
        <p className="text-sm text-apt-text-muted">This product has no admin role.</p>
      ) : (
        <>
          <RoleHolders ecosystemId={ecosystemId} role={adminRole} />
          {/* noValidate: the pane says what is wrong in its own words, the same ones as the backend. */}
          <form className="flex flex-wrap items-center gap-2" onSubmit={onAdd} noValidate>
            <Input
              aria-label="Admin email"
              type="email"
              placeholder="name@example.com"
              value={email}
              disabled={busy}
              onChange={(e) => setEmail(e.target.value)}
              className="w-64"
            />
            <Button type="submit" size="sm" disabled={busy || email.trim() === ""}>
              Add an admin
            </Button>
          </form>
          <p className="text-xs text-apt-text-muted">
            The person becomes an admin the first time they sign in to the admin site with this address.
          </p>
          {added && <p className="text-sm text-apt-text">{`${added} is on the sign-up list as an admin.`}</p>}
          <ErrorText error={error} />
        </>
      )}
    </FieldGroup>
  );
}

"use client";

import { useCallback, useMemo, useState, type FormEvent, type ReactNode } from "react";
import { TriangleAlert } from "lucide-react";

import { revalidateResources, useResourceList } from "@adh-sdk/data";
import { accessApi, accessTargetKey, type AccessRoleRow } from "@adh-sdk/data/access";
import { signupListApi } from "@adh-sdk/data/ecosystem-config";
import { useProductSite, useUpdateProductSite, type ProductSite } from "@adh-sdk/data/product-sites";
import { FieldGroup } from "@adh-sdk/ui/blocks";
import { Alert, AlertDescription, AlertTitle } from "@adh-sdk/ui/components/alert";
import { AlertModal } from "@adh-sdk/ui/components/alert-modal";
import { Badge } from "@adh-sdk/ui/components/badge";
import { Button } from "@adh-sdk/ui/components/button";
import { CopyButton } from "@adh-sdk/ui/components/copy-button";
import { ErrorText } from "@adh-sdk/ui/components/error-text";
import { Input } from "@adh-sdk/ui/components/input";
import { List, ListItem } from "@adh-sdk/ui/components/list";
import { Switch } from "@adh-sdk/ui/components/switch";
import { SettingRow } from "./ClientAuthFields";
import { signupEmailError } from "./client-auth-model";
import { ProductTotalsPane } from "./ProductTotalsPane";
import { RoleHolders, isAdminRole } from "./ProductRolesPane";
import { signupListKey } from "./SignupListPane";

const messageOf = (e: unknown) => (e instanceof Error ? e.message : "Something went wrong.");

/** How the pane's sentences name the product: "Temporal" / "Temporal's", or "this product". */
interface ProductWords {
  /** Mid-sentence: "Temporal" or "this product". */
  name: string;
  /** Mid-sentence possessive: "Temporal's" or "this product's". */
  its: string;
  /** Sentence-initial possessive: "Temporal's" or "This product's". */
  Its: string;
}

const wordsFor = (productName: string | undefined): ProductWords =>
  productName
    ? { name: productName, its: `${productName}'s`, Its: `${productName}'s` }
    : { name: "this product", its: "this product's", Its: "This product's" };

/**
 * The address a handle gives the product, on the base domain `primaryOrigin` is on:
 * `https://temporal.example.com` with handle `temporal` and `next` = `temporal-app` is
 * `https://temporal-app.example.com`. Null when the backend has no base domain.
 */
function originForHandle(site: Pick<ProductSite, "handle" | "primaryOrigin">, next: string): string | null {
  const suffix = baseDomainSuffix(site);
  if (suffix === null || site.primaryOrigin === null) return null;
  const scheme = site.primaryOrigin.slice(0, site.primaryOrigin.indexOf("//") + 2);
  return `${scheme}${next}${suffix}`;
}

/** `.example.com` for `https://temporal.example.com`: what follows the handle in the host. */
function baseDomainSuffix(site: Pick<ProductSite, "handle" | "primaryOrigin">): string | null {
  if (site.primaryOrigin === null) return null;
  let host: string;
  try {
    host = new URL(site.primaryOrigin).host;
  } catch {
    return null;
  }
  const lead = `${site.handle}.`;
  return host.startsWith(lead) ? host.slice(site.handle.length) : null;
}

/**
 * A product's PRODUCT SITE at the hub (product sites phase 5), for its managers: the address
 * every product is given when it is made (`https://<handle>.<base domain>`), its handle and the
 * rename, the switch for the `/admin` console at that address, who holds the product's `admin`
 * role and a form to add one, and the product's totals. It replaces the Admin site pane, whose
 * host-per-product registration is gone.
 *
 * Adding an admin writes a sign-up list entry carrying the `admin` role: the person gets the role
 * the first time they prove the address, at the console's own sign-in. It is how the first admin
 * is made, and the developer's way back in if every admin has gone. An address already on the
 * list keeps the set its entry grants; only the role changes.
 */
export function ProductSitePane({
  ecosystemId,
  productName,
  help,
}: {
  ecosystemId?: string;
  /** The product's name, for the pane's sentences. */
  productName?: string;
  /** The pane's blurb, shown when there is no product name to write the pane's own. */
  help?: ReactNode;
}) {
  if (!ecosystemId) {
    return (
      <div className="min-h-0 flex-1 overflow-y-auto px-6 py-6">
        <p className="text-sm text-apt-text-muted">No product selected.</p>
      </div>
    );
  }
  return <ProductSiteBody key={ecosystemId} ecosystemId={ecosystemId} productName={productName} help={help} />;
}

function ProductSiteBody({
  ecosystemId,
  productName,
  help,
}: {
  ecosystemId: string;
  productName?: string;
  help?: ReactNode;
}) {
  const { data: site, error: loadError } = useProductSite(ecosystemId);
  const words = wordsFor(productName);
  // The intro names the product when the host knows its name; otherwise the host's blurb, which
  // says the same of "the product".
  const intro = productName
    ? `${words.Its} own address, where its customers sign in and sign up, and where its admins run its users once the admin console is on. The address was made with the product. Here you see it, rename it, turn the console on, and see the product's totals.`
    : help;

  return (
    <div className="min-h-0 flex-1 overflow-y-auto px-6 py-6">
      <div className="flex flex-col gap-6">
        {intro && <p className="text-sm text-apt-text-muted">{intro}</p>}
        {loadError ? (
          <ErrorText error={`Couldn't load the product site: ${loadError.message}`} />
        ) : site === undefined ? (
          <p className="text-sm text-apt-text-muted">Loading…</p>
        ) : (
          <>
            <Address site={site} words={words} />
            {/* Keyed on the handle so a rename's answer starts the field afresh. */}
            <Handle key={site.handle} ecosystemId={ecosystemId} site={site} words={words} />
            <AdminConsole ecosystemId={ecosystemId} site={site} words={words} />
          </>
        )}
        <ProductAdmins ecosystemId={ecosystemId} words={words} />
        <ProductTotalsPane ecosystemId={ecosystemId} />
      </div>
    </div>
  );
}

function Address({ site, words }: { site: ProductSite; words: ProductWords }) {
  const origin = site.primaryOrigin;
  if (origin === null) {
    return (
      <FieldGroup title="Address">
        <p className="text-sm text-apt-text-muted">
          {`The product sites address is not configured on this server, so ${words.name} has no address here yet. Its handle is ${site.handle}.`}
        </p>
      </FieldGroup>
    );
  }
  const links = [
    { label: "Sign-in and sign-up", href: `${origin}/login`, notOn: false },
    { label: "Admin console", href: `${origin}/admin`, notOn: !site.adminEnabled },
  ];
  return (
    <FieldGroup title="Address">
      <p className="text-sm text-apt-text">
        {`${words.Its} address is `}
        <a className="font-mono underline" href={origin} target="_blank" rel="noreferrer">
          {origin}
        </a>
        .
      </p>
      <List>
        {links.map((link) => (
          <ListItem key={link.href}>
            <span className="flex grow items-center gap-2 text-sm text-apt-text">
              {link.label}
              {link.notOn && <Badge>Not turned on</Badge>}
            </span>
            <a className="font-mono text-sm underline" href={link.href} target="_blank" rel="noreferrer">
              {link.href}
            </a>
            <CopyButton label={`Copy the ${link.label.toLowerCase()} address`} getText={() => link.href} />
          </ListItem>
        ))}
      </List>
    </FieldGroup>
  );
}

function Handle({ ecosystemId, site, words }: { ecosystemId: string; site: ProductSite; words: ProductWords }) {
  const update = useUpdateProductSite(ecosystemId);
  const [editing, setEditing] = useState(false);
  const [draft, setDraft] = useState(site.handle);
  const [error, setError] = useState<string | null>(null);
  const [confirming, setConfirming] = useState(false);
  const next = draft.trim().toLowerCase();
  const suffix = baseDomainSuffix(site);
  const oldAddress = site.primaryOrigin ?? site.handle;
  const newAddress = originForHandle(site, next) ?? next;
  const busy = update.isPending;

  const onCancel = () => {
    setEditing(false);
    setDraft(site.handle);
    setError(null);
  };

  // Rename only asks: the confirm dialog is the one that sends.
  const onSubmit = (e: FormEvent) => {
    e.preventDefault();
    if (next === "" || next === site.handle) return;
    setError(null);
    setConfirming(true);
  };

  // A 400 (a malformed or reserved handle) or a 409 (another product's) carries the backend's
  // sentence, shown as it is under the field. The field stays open with the draft, so the manager
  // can try another; a success re-keys this section on the new handle, which closes it.
  const onConfirm = () => {
    update.mutate(
      { handle: next },
      {
        onError: (err) => setError(messageOf(err)),
        onSettled: () => setConfirming(false),
      },
    );
  };

  return (
    <FieldGroup title="Handle">
      <p className="text-sm text-apt-text-muted">
        {`The handle is the first part of ${words.its} address. Rename it only on purpose: the old address stops working.`}
      </p>
      {editing ? (
        <form className="flex flex-wrap items-center gap-2" onSubmit={onSubmit} noValidate>
          <span className="flex items-center gap-1">
            <Input
              aria-label="Handle"
              value={draft}
              disabled={busy}
              aria-invalid={error ? true : undefined}
              onChange={(e) => setDraft(e.target.value)}
              className="w-48 font-mono"
              autoFocus
            />
            {suffix && <span className="font-mono text-sm text-apt-text-muted">{suffix}</span>}
          </span>
          <Button type="submit" size="sm" variant="warning" disabled={busy || next === "" || next === site.handle}>
            Rename
          </Button>
          <Button type="button" size="sm" variant="ghost" disabled={busy} onClick={onCancel}>
            Cancel
          </Button>
        </form>
      ) : (
        <div className="flex flex-wrap items-center gap-2">
          <span className="flex items-center gap-1">
            <Input aria-label="Handle" value={site.handle} disabled readOnly className="w-48 font-mono" />
            {suffix && <span className="font-mono text-sm text-apt-text-muted">{suffix}</span>}
          </span>
          <Button type="button" size="sm" variant="outline" onClick={() => setEditing(true)}>
            Rename
          </Button>
        </div>
      )}
      <ErrorText error={error} />
      {editing && (
        <Alert variant="warning">
          <TriangleAlert aria-hidden />
          <AlertTitle>The old address stops working.</AlertTitle>
          <AlertDescription>
            {"Once you rename, "}
            <span className="font-mono">{oldAddress}</span>
            {" answers “not found” at once. Nothing redirects from it: links, bookmarks, saved sign-in pages and support emails already sent all break. The new address is "}
            <span className="font-mono">{newAddress}</span>.
          </AlertDescription>
        </Alert>
      )}
      <AlertModal
        open={confirming}
        tone="warning"
        title={`Rename ${words.its} address?`}
        description={
          <>
            <span className="font-mono">{oldAddress}</span>
            {` stops working at once, and ${words.name} moves to `}
            <span className="font-mono">{newAddress}</span>
            . Nothing redirects from the old address.
          </>
        }
        confirmLabel="Rename"
        confirmVariant="warning"
        onConfirm={onConfirm}
        cancelLabel="Cancel"
        onCancel={() => setConfirming(false)}
        busy={busy}
      />
    </FieldGroup>
  );
}

function AdminConsole({ ecosystemId, site, words }: { ecosystemId: string; site: ProductSite; words: ProductWords }) {
  const update = useUpdateProductSite(ecosystemId);
  const [error, setError] = useState<string | null>(null);
  const consoleAddress = site.primaryOrigin ? `${site.primaryOrigin}/admin` : "/admin";
  const id = `product-site-admin-console-${ecosystemId}`;

  // A 409 `product_sites_unconfigured` (no base domain on this server) carries its sentence.
  const onChange = (adminEnabled: boolean) => {
    setError(null);
    update.mutate({ adminEnabled }, { onError: (err) => setError(messageOf(err)) });
  };

  // The rail moves the four rows only once the console is LIVE (`consoleLive`), which can trail
  // the switch while its login registration is made, so "on" says which of the two it is.
  const help = !site.adminEnabled ? (
    <>
      {"Off. "}
      <span className="font-mono">/admin</span>
      {` says the admin console is not turned on for ${words.name}, and you run ${words.its} users, roles, sign-up list and sets here in the hub.`}
    </>
  ) : site.consoleLive ? (
    <>
      {`On. ${words.Its} admins run its users, roles, sign-up list and sets at `}
      <span className="font-mono">{consoleAddress}</span>
      {", and those rows have left the hub's rail."}
    </>
  ) : (
    <>
      {`On, and not answering yet at `}
      <span className="font-mono">{consoleAddress}</span>
      {`. Until it does, you run ${words.its} users, roles, sign-up list and sets here in the hub.`}
    </>
  );

  return (
    <FieldGroup title="Admin console">
      <SettingRow id={id} label="Admin console at /admin" help={help}>
        <Switch
          id={id}
          aria-label="Admin console at /admin"
          checked={site.adminEnabled}
          disabled={update.isPending}
          onCheckedChange={onChange}
        />
      </SettingRow>
      <ErrorText error={error} />
    </FieldGroup>
  );
}

function ProductAdmins({ ecosystemId, words }: { ecosystemId: string; words: ProductWords }) {
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
            {`The person becomes an admin the first time they sign in to ${words.its} admin console with this address.`}
          </p>
          {added && <p className="text-sm text-apt-text">{`${added} is on the sign-up list as an admin.`}</p>}
          <ErrorText error={error} />
        </>
      )}
    </FieldGroup>
  );
}

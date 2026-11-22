"use client";

import { useCallback, useMemo, useRef, useState, type FormEvent, type ReactNode } from "react";
import { Trash2 } from "lucide-react";

import { useResourceList } from "@adh-sdk/data";
import { ecosystemFeaturesApi, type CatalogFeature } from "@adh-sdk/data/ecosystems";
import {
  SetRefusedError,
  setEntryFeatures,
  setsApi,
  type SetEntryFeature,
  type SetLimitEntry,
  type SetRow,
  type SetValue,
} from "@adh-sdk/data/sets";
import { DEFAULT_QUOTA_BYTES } from "@adh-sdk/data/product-admin";
import { FieldGroup } from "@adh-sdk/ui/blocks";
import { Badge } from "@adh-sdk/ui/components/badge";
import { Button } from "@adh-sdk/ui/components/button";
import { Checkbox } from "@adh-sdk/ui/components/checkbox";
import { ErrorText } from "@adh-sdk/ui/components/error-text";
import { Input } from "@adh-sdk/ui/components/input";
import { List, ListItem } from "@adh-sdk/ui/components/list";
import type { PaneCaller } from "./pane-caller";

/** The cache key an ecosystem's sets are read under (the sign-up list's set picker shares it). */
const setsKey = (ecosystemId: string) => `sets:${ecosystemId}`;

/** The rate limit tier: a product admin may not write it (403 from `PUT /sets/:id/values`). */
export const USAGE_TIER_LIMIT_KEY = "usage.tier";
/** The storage quota: a product admin may not set it above `DEFAULT_QUOTA_BYTES`. */
export const STORAGE_QUOTA_LIMIT_KEY = "storage.quota_bytes";

/**
 * An ecosystem's SETS (phase 5): named bundles of the product's permissions and limits that its
 * customers hold, through an offer they bought, the sign-up list, or a direct grant. A set may
 * contain other sets and then holds everything they do.
 *
 * Nothing here knows any one feature. What a set can define is the feature catalog's
 * `setEntries`: a checkbox for each feature a set can grant, and a typed field for each limit
 * (text for a tier, a whole number for bytes or a count). A limit left empty is not defined.
 *
 * A change the backend refuses says which rule it would break and the limits at issue.
 */
export function SetsPane({
  ecosystemId,
  help,
  caller = "manager",
}: {
  ecosystemId?: string;
  /** Unused: the breadcrumb names the pane (kept for the ScopedPane prop shape). */
  title?: ReactNode;
  help?: ReactNode;
  /** `product_admin` hides the usage tier and caps the storage quota at the default. */
  caller?: PaneCaller;
}) {
  if (!ecosystemId) {
    return (
      <div className="min-h-0 flex-1 overflow-y-auto px-6 py-6">
        <p className="text-sm text-apt-text-muted">No product selected.</p>
      </div>
    );
  }
  return <Sets key={ecosystemId} ecosystemId={ecosystemId} help={help} caller={caller} />;
}

/** What a refusal says: the rule, its reason, and what it names. */
export function refusalText(e: unknown, setNames: ReadonlyMap<string, string>): string {
  if (!(e instanceof SetRefusedError)) return e instanceof Error ? e.message : "Something went wrong.";
  const { rule, message, limits, containers, customers } = e.refusal;
  const parts = [`Refused under rule ${rule}: ${message}.`];
  if (limits?.length) parts.push(`Limits: ${limits.join(", ")}.`);
  if (containers?.length) {
    parts.push(`Sets affected: ${containers.map((id) => setNames.get(id) ?? id).join(", ")}.`);
  }
  if (customers) parts.push(`${customers} ${customers === 1 ? "customer" : "customers"} would conflict.`);
  return parts.join(" ");
}

function Sets({
  ecosystemId,
  help,
  caller,
}: {
  ecosystemId: string;
  help?: ReactNode;
  caller: PaneCaller;
}) {
  const loadSets = useCallback(() => setsApi.list(ecosystemId), [ecosystemId]);
  const { items: sets, reload, error: loadError } = useResourceList<SetRow>(setsKey(ecosystemId), loadSets);

  const loadCatalog = useCallback(() => ecosystemFeaturesApi.catalog(), []);
  const { items: catalog, error: catalogError } = useResourceList<CatalogFeature>(
    "feature-catalog",
    loadCatalog,
  );
  const features = useMemo(
    () => setEntryFeaturesFor(setEntryFeatures(catalog ?? []), caller),
    [catalog, caller],
  );
  const setNames = useMemo(() => new Map((sets ?? []).map((s) => [s.id, s.name])), [sets]);

  const [selectedId, setSelectedId] = useState<string | null>(null);
  const selected = (sets ?? []).find((s) => s.id === selectedId) ?? null;

  const [name, setName] = useState("");
  const [slug, setSlug] = useState("");
  const [busy, setBusy] = useState(false);
  const busyRef = useRef(false);
  const [error, setError] = useState<string | null>(null);

  const run = async (fn: () => Promise<void>): Promise<boolean> => {
    if (busyRef.current) return false;
    busyRef.current = true;
    setBusy(true);
    setError(null);
    try {
      await fn();
      await reload().catch(() => {});
      return true;
    } catch (e) {
      setError(refusalText(e, setNames));
      return false;
    } finally {
      busyRef.current = false;
      setBusy(false);
    }
  };

  const onCreate = (e: FormEvent) => {
    e.preventDefault();
    void run(async () => {
      const made = await setsApi.create(ecosystemId, { name: name.trim(), slug: slug.trim() });
      setName("");
      setSlug("");
      setSelectedId(made.id);
    });
  };

  return (
    <div className="min-h-0 flex-1 overflow-y-auto px-6 py-6">
      <div className="flex flex-col gap-6">
        {help && <p className="text-sm text-apt-text-muted">{help}</p>}
        <FieldGroup title="New set">
          <form className="flex flex-wrap items-center gap-2" onSubmit={onCreate}>
            <Input
              aria-label="Name"
              placeholder="Pro"
              value={name}
              disabled={busy}
              onChange={(e) => setName(e.target.value)}
              className="w-48"
            />
            <Input
              aria-label="Slug"
              placeholder="pro"
              value={slug}
              disabled={busy}
              onChange={(e) => setSlug(e.target.value)}
              className="w-40 font-mono"
            />
            <Button type="submit" size="sm" disabled={busy || !name.trim() || !slug.trim()}>
              Create
            </Button>
          </form>
        </FieldGroup>

        <ErrorText error={error} />

        <FieldGroup title="Sets">
          {loadError ? (
            <ErrorText error={`Couldn't load the sets: ${loadError}`} />
          ) : sets === null ? (
            <p className="text-sm text-apt-text-muted">Loading…</p>
          ) : sets.length === 0 ? (
            <p className="text-sm text-apt-text-muted">This product has no sets.</p>
          ) : (
            <List>
              {sets.map((s) => (
                <ListItem key={s.id} className="flex items-center gap-3">
                  <button
                    type="button"
                    className="min-w-0 flex-1 truncate text-left text-sm text-apt-text"
                    aria-pressed={s.id === selectedId}
                    onClick={() => setSelectedId(s.id === selectedId ? null : s.id)}
                  >
                    {s.name}
                  </button>
                  <span className="truncate font-mono text-xs text-apt-text-muted">{s.slug}</span>
                  {s.isDefault && <Badge variant="accent">Default</Badge>}
                  <Button
                    size="sm"
                    variant="destructive-ghost"
                    aria-label={`Delete ${s.name}`}
                    disabled={busy}
                    onClick={() =>
                      void run(async () => {
                        await setsApi.remove(ecosystemId, s.id);
                        if (s.id === selectedId) setSelectedId(null);
                      })
                    }
                  >
                    <Trash2 size={14} aria-hidden />
                  </Button>
                </ListItem>
              ))}
            </List>
          )}
        </FieldGroup>

        {selected && (
          <SetEditor
            key={selected.id}
            set={selected}
            others={(sets ?? []).filter((s) => s.id !== selected.id)}
            features={features}
            caller={caller}
            catalogError={catalogError}
            busy={busy}
            onMakeDefault={() =>
              void run(async () => {
                await setsApi.edit(ecosystemId, selected.id, { isDefault: true });
              })
            }
            onSave={(values, contains) =>
              run(async () => {
                if (values) await setsApi.setValues(ecosystemId, selected.id, values);
                if (contains) await setsApi.setMembers(ecosystemId, selected.id, contains);
              })
            }
          />
        )}
      </div>
    </div>
  );
}

/** A limit field, with the ceiling a caller may enter when it has one. */
type LimitField = SetLimitEntry & { max?: number };

/**
 * The set entries a caller may edit. A product admin does not see the usage tier, and the storage
 * quota field carries the default as its ceiling, so the backend's refusals are never the first a
 * product admin hears of either rule.
 */
export function setEntryFeaturesFor(
  features: readonly SetEntryFeature[],
  caller: PaneCaller,
): SetEntryFeature[] {
  if (caller !== "product_admin") return [...features];
  return features.map((f) => {
    const limits = f.setEntries.limits;
    if (!limits) return f;
    return {
      ...f,
      setEntries: {
        ...f.setEntries,
        limits: limits
          .filter((l) => l.key !== USAGE_TIER_LIMIT_KEY)
          .map((l): LimitField => (l.key === STORAGE_QUOTA_LIMIT_KEY ? { ...l, max: DEFAULT_QUOTA_BYTES } : l)),
      },
    };
  });
}

interface SetDraft {
  permissions: Set<string>;
  /** Limit key to the field's text; empty leaves the limit undefined. */
  limits: Record<string, string>;
  contains: Set<string>;
}

const draftOf = (set: SetRow): SetDraft => ({
  permissions: new Set(set.values.filter((v) => v.kind === "permission").map((v) => v.key)),
  limits: Object.fromEntries(
    set.values.filter((v) => v.kind === "limit").map((v) => [v.key, String(v.value)]),
  ),
  contains: new Set(set.contains),
});

/**
 * The values a draft defines, or the first field that is not a value of its type. A value the
 * catalog no longer declares is kept as it was: the pane cannot show it, so it does not drop it.
 */
export function valuesOfDraft(
  set: SetRow,
  draft: Pick<SetDraft, "permissions" | "limits">,
  features: readonly SetEntryFeature[],
): { values: SetValue[] } | { error: string } {
  const permissionKeys = new Set(features.filter((f) => f.setEntries.permission).map((f) => f.key));
  const limitEntries = new Map<string, LimitField>(
    features.flatMap((f) => (f.setEntries.limits ?? []).map((l) => [l.key, l] as const)),
  );
  const values: SetValue[] = set.values.filter((v) =>
    v.kind === "permission" ? !permissionKeys.has(v.key) : !limitEntries.has(v.key),
  );
  for (const key of permissionKeys) {
    if (draft.permissions.has(key)) values.push({ kind: "permission", key, value: true });
  }
  for (const [key, entry] of limitEntries) {
    const text = (draft.limits[key] ?? "").trim();
    if (text === "") continue;
    if (entry.type === "tier") {
      values.push({ kind: "limit", key, value: text });
    } else if (/^\d+$/.test(text)) {
      if (entry.max !== undefined && Number(text) > entry.max) {
        return { error: `${entry.label} can be at most ${entry.max}.` };
      }
      values.push({ kind: "limit", key, value: Number(text) });
    } else {
      return { error: `${entry.label} must be a whole number.` };
    }
  }
  return { values };
}

const TIER_LOCKED =
  "This set has a usage tier, which only the product's managers can change, so its permissions and limits are theirs to change too. What it contains is yours.";

const sameValues = (a: readonly SetValue[], b: readonly SetValue[]) => {
  const norm = (vs: readonly SetValue[]) =>
    vs.map((v) => `${v.kind}\u0000${v.key}\u0000${JSON.stringify(v.value)}`).sort().join("\u0001");
  return norm(a) === norm(b);
};

const sameMembers = (a: readonly string[], b: ReadonlySet<string>) =>
  a.length === b.size && a.every((id) => b.has(id));

function SetEditor({
  set,
  others,
  features,
  caller,
  catalogError,
  busy,
  onMakeDefault,
  onSave,
}: {
  set: SetRow;
  others: SetRow[];
  features: SetEntryFeature[];
  caller: PaneCaller;
  catalogError: string | null;
  busy: boolean;
  onMakeDefault: () => void;
  /** Null for a part that did not change. */
  onSave: (values: SetValue[] | null, contains: string[] | null) => Promise<boolean>;
}) {
  const [draft, setDraft] = useState<SetDraft>(() => draftOf(set));
  const [error, setError] = useState<string | null>(null);
  const tierLocked =
    caller === "product_admin" && set.values.some((v) => v.key === USAGE_TIER_LIMIT_KEY);

  const toggle = (field: "permissions" | "contains", key: string, on: boolean) =>
    setDraft((d) => {
      const next = new Set(d[field]);
      if (on) next.add(key);
      else next.delete(key);
      return { ...d, [field]: next };
    });

  const onSubmit = (e: FormEvent) => {
    e.preventDefault();
    const out = valuesOfDraft(set, draft, features);
    if ("error" in out) {
      setError(out.error);
      return;
    }
    setError(null);
    const values = sameValues(out.values, set.values) ? null : out.values;
    const contains = sameMembers(set.contains, draft.contains) ? null : [...draft.contains];
    if (!values && !contains) return;
    // The backend refuses a product admin any write that names the tier, and a set's values are
    // written whole, so a set that has one is the managers' to change.
    if (values && tierLocked) {
      setError(TIER_LOCKED);
      return;
    }
    void onSave(values, contains);
  };

  const permissionFeatures = features.filter((f) => f.setEntries.permission);
  const limits: LimitField[] = features.flatMap((f) => f.setEntries.limits ?? []);

  return (
    <FieldGroup title={set.name}>
      <form className="flex flex-col gap-4" onSubmit={onSubmit} noValidate>
        {catalogError && <ErrorText error={`Couldn't load the feature catalog: ${catalogError}`} />}
        {tierLocked && <p className="text-xs text-apt-text-muted">{TIER_LOCKED}</p>}
        {set.isDefault ? (
          <p className="text-xs text-apt-text-muted">
            The default set: a customer who holds no other set holds this one.
          </p>
        ) : (
          <div>
            <Button type="button" size="sm" variant="outline" disabled={busy} onClick={onMakeDefault}>
              Make default
            </Button>
          </div>
        )}

        <section className="flex flex-col gap-2">
          <h3 className="text-xs font-medium uppercase tracking-wide text-apt-text-dim">Permissions</h3>
          {permissionFeatures.length === 0 ? (
            <p className="text-sm text-apt-text-muted">No feature can be granted by a set.</p>
          ) : (
            permissionFeatures.map((f) => (
              <label key={f.key} className="flex items-center gap-2 text-sm text-apt-text">
                <Checkbox
                  checked={draft.permissions.has(f.key)}
                  disabled={busy}
                  onCheckedChange={(on) => toggle("permissions", f.key, on === true)}
                />
                {f.label}
              </label>
            ))
          )}
        </section>

        <section className="flex flex-col gap-2">
          <h3 className="text-xs font-medium uppercase tracking-wide text-apt-text-dim">Limits</h3>
          {limits.length === 0 ? (
            <p className="text-sm text-apt-text-muted">No feature declares a limit.</p>
          ) : (
            limits.map((l) => (
              <label key={l.key} className="flex items-center gap-2 text-sm text-apt-text">
                <span className="w-48 truncate">{l.label}</span>
                <Input
                  aria-label={l.label}
                  type={l.type === "tier" ? "text" : "number"}
                  min={l.type === "tier" ? undefined : 0}
                  max={l.type === "tier" ? undefined : l.max}
                  step={l.type === "tier" ? undefined : 1}
                  placeholder={l.type === "tier" ? "tier slug" : l.type}
                  value={draft.limits[l.key] ?? ""}
                  disabled={busy}
                  onChange={(e) =>
                    setDraft((d) => ({ ...d, limits: { ...d.limits, [l.key]: e.target.value } }))
                  }
                  className="w-48 font-mono"
                />
              </label>
            ))
          )}
        </section>

        <section className="flex flex-col gap-2">
          <h3 className="text-xs font-medium uppercase tracking-wide text-apt-text-dim">Contains</h3>
          {others.length === 0 ? (
            <p className="text-sm text-apt-text-muted">There are no other sets to contain.</p>
          ) : (
            others.map((s) => (
              <label key={s.id} className="flex items-center gap-2 text-sm text-apt-text">
                <Checkbox
                  checked={draft.contains.has(s.id)}
                  disabled={busy}
                  onCheckedChange={(on) => toggle("contains", s.id, on === true)}
                />
                {s.name}
              </label>
            ))
          )}
        </section>

        <div>
          <Button type="submit" size="sm" disabled={busy}>
            Save
          </Button>
        </div>
        <ErrorText error={error} />
      </form>
    </FieldGroup>
  );
}

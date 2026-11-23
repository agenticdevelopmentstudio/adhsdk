"use client";

import { useEffect, useState, type FormEvent } from "react";

import {
  DEFAULT_QUOTA_BYTES,
  isAdminSeatProtected,
  useDeleteCustomer,
  usePauseCustomer,
  useProductCustomers,
  useSetCustomerQuota,
  useUnpauseCustomer,
  type ProductCustomer,
} from "@adh-sdk/data/product-admin";
import { AlertModal } from "@adh-sdk/ui/components/alert-modal";
import { Badge } from "@adh-sdk/ui/components/badge";
import { Button } from "@adh-sdk/ui/components/button";
import { ErrorText } from "@adh-sdk/ui/components/error-text";
import { Input } from "@adh-sdk/ui/components/input";
import { List, ListItem } from "@adh-sdk/ui/components/list";
import { formatBytes } from "@adh-sdk/ui/lib/quantities";

/** What a refused pause or delete of an admin's seat says (the backend's 422 `admin_seat_protected`). */
export const ADMIN_SEAT_PROTECTED = "Admins cannot be paused or deleted here";

const GIB = 1024 ** 3;
const MAX_QUOTA_GIB = DEFAULT_QUOTA_BYTES / GIB;

type Pending =
  | { kind: "pause" | "unpause" | "delete"; customer: ProductCustomer }
  | { kind: "quota"; customer: ProductCustomer };

const nameOf = (c: ProductCustomer) => c.displayName || c.email || c.id;

/**
 * The product's CUSTOMERS (phase 6), for the product's own admins: the roster, newest first, with
 * search and paging, and per person a pause or unpause, a storage quota (at most
 * `DEFAULT_QUOTA_BYTES`) and a delete. Every change is confirmed first.
 *
 * Paging is by cursor: the backend hands back the cursor of the next page, so the pane keeps the
 * cursors it followed to walk back.
 */
export function ProductUsersPane({ ecosystemId }: { ecosystemId: string }) {
  const [draft, setDraft] = useState("");
  const [q, setQ] = useState("");
  const [cursors, setCursors] = useState<string[]>([]);
  const cursor = cursors.at(-1);
  const { data: page, error: loadError, isPending: loading } = useProductCustomers(ecosystemId, { q, cursor });

  // A later page that comes back empty (its last person was just deleted) steps back a page,
  // rather than saying "No users yet." while earlier pages still hold people.
  const emptyLaterPage = page !== undefined && page.items.length === 0 && cursors.length > 0;
  useEffect(() => {
    if (emptyLaterPage) setCursors((cs) => cs.slice(0, -1));
  }, [emptyLaterPage]);

  const pause = usePauseCustomer(ecosystemId);
  const unpause = useUnpauseCustomer(ecosystemId);
  const setQuota = useSetCustomerQuota(ecosystemId);
  const remove = useDeleteCustomer(ecosystemId);

  const [pending, setPending] = useState<Pending | null>(null);
  const [quotaGib, setQuotaGib] = useState("");
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const onSearch = (e: FormEvent) => {
    e.preventDefault();
    setQ(draft.trim());
    setCursors([]);
  };

  const ask = (next: Pending) => {
    setError(null);
    if (next.kind === "quota") setQuotaGib(String(+(next.customer.quotaBytes / GIB).toFixed(2)));
    setPending(next);
  };

  const quotaBytes = (): number | string => {
    const n = Number(quotaGib.trim());
    if (quotaGib.trim() === "" || !Number.isFinite(n) || n <= 0) return "Enter a quota in GB.";
    const bytes = Math.round(n * GIB);
    if (bytes > DEFAULT_QUOTA_BYTES) return `The quota can be at most ${MAX_QUOTA_GIB} GB.`;
    return bytes;
  };

  const onConfirm = async () => {
    if (!pending || busy) return;
    const { customer } = pending;
    setBusy(true);
    setError(null);
    try {
      if (pending.kind === "pause") await pause.mutateAsync({ customerId: customer.id });
      else if (pending.kind === "unpause") await unpause.mutateAsync(customer.id);
      else if (pending.kind === "delete") await remove.mutateAsync(customer.id);
      else {
        const bytes = quotaBytes();
        if (typeof bytes === "string") {
          setError(bytes);
          return;
        }
        await setQuota.mutateAsync({ customerId: customer.id, bytes });
      }
      setPending(null);
    } catch (err) {
      setPending(null);
      setError(
        isAdminSeatProtected(err)
          ? `${ADMIN_SEAT_PROTECTED}.`
          : err instanceof Error
            ? err.message
            : "Something went wrong.",
      );
    } finally {
      setBusy(false);
    }
  };

  const customers = page?.items ?? [];
  return (
    <div className="min-h-0 flex-1 overflow-y-auto px-6 py-6">
      <div className="flex flex-col gap-4">
        <form className="flex flex-wrap items-center gap-2" onSubmit={onSearch} role="search">
          <Input
            aria-label="Search users"
            placeholder="Email or name"
            value={draft}
            onChange={(e) => setDraft(e.target.value)}
            className="w-72"
          />
          <Button type="submit" size="sm">
            Search
          </Button>
        </form>
        {pending === null && <ErrorText error={error} />}

        {loadError ? (
          <ErrorText error={`Couldn't load the users: ${loadError.message}`} />
        ) : loading || emptyLaterPage ? (
          <p className="text-sm text-apt-text-muted">Loading…</p>
        ) : customers.length === 0 ? (
          <p className="text-sm text-apt-text-muted">{q ? `No users match "${q}".` : "No users yet."}</p>
        ) : (
          <List aria-label="Users">
            {customers.map((c) => (
              <ListItem key={c.id} className="flex flex-wrap items-center gap-3">
                <div className="min-w-0 flex-1">
                  <div className="truncate text-sm text-apt-text">{nameOf(c)}</div>
                  {c.email && c.displayName && (
                    <div className="truncate font-mono text-xs text-apt-text-muted">{c.email}</div>
                  )}
                </div>
                {c.roles.length > 0 && (
                  <span className="text-xs text-apt-text-muted">{c.roles.map((r) => r.name).join(", ")}</span>
                )}
                <span className="w-40 text-right text-xs text-apt-text-muted">
                  {`${formatBytes(c.storageBytes)} of ${formatBytes(c.quotaBytes)}`}
                </span>
                {c.paused && <Badge variant="error">Paused</Badge>}
                <div className="flex items-center gap-1">
                  <Button
                    size="sm"
                    variant="ghost"
                    aria-label={`${c.paused ? "Unpause" : "Pause"} ${nameOf(c)}`}
                    onClick={() => ask({ kind: c.paused ? "unpause" : "pause", customer: c })}
                  >
                    {c.paused ? "Unpause" : "Pause"}
                  </Button>
                  <Button
                    size="sm"
                    variant="ghost"
                    aria-label={`Quota for ${nameOf(c)}`}
                    onClick={() => ask({ kind: "quota", customer: c })}
                  >
                    Quota
                  </Button>
                  <Button
                    size="sm"
                    variant="destructive-ghost"
                    aria-label={`Delete ${nameOf(c)}`}
                    onClick={() => ask({ kind: "delete", customer: c })}
                  >
                    Delete
                  </Button>
                </div>
              </ListItem>
            ))}
          </List>
        )}

        <div className="flex items-center gap-2">
          <Button
            size="sm"
            variant="ghost"
            disabled={cursors.length === 0}
            onClick={() => setCursors((cs) => cs.slice(0, -1))}
          >
            Previous
          </Button>
          <Button
            size="sm"
            variant="ghost"
            disabled={!page?.nextCursor}
            onClick={() => page?.nextCursor && setCursors((cs) => [...cs, page.nextCursor as string])}
          >
            Next
          </Button>
        </div>
      </div>

      {pending && (
        <AlertModal
          open
          title={TITLES[pending.kind](nameOf(pending.customer))}
          tone={pending.kind === "delete" || pending.kind === "pause" ? "error" : "info"}
          destructive={pending.kind === "delete"}
          confirmLabel={CONFIRM[pending.kind]}
          cancelLabel="Cancel"
          busy={busy}
          onCancel={() => {
            setPending(null);
            setError(null);
          }}
          onConfirm={() => void onConfirm()}
          description={
            <div className="flex flex-col gap-2">
              <p>{DESCRIPTIONS[pending.kind]}</p>
              {pending.kind === "quota" && (
                <Input
                  aria-label="Quota in GB"
                  type="number"
                  min={0}
                  max={MAX_QUOTA_GIB}
                  step="any"
                  value={quotaGib}
                  onChange={(e) => setQuotaGib(e.target.value)}
                />
              )}
              <ErrorText error={error} />
            </div>
          }
        />
      )}
    </div>
  );
}

const TITLES: Record<Pending["kind"], (name: string) => string> = {
  pause: (n) => `Pause ${n}?`,
  unpause: (n) => `Unpause ${n}?`,
  quota: (n) => `Storage quota for ${n}`,
  delete: (n) => `Delete ${n}?`,
};

const CONFIRM: Record<Pending["kind"], string> = {
  pause: "Pause",
  unpause: "Unpause",
  quota: "Save",
  delete: "Delete",
};

const DESCRIPTIONS: Record<Pending["kind"], string> = {
  pause: "They are signed out and cannot sign in or use the product until they are unpaused.",
  unpause: "They can sign in and use the product again.",
  quota: `The most storage they may use, up to ${MAX_QUOTA_GIB} GB.`,
  delete: "They are removed from the product. A person who still owns data cannot be deleted.",
};

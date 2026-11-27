"use client";

import { useEffect, useState, type FormEvent, type ReactElement, type ReactNode } from "react";
import { Globe, Loader2, RefreshCw } from "lucide-react";
import { useQueryClient } from "@tanstack/react-query";

import {
  PRODUCT_DOMAINS_KEY,
  productDomainsAvailable,
  useAddProductDomain,
  useCheckProductDomain,
  useProductDomains,
  useRemoveProductDomain,
  useSetPrimaryProductDomain,
  type ProductDomain,
  type ProductDomainRecord,
  type ProductSite,
} from "@adh-sdk/data/product-sites";
import { FieldGroup } from "@adh-sdk/ui/blocks";
import { AlertModal } from "@adh-sdk/ui/components/alert-modal";
import { Badge } from "@adh-sdk/ui/components/badge";
import { Button } from "@adh-sdk/ui/components/button";
import { CopyButton } from "@adh-sdk/ui/components/copy-button";
import { ErrorText } from "@adh-sdk/ui/components/error-text";
import { Input } from "@adh-sdk/ui/components/input";
import { List, ListItem } from "@adh-sdk/ui/components/list";
import { wordsFor, type ProductWords } from "./product-words";

/** The most domains a product can have; the backend refuses a sixth (`product_domain_limit`). */
const DOMAIN_LIMIT = 5;

/** The ownership challenge's record name starts with this label (`_adh-challenge.<host>`). */
const CHALLENGE_LABEL = "_adh-challenge";

const FALLBACK = "Something went wrong. Try again.";

/**
 * The human sentence for a refusal from the product-domains route (design §6): each code the
 * backend sends has its own; a 403 says who may change the domains; anything else falls back to
 * the backend's sentence, then to a generic one. Always plain text.
 */
export function domainErrorMessage(err: unknown, words: ProductWords = wordsFor(undefined)): string {
  const code = typeof (err as { code?: unknown } | null)?.code === "string" ? (err as { code: string }).code : undefined;
  switch (code) {
    case "product_domain_invalid":
      return `That isn't a domain name ${words.name} can use. Enter one such as app.example.com.`;
    case "product_domain_local":
      return "That name only works on a local network. Enter a public domain such as app.example.com.";
    case "product_domain_ours":
      return "That domain belongs to the hub. Enter a domain you own.";
    case "product_domain_limit":
      return `${words.Name} already has five domains, the most it can have. Remove one to add another.`;
    case "product_domain_taken":
      return "Another product already uses that domain.";
    case "product_domain_taken_elsewhere":
      return "That domain is in use on another Vercel account, so it can't be added here.";
    case "product_domain_vercel_unavailable":
      return "The domain service didn't answer. Try again in a minute.";
    case "product_domains_rate_limited":
      return "Too many tries in the last hour. Try again later.";
    case "product_domains_unconfigured":
      return "Custom domains aren't set up on this server yet.";
    case "product_domain_not_verified":
      return "That domain isn't verified yet, so it can't be the primary address.";
    case "product_domain_primary_race":
      return "Another change to the primary address happened at the same time. Try again.";
    case "product_domain_not_found":
      return "That domain was already removed.";
  }
  const status = (err as { status?: unknown } | null)?.status;
  if (status === 403) return "Only the product's managers can change its domains.";
  if (err instanceof Error && err.message.trim() !== "") return err.message;
  return FALLBACK;
}

/**
 * The refusals that mean the list on screen is out of date, so it is read again: the domain was
 * removed elsewhere, the sweep demoted it before Make primary landed, or another primary change
 * won the race.
 */
const STALE_LIST_CODES = new Set(["product_domain_not_found", "product_domain_not_verified", "product_domain_primary_race"]);

const listIsStale = (err: unknown) => {
  const code = (err as { code?: unknown } | null)?.code;
  return typeof code === "string" && STALE_LIST_CODES.has(code);
};

// ── Times ─────────────────────────────────────────────────────────────────────

const parse = (iso: string | null | undefined): Date | null => {
  if (!iso) return null;
  const d = new Date(iso);
  return Number.isNaN(d.getTime()) ? null : d;
};

/** "19 Nov, 14:05" (in the reader's locale). */
const when = (iso: string | null | undefined): string | null =>
  parse(iso)?.toLocaleString(undefined, { day: "numeric", month: "short", hour: "2-digit", minute: "2-digit" }) ?? null;

/** "19 November" (in the reader's locale), for an ISO string or a Date. */
const day = (at: string | Date | null | undefined): string | null =>
  (at instanceof Date ? at : parse(at))?.toLocaleDateString(undefined, { day: "numeric", month: "long" }) ?? null;

/** How long the sweep checks a pending domain before failing it (the backend's 7 days). */
const CHECK_WINDOW_MS = 7 * 86_400_000;

/**
 * When the domain's current 7-day window began: `expiresAt` minus 7 days. The backend starts a
 * fresh window on a demotion and on a Check now of a failed row, so this is not always `createdAt`.
 */
const windowStart = (domain: ProductDomain): Date | null => {
  const expires = parse(domain.expiresAt);
  return expires ? new Date(expires.getTime() - CHECK_WINDOW_MS) : null;
};

/** Each unit, smallest first, with its size in seconds and how many of it make the next unit. */
const UNITS: [Intl.RelativeTimeFormatUnit, number, number][] = [
  ["second", 1, 60],
  ["minute", 60, 60],
  ["hour", 3_600, 24],
  ["day", 86_400, Infinity],
];

/**
 * "4 minutes ago", through `Intl.RelativeTimeFormat`, relative to `now`. A time after `now` (the
 * reader's clock behind the server's) is read as now, so it never says "in 30 seconds".
 */
function ago(iso: string | null | undefined, now: number): string | null {
  const d = parse(iso);
  if (!d) return null;
  const seconds = Math.round((Math.min(d.getTime(), now) - now) / 1000);
  const rtf = new Intl.RelativeTimeFormat(undefined, { numeric: "auto" });
  // The unit is picked from the rounded value, so 3590 seconds is "1 hour ago", not "60 minutes
  // ago": round in a unit, and move up while the rounded count reaches the next unit.
  const sign = seconds < 0 ? -1 : 1;
  const abs = Math.abs(seconds);
  for (const [unit, size, next] of UNITS) {
    const count = Math.round(abs / size);
    if (count < next) return rtf.format(sign * count, unit);
  }
  return null;
}

/** How often the relative times are read again, so "Last checked 4 minutes ago" ages. */
const TICK_MS = 60_000;

/** The current time, read again every `TICK_MS`; the interval is cleared on unmount. */
function useNow(): number {
  const [now, setNow] = useState(() => Date.now());
  useEffect(() => {
    const id = setInterval(() => setNow(Date.now()), TICK_MS);
    return () => clearInterval(id);
  }, []);
  return now;
}

// ── Hosts ─────────────────────────────────────────────────────────────────────

/** `temporal.example.com` for `https://temporal.example.com`; null when there is none. */
const hostOf = (origin: string | null | undefined): string | null => {
  if (!origin) return null;
  try {
    return new URL(origin).host;
  } catch {
    return null;
  }
};

/**
 * Where the records are created: the DNS zone, read from the records the backend sent. An `A`
 * record named `@` means the host is its own apex; a `CNAME` is named for the labels left of the
 * apex, so `app` on `app.example.co.uk` gives `example.co.uk`. Only with neither does it guess:
 * the host minus its first label, or the host at two labels.
 */
const zoneOf = ({ host, records }: Pick<ProductDomain, "host" | "records">): string => {
  if (records.some((r) => r.type === "A" && r.name === "@")) return host;
  const cname = records.find((r) => r.type === "CNAME" && r.name !== "" && host.startsWith(`${r.name}.`));
  if (cname) return host.slice(cname.name.length + 1);
  const labels = host.split(".");
  return labels.length > 2 ? labels.slice(1).join(".") : host;
};

/** The backend's sentence without a closing full stop, so it can sit inside one of ours. */
const clause = (s: string) => s.trim().replace(/\.+$/, "");

// ── The section ───────────────────────────────────────────────────────────────

/**
 * A product's CUSTOM DOMAINS at the hub (product sites phase 8), rendered by `ProductSitePane`
 * after its admin console section: the domains the product answers at besides its own address,
 * each with the DNS records it waits for, and the add, check, make-primary and remove actions.
 *
 * It hides itself entirely while the backend's `product_custom_domains` switch is off (the list
 * answers 404 `not_found`), and renders nothing while loading, so a product without the switch
 * never flashes a heading. Every API string (host, records, `error`) is rendered as text.
 */
export function ProductDomainsSection({
  ecosystemId,
  site,
  productName,
}: {
  ecosystemId: string;
  site: ProductSite;
  productName?: string;
}): ReactElement | null {
  const { data: domains, error } = useProductDomains(ecosystemId);
  const now = useNow();
  const words = wordsFor(productName);

  if (error && !productDomainsAvailable(error)) return null;
  if (!error && domains === undefined) return null;

  const intro = `${words.Name} can also answer at a domain you own. Its sign-in, admin console and support pages then work there too, and once the domain is verified you can make it ${words.its} primary address.`;

  // Only a list never loaded is replaced by the error: a failed background refetch keeps the
  // list already on screen and says, under the intro, that it could not be refreshed.
  if (domains === undefined) {
    return (
      <FieldGroup title="Custom domain">
        <ErrorText error={`Couldn't load the custom domains: ${domainErrorMessage(error, words)}`} />
      </FieldGroup>
    );
  }

  const canAdd = domains.length < DOMAIN_LIMIT && !domains.some((d) => d.status === "verified");

  return (
    <FieldGroup title="Custom domain">
      <p className="text-sm text-apt-text-muted">{intro}</p>
      {error ? <ErrorText error={`Couldn't refresh the custom domains: ${domainErrorMessage(error, words)}`} /> : null}
      {domains.map((domain) => (
        <DomainBox key={domain.id} ecosystemId={ecosystemId} domain={domain} site={site} words={words} now={now} />
      ))}
      {canAdd && <AddDomain ecosystemId={ecosystemId} words={words} />}
      <Guidance />
    </FieldGroup>
  );
}

function AddDomain({ ecosystemId, words }: { ecosystemId: string; words: ProductWords }) {
  const add = useAddProductDomain(ecosystemId);
  const [draft, setDraft] = useState("");
  const [error, setError] = useState<string | null>(null);
  const host = draft.trim();
  const busy = add.isPending;

  const onSubmit = (e: FormEvent) => {
    e.preventDefault();
    if (host === "" || busy) return;
    setError(null);
    add.mutate(host, {
      onSuccess: () => setDraft(""),
      onError: (err) => setError(domainErrorMessage(err, words)),
    });
  };

  return (
    <div className="flex flex-col gap-2">
      {/* noValidate: the section says what is wrong in the backend's terms, not the browser's. */}
      <form className="flex flex-wrap items-center gap-2" onSubmit={onSubmit} noValidate>
        <Input
          aria-label="Domain"
          placeholder="app.example.com"
          value={draft}
          disabled={busy}
          aria-invalid={error ? true : undefined}
          onChange={(e) => setDraft(e.target.value)}
          className="w-64 font-mono"
        />
        <Button type="submit" size="sm" disabled={busy || host === ""} aria-busy={busy || undefined}>
          {busy && <Loader2 className="animate-spin" aria-hidden />}
          Add domain
        </Button>
      </form>
      <ErrorText error={error} />
    </div>
  );
}

function Guidance() {
  return (
    <List>
      <ListItem className="block text-sm text-apt-text-muted">
        <strong className="text-apt-text">Use a subdomain</strong>
        {", such as "}
        <span className="font-mono">app.example.com</span>
        {", rather than "}
        <span className="font-mono">example.com</span>
        {" itself. A subdomain needs one CNAME record, which every DNS provider supports. A bare domain needs an A record instead."}
      </ListItem>
      <ListItem className="block text-sm text-apt-text-muted">
        <strong className="text-apt-text">On Cloudflare, set the record to DNS only</strong>
        {" (the grey cloud, not the orange one). With the orange cloud, Cloudflare stands in front of the domain and it can't be verified."}
      </ListItem>
      <ListItem className="block text-sm text-apt-text-muted">
        <strong className="text-apt-text">Passkeys and security keys don't work on a custom domain.</strong>
        {" A passkey belongs to one domain, so a customer who signs in with one there is asked for another way to sign in."}
      </ListItem>
    </List>
  );
}

function DomainBox({
  ecosystemId,
  domain,
  site,
  words,
  now,
}: {
  ecosystemId: string;
  domain: ProductDomain;
  site: ProductSite;
  words: ProductWords;
  /** The section's ticking clock, for the relative "Last checked" time. */
  now: number;
}) {
  const qc = useQueryClient();
  const check = useCheckProductDomain(ecosystemId);
  const setPrimary = useSetPrimaryProductDomain(ecosystemId);
  const remove = useRemoveProductDomain(ecosystemId);
  const [error, setError] = useState<string | null>(null);
  const [confirming, setConfirming] = useState(false);
  const { host } = domain;
  const busy = check.isPending || setPrimary.isPending || remove.isPending;

  // A refusal that means the list is out of date (removed elsewhere, demoted, a primary race):
  // say so, and read the list again so the boxes follow.
  const onError = (err: unknown) => {
    setError(domainErrorMessage(err, words));
    if (listIsStale(err)) void qc.invalidateQueries({ queryKey: PRODUCT_DOMAINS_KEY(ecosystemId) });
  };

  const onCheck = () => {
    setError(null);
    check.mutate(domain.id, { onError });
  };

  const onMakePrimary = () => {
    setError(null);
    setPrimary.mutate({ domainId: domain.id, primary: true }, { onError });
  };

  const onRemove = () => {
    setError(null);
    remove.mutate(domain.id, { onError, onSettled: () => setConfirming(false) });
  };

  const showRecords = (domain.status === "pending" || domain.status === "failed") && domain.records.length > 0;
  const canCheck = domain.status === "pending" || domain.status === "failed";
  const canMakePrimary = domain.status === "verified" && !domain.isPrimary;

  return (
    <div className="flex flex-col gap-3 rounded-lg border border-apt-border p-3">
      <div className="flex flex-wrap items-center gap-2">
        <Globe className="size-4 text-apt-text-muted" aria-hidden />
        <span className="font-mono text-sm text-apt-text">{host}</span>
        <StatusBadges domain={domain} />
      </div>
      {/* The live region holds only the state sentence, so a Check now outcome is announced but
          the check line, which ticks once a minute in every pending box, is not. */}
      <p className="text-sm text-apt-text-muted">
        <span role="status">
          <StateText domain={domain} site={site} words={words} />
        </span>
        {domain.status === "pending" ? ` ${checkLine(domain, now)}` : null}
      </p>
      {showRecords && <Records domain={domain} />}
      <div className="flex flex-wrap items-center gap-2">
        {canCheck && (
          <Button
            type="button"
            size="sm"
            variant="outline"
            aria-label={`Check ${host} now`}
            aria-busy={check.isPending || undefined}
            disabled={busy}
            onClick={onCheck}
          >
            {check.isPending ? <Loader2 className="animate-spin" aria-hidden /> : <RefreshCw aria-hidden />}
            Check now
          </Button>
        )}
        {canMakePrimary && (
          <Button
            type="button"
            size="sm"
            aria-label={`Make ${host} primary`}
            aria-busy={setPrimary.isPending || undefined}
            disabled={busy}
            onClick={onMakePrimary}
          >
            {setPrimary.isPending && <Loader2 className="animate-spin" aria-hidden />}
            Make primary
          </Button>
        )}
        <Button
          type="button"
          size="sm"
          variant="destructive-ghost"
          aria-label={`Remove ${host}`}
          disabled={busy}
          onClick={() => {
            setError(null);
            setConfirming(true);
          }}
        >
          Remove
        </Button>
      </div>
      <ErrorText error={error} />
      <AlertModal
        open={confirming}
        tone="error"
        title={`Remove ${host}?`}
        description={removeDescription(domain, site, words)}
        confirmLabel="Remove"
        confirmVariant="destructive"
        onConfirm={onRemove}
        cancelLabel="Cancel"
        onCancel={() => setConfirming(false)}
        busy={remove.isPending}
      />
    </div>
  );
}

function removeDescription(domain: ProductDomain, site: ProductSite, words: ProductWords): string {
  const gone = `${words.Name} stops answering at ${domain.host} at once`;
  if (!domain.isPrimary) return `${gone}.`;
  return site.subdomainOrigin
    ? `${gone}, and ${site.subdomainOrigin} becomes its primary address again. Links to the custom domain stop working.`
    : `${gone}. Links to the custom domain stop working.`;
}

function StatusBadges({ domain }: { domain: ProductDomain }) {
  switch (domain.status) {
    case "pending":
      return <Badge variant="orange">Pending</Badge>;
    case "verified":
      return (
        <>
          <Badge variant="success">Verified</Badge>
          {domain.isPrimary && <Badge variant="accent">Primary</Badge>}
        </>
      );
    case "failed":
      return <Badge variant="error">Failed</Badge>;
    case "removing":
      return <Badge variant="neutral">Removing</Badge>;
  }
}

/** "Last checked 4 minutes ago; it is checked again every 10 minutes until 3 December." */
function checkLine(domain: ProductDomain, now: number): string {
  const until = day(domain.expiresAt);
  const checked = ago(domain.checkedAt, now);
  const tail = until ? ` until ${until}` : "";
  return checked
    ? `Last checked ${checked}; it is checked again every 10 minutes${tail}.`
    : `It is checked every 10 minutes${tail}.`;
}

function StateText({ domain, site, words }: { domain: ProductDomain; site: ProductSite; words: ProductWords }): ReactNode {
  const { host } = domain;
  const subdomainHost = hostOf(site.subdomainOrigin);
  const added = when(domain.createdAt);
  const addedLead = added ? `Added ${added}. ` : "";
  // The records table shows only when the backend sent records; without them no sentence may
  // point at "the records below".
  const hasRecords = domain.records.length > 0;

  switch (domain.status) {
    case "pending":
      // A pending row with an error is a domain the re-check demoted (or one whose last check
      // found a problem): it names the problem rather than "waiting" as if nothing had happened.
      return domain.error
        ? `${addedLead}The last check found a problem: ${clause(domain.error)}. ${words.Name} answers at ${host} only once it is verified.`
        : hasRecords
          ? `${addedLead}Waiting for the records below.`
          : `${addedLead}Waiting for the DNS records, which appear here after the next check.`;

    case "verified": {
      if (domain.isPrimary) {
        return (
          <>
            <span className="font-mono">{host}</span>
            {` is ${words.its} primary address. Customers sign in there, the admin console signs in there, and support emails link there.`}
            {subdomainHost ? (
              <>
                {" "}
                <span className="font-mono">{subdomainHost}</span>
                {" still works."}
              </>
            ) : null}
          </>
        );
      }
      const verified = when(domain.verifiedAt);
      // The site's primary, which is another custom domain when two pending ones both verified
      // and one was made primary; the subdomain only when the site names no primary.
      const primaryHost = hostOf(site.primaryOrigin) ?? subdomainHost;
      return (
        <>
          {`${words.Name} answers at `}
          {/* The one href built from an API string: only for a verified row, from its host. */}
          <a className="font-mono underline" href={`https://${host}`} target="_blank" rel="noreferrer">
            {`https://${host}`}
          </a>
          {"."}
          {verified ? ` Verified ${verified}.` : ""}
          {primaryHost ? (
            <>
              {" Its primary address is still "}
              <span className="font-mono">{primaryHost}</span>
              {"."}
            </>
          ) : null}
        </>
      );
    }

    case "failed": {
      const addedDay = day(domain.createdAt);
      const started = day(windowStart(domain));
      // The window restarted after the domain was added (a demotion, or Check now on a failed
      // row): name the day it last went back to waiting, not the day it was added.
      const within =
        started && started !== addedDay
          ? `within 7 days of ${started}, when it last went back to waiting`
          : `within 7 days of adding the domain${addedDay ? ` on ${addedDay}` : ""}`;
      const base = hasRecords
        ? `The records below were not found ${within}, so it is no longer checked by itself. Create them and choose Check now, or remove the domain.`
        : `The DNS records were not found ${within}, so it is no longer checked by itself. They appear here after the next check: choose Check now, then create them, or remove the domain.`;
      return domain.error ? `${base} The last check found a problem: ${clause(domain.error)}.` : base;
    }

    case "removing":
      return "Being removed. If this stays, choose Remove again.";
  }
}

function Records({ domain }: { domain: ProductDomain }) {
  const hasChallenge = domain.records.some(
    (r) => r.type === "TXT" && (r.name === CHALLENGE_LABEL || r.name.startsWith(`${CHALLENGE_LABEL}.`)),
  );
  return (
    <div className="flex flex-col gap-2">
      <p className="text-sm text-apt-text">
        {"Create these records at the DNS provider for "}
        <span className="font-mono">{zoneOf(domain)}</span>
        {":"}
      </p>
      <div className="overflow-x-auto">
        <table aria-label={`DNS records for ${domain.host}`} className="w-full text-left text-sm">
          <thead className="text-xs text-apt-text-muted">
            <tr>
              <th scope="col" className="py-1 pr-3 font-medium">Type</th>
              <th scope="col" className="py-1 pr-3 font-medium">Name</th>
              <th scope="col" className="py-1 font-medium">Value</th>
            </tr>
          </thead>
          <tbody className="divide-y divide-apt-border">
            {domain.records.map((record, i) => (
              <RecordRow key={`${record.type}:${record.name}:${i}`} record={record} />
            ))}
          </tbody>
        </table>
      </div>
      {hasChallenge && (
        <p className="text-xs text-apt-text-muted">
          {"The TXT record named "}
          <span className="font-mono">{CHALLENGE_LABEL}</span>
          {" proves the domain is yours."}
        </p>
      )}
    </div>
  );
}

function RecordRow({ record }: { record: ProductDomainRecord }) {
  return (
    <tr>
      <td className="py-1.5 pr-3 align-top font-mono">{record.type}</td>
      <td className="py-1.5 pr-3 align-top">
        <span className="flex items-center gap-2">
          <span className="font-mono break-all">{record.name}</span>
          {/* getText returns the API string itself: no trimming, no trailing dot added. */}
          <CopyButton label={`Copy the ${record.type} record name ${record.name}`} getText={() => record.name} />
        </span>
      </td>
      <td className="py-1.5 align-top">
        <span className="flex items-center gap-2">
          <span className="font-mono break-all">{record.value}</span>
          <CopyButton label={`Copy the ${record.type} record value for ${record.name}`} getText={() => record.value} />
        </span>
      </td>
    </tr>
  );
}

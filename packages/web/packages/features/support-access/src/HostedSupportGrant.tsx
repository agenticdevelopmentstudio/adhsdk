"use client";

import { useCallback, useEffect, useRef, useState, type FormEvent, type ReactElement, type ReactNode } from "react";
import { httpStatus } from "@adh-sdk/data";
import {
  accessTable,
  grantState,
  localDay,
  publicSupportApi,
  type SupportAccess,
  type SupportAdminGrant,
} from "@adh-sdk/data/support";
import { Button } from "@adh-sdk/ui/components/button";
import { Input } from "@adh-sdk/ui/components/input";
import { Label } from "@adh-sdk/ui/components/label";
import { ErrorText } from "@adh-sdk/ui/components/error-text";
import { hoursPhrase } from "./GrantCard";
import { tableWords } from "./AccessLogList";

/**
 * The body of the hosted support page, mounted by the hub's and each product site's `/support`:
 * one grant, reached by the link in a support notice email (`/support?grant=<id>&token=<token>`,
 * built by the backend's `supportPageLink`). There is no session here; the token is the only
 * credential. It arrives in the URL, is held by this component from its first props for the life
 * of the mount, and is taken out of the address bar as soon as the load starts; it is never put
 * in storage.
 *
 * Deny and Revoke take the link alone, because refusing access is the easy direction. Approve
 * first asks the backend to email a code to the person's own verified address, and sends the
 * approval only with that code: a forwarded link can refuse, never grant (phase 7 design,
 * section 11; recipe `hub/auth/support-page`).
 *
 * What the backend answers, and what it means here:
 * - GET answers the grant and its latest reads while it is pending or live. Once it is decided
 *   and over it answers 409 `decided`, and a request left undecided for seven days 410 `lapsed`;
 *   a wrong token or id is 404, never 403, so ids cannot be probed. 404, 403 and 410 all show the
 *   one invalid-link sentence, so the page never says which applied.
 * - Deny, Revoke and Approve answer the grant as it now stands, so the new state is drawn from
 *   that answer: a refetch would get the 409 above for a decided grant and lose the detail, and
 *   for an approval it is one more call against the per-address limit.
 * - Approve answers 403 `code_invalid` for a wrong, expired or missing code; the field stays open.
 */

export const INVALID_LINK = "This link is no longer valid.";
export const NO_READS = "No reads yet.";

export type SupportStateLabel = "Pending" | "Live" | "Denied" | "Revoked" | "Expired";

/**
 * The hosted page's state labels. "Ended" is never shown. There is no "Lapsed", unlike the panes'
 * `endedLabel`: a request left undecided until it lapses never reaches this page, because GET
 * answers it with 410 and the page shows the invalid-link sentence.
 */
export function stateLabel(grant: SupportAdminGrant, now: Date = new Date()): SupportStateLabel {
  if (grant.revokedAt) return "Revoked";
  if (grant.decision === "denied") return "Denied";
  const state = grantState(grant, now);
  if (state === "pending") return "Pending";
  if (state === "live") return "Live";
  return "Expired";
}

type View =
  | { kind: "loading" }
  | { kind: "invalid" }
  /** The token matched, but the grant is decided and over: GET's 409. */
  | { kind: "settled" }
  /** The load itself failed (network, outage, rate limit): the link may be fine. */
  | { kind: "load-error"; message: string }
  | { kind: "grant"; grant: SupportAdminGrant; reads: SupportAccess[] };

type Busy = "deny" | "send-code" | "approve" | "revoke" | null;

const code = (err: unknown): string | undefined => {
  const c = (err as { code?: unknown } | null)?.code;
  return typeof c === "string" ? c : undefined;
};

function actionMessage(err: unknown, fallback: string): string {
  const status = httpStatus(err);
  if (status === 429) return "Too many attempts from here. Wait a little while and try again.";
  if (status === 403 && code(err) === "code_invalid") {
    return "That code was not accepted. Check it, or send a new one.";
  }
  return fallback;
}

/** The reads grouped by the viewer's local day, newest day first and newest read first in each. */
export function readsByDay(reads: readonly SupportAccess[]): { day: string; reads: SupportAccess[] }[] {
  // A read whose time does not parse would break the sort and head an "Invalid Date" day: drop it.
  const sorted = reads.filter((r) => !Number.isNaN(Date.parse(r.at))).sort((a, b) => Date.parse(b.at) - Date.parse(a.at));
  const days: { day: string; reads: SupportAccess[] }[] = [];
  for (const read of sorted) {
    const day = localDay(read.at);
    const last = days[days.length - 1];
    if (last && last.day === day) last.reads.push(read);
    else days.push({ day, reads: [read] });
  }
  return days;
}

const dayLabel = (day: string): string =>
  new Date(`${day}T00:00:00`).toLocaleDateString(undefined, {
    weekday: "long",
    year: "numeric",
    month: "long",
    day: "numeric",
  });

const timeLabel = (iso: string): string =>
  new Date(iso).toLocaleTimeString(undefined, { hour: "numeric", minute: "2-digit" });

const whenLabel = (iso: string): string =>
  new Date(iso).toLocaleString(undefined, { dateStyle: "medium", timeStyle: "short" });

function Card({ children }: { children: ReactNode }): ReactElement {
  return (
    <div
      data-testid="hosted-support"
      className="w-full max-w-lg p-8 rounded-2xl"
      style={{ background: "var(--color-surface-container)", border: "1px solid var(--color-outline)" }}
    >
      {children}
    </div>
  );
}

function Heading({ children }: { children: ReactNode }): ReactElement {
  return (
    <h1
      className="mb-2"
      style={{ fontFamily: "var(--font-serif)", fontSize: "2rem", lineHeight: 1.15, color: "var(--color-on-surface)", fontWeight: 400 }}
    >
      {children}
    </h1>
  );
}

function Muted({ children }: { children: ReactNode }): ReactElement {
  return (
    <p className="text-sm" style={{ color: "var(--color-on-surface-variant)" }}>
      {children}
    </p>
  );
}

function ReadLog({ reads }: { reads: readonly SupportAccess[] }): ReactElement {
  const days = readsByDay(reads);
  return (
    <section aria-labelledby="support-read-log" className="mt-6">
      <h2 id="support-read-log" className="text-sm font-medium mb-2" style={{ color: "var(--color-on-surface)" }}>
        What they looked at
      </h2>
      {days.length === 0 ? (
        <Muted>{NO_READS}</Muted>
      ) : (
        days.map((group) => (
          <div key={group.day} className="mb-3" data-testid="support-read-day">
            <h3 className="text-xs font-medium mb-1" style={{ color: "var(--color-on-surface-variant)" }}>
              {dayLabel(group.day)}
            </h3>
            <ul className="text-sm space-y-1" style={{ color: "var(--color-on-surface)" }}>
              {group.reads.map((read) => {
                const where = accessTable(read);
                return (
                  <li key={read.id} data-testid="support-read">
                    {timeLabel(read.at)}
                    {" — "}
                    {read.granteeName ? `${read.granteeName} viewed ` : "Viewed "}
                    {where ? tableWords(where.table) : "your account"}
                  </li>
                );
              })}
            </ul>
          </div>
        ))
      )}
    </section>
  );
}

/** One GET, turned into what the page shows. Never throws. */
async function fetchView(id: string | null, tok: string | null, ecosystemId: string | null): Promise<View> {
  if (!id || !tok) return { kind: "invalid" };
  try {
    const { grant, reads } = await publicSupportApi.get(id, tok);
    // Another product's grant on this host: the same sentence as a bad link, and no action. A
    // grant that names no ecosystem fails closed the same way, whatever the wire type promises.
    if (ecosystemId) {
      const grantEco = typeof grant.ecosystemId === "string" ? grant.ecosystemId.toLowerCase() : "";
      if (grantEco !== ecosystemId.toLowerCase()) return { kind: "invalid" };
    }
    return { kind: "grant", grant, reads };
  } catch (err) {
    const status = httpStatus(err);
    if (status === 404 || status === 403 || status === 410) return { kind: "invalid" };
    if (status === 409) return { kind: "settled" };
    if (status === 429) return { kind: "load-error", message: actionMessage(err, "") };
    return { kind: "load-error", message: "We couldn't load this request. Check your connection and try again." };
  }
}

/**
 * Takes `token` out of the address bar and the history entry once the component holds it. Left
 * there, anyone who later opens that browser profile's history, or a synced one, could reopen
 * the link, read who asked and the read log, and deny or revoke without any further proof.
 * `grant` stays, so the address still says which request this is. A reload after this
 * shows the invalid-link sentence; the email's link opens the page again.
 */
function dropTokenFromAddress(): void {
  if (typeof window === "undefined") return;
  const url = new URL(window.location.href);
  if (!url.searchParams.has("token")) return;
  url.searchParams.delete("token");
  window.history.replaceState(null, "", `${url.pathname}${url.search}${url.hash}`);
}

/**
 * Read once, at mount: a change to any of these after the first render is ignored, so a host
 * keys the component by the link to show another grant.
 */
export interface HostedSupportGrantProps {
  /** The `grant` query value; null or empty shows the invalid-link sentence with no request. */
  grantId: string | null;
  /** The `token` query value; null or empty shows the invalid-link sentence with no request. */
  token: string | null;
  /**
   * The ecosystem the page's host belongs to: a product site passes its product, the hub passes
   * nothing. When given, a grant of any other ecosystem shows the invalid-link sentence and no
   * action, so the page never acts on another product's grant under this product's name.
   * Compared case-insensitively.
   */
  ecosystemId?: string | null;
}

/**
 * The link is read once per mount: the id, token and ecosystem are captured from the first props
 * and later props are ignored, because the page takes the token out of the address bar and a host
 * that reads it from the live query would otherwise re-render with no token and leave every
 * action silently dead. To show another grant, a host keys the component by the link
 * (`key={`${grantId}|${token}`}`), as the hub's and the product sites' `/support` both do.
 */
export function HostedSupportGrant({ grantId, token, ecosystemId }: HostedSupportGrantProps): ReactElement {
  const [{ id, tok, eco }] = useState(() => ({
    id: grantId?.trim() || null,
    tok: token?.trim() || null,
    eco: ecosystemId?.trim() || null,
  }));
  const [view, setView] = useState<View>(() => (id && tok ? { kind: "loading" } : { kind: "invalid" }));
  const [busy, setBusy] = useState<Busy>(null);
  const [codeOpen, setCodeOpen] = useState(false);
  const [codeValue, setCodeValue] = useState("");
  const [actionError, setActionError] = useState<string | null>(null);
  const started = useRef(false);

  const load = useCallback(async (): Promise<void> => {
    setView(await fetchView(id, tok, eco));
  }, [id, tok, eco]);

  useEffect(() => {
    // Once per mount: StrictMode runs effects twice in dev, and each load counts against the
    // backend's per-address limit on these routes. A missing query starts as `invalid` and
    // makes no call at all.
    if (started.current) return;
    started.current = true;
    if (!id || !tok) return;
    dropTokenFromAddress();
    void fetchView(id, tok, eco).then(setView);
  }, [id, tok, eco]);

  /** After an action the backend refused because the grant moved on (409, 410), show where it is now. */
  const settleAfter = async (err: unknown, fallback: string): Promise<void> => {
    const status = httpStatus(err);
    if (status === 409 || status === 410 || status === 404) {
      setCodeOpen(false);
      setActionError(null);
      await load();
      return;
    }
    setActionError(actionMessage(err, fallback));
  };

  const showDecided = (grant: SupportAdminGrant): void => {
    setView((prev) => ({ kind: "grant", grant, reads: prev.kind === "grant" ? prev.reads : [] }));
  };

  const onDeny = async (): Promise<void> => {
    if (!id || !tok) return;
    setBusy("deny");
    setActionError(null);
    try {
      const grant = await publicSupportApi.deny(id, tok);
      setCodeOpen(false);
      showDecided(grant);
    } catch (err) {
      await settleAfter(err, "We couldn't deny this request. Try again.");
    } finally {
      setBusy(null);
    }
  };

  const onRevoke = async (): Promise<void> => {
    if (!id || !tok) return;
    setBusy("revoke");
    setActionError(null);
    try {
      showDecided(await publicSupportApi.revoke(id, tok));
    } catch (err) {
      await settleAfter(err, "We couldn't end this access. Try again.");
    } finally {
      setBusy(null);
    }
  };

  /** Approve's first press, and "Send a new code": email the code, then open the field. */
  const onSendCode = async (): Promise<void> => {
    if (!id || !tok) return;
    setBusy("send-code");
    setActionError(null);
    try {
      await publicSupportApi.sendCode(id, tok);
      setCodeOpen(true);
    } catch (err) {
      await settleAfter(err, "We couldn't send a code. Try again.");
    } finally {
      setBusy(null);
    }
  };

  const onApprove = async (e: FormEvent): Promise<void> => {
    e.preventDefault();
    const entered = codeValue.trim();
    if (!id || !tok || !entered) return;
    setBusy("approve");
    setActionError(null);
    try {
      // Drawn from approve's own answer, as Deny and Revoke are: a refetch would be one more call
      // on the rate-limited public routes, and a 429 or a dropped connection on it would turn an
      // approval that went through into the load-error card.
      const grant = await publicSupportApi.approve(id, tok, entered);
      setCodeOpen(false);
      setCodeValue("");
      showDecided(grant);
    } catch (err) {
      await settleAfter(err, "We couldn't approve this request. Try again.");
    } finally {
      setBusy(null);
    }
  };

  if (view.kind === "loading") {
    return (
      <Card>
        <p role="status" className="text-sm" style={{ color: "var(--color-on-surface-variant)" }}>
          Loading this request…
        </p>
      </Card>
    );
  }

  if (view.kind === "invalid") {
    return (
      <Card>
        <p role="status" className="text-sm" style={{ color: "var(--color-on-surface)" }}>
          {INVALID_LINK}
        </p>
      </Card>
    );
  }

  if (view.kind === "settled") {
    return (
      <Card>
        <Heading>Support access</Heading>
        <p role="status" className="text-sm" style={{ color: "var(--color-on-surface-variant)" }}>
          This request has already been answered, or the access it gave has ended. There is nothing
          left to do with this link. You can see every request in the support section of your account
          settings.
        </p>
      </Card>
    );
  }

  if (view.kind === "load-error") {
    return (
      <Card>
        <ErrorText error={view.message} />
        <div className="mt-4">
          <Button
            type="button"
            variant="outline"
            onClick={() => {
              setView({ kind: "loading" });
              void load();
            }}
          >
            Try again
          </Button>
        </div>
      </Card>
    );
  }

  const { grant, reads } = view;
  const label = stateLabel(grant);
  const asker = `${grant.granteeName}, ${grant.granteeRole}`;

  return (
    <Card>
      <Heading>Support access</Heading>
      <p role="status" aria-live="polite" className="text-sm font-medium mb-4" style={{ color: "var(--color-on-surface)" }}>
        Status: <span data-testid="support-state">{label}</span>
      </p>

      <dl className="text-sm space-y-2" style={{ color: "var(--color-on-surface)" }}>
        <div>
          <dt style={{ color: "var(--color-on-surface-variant)" }}>Who asked</dt>
          <dd>
            {asker}
            {grant.consent === "break_glass" ? " (emergency access, opened without asking first)" : null}
          </dd>
        </div>
        <div>
          <dt style={{ color: "var(--color-on-surface-variant)" }}>Why</dt>
          <dd>{grant.reason}</dd>
        </div>
        <div>
          <dt style={{ color: "var(--color-on-surface-variant)" }}>For how long</dt>
          <dd>
            {hoursPhrase(grant.requestedFor)}
            {label === "Live" && grant.expiresAt ? `, until ${whenLabel(grant.expiresAt)}` : null}
          </dd>
        </div>
        <div>
          <dt style={{ color: "var(--color-on-surface-variant)" }}>Asked</dt>
          <dd>{whenLabel(grant.requestedAt)}</dd>
        </div>
      </dl>

      {label === "Pending" ? (
        <div className="mt-6 space-y-3">
          <div className="flex flex-wrap gap-2">
            <Button type="button" variant="outline" onClick={() => void onDeny()} disabled={busy !== null}>
              Deny
            </Button>
            {codeOpen ? null : (
              <Button type="button" onClick={() => void onSendCode()} disabled={busy !== null}>
                Approve
              </Button>
            )}
          </div>
          {codeOpen ? (
            <form onSubmit={(e) => void onApprove(e)} className="space-y-2">
              <Muted>We emailed you a code. Enter it to approve this request.</Muted>
              <Label htmlFor="support-approve-code">Code</Label>
              <Input
                id="support-approve-code"
                name="code"
                inputMode="numeric"
                autoComplete="one-time-code"
                value={codeValue}
                onChange={(e) => setCodeValue(e.target.value)}
              />
              <div className="flex flex-wrap gap-2">
                <Button type="submit" disabled={busy !== null || codeValue.trim() === ""}>
                  Approve with code
                </Button>
                <Button type="button" variant="ghost" onClick={() => void onSendCode()} disabled={busy !== null}>
                  Send a new code
                </Button>
              </div>
            </form>
          ) : null}
        </div>
      ) : null}

      {label === "Live" ? (
        <div className="mt-6">
          <Button type="button" variant="outline" onClick={() => void onRevoke()} disabled={busy !== null}>
            Revoke
          </Button>
        </div>
      ) : null}

      <ErrorText error={actionError} className="mt-3" />

      <ReadLog reads={reads} />
    </Card>
  );
}

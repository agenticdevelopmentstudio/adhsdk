import {
  authedJson,
  authedRequest,
  listAllV1,
  listV1Page,
  unixToIso,
  withV1Query,
} from "@adh-sdk/auth/client";

/**
 * Every path here carries the `/api` prefix and is a `/v1` route: snake_case on the wire,
 * list envelopes drained with `listAllV1`, updates POSTed. The exported row types stay
 * camelCase; each `from*` mapper below is the one place the wire is translated.
 *
 * `authedJson` takes a FULL path and bakes in no prefix of its own, and `/api` is
 * the Next rewrite that forwards to the backend — inside Hono the route is
 * `/billing/offers`, but nothing in the browser can reach Hono directly. A path
 * written without it resolves against the Next app itself, which has no such
 * route, so the call returns the app's 404 HTML and fails as a JSON parse error
 * naming neither billing nor the missing prefix. Checked against every sibling
 * client in the repo: all of them, in both `@adh-sdk/data` and the
 * feature packages' own `src/api/` directories, spell the prefix out.
 */
const BASE = "/api/v1/billing";

/** What the billing UI needs before it can draw a control. See routes/billing.ts's `/context`. */
export interface BillingContext {
  /** The ACTING ecosystem — the same id every other billing route scopes to, by construction.
   *  Never derive this in the browser; `useWorkspaceDefaultEcosystemId` answers a different
   *  question and the two are not guaranteed to agree. */
  ecosystemId: string;
  billingEnabled: boolean;
  canManage: boolean;
  /**
   * THREE states, and the third is not padding. `unknown` is what the route answers when the
   * Stripe-connection read THREW — a missing or rotated SECRETS_ENCRYPTION_KEY, which is a live
   * degraded condition in this fleet — as distinct from a read that succeeded and found no key.
   * Folding those together is the false, unactionable answer `stripeConnectedFor` returns a
   * boolean specifically to avoid: it sends the operator to re-paste a key that was never the
   * problem, and the status does not change when they do.
   */
  stripeStatus: "connected" | "not_connected" | "unknown";
  /** Origin-relative. Render against `window.location.origin`; adh does not register it with
   *  Stripe, the operator pastes it in. */
  webhookPath: string;
}

/**
 * One offer row, the full shape generic CRUD returns for `billing.offers`.
 *
 * Taken from the TABLE (db/schema/billing.ts:123-186), not from what a pane happened to need:
 * the previous interface omitted `description` and `stripeProductId`, so an editor built on it
 * would have silently dropped both on every save.
 */
export interface OfferRow {
  id: string;
  slug: string;
  name: string;
  description: string | null;
  purpose: "access" | "service" | "goods";
  stripePriceId: string;
  stripeProductId: string | null;
  collectionMethod: "charge_automatically" | "send_invoice";
  daysUntilDue: number | null;
  grantsEcosystemId: string | null;
  lapseAction: "none" | "read_only" | "no_access";
  graceDays: number;
  isActive: boolean;
}

/**
 * What a create or update body may carry: `OfferRow` minus `id`, and minus every masked column.
 *
 * Keeping the masked columns out is THIS client's job, not something the server enforces for it.
 * `crudBodySchemas` (backend/src/adh/src/crud/generate.ts) builds the create body as
 * `createInsertSchema(table).omit(mask)` and the update body as that schema `.partial()` — plain
 * `z.object`s. A plain zod object STRIPS keys it does not declare; it does not reject them. The
 * same backend writes `.strict()` explicitly where it does want a refusal (routes/integrations.ts,
 * routes/projects.ts, llm/connectionSpec.ts, llm/catalog.ts, sync/registry.ts among others), and
 * the CRUD schemas do not.
 *
 * So a body naming `createdAt`, `updatedAt`, `ownerKind`, `ownerId` or `deletedAt` is accepted and
 * quietly discarded — no error to notice, and no signal that the client is sending something it
 * believes is being honoured. `ecosystemId` is the one that is worse: it is `plan.scopeIdProp`,
 * re-extended as optional-but-declared, so it is not stripped at all — it parses, and only
 * `assertWriteWithinScope` stands between a wrong value and a cross-tenant write. It is omitted
 * here because the factory fills it from the caller's scope, which is the only correct value.
 *
 * The consequence of getting this wrong is deferred rather than absent: the day anyone tightens
 * `crudBodySchemas` to `.strict()` — in line with the rest of the backend — every offer UPDATE
 * would start 400ing while creates kept working, a split that looks like a billing bug and is not.
 * `offerToInput` (../OfferDetail.ts) therefore builds the body key by key rather than by
 * subtracting from a row.
 */
export type OfferBody = Omit<OfferRow, "id">;

export interface AccountRow {
  id: string;
  offerId: string;
  stripeCustomerId: string | null;
  /** For a one-off `mode: payment` purchase this is the ONLY Stripe handle the row has — an
   *  operator searching the Stripe dashboard has nothing else. */
  stripeCheckoutSessionId: string | null;
  stripeSubscriptionId: string | null;
  payerEmail: string | null;
  status: string;
  currentPeriodEnd: string | null;
  lapsedAt: string | null;
  claimedCustomerId: string | null;
  claimedAt: string | null;
  createdAt: string;
}

/** One Stripe price, read live. Never cached — the dashboard is the source (spec §1). */
export interface PriceRow {
  id: string;
  productId: string;
  productName: string | null;
  unitAmount: number | null;
  currency: string;
  interval: string | null;
}

/** One row of the webhook ledger. `payload` is deliberately not part of this shape — see the
 *  route: it is unbounded jsonb and it is Stripe's copy rather than ours. */
export interface EventRow {
  id: string;
  stripeEventId: string;
  type: string;
  receivedAt: string;
  processedAt: string | null;
  error: string | null;
}

/** The redrive's counts, rendered verbatim. `nextOffset` is non-null only when the batch came
 *  back full, which is the one case where there may be more. */
export interface RedriveResult {
  examined: number;
  applied: number;
  terminal: number;
  stillPending: number;
  unreadable: number;
  failed: number;
  nextOffset: number | null;
}

export interface ResendClaimResult {
  ok: true;
  accountId: string;
  expiresAt: string;
}

/** What redeeming a claim token binds the caller to. */
export interface ClaimResult {
  ok: true;
  ecosystemId: string;
  offerId: string;
}

const jsonHeaders = { "content-type": "application/json" };

// ── Wire shapes (the /v1 JSON, snake_case) ───────────────────────────────────

interface BillingContextWire {
  ecosystem_id: string;
  billing_enabled: boolean;
  can_manage: boolean;
  stripe_status: BillingContext["stripeStatus"];
  webhook_path: string;
}

interface OfferWire {
  id: string;
  slug: string;
  name: string;
  description: string | null;
  purpose: OfferRow["purpose"];
  stripe_price_id: string;
  stripe_product_id: string | null;
  collection_method: OfferRow["collectionMethod"];
  days_until_due: number | null;
  grants_ecosystem_id: string | null;
  lapse_action: OfferRow["lapseAction"];
  grace_days: number;
  is_active: boolean;
}

interface AccountWire {
  id: string;
  offer_id: string;
  stripe_customer_id: string | null;
  stripe_checkout_session_id: string | null;
  stripe_subscription_id: string | null;
  payer_email: string | null;
  status: string;
  current_period_end: string | null;
  lapsed_at: string | null;
  claimed_customer_id: string | null;
  claimed_at: string | null;
  /** Unix seconds. */
  created: number;
}

interface PriceWire {
  id: string;
  product_id: string;
  product_name: string | null;
  unit_amount: number | null;
  currency: string;
  interval: string | null;
}

interface EventWire {
  id: string;
  stripe_event_id: string;
  type: string;
  received_at: string;
  processed_at: string | null;
  error: string | null;
}

interface RedriveWire {
  examined: number;
  applied: number;
  terminal: number;
  still_pending: number;
  unreadable: number;
  failed: number;
  next_offset: number | null;
}

function fromOffer(w: OfferWire): OfferRow {
  return {
    id: w.id,
    slug: w.slug,
    name: w.name,
    description: w.description,
    purpose: w.purpose,
    stripePriceId: w.stripe_price_id,
    stripeProductId: w.stripe_product_id,
    collectionMethod: w.collection_method,
    daysUntilDue: w.days_until_due,
    grantsEcosystemId: w.grants_ecosystem_id,
    lapseAction: w.lapse_action,
    graceDays: w.grace_days,
    isActive: w.is_active,
  };
}

/** Key by key, never by spreading — see `OfferBody` on why a stray column must not ride along. */
function toOfferWire(b: OfferBody): Omit<OfferWire, "id"> {
  return {
    slug: b.slug,
    name: b.name,
    description: b.description,
    purpose: b.purpose,
    stripe_price_id: b.stripePriceId,
    stripe_product_id: b.stripeProductId,
    collection_method: b.collectionMethod,
    days_until_due: b.daysUntilDue,
    grants_ecosystem_id: b.grantsEcosystemId,
    lapse_action: b.lapseAction,
    grace_days: b.graceDays,
    is_active: b.isActive,
  };
}

function fromAccount(w: AccountWire): AccountRow {
  return {
    id: w.id,
    offerId: w.offer_id,
    stripeCustomerId: w.stripe_customer_id,
    stripeCheckoutSessionId: w.stripe_checkout_session_id,
    stripeSubscriptionId: w.stripe_subscription_id,
    payerEmail: w.payer_email,
    status: w.status,
    currentPeriodEnd: w.current_period_end,
    lapsedAt: w.lapsed_at,
    claimedCustomerId: w.claimed_customer_id,
    claimedAt: w.claimed_at,
    createdAt: unixToIso(w.created),
  };
}

function fromPrice(w: PriceWire): PriceRow {
  return {
    id: w.id,
    productId: w.product_id,
    productName: w.product_name,
    unitAmount: w.unit_amount,
    currency: w.currency,
    interval: w.interval,
  };
}

function fromEvent(w: EventWire): EventRow {
  return {
    id: w.id,
    stripeEventId: w.stripe_event_id,
    type: w.type,
    receivedAt: w.received_at,
    processedAt: w.processed_at,
    error: w.error,
  };
}

export const getBillingContext = async (): Promise<BillingContext> => {
  const w = await authedJson<BillingContextWire>(`${BASE}/context`);
  return {
    ecosystemId: w.ecosystem_id,
    billingEnabled: w.billing_enabled,
    canManage: w.can_manage,
    stripeStatus: w.stripe_status,
    webhookPath: w.webhook_path,
  };
};

export const listOffers = async (): Promise<OfferRow[]> =>
  (await listAllV1<OfferWire>(`${BASE}/offers`)).map(fromOffer);
export const createOffer = async (body: OfferBody): Promise<OfferRow> =>
  fromOffer(
    await authedJson<OfferWire>(`${BASE}/offers`, {
      method: "POST",
      body: JSON.stringify(toOfferWire(body)),
      headers: jsonHeaders,
    }),
  );
// POST, not PUT: /v1 updates are POSTs to the item.
export const updateOffer = async (id: string, body: OfferBody): Promise<OfferRow> =>
  fromOffer(
    await authedJson<OfferWire>(`${BASE}/offers/${id}`, {
      method: "POST",
      body: JSON.stringify(toOfferWire(body)),
      headers: jsonHeaders,
    }),
  );
// A DECLARED tombstone (policy.ts) — the row is soft-deleted, and its slug is freed by the
// partial unique index. Not a hard delete, whatever the verb suggests.
export const deleteOffer = (id: string) => authedRequest(`${BASE}/offers/${id}`, { method: "DELETE" });

export const listAccounts = async (): Promise<AccountRow[]> =>
  (await listAllV1<AccountWire>(`${BASE}/accounts`)).map(fromAccount);
export const resendClaim = async (accountId: string): Promise<ResendClaimResult> => {
  const w = await authedJson<{ ok: true; account_id: string; expires_at: string }>(
    `${BASE}/accounts/${accountId}/resend_claim`,
    { method: "POST" },
  );
  return { ok: w.ok, accountId: w.account_id, expiresAt: w.expires_at };
};

export const listPrices = async (): Promise<PriceRow[]> =>
  (await listAllV1<PriceWire>(`${BASE}/prices`)).map(fromPrice);

/** The newest `limit` ledger rows. The ledger is unbounded, so this walks pages only as far as
 *  `limit` needs rather than draining it with `listAllV1`. */
export const listEvents = async (limit = 200): Promise<EventRow[]> => {
  const rows: EventWire[] = [];
  let after: string | undefined;
  for (;;) {
    const page = await listV1Page<EventWire>(
      withV1Query(`${BASE}/events`, { limit: Math.min(100, limit - rows.length), starting_after: after }),
    );
    rows.push(...page.data);
    const last = page.data[page.data.length - 1];
    if (!page.hasMore || rows.length >= limit || !last) break;
    after = last.id;
  }
  return rows.slice(0, limit).map(fromEvent);
};
export const redriveEvents = async (opts?: {
  includeProcessed?: boolean;
  offset?: number;
}): Promise<RedriveResult> => {
  const url = withV1Query(`${BASE}/events/redrive`, {
    include_processed: opts?.includeProcessed ? true : undefined,
    offset: opts?.offset ? opts.offset : undefined,
  });
  const w = await authedJson<RedriveWire>(url, { method: "POST" });
  return {
    examined: w.examined,
    applied: w.applied,
    terminal: w.terminal,
    stillPending: w.still_pending,
    unreadable: w.unreadable,
    failed: w.failed,
    nextOffset: w.next_offset,
  };
};

/**
 * Redeem a claim token, binding the signed-in identity to a paid account.
 *
 * Requires a session — that is the whole operation, so there is nothing to bind
 * without one, and the route's own 401 on a missing bearer is the signal that
 * sends the visitor to sign in. The caller must keep the token across that
 * round trip rather than losing it in the redirect.
 *
 * The backend answers one 404 for all four failure modes (no such token, already
 * claimed, expired, lost the race). Do not try to tell them apart in the UI:
 * distinguishing them tells a prober which tokens exist, and none of the four is
 * actionable by the claimant anyway — all four mean "ask the operator".
 */
export const claimPurchase = async (token: string): Promise<ClaimResult> => {
  const w = await authedJson<{ ok: true; ecosystem_id: string; offer_id: string }>(
    `${BASE}/accounts/claim`,
    {
      method: "POST",
      body: JSON.stringify({ token }),
      headers: { "content-type": "application/json" },
    },
  );
  return { ok: w.ok, ecosystemId: w.ecosystem_id, offerId: w.offer_id };
};

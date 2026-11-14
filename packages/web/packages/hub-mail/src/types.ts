/**
 * Resolves a backend path (`/sync/pull?…`, `/integrations/me/connections`) to parsed JSON,
 * carrying the caller's bearer token. On an HTTP failure it rejects with an `Error` whose
 * numeric `status` is the response status. The host owns the base URL and the token.
 */
export type FetchJson = (path: string) => Promise<unknown>

/** One of the caller's Gmail connections, as the Email App lists it. */
export interface HubMailAccount {
  /** The connection id. */
  id: string
  /** The connection's username, else its display name, else its id. */
  email: string
  /** active | error | revoked | pending */
  status: string
  lastError: string | null
}

/** A message as a mailbox list shows it. */
export interface HubMailMessageSummary {
  id: string
  /** The connection id the message belongs to. */
  account: string
  threadId: string | null
  from: string | null
  to: string[]
  cc: string[]
  subject: string | null
  snippet: string | null
  /** The message's `internal_date` (ISO-8601), or null. */
  date: string | null
  labelIds: string[]
}

/** A message with its full body. */
export interface HubMailMessage extends HubMailMessageSummary {
  bodyText: string | null
  bodyHtml: string | null
}

/** The reads the web Email App needs. */
export interface HubMailClient {
  accounts(): Promise<HubMailAccount[]>
  messages(account: string, limit?: number): Promise<HubMailMessageSummary[]>
  message(account: string, id: string): Promise<HubMailMessage | null>
  /** Pulls what changed since the last pull. */
  refresh(): Promise<void>
  /** Drops everything held, so the next read pulls from the start (sign-out). */
  reset(): void
}

/** One change in a `/sync/pull` page. */
export interface HubSyncChange {
  resource: string
  id: string
  op: 'upsert' | 'delete'
  syncVersion: string
  data?: Record<string, unknown>
}

/** The `/sync/pull` envelope. */
export interface HubSyncPullPage {
  changes: HubSyncChange[]
  cursor: string
  hasMore: boolean
}

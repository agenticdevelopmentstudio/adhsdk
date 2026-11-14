import type { HubMailMessage, HubMailMessageSummary, HubSyncChange } from './types'

export const MESSAGES_RESOURCE = 'integration.integration_email_messages'
export const LABELS_RESOURCE = 'integration.integration_email_labels'

type Row = Record<string, unknown>

/** The Gmail rows read from `/sync/pull`, keyed by row id, held in memory only. */
export class MailSnapshot {
  private readonly messages = new Map<string, Row>()
  private readonly labels = new Map<string, Row>()

  /** Applies one change; changes for any other resource are ignored. */
  apply(change: HubSyncChange): void {
    const table =
      change.resource === MESSAGES_RESOURCE
        ? this.messages
        : change.resource === LABELS_RESOURCE
          ? this.labels
          : undefined
    if (!table) return
    if (change.op === 'delete') table.delete(change.id)
    else table.set(change.id, { ...(change.data ?? {}), id: change.id })
  }

  clear(): void {
    this.messages.clear()
    this.labels.clear()
  }

  /** The connection's live messages, newest first, undated last, ties by id descending. */
  list(account: string, limit: number): HubMailMessageSummary[] {
    const rows = [...this.messages.values()].filter(
      (row) => isLive(row) && row.connection_id === account,
    )
    rows.sort(compareNewestFirst)
    return rows.slice(0, Math.max(1, limit)).map(summary)
  }

  /** The connection's live message with that id, or null. */
  find(account: string, id: string): HubMailMessage | null {
    const row = this.messages.get(id)
    if (!row || !isLive(row) || row.connection_id !== account) return null
    return { ...summary(row), bodyText: text(row.body_text), bodyHtml: text(row.body_html) }
  }
}

function isLive(row: Row): boolean {
  return row.deleted_at == null && row.is_deleted !== true
}

function compareNewestFirst(a: Row, b: Row): number {
  const da = text(a.internal_date)
  const db = text(b.internal_date)
  if (da !== db) {
    if (da === null) return 1
    if (db === null) return -1
    return da < db ? 1 : -1
  }
  const ia = String(a.id)
  const ib = String(b.id)
  return ia === ib ? 0 : ia < ib ? 1 : -1
}

function summary(row: Row): HubMailMessageSummary {
  return {
    id: String(row.id),
    account: String(row.connection_id),
    threadId: text(row.thread_id),
    from: text(row.from_address),
    to: list(row.to_addresses),
    cc: list(row.cc_addresses),
    subject: text(row.subject),
    snippet: text(row.snippet),
    date: text(row.internal_date),
    labelIds: list(row.label_ids),
  }
}

function text(value: unknown): string | null {
  return typeof value === 'string' ? value : null
}

function list(value: unknown): string[] {
  return Array.isArray(value) ? value.filter((v): v is string => typeof v === 'string') : []
}

import { MailSnapshot } from './snapshot'
import type {
  FetchJson,
  HubMailAccount,
  HubMailClient,
  HubMailMessage,
  HubMailMessageSummary,
  HubSyncPullPage,
} from './types'

export interface HubMailClientOptions {
  fetchJson: FetchJson
  /** The `limit` sent to `/sync/pull`; the hub clamps it to 1..1000. */
  pageSize?: number
}

const DEFAULT_PAGE_SIZE = 500
const DEFAULT_MESSAGE_LIMIT = 50

interface ConnectionRow {
  id: string
  provider?: string
  serviceType?: string
  status?: string
  displayName?: string
  username?: string
  lastError?: string | null
}

/**
 * Reads the caller's hub-synced Gmail through the hub API, holding what it read in memory
 * for the life of the page (no local database, nothing persisted).
 */
export function createHubMailClient(options: HubMailClientOptions): HubMailClient {
  const { fetchJson } = options
  const pageSize = options.pageSize ?? DEFAULT_PAGE_SIZE
  const snapshot = new MailSnapshot()
  let cursor = ''
  let pulled = false
  let inFlight: Promise<void> | null = null

  async function pullPages(): Promise<void> {
    for (;;) {
      const page = (await fetchJson(
        `/sync/pull?cursor=${encodeURIComponent(cursor)}&limit=${pageSize}`,
      )) as HubSyncPullPage
      for (const change of page.changes) snapshot.apply(change)
      cursor = page.cursor
      if (!page.hasMore) return
    }
  }

  async function pull(): Promise<void> {
    try {
      await pullPages()
    } catch (err) {
      if (statusOf(err) !== 410) throw err
      snapshot.clear()
      cursor = ''
      await pullPages()
    }
    pulled = true
  }

  function sharedPull(): Promise<void> {
    if (!inFlight) {
      inFlight = pull().finally(() => {
        inFlight = null
      })
    }
    return inFlight
  }

  async function ensurePulled(): Promise<void> {
    if (!pulled || inFlight) await sharedPull()
  }

  return {
    async accounts(): Promise<HubMailAccount[]> {
      const body = (await fetchJson('/integrations/me/connections')) as {
        connections?: ConnectionRow[]
      }
      return (body.connections ?? [])
        .filter((c) => c.provider === 'gmail' && c.serviceType === 'messages')
        .map((c) => ({
          id: c.id,
          email: c.username || c.displayName || c.id,
          status: c.status ?? 'active',
          lastError: c.lastError ?? null,
        }))
    },

    async messages(account: string, limit = DEFAULT_MESSAGE_LIMIT): Promise<HubMailMessageSummary[]> {
      await ensurePulled()
      return snapshot.list(account, limit)
    },

    async message(account: string, id: string): Promise<HubMailMessage | null> {
      await ensurePulled()
      return snapshot.find(account, id)
    },

    refresh(): Promise<void> {
      return sharedPull()
    },

    reset(): void {
      snapshot.clear()
      cursor = ''
      pulled = false
    },
  }
}

function statusOf(err: unknown): number | undefined {
  if (!(err instanceof Error)) return undefined
  const status = (err as { status?: unknown }).status
  return typeof status === 'number' ? status : undefined
}

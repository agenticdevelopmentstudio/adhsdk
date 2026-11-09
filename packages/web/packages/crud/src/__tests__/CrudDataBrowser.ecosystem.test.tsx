import '@testing-library/jest-dom/vitest'
import { describe, it, expect, vi } from 'vitest'
import { render, screen, waitFor } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import type { AuthUser } from '@adh-sdk/auth'
import type { CrudColumn, CrudTableMeta } from '../types'
import type { CrudShellProps } from '../CrudDataBrowser'

// An ecosystem's Storage ▸ All Data scoped its LIST to that ecosystem but not its writes: a row
// created there was stamped with the caller's JWT ecosystem (every hub JWT is ecosystem zero), and
// the re-list, filtered to this ecosystem, dropped it. The REAL editor is mounted here, because
// the write it sends is what is under test.

const ECO = 'ecosystem.ads.ape'
/** A non-admin: an owner-tier table is theirs to write. */
const member = { id: 'u1', email: 'u@example.com', capabilities: [] as string[] } as AuthUser

vi.mock('next/navigation', () => ({ useRouter: () => ({ push: vi.fn() }) }))
vi.mock('@adh-sdk/auth', async (importOriginal) => ({
  ...(await importOriginal<typeof import('@adh-sdk/auth')>()),
  useOptionalAuth: () => ({ user: member, isLoading: false }),
  useAuth: () => ({ user: member, isLoading: false }),
}))
// The has-rows probe and the editor both reach the network through this client. The real module
// underneath supplies AuthHttpError, which the probe tells a refusal from a failure by.
vi.mock('@adh-sdk/auth/client', async (importOriginal) => ({
  ...(await importOriginal<typeof import('@adh-sdk/auth/client')>()),
  authedJson: vi.fn(),
  listAllV1: vi.fn(),
}))

const { authedJson, listAllV1 } = vi.mocked(await import('@adh-sdk/auth/client'))
const { CrudDataBrowser } = await import('../CrudDataBrowser')

const col = (name: string, overrides: Partial<CrudColumn> = {}): CrudColumn => ({
  name,
  type: 'string',
  required: false,
  nullable: false,
  serverManaged: false,
  ...overrides,
})

const BUCKETS: CrudTableMeta = {
  key: 'bucket/buckets',
  schema: 'bucket',
  table: 'buckets',
  basePath: '/v1/bucket/buckets',
  itemPath: '/v1/bucket/buckets/{id}',
  pkParams: ['id'],
  exposure: 'owner',
  columns: [col('id', { serverManaged: true }), col('ecosystem_id'), col('name')],
}

/** The rail is not under test here; the shell only has to render the open table's editor. */
function RailProbe({ children }: CrudShellProps) {
  return <div>{children}</div>
}

describe('CrudDataBrowser scoped to an ecosystem', () => {
  it('creates a new row in that ecosystem, not the caller’s', async () => {
    // Lists walk the collection through listAllV1; the create is the one authedJson call.
    listAllV1.mockResolvedValue([{ id: 'b1', ecosystem_id: ECO, name: 'Existing' }] as never)
    authedJson.mockResolvedValue({ id: 'b2', ecosystem_id: ECO, name: 'Fresh' } as never)
    const user = userEvent.setup()
    render(
      <CrudDataBrowser
        basePath="/w/all-data"
        tables={[BUCKETS]}
        shell={RailProbe}
        workspace="w"
        ecosystemId={ECO}
        activeSchema="bucket"
        activeTable="buckets"
      />,
    )
    await screen.findByText('Existing')
    await user.click(screen.getByRole('button', { name: 'Create' }))
    await user.type(await screen.findByLabelText('name'), 'Fresh')
    // The surface has already decided the ecosystem, so the new row's form does not offer it.
    expect(screen.queryByLabelText('ecosystem_id')).not.toBeInTheDocument()
    await user.click(screen.getByRole('button', { name: 'Save' }))

    // Named on the URL (the scope the backend authorizes the write against) AND in the body (the
    // row's own column), so the re-list, filtered to this ecosystem, finds the row it just made.
    // The workspace rides too: it is the owner the backend stamps a create with.
    await waitFor(() =>
      expect(authedJson).toHaveBeenCalledWith(
        `/api/v1/bucket/buckets?ecosystem_id=${ECO}&workspace=w`,
        expect.objectContaining({ method: 'POST' }),
      ),
    )
    const post = authedJson.mock.calls.find(([, init]) => init?.method === 'POST')
    expect(JSON.parse(String(post?.[1]?.body))).toEqual({ ecosystem_id: ECO, name: 'Fresh' })
  })
})

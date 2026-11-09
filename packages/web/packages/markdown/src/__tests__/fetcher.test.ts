import { describe, it, expect, vi, afterEach } from 'vitest'
import { defaultMarkdownFetcher } from '../hooks/useMarkdownDocument'

// Helpers — build minimal Response-shaped mocks without a real DOM.
function makeOkResponse(body: unknown): Response {
  return {
    ok: true,
    status: 200,
    headers: { get: (_k: string) => null } as unknown as Headers,
    json: async () => body,
    text: async () => JSON.stringify(body),
  } as unknown as Response
}

function makeErrorResponse(
  status: number,
  contentType: string | null,
  body: string,
): Response {
  return {
    ok: false,
    status,
    headers: { get: (k: string) => (k === 'content-type' ? contentType : null) } as unknown as Headers,
    json: async () => JSON.parse(body),
    text: async () => body,
  } as unknown as Response
}

afterEach(() => {
  vi.unstubAllGlobals()
})

describe('defaultMarkdownFetcher', () => {
  it('resolves to the JSON body on an ok response', async () => {
    const wire = {
      object: 'paper',
      id: 'abc',
      owner_kind: 'customer',
      owner_id: 'c1',
      ecosystem_id: 'e1',
      title: 'Test doc',
      content: '# Hello',
      tags: ['a'],
      visibility: 'private',
      stage: 'draft',
      kind: 'paper',
      content_hash: 'h',
      size_bytes: 7,
      current_version: 2,
      created: 1767323045,
      updated: 1767323046,
      is_deleted: false,
    }
    const fetchMock = vi.fn().mockResolvedValue(makeOkResponse(wire))
    vi.stubGlobal('fetch', fetchMock)

    const signal = new AbortController().signal
    const result = await defaultMarkdownFetcher('abc', signal)

    expect(fetchMock.mock.calls[0]![0]).toBe('/api/v1/papers/abc')
    expect(result).toMatchObject({
      id: 'abc',
      ownerKind: 'customer',
      ownerId: 'c1',
      ecosystemId: 'e1',
      title: 'Test doc',
      content: '# Hello',
      contentHash: 'h',
      sizeBytes: 7,
      currentVersion: 2,
      createdAt: '2026-01-02T03:04:05.000Z',
      updatedAt: '2026-01-02T03:04:06.000Z',
      isDeleted: false,
    })
  })

  it('rejects with the message of a /v1 error body', async () => {
    const body = JSON.stringify({ error: { type: 'invalid_request_error', code: 'bad', message: 'Nope.' } })
    vi.stubGlobal('fetch', vi.fn().mockResolvedValue(makeErrorResponse(400, 'application/json', body)))

    const signal = new AbortController().signal
    await expect(defaultMarkdownFetcher('x', signal)).rejects.toThrow('Nope.')
  })

  // body-read-once path: the fetcher reads the body as text and then parses
  // problem+json from that string — no double-read on the Response stream.
  it('rejects with a "title — detail" message for problem+json errors', async () => {
    const body = JSON.stringify({ title: 'Bad', detail: 'nope' })
    vi.stubGlobal(
      'fetch',
      vi.fn().mockResolvedValue(
        makeErrorResponse(422, 'application/problem+json', body),
      ),
    )

    const signal = new AbortController().signal
    await expect(defaultMarkdownFetcher('x', signal)).rejects.toThrow('Bad — nope')
  })

  it('rejects with "Document not found" for a 404', async () => {
    vi.stubGlobal(
      'fetch',
      vi.fn().mockResolvedValue(makeErrorResponse(404, null, '')),
    )

    const signal = new AbortController().signal
    await expect(defaultMarkdownFetcher('missing', signal)).rejects.toThrow(
      'Document not found',
    )
  })
})

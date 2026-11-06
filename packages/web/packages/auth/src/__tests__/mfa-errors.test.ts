import { afterEach, describe, expect, it, vi } from 'vitest'

vi.mock('@simplewebauthn/browser', () => ({
  startAuthentication: vi.fn(async () => ({ id: 'cred' })),
}))

import { AuthHttpError } from '../client'
import {
  completeLoginCode,
  completeLoginPasskey,
  passwordlessPasskeyLogin,
  requestLoginSms,
} from '../mfa'
import { reportUnexpectedAuthError, setAuthErrorReporter } from '../report'

function respond(status: number, body: unknown): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { 'Content-Type': 'application/json' },
  })
}

function stubFetch(...responses: Response[]): void {
  const queue = [...responses]
  vi.stubGlobal('fetch', vi.fn(async () => queue.shift() ?? respond(500, {})))
}

async function rejection(promise: Promise<unknown>): Promise<unknown> {
  try {
    await promise
  } catch (err) {
    return err
  }
  throw new Error('expected a rejection')
}

afterEach(() => {
  setAuthErrorReporter(null)
  vi.unstubAllGlobals()
  vi.restoreAllMocks()
})

// A login-step failure the server answers with a 4xx is the user's (no passkey on
// the account, a mistyped code), and LoginCard's reportUnexpectedAuthError gate
// drops it by its `.status`. A plain Error carries no status, so the gate used to
// report every one of them to GlitchTip ("no passkey is available for this account").
describe('MFA login steps throw AuthHttpError carrying the HTTP status', () => {
  it('passwordless passkey: a 4xx from the options step', async () => {
    stubFetch(respond(404, { error: 'no passkey is available for this account' }))
    const err = await rejection(passwordlessPasskeyLogin('someone@example.com'))
    expect(err).toBeInstanceOf(AuthHttpError)
    expect(err).toMatchObject({ status: 404, message: 'no passkey is available for this account' })
  })

  it('passwordless passkey: a 4xx from the verify step', async () => {
    stubFetch(respond(200, { options: {}, token: 't' }), respond(401, { error: 'bad assertion' }))
    const err = await rejection(passwordlessPasskeyLogin('someone@example.com'))
    expect(err).toMatchObject({ status: 401, message: 'bad assertion' })
  })

  it('second-factor passkey, sms send and typed code', async () => {
    stubFetch(respond(400, {}))
    expect(await rejection(completeLoginPasskey('t'))).toMatchObject({
      status: 400,
      message: 'Could not start the passkey check.',
    })
    stubFetch(respond(429, {}))
    expect(await rejection(requestLoginSms('t'))).toMatchObject({ status: 429 })
    stubFetch(respond(400, { error: 'wrong code' }))
    expect(await rejection(completeLoginCode('t', 'totp', '000000'))).toMatchObject({
      status: 400,
      message: 'wrong code',
    })
  })

  it('so the report gate drops a 4xx and still reports a 5xx', async () => {
    vi.spyOn(console, 'error').mockImplementation(() => {})
    const sink = vi.fn()
    setAuthErrorReporter(sink)

    stubFetch(respond(404, { error: 'no passkey is available for this account' }))
    reportUnexpectedAuthError(await rejection(passwordlessPasskeyLogin('a@example.com')))
    expect(sink).not.toHaveBeenCalled()

    stubFetch(respond(503, {}))
    reportUnexpectedAuthError(await rejection(passwordlessPasskeyLogin('b@example.com')))
    expect(sink).toHaveBeenCalledTimes(1)
  })
})

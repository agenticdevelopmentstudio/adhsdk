// @vitest-environment jsdom
import { render, screen, fireEvent, cleanup, waitFor } from '@testing-library/react'
import { describe, it, expect, afterEach, vi } from 'vitest'
import { ClientAuthSettingsPane } from './ClientAuthSettingsPane'
import { clientAuthApi, type EcosystemClientAuth } from '@adh-sdk/data/ecosystem-config'

vi.mock('@adh-sdk/data/ecosystem-config', () => ({
  clientAuthApi: {
    ecosystem: vi.fn(),
    updateEcosystem: vi.fn(),
  },
}))

const PROVIDERS = [
  { slug: 'github', name: 'GitHub' },
  { slug: 'google', name: 'Google' },
]

function config(over: Partial<EcosystemClientAuth['settings']> = {}): EcosystemClientAuth {
  return {
    settings: {
      signupMode: 'invite_only',
      loginEnabled: true,
      passwordEnabled: true,
      allowedProviders: null,
      loginAllowedEmails: null,
      ...over,
    },
    registration: null,
    providers: PROVIDERS,
  }
}

// Each test reads a different ecosystem: the item cache is shared across tests in this file.
let n = 0
async function renderPane(loaded: EcosystemClientAuth) {
  const id = `eco${++n}`
  vi.mocked(clientAuthApi.ecosystem).mockResolvedValue(loaded)
  vi.mocked(clientAuthApi.updateEcosystem).mockImplementation(async (_id, update) => ({
    ...loaded,
    settings: { ...loaded.settings, ...update.settings },
  }))
  render(<ClientAuthSettingsPane ecosystemId={id} />)
  await screen.findByRole('switch', { name: 'Email and password' })
  return id
}

const save = () => fireEvent.click(screen.getByRole('button', { name: 'Save' }))
const putBody = () => vi.mocked(clientAuthApi.updateEcosystem).mock.calls[0]?.[1]

// A base-ui Switch labels both its role="switch" span and a hidden checkbox, so it is found by role.
const sw = (name: string) => screen.getByRole('switch', { name })

afterEach(() => {
  cleanup()
  vi.clearAllMocks()
})

describe('ClientAuthSettingsPane', () => {
  it('sends only the policy fields that changed', async () => {
    const id = await renderPane(config())
    fireEvent.click(sw('Email and password'))
    fireEvent.change(screen.getByLabelText('Sign-up mode'), { target: { value: 'closed' } })
    save()
    await waitFor(() => expect(clientAuthApi.updateEcosystem).toHaveBeenCalledTimes(1))
    expect(vi.mocked(clientAuthApi.updateEcosystem).mock.calls[0]?.[0]).toBe(id)
    expect(putBody()).toEqual({ settings: { passwordEnabled: false, signupMode: 'closed' } })
  })

  it('turns one provider off into the list of the rest', async () => {
    await renderPane(config())
    fireEvent.click(sw('Google'))
    save()
    await waitFor(() => expect(clientAuthApi.updateEcosystem).toHaveBeenCalled())
    expect(putBody()?.settings).toEqual({ allowedProviders: ['github'] })
  })

  it('sends null, not the full list, when every provider is on', async () => {
    await renderPane(config({ allowedProviders: ['github'] }))
    fireEvent.click(sw('Google'))
    save()
    await waitFor(() => expect(clientAuthApi.updateEcosystem).toHaveBeenCalled())
    expect(putBody()?.settings).toEqual({ allowedProviders: null })
  })

  it('will not turn the last provider off', async () => {
    await renderPane(config({ allowedProviders: ['github'] }))
    expect(sw('GitHub')).toHaveAttribute('data-disabled')
    expect(sw('Google')).not.toHaveAttribute('data-disabled')
  })

  // Each application has its own login registration: the ecosystem's is neither shown nor sent.
  it('shows no login registration, even when the ecosystem still has one', async () => {
    await renderPane({
      ...config(),
      registration: { clientId: 'cid_1', allowedReturnOrigins: ['https://a.com'], redirectUris: [] },
    })
    expect(screen.queryByText('Login registration')).toBeNull()
    expect(screen.queryByDisplayValue('cid_1')).toBeNull()
    fireEvent.click(sw('Email and password'))
    save()
    await waitFor(() => expect(clientAuthApi.updateEcosystem).toHaveBeenCalled())
    expect(putBody()).not.toHaveProperty('registration')
  })
})

describe('ClientAuthSettingsPane: who can sign in', () => {
  const ALICE = 'alice@example.com'
  const BOB = 'bob@example.com'
  const emailInputs = () => screen.queryAllByPlaceholderText('name@example.com') as HTMLInputElement[]
  const addPerson = () => fireEvent.click(screen.getByRole('button', { name: 'Add person' }))

  it('starts as everyone, with no list drawn', async () => {
    await renderPane(config())
    expect(sw('Only listed people')).not.toHaveAttribute('data-checked')
    expect(emailInputs()).toHaveLength(0)
    expect(screen.getByText('Everyone can sign in.')).toBeInTheDocument()
  })

  it('turned on and left blank, sends an empty list: nobody', async () => {
    await renderPane(config())
    fireEvent.click(sw('Only listed people'))
    expect(emailInputs()).toHaveLength(1)
    save()
    await waitFor(() => expect(clientAuthApi.updateEcosystem).toHaveBeenCalled())
    expect(putBody()?.settings).toEqual({ loginAllowedEmails: [] })
  })

  it('sends the listed emails trimmed and lowercased, without blanks or duplicates', async () => {
    await renderPane(config())
    fireEvent.click(sw('Only listed people'))
    fireEvent.change(emailInputs()[0]!, { target: { value: `  ${ALICE} ` } })
    addPerson()
    addPerson()
    addPerson()
    fireEvent.change(emailInputs()[1]!, { target: { value: BOB } })
    fireEvent.change(emailInputs()[3]!, { target: { value: 'Alice@Example.com' } })
    save()
    await waitFor(() => expect(clientAuthApi.updateEcosystem).toHaveBeenCalled())
    expect(putBody()?.settings).toEqual({ loginAllowedEmails: [ALICE, BOB] })
  })

  it('shows a saved list, and turning it off sends null: everyone', async () => {
    await renderPane(config({ loginAllowedEmails: [ALICE] }))
    expect(emailInputs().map((i) => i.value)).toEqual([ALICE])
    fireEvent.click(sw('Only listed people'))
    expect(emailInputs()).toHaveLength(0)
    save()
    await waitFor(() => expect(clientAuthApi.updateEcosystem).toHaveBeenCalled())
    expect(putBody()?.settings).toEqual({ loginAllowedEmails: null })
  })

  it('ecosystem-config-037: fails the save, keeping the list, when the backend drops it', async () => {
    const loaded = config()
    await renderPane(loaded)
    // A backend without the allow-list strips the unknown field and answers 200.
    vi.mocked(clientAuthApi.updateEcosystem).mockImplementation(async (_id, update) => {
      const { loginAllowedEmails: _dropped, ...kept } = update.settings ?? {}
      return { ...loaded, settings: { ...loaded.settings, ...kept } }
    })
    fireEvent.click(sw('Only listed people'))
    fireEvent.change(emailInputs()[0]!, { target: { value: ALICE } })
    save()
    expect(await screen.findByText(/sign-in list was not saved/)).toBeInTheDocument()
    expect(sw('Only listed people')).toHaveAttribute('data-checked')
    expect(emailInputs().map((i) => i.value)).toEqual([ALICE])
  })

  it('a blank row added to a saved list is not an edit', async () => {
    await renderPane(config({ loginAllowedEmails: [ALICE] }))
    addPerson()
    expect(emailInputs()).toHaveLength(2)
    expect(screen.getByRole('button', { name: 'Save' })).toBeDisabled()
  })

  it('ecosystem-config-032: refuses an entry that is not an email address, before the round trip', async () => {
    await renderPane(config())
    fireEvent.click(sw('Only listed people'))
    fireEvent.change(emailInputs()[0]!, { target: { value: 'alice' } })
    expect(screen.getByText('"alice" is not an email address.')).toBeInTheDocument()
    save()
    expect(clientAuthApi.updateEcosystem).not.toHaveBeenCalled()
  })

  it('ecosystem-config-032: refuses a 501st email, and Save stays blocked', async () => {
    const many = Array.from({ length: 500 }, (_, i) => `p${i}@example.com`)
    await renderPane(config({ loginAllowedEmails: many }))
    addPerson()
    fireEvent.change(emailInputs()[500]!, { target: { value: 'extra@example.com' } })
    expect(screen.getByText('At most 500 people can be listed.')).toBeInTheDocument()
    save()
    expect(clientAuthApi.updateEcosystem).not.toHaveBeenCalled()
  })

  it('Cancel puts the saved rows back', async () => {
    await renderPane(config({ loginAllowedEmails: [ALICE] }))
    fireEvent.change(emailInputs()[0]!, { target: { value: BOB } })
    fireEvent.click(screen.getByRole('button', { name: 'Cancel' }))
    await waitFor(() => expect(emailInputs().map((i) => i.value)).toEqual([ALICE]))
  })
})

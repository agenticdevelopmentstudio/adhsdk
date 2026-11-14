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
      loginAllowedCustomerIds: null,
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
  const ALICE = '0b6f3c1e-2a4d-4e5f-8a9b-0c1d2e3f4a5b'
  const BOB = '1c7a4d2f-3b5e-4f60-9bac-1d2e3f4a5b6c'
  const idInputs = () => screen.queryAllByPlaceholderText('Customer id') as HTMLInputElement[]
  const addCustomer = () => fireEvent.click(screen.getByRole('button', { name: 'Add customer' }))

  it('starts as everyone, with no customer list drawn', async () => {
    await renderPane(config())
    expect(sw('Only listed customers')).not.toHaveAttribute('data-checked')
    expect(idInputs()).toHaveLength(0)
    expect(screen.getByText('Every customer can sign in.')).toBeInTheDocument()
  })

  it('turned on and left blank, sends an empty list: nobody', async () => {
    await renderPane(config())
    fireEvent.click(sw('Only listed customers'))
    expect(idInputs()).toHaveLength(1)
    save()
    await waitFor(() => expect(clientAuthApi.updateEcosystem).toHaveBeenCalled())
    expect(putBody()?.settings).toEqual({ loginAllowedCustomerIds: [] })
  })

  it('sends the listed ids trimmed, without blanks or duplicates', async () => {
    await renderPane(config())
    fireEvent.click(sw('Only listed customers'))
    fireEvent.change(idInputs()[0]!, { target: { value: `  ${ALICE} ` } })
    addCustomer()
    addCustomer()
    addCustomer()
    fireEvent.change(idInputs()[1]!, { target: { value: BOB } })
    fireEvent.change(idInputs()[3]!, { target: { value: ALICE } })
    save()
    await waitFor(() => expect(clientAuthApi.updateEcosystem).toHaveBeenCalled())
    expect(putBody()?.settings).toEqual({ loginAllowedCustomerIds: [ALICE, BOB] })
  })

  it('shows a saved list, and turning it off sends null: everyone', async () => {
    await renderPane(config({ loginAllowedCustomerIds: [ALICE] }))
    expect(idInputs().map((i) => i.value)).toEqual([ALICE])
    fireEvent.click(sw('Only listed customers'))
    expect(idInputs()).toHaveLength(0)
    save()
    await waitFor(() => expect(clientAuthApi.updateEcosystem).toHaveBeenCalled())
    expect(putBody()?.settings).toEqual({ loginAllowedCustomerIds: null })
  })

  it('a blank row added to a saved list is not an edit', async () => {
    await renderPane(config({ loginAllowedCustomerIds: [ALICE] }))
    addCustomer()
    expect(idInputs()).toHaveLength(2)
    expect(screen.getByRole('button', { name: 'Save' })).toBeDisabled()
  })

  it('refuses an id too long to be a customer id, before the round trip', async () => {
    await renderPane(config())
    fireEvent.click(sw('Only listed customers'))
    fireEvent.change(idInputs()[0]!, { target: { value: 'x'.repeat(37) } })
    expect(screen.getByText(/is not a customer id/)).toBeInTheDocument()
    save()
    expect(clientAuthApi.updateEcosystem).not.toHaveBeenCalled()
  })

  it('Cancel puts the saved rows back', async () => {
    await renderPane(config({ loginAllowedCustomerIds: [ALICE] }))
    fireEvent.change(idInputs()[0]!, { target: { value: BOB } })
    fireEvent.click(screen.getByRole('button', { name: 'Cancel' }))
    await waitFor(() => expect(idInputs().map((i) => i.value)).toEqual([ALICE]))
  })
})

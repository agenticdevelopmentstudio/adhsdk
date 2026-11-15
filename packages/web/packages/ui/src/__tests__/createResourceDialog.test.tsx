/**
 * CreateResourceDialog conformance vectors (create-resource-001 .. 034): rendering, the dirty/
 * pristine Save gate, the save flow (validate / create / onCreated / onSaveError), and the close
 * guard. `createResourceDialogExit.test.tsx` goes deeper on the guard's alert; this file pins every
 * vector in `conformance-test-vectors.md` to a test.
 */
import { renderToString } from 'react-dom/server'
import { act, cleanup, fireEvent, render, screen, waitFor, within } from '@testing-library/react'
import type { ReactNode } from 'react'
import { afterEach, describe, expect, it, vi } from 'vitest'
import { CreateResourceDialog } from '../blocks/create-resource-dialog'

interface Draft {
  text: string
}
interface Result {
  id: string
}

interface Options {
  heading?: string
  ariaLabel?: string
  validate?: (d: Draft) => string | null
  create?: (d: Draft) => Promise<Result>
  saveEnabled?: (d: Draft) => boolean
  onSaveError?: (e: unknown) => void
}

function build(opts: Options = {}) {
  const onClose = vi.fn()
  const onCreated = vi.fn()
  const create = vi.fn(opts.create ?? (async (): Promise<Result> => ({ id: '1' })))
  const validate = vi.fn(opts.validate ?? ((d: Draft) => (d.text.trim() ? null : 'Required')))
  const renderForm = vi.fn(
    (draft: Draft, onChange: (next: Draft) => void, _error: string | null): ReactNode => (
      <input
        aria-label="Text"
        value={draft.text}
        onChange={(e) => onChange({ text: e.target.value })}
      />
    ),
  )
  const ui = (
    <CreateResourceDialog<Draft, Result>
      ariaLabel={opts.ariaLabel ?? 'New Thing'}
      heading={opts.heading ?? 'New Thing'}
      blank={() => ({ text: '' })}
      validate={validate}
      create={create}
      onClose={onClose}
      onCreated={onCreated}
      renderForm={renderForm}
      saveEnabled={opts.saveEnabled}
      onSaveError={opts.onSaveError}
    />
  )
  return { ui, onClose, onCreated, create, validate, renderForm }
}

function mount(opts: Options = {}) {
  const b = build(opts)
  render(b.ui)
  return b
}

const typeText = (value = 'a draft') =>
  fireEvent.change(screen.getByRole('textbox', { name: 'Text' }), { target: { value } })
const saveButton = () => screen.getByRole('button', { name: /^Sav/ })
const cancelButton = () => screen.getByRole('button', { name: 'Cancel' })
const lastError = (renderForm: ReturnType<typeof build>['renderForm']) =>
  renderForm.mock.calls.at(-1)![2]
const mainDialog = () => document.body.querySelector<HTMLElement>('[role="dialog"][aria-label="New Thing"]')

afterEach(cleanup)

type Listener = (...args: unknown[]) => void
const proc = (
  globalThis as unknown as {
    process: {
      listeners(e: string): Listener[]
      removeAllListeners(e: string): void
      on(e: string, l: Listener): void
      removeListener(e: string, l: Listener): void
    }
  }
).process

describe('CreateResourceDialog — rendering', () => {
  it('create-resource-001 renders a modal dialog with role and aria-modal in document.body', () => {
    mount()
    const dialog = mainDialog()
    expect(dialog).not.toBeNull()
    expect(dialog!.getAttribute('aria-modal')).toBe('true')
    expect(dialog!.parentElement).toBe(document.body)
  })

  it('create-resource-002 renders the heading as an h2', () => {
    mount({ heading: 'New Product' })
    const h = screen.getByRole('heading', { name: 'New Product', level: 2 })
    expect(h.tagName).toBe('H2')
  })

  it('create-resource-003 renders a × close button labelled Close in the header', () => {
    mount()
    const close = screen.getByRole('button', { name: 'Close' })
    expect(close.getAttribute('aria-label')).toBe('Close')
    expect(close.closest('div')!.querySelector('h2')).not.toBeNull()
  })

  it('create-resource-004 renders a Cancel button in the footer', () => {
    mount()
    expect(cancelButton()).toBeInTheDocument()
  })

  it('create-resource-005 renders a Save button with text Save', () => {
    mount()
    expect(saveButton()).toHaveTextContent(/^Save$/)
  })

  it('create-resource-029 calls renderForm with (draft, onChange, error) and renders its output in the dialog', () => {
    const { renderForm } = mount()
    const first = renderForm.mock.calls[0]!
    expect(first[0]).toEqual({ text: '' })
    expect(typeof first[1]).toBe('function')
    expect(first[2]).toBeNull()
    const dialog = mainDialog()!
    const form = within(dialog).getByRole('textbox', { name: 'Text' })
    const heading = within(dialog).getByRole('heading')
    const footerSave = saveButton()
    expect(heading.compareDocumentPosition(form) & Node.DOCUMENT_POSITION_FOLLOWING).toBeTruthy()
    expect(form.compareDocumentPosition(footerSave) & Node.DOCUMENT_POSITION_FOLLOWING).toBeTruthy()
  })

  it('create-resource-030 puts ariaLabel on the dialog container', () => {
    mount({ ariaLabel: 'Create Product' })
    expect(screen.getByRole('dialog', { name: 'Create Product' })).toHaveAttribute('aria-label', 'Create Product')
  })

  it('create-resource-025 returns null when document is undefined (server render)', () => {
    const { ui } = build()
    vi.stubGlobal('document', undefined)
    try {
      expect(renderToString(ui)).toBe('')
    } finally {
      vi.unstubAllGlobals()
    }
  })
})

describe('CreateResourceDialog — Save gate', () => {
  it('create-resource-006 disables Save while the draft equals blank', () => {
    mount()
    expect(saveButton()).toBeDisabled()
  })

  it('create-resource-007 enables Save once the draft differs from blank', () => {
    mount()
    typeText()
    expect(saveButton()).toBeEnabled()
  })

  it('create-resource-023 disables Save when saveEnabled returns false even if dirty', () => {
    mount({ saveEnabled: () => false })
    typeText()
    expect(saveButton()).toBeDisabled()
  })

  it('create-resource-024 enables Save when saveEnabled returns true and the draft is dirty', () => {
    mount({ saveEnabled: () => true })
    typeText()
    expect(saveButton()).toBeEnabled()
  })

  it('create-resource-033 keeps Save disabled when saveEnabled is true but the draft is pristine', () => {
    mount({ saveEnabled: () => true })
    expect(saveButton()).toBeDisabled()
  })
})

describe('CreateResourceDialog — save flow', () => {
  it('create-resource-008 hands the validate error to renderForm as its third argument', () => {
    const { renderForm } = mount({ validate: () => 'Name is required' })
    typeText()
    fireEvent.click(saveButton())
    expect(lastError(renderForm)).toBe('Name is required')
  })

  it('create-resource-009 does not call create when validate returns an error', () => {
    const { create } = mount({ validate: () => 'Name is required' })
    typeText()
    fireEvent.click(saveButton())
    expect(create).not.toHaveBeenCalled()
  })

  it('create-resource-010 calls create with the current draft when validate returns null', async () => {
    const { create, onCreated } = mount({ validate: () => null })
    typeText('hello')
    fireEvent.click(saveButton())
    await waitFor(() => expect(onCreated).toHaveBeenCalled())
    expect(create).toHaveBeenCalledWith({ text: 'hello' })
  })

  it('create-resource-011 disables Cancel and Save while create is in progress', async () => {
    mount({ create: () => new Promise<Result>(() => {}) })
    typeText()
    fireEvent.click(saveButton())
    await waitFor(() => expect(cancelButton()).toBeDisabled())
    expect(saveButton()).toBeDisabled()
  })

  it('create-resource-012 shows Saving… on the Save button while create is in progress', async () => {
    mount({ create: () => new Promise<Result>(() => {}) })
    typeText()
    fireEvent.click(saveButton())
    await waitFor(() => expect(saveButton()).toHaveTextContent('Saving…'))
  })

  it('create-resource-013 calls onCreated with the result and neither alerts nor closes itself', async () => {
    const { onCreated, onClose } = mount({ create: async () => ({ id: 'new-7' }) })
    typeText()
    fireEvent.click(saveButton())
    await waitFor(() => expect(onCreated).toHaveBeenCalledWith({ id: 'new-7' }))
    expect(screen.queryByRole('button', { name: 'Discard' })).toBeNull()
    expect(onClose).not.toHaveBeenCalled()
    expect(mainDialog()).not.toBeNull()
  })

  it('create-resource-014 surfaces a thrown Error message and re-enables the buttons', async () => {
    const { renderForm, onCreated } = mount({
      create: async () => {
        throw new Error('Network timeout')
      },
    })
    typeText()
    fireEvent.click(saveButton())
    await waitFor(() => expect(lastError(renderForm)).toBe('Network timeout'))
    expect(onCreated).not.toHaveBeenCalled()
    expect(cancelButton()).toBeEnabled()
    expect(saveButton()).toBeEnabled()
    expect(saveButton()).toHaveTextContent(/^Save$/)
  })

  it('create-resource-015 falls back to "Failed to create." for a non-Error throw', async () => {
    const { renderForm } = mount({
      create: async () => {
        throw { code: 500 }
      },
    })
    typeText()
    fireEvent.click(saveButton())
    await waitFor(() => expect(lastError(renderForm)).toBe('Failed to create.'))
  })

  it('create-resource-016 passes the exception to onSaveError', async () => {
    const boom = new Error('boom')
    const onSaveError = vi.fn()
    mount({
      create: async () => {
        throw boom
      },
      onSaveError,
    })
    typeText()
    fireEvent.click(saveButton())
    await waitFor(() => expect(onSaveError).toHaveBeenCalledWith(boom))
  })

  it('create-resource-031 treats an empty-string validate result as valid', async () => {
    const { create, renderForm } = mount({ validate: () => '' })
    typeText()
    fireEvent.click(saveButton())
    await waitFor(() => expect(create).toHaveBeenCalledTimes(1))
    expect(lastError(renderForm)).toBeNull()
  })

  it('create-resource-032 lets a throwing validate escape as a rejected save and leaves the dialog intact', async () => {
    // `save` is an async handler, so the throw surfaces as an unhandled rejection rather than a
    // synchronous exception. Capture it here instead of letting the runner fail the file.
    const seen: unknown[] = []
    const handler = (reason: unknown) => {
      seen.push(reason)
    }
    const saved = proc.listeners('unhandledRejection')
    proc.removeAllListeners('unhandledRejection')
    proc.on('unhandledRejection', handler)
    try {
      const onSaveError = vi.fn()
      const { create, renderForm, onClose } = mount({
        validate: () => {
          throw new Error('validate blew up')
        },
        onSaveError,
      })
      typeText()
      fireEvent.click(saveButton())
      await act(async () => {
        await new Promise((r) => setTimeout(r, 20))
      })
      expect(seen).toHaveLength(1)
      expect((seen[0] as Error).message).toBe('validate blew up')
      expect(create).not.toHaveBeenCalled()
      expect(onSaveError).not.toHaveBeenCalled()
      expect(lastError(renderForm)).toBeNull()
      expect(onClose).not.toHaveBeenCalled()
      expect(screen.getByRole('textbox', { name: 'Text' })).toHaveValue('a draft')
    } finally {
      proc.removeListener('unhandledRejection', handler)
      for (const l of saved) proc.on('unhandledRejection', l)
    }
  })

  it('create-resource-034 shows the thrown message and swallows the exception without onSaveError', async () => {
    const { renderForm } = mount({
      create: async () => {
        throw new Error('Network timeout')
      },
    })
    typeText()
    fireEvent.click(saveButton())
    await waitFor(() => expect(lastError(renderForm)).toBe('Network timeout'))
  })
})

describe('CreateResourceDialog — closing', () => {
  it('create-resource-017 raises the alert on Cancel when dirty and does not close', () => {
    const { onClose } = mount()
    typeText()
    fireEvent.click(cancelButton())
    expect(screen.getByRole('button', { name: 'Discard' })).toBeInTheDocument()
    expect(onClose).not.toHaveBeenCalled()
    expect(mainDialog()).not.toBeNull()
  })

  it('create-resource-018 closes immediately from × when pristine, without the alert', () => {
    const { onClose } = mount()
    fireEvent.click(screen.getByRole('button', { name: 'Close' }))
    expect(onClose).toHaveBeenCalledTimes(1)
    expect(screen.queryByRole('button', { name: 'Discard' })).toBeNull()
  })

  it('create-resource-019 ignores a click on the backdrop', () => {
    const { onClose } = mount()
    typeText()
    fireEvent.click(mainDialog()!)
    expect(onClose).not.toHaveBeenCalled()
    expect(screen.queryByRole('button', { name: 'Discard' })).toBeNull()
    expect(mainDialog()).not.toBeNull()
  })

  it('create-resource-020 routes Escape through the guard when dirty', () => {
    const { onClose } = mount()
    typeText()
    fireEvent.keyDown(window, { key: 'Escape' })
    expect(screen.getByRole('button', { name: 'Discard' })).toBeInTheDocument()
    expect(onClose).not.toHaveBeenCalled()
  })

  it('create-resource-021 maps Escape to Stay while the alert is open', () => {
    const { onClose } = mount()
    typeText()
    fireEvent.keyDown(window, { key: 'Escape' })
    expect(screen.getByRole('button', { name: 'Discard' })).toBeInTheDocument()
    fireEvent.keyDown(window, { key: 'Escape' })
    expect(screen.queryByRole('button', { name: 'Discard' })).toBeNull()
    expect(onClose).not.toHaveBeenCalled()
    expect(mainDialog()).not.toBeNull()
  })

  it('create-resource-022 closes on Escape without an alert when pristine', () => {
    const { onClose } = mount()
    fireEvent.keyDown(window, { key: 'Escape' })
    expect(onClose).toHaveBeenCalledTimes(1)
    expect(screen.queryByRole('button', { name: 'Discard' })).toBeNull()
  })

  it('create-resource-026 calls onClose on Discard and leaves the alert showing', () => {
    const { onClose } = mount()
    typeText()
    fireEvent.click(cancelButton())
    fireEvent.click(screen.getByRole('button', { name: 'Discard' }))
    expect(onClose).toHaveBeenCalledTimes(1)
    expect(screen.getByRole('button', { name: 'Discard' })).toBeInTheDocument()
  })

  it('create-resource-027 closes the alert on Stay, keeps the draft, and does not call onClose', () => {
    const { onClose } = mount()
    typeText()
    fireEvent.click(cancelButton())
    fireEvent.click(screen.getByRole('button', { name: 'Stay' }))
    expect(screen.queryByRole('button', { name: 'Discard' })).toBeNull()
    expect(screen.getByRole('textbox', { name: 'Text' })).toHaveValue('a draft')
    expect(onClose).not.toHaveBeenCalled()
  })

  it('create-resource-028 still raises the alert on Escape while saving', async () => {
    mount({ create: () => new Promise<Result>(() => {}) })
    typeText()
    fireEvent.click(saveButton())
    await waitFor(() => expect(cancelButton()).toBeDisabled())
    fireEvent.keyDown(window, { key: 'Escape' })
    expect(screen.getByRole('button', { name: 'Discard' })).toBeInTheDocument()
  })
})

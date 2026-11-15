/** The Danger Zone's copy is parameterized by `actionVerb` so a REVERSIBLE destructive action
 *  (archive) can reuse the same two-phase type-to-confirm ceremony without telling the user their
 *  data is being deleted, or that the action is permanent. Passing no `actionVerb` at all must
 *  render today's exact "Delete"/"Permanently"/"cannot be undone" wording, unchanged — every
 *  existing caller (TeamSettingsPane, EcosystemSettingsPane, the ui-showcase demo) passes none. */
/// <reference types="@testing-library/jest-dom/vitest" />
import { render, screen, fireEvent, waitFor, within } from '@testing-library/react'
import { describe, it, expect, vi } from 'vitest'
import { DeleteEntitySection } from '../blocks/delete-entity-section'

const noop = async (): Promise<void> => {}

/** A promise this test can resolve/reject on its own schedule, to assert mid-flight UI. */
function deferred<T>(): { promise: Promise<T>; resolve: (v: T) => void; reject: (e: unknown) => void } {
  let resolve!: (v: T) => void
  let reject!: (e: unknown) => void
  const promise = new Promise<T>((res, rej) => {
    resolve = res
    reject = rej
  })
  return { promise, resolve, reject }
}

/** The section is a Disclosure, collapsed by default; its header is a button carrying the title. */
function disclose(): void {
  fireEvent.click(screen.getByRole('button', { name: /Danger Zone/ }))
}

describe('DeleteEntitySection', () => {
  it('defaults to Delete/Permanently/cannot-be-undone wording through both dialog phases', () => {
    render(
      <DeleteEntitySection
        entityNoun="Team"
        confirmValue="team.x"
        childEntities="its members"
        onConfirm={noop}
      />,
    )
    disclose()
    // Collapsed section's built-in description (no `description` prop passed).
    expect(
      screen.getByText('Permanently delete this team and all of its data. This cannot be undone.'),
    ).toBeInTheDocument()
    fireEvent.click(screen.getByRole('button', { name: /^Delete Team$/ }))

    // Phase 1 (warn).
    expect(screen.getByText('Delete Team?')).toBeInTheDocument()
    expect(
      screen.getByText(
        'Deleting a team deletes all the data associated with the team, including its members. Do you wish to proceed?',
      ),
    ).toBeInTheDocument()
    fireEvent.click(screen.getByRole('button', { name: 'Yes' }))

    // Phase 2 (type-to-confirm).
    expect(screen.getByText('Permanently delete this Team')).toBeInTheDocument()
    expect(screen.getByText(/^You are about to permanently delete this Team\./)).toBeInTheDocument()
    expect(screen.getByText('Type team.x to confirm deletion')).toBeInTheDocument()
    expect(screen.getByRole('button', { name: 'Permanently Delete' })).toBeInTheDocument()
  })

  it('uses a supplied reversible action verb through both dialog phases, with no "delete" anywhere', () => {
    render(
      <DeleteEntitySection
        entityNoun="Organization"
        confirmValue="acme"
        childEntities="its handle"
        onConfirm={noop}
        description="Archiving hides this organization and frees its handle."
        actionVerb={{ imperative: 'Archive', gerund: 'Archiving', reversible: true }}
      />,
    )
    disclose()
    fireEvent.click(screen.getByRole('button', { name: /^Archive Organization$/ }))

    expect(screen.getByText('Archive Organization?')).toBeInTheDocument()
    fireEvent.click(screen.getByRole('button', { name: 'Yes' }))

    expect(screen.getByText('Archive this Organization')).toBeInTheDocument()
    // The whole flow must be free of "delete" — the action is reversible.
    expect(screen.queryByText(/[Dd]elete/)).toBeNull()
    // ...and free of any claim that it is permanent or irreversible.
    expect(screen.queryByText(/permanently/i)).toBeNull()
    expect(screen.queryByText(/cannot be undone/i)).toBeNull()
  })

  it('a reversible action verb never claims permanence even without a caller-supplied description', () => {
    render(
      <DeleteEntitySection
        entityNoun="Organization"
        confirmValue="acme"
        childEntities="its handle"
        onConfirm={noop}
        actionVerb={{ imperative: 'Archive', gerund: 'Archiving', reversible: true }}
      />,
    )
    disclose()
    // The built-in fallback description (no `description` override) must itself be
    // reversible-safe — this is the exact gap a prior review round caught: the fallback
    // hardcoded "Permanently {verb} ... This cannot be undone." regardless of reversibility.
    expect(screen.getByText('Archive this organization. This can be undone later.')).toBeInTheDocument()
    expect(screen.queryByText(/permanently/i)).toBeNull()
    expect(screen.queryByText(/cannot be undone/i)).toBeNull()

    fireEvent.click(screen.getByRole('button', { name: /^Archive Organization$/ }))
    fireEvent.click(screen.getByRole('button', { name: 'Yes' }))

    // Phase 2 (type-to-confirm) must also stay reversible-safe: no "permanently", no "deletion".
    expect(screen.queryByText(/permanently/i)).toBeNull()
    expect(screen.queryByText(/deletion/i)).toBeNull()
    expect(screen.getByText('Type acme to confirm')).toBeInTheDocument()
  })

  it('the reversible trigger renders the archive glyph, not the trash-can', () => {
    render(
      <DeleteEntitySection
        entityNoun="Organization"
        confirmValue="acme"
        childEntities="its handle"
        onConfirm={noop}
        actionVerb={{ imperative: 'Archive', gerund: 'Archiving', reversible: true }}
      />,
    )
    disclose()
    const trigger = screen.getByRole('button', { name: /^Archive Organization$/ })
    expect(trigger.querySelector('svg.lucide-archive')).not.toBeNull()
    expect(trigger.querySelector('svg.lucide-trash-2')).toBeNull()
  })

  it('the default (non-reversible) trigger keeps the trash-can glyph', () => {
    render(
      <DeleteEntitySection
        entityNoun="Team"
        confirmValue="team.x"
        childEntities="its members"
        onConfirm={noop}
      />,
    )
    disclose()
    const trigger = screen.getByRole('button', { name: /^Delete Team$/ })
    expect(trigger.querySelector('svg.lucide-trash-2')).not.toBeNull()
    expect(trigger.querySelector('svg.lucide-archive')).toBeNull()
  })

  it('reversible mode shows "Archiving…" as the busy label while onConfirm is pending, not "Deleting…"', async () => {
    const { promise, resolve } = deferred<void>()
    render(
      <DeleteEntitySection
        entityNoun="Organization"
        confirmValue="acme"
        childEntities="its handle"
        onConfirm={() => promise}
        actionVerb={{ imperative: 'Archive', gerund: 'Archiving', reversible: true }}
      />,
    )
    disclose()
    fireEvent.click(screen.getByRole('button', { name: /^Archive Organization$/ }))
    fireEvent.click(screen.getByRole('button', { name: 'Yes' }))
    // Scope to the open confirm dialog: its type-to-confirm trigger button shares the
    // same accessible name ("Archive Organization") as the disclosure's trigger button
    // still mounted behind it.
    const dialog = screen.getByRole('dialog')
    fireEvent.change(within(dialog).getByRole('textbox'), { target: { value: 'acme' } })
    fireEvent.click(within(dialog).getByRole('button', { name: 'Archive Organization' }))

    expect(await within(dialog).findByRole('button', { name: 'Archiving…' })).toBeInTheDocument()
    expect(within(dialog).queryByRole('button', { name: 'Deleting…' })).toBeNull()

    resolve()
    await waitFor(() => expect(screen.queryByRole('dialog')).toBeNull())
  })

  it('reversible mode falls back to "Failed to archive organization." when onConfirm rejects a non-Error', async () => {
    // A non-Error rejection: only this fallback path renders the message — `e.message`
    // never runs.
    const onConfirm = async (): Promise<void> => {
      throw 'boom'
    }
    render(
      <DeleteEntitySection
        entityNoun="Organization"
        confirmValue="acme"
        childEntities="its handle"
        onConfirm={onConfirm}
        actionVerb={{ imperative: 'Archive', gerund: 'Archiving', reversible: true }}
      />,
    )
    disclose()
    fireEvent.click(screen.getByRole('button', { name: /^Archive Organization$/ }))
    fireEvent.click(screen.getByRole('button', { name: 'Yes' }))
    const dialog = screen.getByRole('dialog')
    fireEvent.change(within(dialog).getByRole('textbox'), { target: { value: 'acme' } })
    fireEvent.click(within(dialog).getByRole('button', { name: 'Archive Organization' }))

    expect(await within(dialog).findByText('Failed to archive organization.')).toBeInTheDocument()
  })
})

// One test per integration vector in cookbook/adh/hub/admin/delete-entity-section/
// integration-test-vectors.md (T1 to T19).
describe('DeleteEntitySection integration vectors', () => {
  const ARCHIVE = { imperative: 'Archive', gerund: 'Archiving', reversible: true } as const

  const renderSection = (
    props: Partial<React.ComponentProps<typeof DeleteEntitySection>> = {},
  ): ReturnType<typeof render> =>
    render(
      <DeleteEntitySection
        entityNoun="Team"
        confirmValue="team.x"
        childEntities="its members"
        onConfirm={noop}
        {...props}
      />,
    )

  /** Disclose, click the trigger, and (optionally) click Yes. Returns the open dialog. */
  function toConfirmPhase(triggerName: RegExp): HTMLElement {
    disclose()
    fireEvent.click(screen.getByRole('button', { name: triggerName }))
    fireEvent.click(screen.getByRole('button', { name: 'Yes' }))
    return screen.getByRole('dialog')
  }

  const section = (): HTMLElement => screen.getByRole('region', { name: 'Danger Zone' })
  const titleSpan = (): HTMLElement =>
    screen.getByRole('button', { name: /Danger Zone/ }).querySelector('span span span') as HTMLElement

  it('T1 starts collapsed and neutral, with a gold warning glyph', () => {
    renderSection()
    expect(screen.getByRole('button', { name: /Danger Zone/ })).toHaveAttribute('aria-expanded', 'false')
    expect(screen.queryByRole('button', { name: /^Delete Team$/ })).toBeNull()
    expect(section().innerHTML).not.toContain('apt-red')
    const glyph = screen.getByRole('button', { name: /Danger Zone/ }).querySelector('svg.lucide-triangle-alert')
    expect(glyph).not.toBeNull()
    expect(glyph!.getAttribute('class')).toContain('text-apt-gold')
  })

  it('T2 turns red when disclosed, and the warning glyph stays gold', () => {
    renderSection()
    disclose()
    expect(screen.getByRole('button', { name: /Danger Zone/ })).toHaveAttribute('aria-expanded', 'true')
    expect(titleSpan().className).toContain('text-apt-red')
    const box = section().firstElementChild as HTMLElement
    expect(box.className).toContain('border-apt-red/40')
    expect(box.className).toContain('bg-apt-red/5')
    const glyph = section().querySelector('svg.lucide-triangle-alert')
    expect(glyph!.getAttribute('class')).toContain('text-apt-gold')
    expect(glyph!.getAttribute('class')).not.toContain('apt-red')
  })

  it('T3 opens on the warn phase naming the child entities', () => {
    renderSection()
    disclose()
    fireEvent.click(screen.getByRole('button', { name: /^Delete Team$/ }))
    expect(screen.getByRole('dialog')).toBeInTheDocument()
    expect(screen.getByText('Delete Team?')).toBeInTheDocument()
    expect(screen.getByText(/including its members\. Do you wish to proceed\?/)).toBeInTheDocument()
    expect(screen.queryByRole('textbox')).toBeNull()
  })

  it('T4 advances to type-to-confirm on Yes without calling onConfirm', () => {
    const onConfirm = vi.fn(noop)
    renderSection({ onConfirm })
    const dialog = toConfirmPhase(/^Delete Team$/)
    expect(within(dialog).getByRole('textbox')).toBeInTheDocument()
    expect(within(dialog).getByRole('button', { name: 'Permanently Delete' })).toBeInTheDocument()
    expect(onConfirm).not.toHaveBeenCalled()
  })

  it('T5 keeps the confirm button disabled for a near-match (wrong case, trailing space)', () => {
    renderSection()
    const dialog = toConfirmPhase(/^Delete Team$/)
    const cta = within(dialog).getByRole('button', { name: 'Permanently Delete' })
    expect(cta).toBeDisabled()
    fireEvent.change(within(dialog).getByRole('textbox'), { target: { value: 'TEAM.X' } })
    expect(cta).toBeDisabled()
    fireEvent.change(within(dialog).getByRole('textbox'), { target: { value: 'team.x ' } })
    expect(cta).toBeDisabled()
    fireEvent.change(within(dialog).getByRole('textbox'), { target: { value: 'team.' } })
    expect(cta).toBeDisabled()
  })

  it('T6 enables on the exact identifier, calls onConfirm once and shows "Deleting…"', async () => {
    const { promise, resolve } = deferred<void>()
    const onConfirm = vi.fn(() => promise)
    renderSection({ onConfirm })
    const dialog = toConfirmPhase(/^Delete Team$/)
    fireEvent.change(within(dialog).getByRole('textbox'), { target: { value: 'team.x' } })
    const cta = within(dialog).getByRole('button', { name: 'Permanently Delete' })
    expect(cta).toBeEnabled()
    fireEvent.click(cta)
    expect(onConfirm).toHaveBeenCalledTimes(1)
    expect(await within(dialog).findByRole('button', { name: 'Deleting…' })).toBeInTheDocument()
    resolve()
    await waitFor(() => expect(screen.queryByRole('dialog')).toBeNull())
  })

  it('T7 keeps the confirm button disabled when confirmValue is empty and the input is empty', () => {
    renderSection({ confirmValue: '' })
    const dialog = toConfirmPhase(/^Delete Team$/)
    expect(within(dialog).getByRole('textbox')).toHaveValue('')
    expect(within(dialog).getByRole('button', { name: 'Permanently Delete' })).toBeDisabled()
  })

  it('T8 cannot be dismissed while onConfirm is pending, and shows no close affordance', async () => {
    const { promise, resolve } = deferred<void>()
    renderSection({ onConfirm: () => promise })
    const dialog = toConfirmPhase(/^Delete Team$/)
    expect(within(dialog).getByRole('button', { name: 'Close' })).toBeInTheDocument() // before busy
    fireEvent.change(within(dialog).getByRole('textbox'), { target: { value: 'team.x' } })
    fireEvent.click(within(dialog).getByRole('button', { name: 'Permanently Delete' }))
    await within(dialog).findByRole('button', { name: 'Deleting…' })

    expect(within(dialog).queryByRole('button', { name: 'Close' })).toBeNull()
    fireEvent.keyDown(dialog, { key: 'Escape' })
    fireEvent.keyDown(document.body, { key: 'Escape' })
    fireEvent.mouseDown(document.body)
    fireEvent.click(document.body)
    expect(screen.getByRole('dialog')).toBeInTheDocument()

    resolve()
    await waitFor(() => expect(screen.queryByRole('dialog')).toBeNull())
  })

  it('T9 shows the error inline when onConfirm rejects, clears busy and keeps the dialog open', async () => {
    const onConfirm = vi.fn(async () => {
      throw new Error('team has live projects')
    })
    renderSection({ onConfirm })
    const dialog = toConfirmPhase(/^Delete Team$/)
    fireEvent.change(within(dialog).getByRole('textbox'), { target: { value: 'team.x' } })
    fireEvent.click(within(dialog).getByRole('button', { name: 'Permanently Delete' }))

    expect(await within(dialog).findByText('team has live projects')).toBeInTheDocument()
    expect(screen.getByRole('dialog')).toBeInTheDocument()
    const cta = within(dialog).getByRole('button', { name: 'Permanently Delete' })
    expect(cta).toBeEnabled() // busy cleared: the user can retry
    fireEvent.click(cta)
    await waitFor(() => expect(onConfirm).toHaveBeenCalledTimes(2))
  })

  it('T10 resets to a closed, empty, warn-phase dialog on cancel and on success; the disclosure stays open', async () => {
    renderSection()
    // Cancel from the confirm phase.
    let dialog = toConfirmPhase(/^Delete Team$/)
    fireEvent.change(within(dialog).getByRole('textbox'), { target: { value: 'team.x' } })
    fireEvent.click(within(dialog).getByRole('button', { name: 'Cancel' }))
    await waitFor(() => expect(screen.queryByRole('dialog')).toBeNull())
    expect(screen.getByRole('button', { name: /Danger Zone/ })).toHaveAttribute('aria-expanded', 'true')

    // Reopening starts at the warn phase with an empty input.
    fireEvent.click(screen.getByRole('button', { name: /^Delete Team$/ }))
    expect(screen.getByText('Delete Team?')).toBeInTheDocument()
    fireEvent.click(screen.getByRole('button', { name: 'Yes' }))
    dialog = screen.getByRole('dialog')
    expect(within(dialog).getByRole('textbox')).toHaveValue('')

    // Success closes it too.
    fireEvent.change(within(dialog).getByRole('textbox'), { target: { value: 'team.x' } })
    fireEvent.click(within(dialog).getByRole('button', { name: 'Permanently Delete' }))
    await waitFor(() => expect(screen.queryByRole('dialog')).toBeNull())
    fireEvent.click(screen.getByRole('button', { name: /^Delete Team$/ }))
    expect(screen.getByText('Delete Team?')).toBeInTheDocument()
  })

  it('T11 reversible copy reads Archive/Archiving through the flow, with no permanence claims', () => {
    renderSection({
      entityNoun: 'Organization',
      confirmValue: 'acme',
      childEntities: 'its handle',
      description: 'Archiving hides this organization and frees its handle.',
      actionVerb: ARCHIVE,
    })
    disclose()
    expect(screen.getByText('Archiving hides this organization and frees its handle.')).toBeInTheDocument()
    fireEvent.click(screen.getByRole('button', { name: /^Archive Organization$/ }))
    expect(screen.getByText('Archiving an organization affects its handle. Do you wish to proceed?')).toBeInTheDocument()
    fireEvent.click(screen.getByRole('button', { name: 'Yes' }))
    expect(screen.getByText('Archive this Organization')).toBeInTheDocument()
    expect(screen.getByText(/^You are about to archive this Organization\./)).toBeInTheDocument()
    const text = document.body.textContent ?? ''
    expect(text).not.toMatch(/permanently/i)
    expect(text).not.toMatch(/cannot be undone/i)
    expect(text).not.toMatch(/deletion/i)
  })

  it('T12 the built-in reversible blurb is permanence-free and the confirm label has no "deletion"', () => {
    renderSection({
      entityNoun: 'organization',
      confirmValue: 'acme',
      childEntities: 'its handle',
      actionVerb: ARCHIVE,
    })
    disclose()
    expect(screen.getByText('Archive this organization. This can be undone later.')).toBeInTheDocument()
    fireEvent.click(screen.getByRole('button', { name: /^Archive organization$/ }))
    fireEvent.click(screen.getByRole('button', { name: 'Yes' }))
    expect(screen.getByText('Type acme to confirm')).toBeInTheDocument()
    expect(document.body.textContent ?? '').not.toMatch(/deletion|permanently|cannot be undone/i)
  })

  it('T13 the reversible trigger shows the archive glyph and no trash glyph', () => {
    renderSection({ actionVerb: ARCHIVE })
    disclose()
    const trigger = screen.getByRole('button', { name: /^Archive Team$/ })
    expect(trigger.querySelector('svg.lucide-archive')).not.toBeNull()
    expect(section().querySelector('svg.lucide-trash-2')).toBeNull()
  })

  it('T14 the default trigger shows the trash glyph and no archive glyph', () => {
    renderSection()
    disclose()
    const trigger = screen.getByRole('button', { name: /^Delete Team$/ })
    expect(trigger.querySelector('svg.lucide-trash-2')).not.toBeNull()
    expect(section().querySelector('svg.lucide-archive')).toBeNull()
  })

  it('T15 the reversible busy label is "Archiving…", never "Deleting…"', async () => {
    const { promise, resolve } = deferred<void>()
    renderSection({ actionVerb: ARCHIVE, onConfirm: () => promise })
    const dialog = toConfirmPhase(/^Archive Team$/)
    fireEvent.change(within(dialog).getByRole('textbox'), { target: { value: 'team.x' } })
    fireEvent.click(within(dialog).getByRole('button', { name: 'Archive Team' }))
    expect(await within(dialog).findByRole('button', { name: 'Archiving…' })).toBeInTheDocument()
    expect(within(dialog).queryByRole('button', { name: 'Deleting…' })).toBeNull()
    resolve()
    await waitFor(() => expect(screen.queryByRole('dialog')).toBeNull())
  })

  it('T16 a non-Error rejection falls back to "Failed to archive organization."', async () => {
    renderSection({
      entityNoun: 'Organization',
      confirmValue: 'acme',
      childEntities: 'its handle',
      actionVerb: ARCHIVE,
      onConfirm: async () => {
        throw 'boom'
      },
    })
    const dialog = toConfirmPhase(/^Archive Organization$/)
    fireEvent.change(within(dialog).getByRole('textbox'), { target: { value: 'acme' } })
    fireEvent.click(within(dialog).getByRole('button', { name: 'Archive Organization' }))
    expect(await within(dialog).findByText('Failed to archive organization.')).toBeInTheDocument()
  })

  it('T17 a double-click on the confirm button calls onConfirm once and disables both CTA and Cancel while busy', async () => {
    const { promise, resolve } = deferred<void>()
    const onConfirm = vi.fn(() => promise)
    renderSection({ onConfirm })
    const dialog = toConfirmPhase(/^Delete Team$/)
    fireEvent.change(within(dialog).getByRole('textbox'), { target: { value: 'team.x' } })
    const cta = within(dialog).getByRole('button', { name: 'Permanently Delete' })
    fireEvent.click(cta)
    fireEvent.click(cta)
    expect(onConfirm).toHaveBeenCalledTimes(1)
    const busyCta = await within(dialog).findByRole('button', { name: 'Deleting…' })
    expect(busyCta).toBeDisabled()
    expect(within(dialog).getByRole('button', { name: 'Cancel' })).toBeDisabled()
    resolve()
    await waitFor(() => expect(screen.queryByRole('dialog')).toBeNull())
  })

  it('T18 uses "an" before a vowel-initial noun', () => {
    renderSection({ entityNoun: 'Ecosystem', childEntities: 'its apps' })
    disclose()
    fireEvent.click(screen.getByRole('button', { name: /^Delete Ecosystem$/ }))
    expect(screen.getByText(/^Deleting an ecosystem deletes/)).toBeInTheDocument()
  })

  it('T19 uses "a" before a consonant-initial noun', () => {
    renderSection({ entityNoun: 'Bucket', childEntities: 'its files' })
    disclose()
    fireEvent.click(screen.getByRole('button', { name: /^Delete Bucket$/ }))
    expect(screen.getByText(/^Deleting a bucket deletes/)).toBeInTheDocument()
  })
})

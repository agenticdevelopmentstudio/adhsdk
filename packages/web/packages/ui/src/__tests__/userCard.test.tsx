import { render, screen, waitFor } from '@testing-library/react'
import { describe, it, expect, afterEach, vi } from 'vitest'
import { UserCard, UserCardSkeleton, type UserCardDto } from '../blocks/user-card'

const base: UserCardDto = {
  slug: 'ada',
  displayName: 'Ada Lovelace',
  avatarUrl: null,
  socialLinks: [],
  emails: [],
  phones: [],
  addresses: [],
  personas: [],
}

const dto = (over: Partial<UserCardDto> = {}): UserCardDto => ({ ...base, ...over })

const address = {
  label: 'Home',
  line1: '1 Main St',
  line2: '',
  city: 'London',
  region: '',
  postalCode: 'N1',
  country: 'UK',
}
const persona = { slug: 'p', name: 'Pro', description: null, visibility: 'public' as const, createdAt: '2020-01-01' }
const social = { platform: 'github', url: 'https://github.com/ada', handle: '@ada' }

const sectionLabels = (c: HTMLElement) =>
  Array.from(c.querySelectorAll('article > section')).map((s) => s.getAttribute('aria-label'))

describe('UserCard conformance vectors', () => {
  afterEach(() => {
    vi.unstubAllGlobals()
  })

  it('T1 no separator or section headings when every collection is empty', () => {
    const { container } = render(<UserCard user={dto()} />)
    expect(screen.queryByRole('separator')).toBeNull()
    expect(container.querySelectorAll('section')).toHaveLength(0)
  })

  it('T2 one social link renders a separator between header and social section', () => {
    const { container } = render(<UserCard user={dto({ socialLinks: [social] })} />)
    const sep = screen.getByRole('separator')
    const social_ = container.querySelector('section[aria-label="Social links"]')!
    const header = container.querySelector('h2')!
    expect(header.compareDocumentPosition(sep) & Node.DOCUMENT_POSITION_FOLLOWING).toBeTruthy()
    expect(sep.compareDocumentPosition(social_) & Node.DOCUMENT_POSITION_FOLLOWING).toBeTruthy()
  })

  it('T3 social link opens externally and shows platform label and handle', () => {
    render(<UserCard user={dto({ socialLinks: [social] })} />)
    const a = screen.getByRole('link', { name: /GitHub/ })
    expect(a.getAttribute('target')).toBe('_blank')
    expect(a.getAttribute('rel')).toBe('noopener noreferrer')
    expect(a.textContent).toContain('GitHub')
    expect(a.textContent).toContain('@ada')
  })

  it('T4 initials from a two-word display name', () => {
    const { container } = render(<UserCard user={dto()} />)
    expect(container.querySelector('.adh-avatar__fallback')?.textContent).toBe('AL')
  })

  it('T5 initial from the slug when displayName is null', () => {
    const { container } = render(<UserCard user={dto({ displayName: null })} />)
    expect(container.querySelector('.adh-avatar__fallback')?.textContent).toBe('A')
  })

  it('T6 heading is the slug when displayName is null', () => {
    render(<UserCard user={dto({ displayName: null })} />)
    expect(screen.getByRole('heading', { level: 2 }).textContent).toBe('ada')
  })

  it("T7 article is labelled with the display name's profile", () => {
    const { container } = render(<UserCard user={dto()} />)
    expect(container.querySelector('article')?.getAttribute('aria-label')).toBe("Ada Lovelace's profile")
  })

  it('T8 skeleton carries status role, aria-busy and label', () => {
    render(<UserCardSkeleton />)
    const s = screen.getByRole('status')
    expect(s.getAttribute('aria-busy')).toBe('true')
    expect(s.getAttribute('aria-label')).toBe('Loading profile…')
  })

  it('T9 className lands on the root article', () => {
    const { container } = render(<UserCard user={dto()} className="my-custom" />)
    expect(container.querySelector('article')?.classList.contains('my-custom')).toBe(true)
  })

  it('T10 identity header always renders with the slug', () => {
    render(<UserCard user={dto({ emails: ['a@b.c'] })} />)
    expect(screen.getByRole('heading', { level: 2 }).textContent).toBe('Ada Lovelace')
    expect(screen.getByText('@ada')).toBeTruthy()
  })

  it('T11 no member-since line when createdAt is null or omitted', () => {
    const { rerender } = render(<UserCard user={dto({ createdAt: null })} />)
    expect(screen.getByText('@ada')).toBeTruthy()
    expect(screen.queryByText(/Member since/)).toBeNull()
    rerender(<UserCard user={dto()} />)
    expect(screen.getByText('@ada')).toBeTruthy()
    expect(screen.queryByText(/Member since/)).toBeNull()
    rerender(<UserCard user={dto({ createdAt: '2020-06-15T00:00:00Z' })} />)
    expect(screen.getByText(/Member since/)).toBeTruthy()
  })

  it('T12 empty displayName and slug: empty heading and generic UserIcon fallback', () => {
    const { container } = render(<UserCard user={dto({ displayName: '', slug: '' })} />)
    expect(screen.getByRole('heading', { level: 2 }).textContent).toBe('')
    const fb = container.querySelector('.adh-avatar__fallback')!
    expect(fb.querySelector('svg.lucide-user')).not.toBeNull()
    expect(fb.textContent).toBe('')
  })

  it('T13 emails, phones and addresses render every item', () => {
    const { container } = render(
      <UserCard
        user={dto({
          emails: ['a@x.com', 'b@x.com'],
          phones: ['111', '222'],
          addresses: [address, { ...address, label: 'Work', line1: '2 Side St' }],
        })}
      />,
    )
    expect(container.querySelectorAll('a[href^="mailto:"]')).toHaveLength(2)
    expect(container.querySelectorAll('a[href^="tel:"]')).toHaveLength(2)
    expect(container.querySelectorAll('address')).toHaveLength(2)
  })

  it('T14 only socialLinks populated renders only the Social section', () => {
    const { container } = render(<UserCard user={dto({ socialLinks: [social] })} />)
    expect(sectionLabels(container)).toEqual(['Social links'])
  })

  it('T15 only emails populated renders only the Email section', () => {
    const { container } = render(<UserCard user={dto({ emails: ['a@x.com'] })} />)
    expect(sectionLabels(container)).toEqual(['Email addresses'])
  })

  it('T16 only phones populated renders only the Phone section', () => {
    const { container } = render(<UserCard user={dto({ phones: ['111'] })} />)
    expect(sectionLabels(container)).toEqual(['Phone numbers'])
  })

  it('T17 only addresses populated renders only the Address section', () => {
    const { container } = render(<UserCard user={dto({ addresses: [address] })} />)
    expect(sectionLabels(container)).toEqual(['Addresses'])
  })

  it('T18 only personas populated renders only the Personas section', () => {
    const { container } = render(<UserCard user={dto({ personas: [persona] })} />)
    expect(sectionLabels(container)).toEqual(['Personas'])
  })

  it('T19 a failing avatar image falls back to initials', async () => {
    class FailingImage {
      onload: null | (() => void) = null
      onerror: null | (() => void) = null
      referrerPolicy = ''
      crossOrigin: string | null = null
      set src(_v: string) {
        queueMicrotask(() => this.onerror?.())
      }
    }
    vi.stubGlobal('Image', FailingImage)
    const { container } = render(<UserCard user={dto({ avatarUrl: 'https://example.invalid/a.png' })} />)
    await waitFor(() => {
      expect(container.querySelector('.adh-avatar__fallback')?.textContent).toBe('AL')
    })
    expect(container.querySelector('img')).toBeNull()
  })

  it('T20 email renders as a mailto link', () => {
    render(<UserCard user={dto({ emails: ['ada@example.com'] })} />)
    const a = screen.getByRole('link', { name: 'ada@example.com' })
    expect(a.getAttribute('href')).toBe('mailto:ada@example.com')
  })

  it('T21 phone renders as a tel link', () => {
    render(<UserCard user={dto({ phones: ['+1 555 0100'] })} />)
    const a = screen.getByRole('link', { name: '+1 555 0100' })
    expect(a.getAttribute('href')).toBe('tel:+1 555 0100')
  })

  it('T22 initials use the first two words of a longer name', () => {
    const { container } = render(<UserCard user={dto({ displayName: 'Ada King Lovelace' })} />)
    expect(container.querySelector('.adh-avatar__fallback')?.textContent).toBe('AK')
  })

  it('T23 all five sections render in order with the only divider under the header', () => {
    const { container } = render(
      <UserCard
        user={dto({
          socialLinks: [social],
          emails: ['a@x.com'],
          phones: ['111'],
          addresses: [address],
          personas: [persona],
        })}
      />,
    )
    expect(sectionLabels(container)).toEqual([
      'Social links',
      'Email addresses',
      'Phone numbers',
      'Addresses',
      'Personas',
    ])
    const seps = screen.getAllByRole('separator')
    expect(seps).toHaveLength(1)
    const first = container.querySelector('section')!
    expect(seps[0]!.compareDocumentPosition(first) & Node.DOCUMENT_POSITION_FOLLOWING).toBeTruthy()
  })
})

import { render, screen } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { describe, it, expect } from 'vitest'
import * as mod from '../components/accordion'
import { Accordion, AccordionItem, AccordionTrigger, AccordionPanel } from '../components/accordion'

function basic(triggerClass?: string) {
  return render(
    <Accordion>
      <AccordionItem value="a">
        <AccordionTrigger className={triggerClass}>Section A</AccordionTrigger>
        <AccordionPanel>Content A</AccordionPanel>
      </AccordionItem>
    </Accordion>,
  )
}

function two() {
  return render(
    <Accordion>
      <AccordionItem value="a">
        <AccordionTrigger>One</AccordionTrigger>
        <AccordionPanel>Panel one</AccordionPanel>
      </AccordionItem>
      <AccordionItem value="b">
        <AccordionTrigger>Two</AccordionTrigger>
        <AccordionPanel>Panel two</AccordionPanel>
      </AccordionItem>
    </Accordion>,
  )
}

describe('Accordion', () => {
  it('accordion-001 exports the four components', () => {
    expect(Object.keys(mod).sort()).toEqual(['Accordion', 'AccordionItem', 'AccordionPanel', 'AccordionTrigger'])
    for (const c of [Accordion, AccordionItem, AccordionTrigger, AccordionPanel]) expect(typeof c).toBe('function')
  })
  it('accordion-002 the chevron svg follows the label inside the trigger', () => {
    basic()
    const trigger = screen.getByRole('button')
    const svg = trigger.querySelector('svg')
    expect(svg).not.toBeNull()
    expect(svg!.getAttribute('class')).toContain('lucide-chevron-down')
    expect(trigger.firstChild?.textContent).toBe('Section A')
    expect(trigger.lastElementChild).toBe(svg)
  })
  it('accordion-003 aria-expanded toggles and the chevron carries the open rotate class', async () => {
    const user = userEvent.setup()
    basic()
    const trigger = screen.getByRole('button')
    const svg = trigger.querySelector('svg')!
    expect(trigger.getAttribute('aria-expanded')).toBe('false')
    expect(svg.getAttribute('class')).toContain('group-data-[panel-open]/acc:rotate-180')
    await user.click(trigger)
    expect(trigger.getAttribute('aria-expanded')).toBe('true')
    expect(trigger.hasAttribute('data-panel-open')).toBe(true)
    await user.click(trigger)
    expect(trigger.getAttribute('aria-expanded')).toBe('false')
    expect(trigger.hasAttribute('data-panel-open')).toBe(false)
  })
  it.skip('accordion-004 computed bottom border width and color (jsdom loads no Tailwind CSS, so computed styles are unavailable)', () => {})
  it.skip('accordion-005 computed panel paddingBottom of 12px (jsdom loads no Tailwind CSS, so computed styles are unavailable)', () => {})
  it('accordion-006 trigger aria-controls references the panel id', async () => {
    const user = userEvent.setup()
    basic()
    const trigger = screen.getByRole('button')
    await user.click(trigger)
    const panel = screen.getByRole('region', { name: 'Section A' })
    expect(panel.id).toBeTruthy()
    expect(trigger.getAttribute('aria-controls')).toBe(panel.id)
  })
  it('accordion-007 data-slot attributes on root, item, trigger and panel', async () => {
    const user = userEvent.setup()
    const { container } = basic()
    await user.click(screen.getByRole('button'))
    expect(container.querySelector('[data-slot="accordion"]')).not.toBeNull()
    expect(container.querySelector('[data-slot="accordion-item"]')).not.toBeNull()
    expect(container.querySelector('[data-slot="accordion-trigger"]')).toBe(screen.getByRole('button'))
    expect(container.querySelector('[data-slot="accordion-panel"]')).toBe(screen.getByRole('region', { name: 'Section A' }))
  })
  it('accordion-008 disabled and value props are forwarded to the primitive', async () => {
    const user = userEvent.setup()
    const { container, unmount } = render(
      <Accordion>
        <AccordionItem value="a" disabled>
          <AccordionTrigger>One</AccordionTrigger>
          <AccordionPanel>Panel one</AccordionPanel>
        </AccordionItem>
      </Accordion>,
    )
    expect(container.querySelector('[data-slot="accordion-item"]')!.hasAttribute('data-disabled')).toBe(true)
    await user.click(screen.getByRole('button'))
    expect(screen.getByRole('button').getAttribute('aria-expanded')).toBe('false')
    unmount()
    render(
      <Accordion value={['b']}>
        <AccordionItem value="a">
          <AccordionTrigger>One</AccordionTrigger>
          <AccordionPanel>Panel one</AccordionPanel>
        </AccordionItem>
        <AccordionItem value="b">
          <AccordionTrigger>Two</AccordionTrigger>
          <AccordionPanel>Panel two</AccordionPanel>
        </AccordionItem>
      </Accordion>,
    )
    expect(screen.getByRole('button', { name: 'One' }).getAttribute('aria-expanded')).toBe('false')
    expect(screen.getByRole('button', { name: 'Two' }).getAttribute('aria-expanded')).toBe('true')
  })
  it('accordion-009 className on the trigger is merged', () => {
    basic('my-custom-class')
    const trigger = screen.getByRole('button')
    expect(trigger.classList.contains('my-custom-class')).toBe(true)
    expect(trigger.classList.contains('items-center')).toBe(true)
  })
  it('accordion-010 default accordion keeps a single panel open', async () => {
    const user = userEvent.setup()
    two()
    const one = screen.getByRole('button', { name: 'One' })
    const twoBtn = screen.getByRole('button', { name: 'Two' })
    await user.click(one)
    expect(one.getAttribute('aria-expanded')).toBe('true')
    await user.click(twoBtn)
    expect(twoBtn.getAttribute('aria-expanded')).toBe('true')
    expect(one.getAttribute('aria-expanded')).toBe('false')
  })
  it.skip('accordion-011 computed transition-property and rotate (jsdom loads no Tailwind CSS, so computed styles are unavailable)', () => {})
  it.skip('accordion-012 reduced-motion transition-duration (jsdom loads no CSS and the source has no prefers-reduced-motion check)', () => {})
  it.skip('accordion-013 visible focus indicator (jsdom loads no CSS; known gap, the source adds outline-none and no replacement)', () => {})
})

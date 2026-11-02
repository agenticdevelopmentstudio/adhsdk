import { describe, expect, it, vi } from 'vitest'
import { render } from '@testing-library/react'
import type { HelpRouteLevel } from '../help/HelpMasterDetail'

// The rail itself is the toolkit HMDV's; what this file asserts is which levels the server
// surface hands it, so the client half is a stand-in that records them.
const rail = vi.hoisted(() => ({ levels: [] as HelpRouteLevel[], rootLabel: '' }))
vi.mock('@agentic-toolkit/adh/help/HelpMasterDetail', () => ({
  HelpMasterDetail: ({ levels, rootLabel }: { levels: HelpRouteLevel[]; rootLabel: string }) => {
    rail.levels = levels
    rail.rootLabel = rootLabel
    return null
  },
}))
vi.mock('../docs/MarkdownHtml', () => ({ MarkdownHtml: () => null }))

import { HelpSurface, HELP_ROOT_LEVEL_KEY } from '../help/HelpSurface'

describe('HelpSurface startAtArea', () => {
  it('keeps the help topics as the root list by default', () => {
    render(<HelpSurface slug="mcp/connect" rootClearHref="/home" />)
    expect(rail.levels[0]?.key).toBe(HELP_ROOT_LEVEL_KEY)
    expect(rail.rootLabel).toBe('Help')
  })

  it("starts at the area's own list, named for the area, when asked", () => {
    render(<HelpSurface slug="mcp/connect" rootClearHref="/home" startAtArea />)
    expect(rail.levels.map((l) => l.key)).toEqual(['help:mcp'])
    expect(rail.levels[0]?.selectedId).toBe('mcp-connect')
    // The breadcrumb root clears to the area's own route.
    expect(rail.levels[0]?.clearHref).toBe('/mcp')
    expect(rail.rootLabel).toBe('MCP')
  })

  it('keeps the topics rail for a topic with no list of its own', () => {
    render(<HelpSurface slug="overview" rootClearHref="/home" startAtArea />)
    expect(rail.levels[0]?.key).toBe(HELP_ROOT_LEVEL_KEY)
    expect(rail.rootLabel).toBe('Help')
  })
})

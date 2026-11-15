// A pre-paint script runs only in the document the server sent. A layout React mounts on a client
// navigation must not create the element: it would never execute, and React reports it.
import { act, cleanup, render } from '@testing-library/react'
import { hydrateRoot } from 'react-dom/client'
import { renderToString } from 'react-dom/server'
import { afterEach, describe, expect, it, vi } from 'vitest'
import { DocumentLoadScript } from '../DocumentLoadScript'

const CODE = 'window.__ran = 1'

afterEach(cleanup)

describe('DocumentLoadScript', () => {
  it('document-load-script-001 is in the server HTML', () => {
    expect(renderToString(<DocumentLoadScript code={CODE} />)).toBe(`<script>${CODE}</script>`)
  })

  it('document-load-script-002 renders nothing on a client mount, so React never warns about it', () => {
    const error = vi.spyOn(console, 'error').mockImplementation(() => {})
    const { container } = render(<DocumentLoadScript code={CODE} />)
    expect(container.querySelector('script')).toBeNull()
    expect(error).not.toHaveBeenCalled()
    error.mockRestore()
  })

  it('document-load-script-003 hydrates the server node without a mismatch', async () => {
    const error = vi.spyOn(console, 'error').mockImplementation(() => {})
    const host = document.createElement('div')
    host.innerHTML = renderToString(<DocumentLoadScript code={CODE} />)
    document.body.append(host)
    await act(async () => {
      hydrateRoot(host, <DocumentLoadScript code={CODE} />)
    })
    expect(error).not.toHaveBeenCalled()
    host.remove()
    error.mockRestore()
  })

  it('document-load-script-004 puts code in the markup unescaped', () => {
    const code = 'if (a < b && c) { x = "1" }'
    const html = renderToString(<DocumentLoadScript code={code} />)
    expect(html).toBe(`<script>${code}</script>`)
    expect(html).not.toMatch(/&lt;|&amp;|&quot;/)
  })

  it('document-load-script-005 renders one empty script for empty code', () => {
    expect(renderToString(<DocumentLoadScript code="" />)).toBe('<script></script>')
  })

  it('document-load-script-006 documents the hazard: a closing tag in code ends the script early', () => {
    const html = renderToString(<DocumentLoadScript code="</script><b>x</b>" />)
    expect(html).toBe('<script></script><b>x</b></script>')
  })

  it('document-load-script-007 leaves the tree after hydration', async () => {
    const error = vi.spyOn(console, 'error').mockImplementation(() => {})
    const host = document.createElement('div')
    host.innerHTML = renderToString(<DocumentLoadScript code={CODE} />)
    expect(host.querySelector('script')).not.toBeNull()
    document.body.append(host)
    await act(async () => {
      hydrateRoot(host, <DocumentLoadScript code={CODE} />)
    })
    expect(host.querySelector('script')).toBeNull()
    host.remove()
    error.mockRestore()
  })

  it('document-load-script-008 opens with a bare script tag', () => {
    for (const code of ['a', 'window.__x = { y: 1 }', '']) {
      expect(renderToString(<DocumentLoadScript code={code} />).startsWith('<script>')).toBe(true)
    }
  })

  it('document-load-script-009 has no side effects on a client render', () => {
    // A first render lets React attach its one-time document listeners before the spies start.
    render(<DocumentLoadScript code={CODE} />)
    cleanup()
    const spies = [
      vi.spyOn(window, 'addEventListener'),
      vi.spyOn(document, 'addEventListener'),
      vi.spyOn(window, 'dispatchEvent'),
      vi.spyOn(document, 'dispatchEvent'),
      vi.spyOn(window.localStorage, 'getItem'),
      vi.spyOn(window.localStorage, 'setItem'),
      vi.spyOn(window.sessionStorage, 'getItem'),
      vi.spyOn(window.sessionStorage, 'setItem'),
      vi.spyOn(console, 'log').mockImplementation(() => {}),
      vi.spyOn(console, 'warn').mockImplementation(() => {}),
      vi.spyOn(console, 'error').mockImplementation(() => {}),
      vi.spyOn(console, 'info').mockImplementation(() => {}),
    ]
    render(<DocumentLoadScript code={CODE} />)
    for (const spy of spies) expect(spy).not.toHaveBeenCalled()
    for (const spy of spies) spy.mockRestore()
  })
})

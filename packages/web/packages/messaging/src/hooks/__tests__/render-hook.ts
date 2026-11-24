// A minimal `renderHook` for this package's hook tests. The messaging package does not
// depend on @testing-library/react, so the hook is mounted with react-dom directly and
// every state change is flushed through React's own `act`. Not a test file (no `.test.`).
import { act, createElement } from 'react'
import { createRoot } from 'react-dom/client'

;(globalThis as { IS_REACT_ACT_ENVIRONMENT?: boolean }).IS_REACT_ACT_ENVIRONMENT = true

export interface RenderedHook<T, P> {
  readonly result: { current: T }
  rerender: (props: P) => void
  unmount: () => void
}

export function renderHook<T, P = undefined>(hook: (props: P) => T, initialProps?: NoInfer<P>): RenderedHook<T, P> {
  const result = { current: undefined as unknown as T }
  const container = document.createElement('div')
  const root = createRoot(container)
  const Probe = ({ props }: { props: P }) => {
    result.current = hook(props)
    return null
  }
  const render = (props: P) => act(() => root.render(createElement(Probe, { props })))
  render(initialProps as P)
  let mounted = true
  return {
    result,
    rerender: (props) => render(props),
    unmount: () => {
      if (!mounted) return
      mounted = false
      act(() => root.unmount())
    },
  }
}

/** Retry `assertion` (flushing React and timers between tries) until it stops throwing. */
export async function waitFor(assertion: () => void, timeoutMs = 1000): Promise<void> {
  const start = Date.now()
  for (;;) {
    try {
      assertion()
      return
    } catch (err) {
      if (Date.now() - start > timeoutMs) throw err
      await act(async () => {
        await new Promise((r) => setTimeout(r, 5))
      })
    }
  }
}

/** A promise the test settles by hand, for ordering two in-flight requests. */
export function deferred<T>(): { promise: Promise<T>; resolve: (v: T) => void; reject: (e: unknown) => void } {
  let resolve!: (v: T) => void
  let reject!: (e: unknown) => void
  const promise = new Promise<T>((res, rej) => {
    resolve = res
    reject = rej
  })
  return { promise, resolve, reject }
}

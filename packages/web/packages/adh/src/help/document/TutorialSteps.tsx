'use client'

/**
 * A tutorial's Steps pane: every step with a checkbox, the step being worked on drawn with a
 * border. Ticking a step moves the border to the next step not yet done; the header's Start
 * clears every box and puts the border back on the first step, which is also how the pane opens
 * the first time. A step made of several actions lists them as sub-steps, each with an indented
 * box of its own: ticking the step ticks them all, and ticking the last of them ticks the step and
 * moves on. Progress is kept in this browser's localStorage per tutorial, so a reader who
 * comes back finds their place, and a tick in one tab shows in another.
 *
 * Its own tsup entry, imported by package path from the server DocumentDetail, so its
 * 'use client' marks this module only.
 */

import { useCallback, useEffect, useMemo, useRef, useSyncExternalStore, type ReactNode } from 'react'
import { StatCard } from '@adh-sdk/ui/blocks'
import { Button } from '@adh-sdk/ui/components/button'
import { Checkbox } from '@adh-sdk/ui/components/checkbox'
import type { TutorialStep } from './parts'
import { progressKey, readProgress, startOf, stepsDone, toggle, type TutorialProgress } from './progress'

/*
 * The saved progress as an external store, read through useSyncExternalStore. Every value this
 * page writes, or hears another tab write, is kept in `memory` as well as localStorage, so the
 * pane keeps working, unsaved, when storage is blocked (a private window, site data cleared).
 */
const memory = new Map<string, string | null>()
const listeners = new Map<string, Set<() => void>>()

function notify(key: string): void {
  for (const listener of listeners.get(key) ?? []) listener()
}

function load(key: string): string | null {
  if (memory.has(key)) return memory.get(key) ?? null
  try {
    return window.localStorage.getItem(key)
  } catch {
    return null
  }
}

function save(key: string, progress: TutorialProgress): void {
  const raw = JSON.stringify(progress)
  memory.set(key, raw)
  try {
    window.localStorage.setItem(key, raw)
  } catch {
    // Blocked: `memory` holds it for this page.
  }
  notify(key)
}

function subscribe(key: string, listener: () => void): () => void {
  const set = listeners.get(key) ?? new Set()
  listeners.set(key, set)
  set.add(listener)
  const fromAnotherTab = (event: StorageEvent) => {
    if (event.key !== key) return
    memory.set(key, event.newValue)
    listener()
  }
  window.addEventListener('storage', fromAnotherTab)
  return () => {
    set.delete(listener)
    window.removeEventListener('storage', fromAnotherTab)
  }
}

export function TutorialSteps({
  tutorialId,
  steps,
  title,
  icon,
}: {
  tutorialId: string
  steps: TutorialStep[]
  title: string
  icon?: ReactNode
}) {
  const key = progressKey(tutorialId)
  // The server, and the client while hydrating, render the starting state; React then re-renders
  // with the saved progress, so the two renders never disagree. The client snapshot is cached by
  // the raw stored string, so an unchanged store returns the same object and renders nothing.
  const serverProgress = useMemo(() => startOf(steps), [steps])
  const readSaved = useMemo(() => {
    let cache: { raw: string | null; value: TutorialProgress } | null = null
    return () => {
      const raw = load(key)
      if (!cache || cache.raw !== raw) cache = { raw, value: readProgress(raw, steps) }
      return cache.value
    }
  }, [key, steps])
  const listen = useCallback((listener: () => void) => subscribe(key, listener), [key])
  const progress = useSyncExternalStore(listen, readSaved, () => serverProgress)
  const follow = useRef(false)
  const rows = useRef(new Map<string, HTMLLIElement>())

  const update = useCallback(
    (next: TutorialProgress, scroll: boolean) => {
      follow.current = scroll
      save(key, next)
    },
    [key],
  )

  // Bring the newly active step into view when a tick moved it, never on load.
  useEffect(() => {
    if (!follow.current || !progress.active) return
    follow.current = false
    rows.current.get(progress.active)?.scrollIntoView({ behavior: 'smooth', block: 'nearest' })
  }, [progress.active])

  const count = stepsDone(progress, steps)

  return (
    <StatCard
      title={title}
      icon={icon}
      className="bg-apt-surface-2"
      actions={
        <span className="flex items-center gap-3">
          <span className="font-mono text-[11px] text-apt-text-dim" aria-live="polite">
            {count} of {steps.length} done
          </span>
          <Button
            size="sm"
            variant="outline"
            onClick={() => update(startOf(steps), true)}
            data-testid="tutorial-start"
          >
            Start
          </Button>
        </span>
      }
    >
      <ol className="flex flex-col gap-3" data-testid="tutorial-steps">
        {steps.map((step, i) => {
          const done = progress.done.includes(step.id)
          const active = progress.active === step.id
          const label = `tutorial-step-${step.id}`
          return (
            <li
              key={step.id}
              ref={(el) => {
                if (el) rows.current.set(step.id, el)
                else rows.current.delete(step.id)
              }}
              aria-current={active ? 'step' : undefined}
              data-done={done || undefined}
              className={`doc-step rounded-lg border p-4 transition-colors ${
                active ? 'border-apt-gold ring-2 ring-apt-gold/25' : 'border-apt-border'
              }`}
            >
              <div className="flex items-start gap-3">
                <Checkbox
                  className="mt-1"
                  checked={done}
                  onCheckedChange={(checked) => update(toggle(progress, steps, step.id, checked), true)}
                  aria-labelledby={label}
                  data-testid="tutorial-step-check"
                />
                <button
                  type="button"
                  id={label}
                  onClick={() => update({ ...progress, active: step.id }, false)}
                  className={`text-left text-[1.02rem] font-[650] leading-snug ${
                    done ? 'text-apt-text-dim line-through' : 'text-apt-text'
                  }`}
                >
                  <span className="mr-2 font-mono text-[12px] text-apt-text-muted">{i + 1}.</span>
                  <span dangerouslySetInnerHTML={{ __html: step.titleHtml }} />
                </button>
              </div>
              {step.before.length || step.substeps.length || step.after.length ? (
                <div className={`mt-3 flex flex-col gap-3 pl-7 ${done ? 'opacity-70' : ''}`}>
                  {step.before.map((html, j) => (
                    <div key={`b${j}`} className="doc-copy" dangerouslySetInnerHTML={{ __html: html }} />
                  ))}
                  {step.substeps.length ? (
                    <ol className="flex flex-col gap-2.5" data-testid="tutorial-substeps">
                      {step.substeps.map((sub, n) => {
                        const subDone = progress.done.includes(sub.id)
                        const subLabel = `tutorial-substep-${sub.id.replace('/', '-')}`
                        return (
                          <li key={sub.id} data-done={subDone || undefined} className="doc-substep flex items-start gap-3">
                            <Checkbox
                              className="mt-[5px]"
                              checked={subDone}
                              onCheckedChange={(checked) => update(toggle(progress, steps, sub.id, checked), true)}
                              aria-labelledby={subLabel}
                              data-testid="tutorial-substep-check"
                            />
                            <div id={subLabel} className={`doc-copy flex-1 ${subDone ? 'text-apt-text-dim line-through' : ''}`}>
                              <span className="mr-2 font-mono text-[12px] text-apt-text-muted">{step.start + n}.</span>
                              <span dangerouslySetInnerHTML={{ __html: sub.html }} />
                            </div>
                          </li>
                        )
                      })}
                    </ol>
                  ) : null}
                  {step.after.map((html, j) => (
                    <div key={`a${j}`} className="doc-copy" dangerouslySetInnerHTML={{ __html: html }} />
                  ))}
                </div>
              ) : null}
            </li>
          )
        })}
      </ol>
    </StatCard>
  )
}

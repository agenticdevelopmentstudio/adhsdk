'use client'

import { type ReactNode } from 'react'
import { useRouter, useSelectedLayoutSegment } from 'next/navigation'
import {
  ColorModeProvider,
  ThemeStyle,
  type ThemeKey,
} from '@adh-sdk/themes'
import { examples } from './examples'
import { useDemoTheme } from './theme-store'
import { ThemeMenu } from './ThemeMenu'
import { Button } from '@/components/ui/button'

// The Shell chrome stays on a fixed toolkit theme; the picker only drives the
// scoped stage below. shadcn tokens (--background, …) render the chrome, so it
// is unaffected by the selected theme's --color-* tokens.
const SHELL_THEME: ThemeKey = 'myprojects'
const EXAMPLE_SCOPE = '.apt-example-content'

export function Shell({ children }: { children: ReactNode }) {
  const router = useRouter()
  const segment = useSelectedLayoutSegment()
  const [theme] = useDemoTheme()

  const activeId = segment ?? examples[0]?.id ?? ''
  const active = examples.find((e) => e.id === activeId) ?? examples[0]

  return (
    <ColorModeProvider>
      <ThemeStyle theme={SHELL_THEME} />
      <ThemeStyle theme={theme} scope={EXAMPLE_SCOPE} />

      <div className="flex h-screen w-full overflow-hidden bg-background text-foreground">
        <nav className="flex h-screen w-52 shrink-0 flex-col gap-1 border-r border-sidebar-border bg-sidebar p-3">
          <div className="px-2 pt-1 pb-4">
            <p className="font-serif text-lg leading-none">
              Agentic <span className="text-primary italic">Toolkit</span>
            </p>
            <p className="mt-1 font-mono text-[10px] tracking-[0.2em] text-muted-foreground uppercase">
              Component Demos
            </p>
          </div>
          <p className="px-2 pb-1 text-xs font-semibold tracking-wider text-muted-foreground uppercase">
            Examples
          </p>
          {examples.map((e) => (
            <Button
              key={e.id}
              variant={e.id === active?.id ? 'secondary' : 'ghost'}
              size="sm"
              className="justify-start font-normal"
              onClick={() => router.push(`/${e.id}/`)}
            >
              {e.label}
            </Button>
          ))}
        </nav>

        <div className="flex min-w-0 flex-1 flex-col">
          <header className="flex h-14 shrink-0 items-center justify-between gap-4 border-b border-border bg-card/30 px-5">
            <h1 className="font-serif text-xl">{active?.label}</h1>
            <div className="flex items-center gap-2">
              <span className="hidden text-xs text-muted-foreground sm:inline">Theme</span>
              <ThemeMenu className="w-44" />
            </div>
          </header>
          <main className="min-h-0 flex-1 overflow-hidden">{children}</main>
        </div>
      </div>
    </ColorModeProvider>
  )
}

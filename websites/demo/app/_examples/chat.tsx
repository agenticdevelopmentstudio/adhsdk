'use client'

import { useRef, useState } from 'react'
import { ExamplePanel } from '../ExamplePanel'
import {
  InlineChatView,
  ThreePaneChatView,
  MobileChatView,
  ContentOverlay,
  MockBackend,
  useChatSession,
  type InlineChatSizing,
  type ChatSizingBehavior,
  type SizingTransition,
} from '@adh-sdk/chat'
import '@adh-sdk/chat/css/base.css'
import '@adh-sdk/chat/css/modes/inline.css'
import '@adh-sdk/chat/css/modes/three-pane.css'
import '@adh-sdk/chat/css/modes/mobile.css'
import '@adh-sdk/chat/css/components/content-overlay.css'
import { Checkbox } from '@/components/ui/checkbox'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { RadioGroup, RadioGroupItem } from '@/components/ui/radio-group'
import { Separator } from '@/components/ui/separator'

type Mode = 'inline' | 'three-pane' | 'mobile'
type SizingKind = 'fixed' | 'hug-css' | 'hug-viewport' | 'hug-element'
type InactiveKind = 'same' | 'minimal'
type Horizontal = 'left' | 'center' | 'right'
type Vertical = 'top' | 'center' | 'bottom'
type Padding = { top: number; right: number; bottom: number; left: number }
type SizeBounds = { minW: number; maxW: number; minH: number; maxH: number }

const SIDEBAR_WIDTH = 240
const DEFAULT_PADDING: Padding = { top: 16, right: 32, bottom: 16, left: 32 }
const DEFAULT_SIZE: SizeBounds = { minW: 240, maxW: 600, minH: 200, maxH: 800 }

const backend = new MockBackend()

const persona = { name: 'Claire', avatar: 'C' }
const welcome = "Hello! I'm Claire, your research assistant. How can I help you today?"

function Section({ title, children }: { title: string; children: React.ReactNode }) {
  return (
    <div className="flex flex-col gap-2">
      <p className="text-xs font-semibold tracking-wider text-muted-foreground uppercase">
        {title}
      </p>
      {children}
    </div>
  )
}

const optionRow = 'flex items-center gap-2 text-sm font-normal'

export default function ChatExample() {
  const [mode, setMode] = useState<Mode>('inline')
  const [sizingKind, setSizingKind] = useState<SizingKind>('fixed')
  const [inactiveKind, setInactiveKind] = useState<InactiveKind>('same')
  const [transitionKind, setTransitionKind] = useState<SizingTransition>('animated')
  const [transparent, setTransparent] = useState(false)
  const [overlayOpen, setOverlayOpen] = useState(false)
  const [horizontal, setHorizontal] = useState<Horizontal>('center')
  const [vertical, setVertical] = useState<Vertical>('bottom')
  const [padding, setPadding] = useState<Padding>(DEFAULT_PADDING)
  const [size, setSize] = useState<SizeBounds>(DEFAULT_SIZE)

  const headerRef = useRef<HTMLElement | null>(null)

  const activeBehavior: ChatSizingBehavior =
    sizingKind === 'fixed'
      ? { mode: 'fixed' }
      : sizingKind === 'hug-css'
        ? { mode: 'content-hugging', maxHeight: { kind: 'css', value: '400px' } }
        : sizingKind === 'hug-viewport'
          ? { mode: 'content-hugging', maxHeight: { kind: 'viewport-offset', topOffsetPx: 80 } }
          : { mode: 'content-hugging', maxHeight: { kind: 'element-offset', ref: headerRef, gapPx: 16 } }

  const sizing: InlineChatSizing = {
    active: activeBehavior,
    inactive: inactiveKind === 'minimal' ? { mode: 'minimal' } : undefined,
    transition: transitionKind,
  }

  const session = useChatSession({
    backend,
    persona,
    user: { name: 'You', avatar: 'Y' },
    welcomeMessage: welcome,
  })

  const hRule =
    horizontal === 'left' ? `left: 0; right: auto;`
      : horizontal === 'right' ? `right: 0; left: auto;`
        : `left: 50%; right: auto;`
  const vRule =
    vertical === 'top' ? `top: 0; bottom: auto;`
      : vertical === 'bottom' ? `bottom: 0; top: auto;`
        : `top: 50%; bottom: auto;`
  const tx = horizontal === 'center' ? '-50%' : '0'
  const ty = vertical === 'center' ? '-50%' : '0'
  const transformRule = tx === '0' && ty === '0' ? 'transform: none;' : `transform: translate(${tx}, ${ty});`
  // The `minimal` idle state must be free to hug just the input bar, so drop
  // the demo's min-height floor while it's selected for the inline chat.
  const effectiveMinH = mode === 'inline' && inactiveKind === 'minimal' ? 0 : size.minH
  const sizeRule = `min-width: ${size.minW}px; max-width: ${size.maxW}px; min-height: ${effectiveMinH}px; max-height: ${size.maxH}px;`
  const layoutOverrides = `
    .pc-inline,
    .pc-three-pane-frame { position: absolute !important; ${hRule} ${vRule} ${transformRule} ${sizeRule} }
  `

  const patternColor = 'var(--color-pattern, rgba(0,0,0,0.07))'
  const mainBackground = `radial-gradient(circle, ${patternColor} 1.5px, transparent 1.5px)`

  return (
    <ExamplePanel>
      <style>{`
        .pc-mobile-overlay { position: absolute !important; left: ${SIDEBAR_WIDTH}px !important; top: 0; right: 0; bottom: 0; }
        .pc-content-overlay { position: absolute !important; left: ${SIDEBAR_WIDTH}px !important; top: 0; right: 0; bottom: 0; }
        ${layoutOverrides}
      `}</style>

      <nav
        style={{ width: SIDEBAR_WIDTH }}
        className="absolute inset-y-0 left-0 z-[200] flex flex-col gap-4 overflow-y-auto border-r border-border bg-card p-4 text-card-foreground"
      >
        <Label className={optionRow}>
          <Checkbox
            checked={transparent}
            onCheckedChange={(c) => setTransparent(c === true)}
          />
          transparent chat
        </Label>

        <Separator />

        <Section title="Mode">
          <Label className={optionRow}>
            <Checkbox
              checked={mode === 'three-pane'}
              onCheckedChange={(c) => setMode(c === true ? 'three-pane' : 'inline')}
            />
            three pane
          </Label>
          <Label className={optionRow}>
            <Checkbox
              checked={mode === 'mobile'}
              onCheckedChange={(c) => setMode(c === true ? 'mobile' : 'inline')}
            />
            mobile overlay
          </Label>
          <Label className={optionRow}>
            <Checkbox
              checked={overlayOpen}
              onCheckedChange={(c) => setOverlayOpen(c === true)}
            />
            content overlay
          </Label>
        </Section>

        <Separator />

        <Section title="Sizing behavior">
          <RadioGroup
            value={sizingKind}
            onValueChange={(v) => setSizingKind(v as SizingKind)}
            className="gap-2"
          >
            <Label className={optionRow}>
              <RadioGroupItem value="fixed" /> fixed
            </Label>
            <Label className={optionRow}>
              <RadioGroupItem value="hug-css" /> hug + 400px
            </Label>
            <Label className={optionRow}>
              <RadioGroupItem value="hug-viewport" /> hug + viewport(80)
            </Label>
            <Label className={optionRow}>
              <RadioGroupItem value="hug-element" /> hug + element(header)
            </Label>
          </RadioGroup>
        </Section>

        <Separator />

        <Section title="Inactive (idle)">
          <RadioGroup
            value={inactiveKind}
            onValueChange={(v) => setInactiveKind(v as InactiveKind)}
            className="gap-2"
          >
            <Label className={optionRow}>
              <RadioGroupItem value="same" /> same as active
            </Label>
            <Label className={optionRow}>
              <RadioGroupItem value="minimal" /> minimal (input only)
            </Label>
          </RadioGroup>
        </Section>

        <Separator />

        <Section title="Transition">
          <RadioGroup
            value={transitionKind}
            onValueChange={(v) => setTransitionKind(v as SizingTransition)}
            className="gap-2"
          >
            <Label className={optionRow}>
              <RadioGroupItem value="none" /> none (instant)
            </Label>
            <Label className={optionRow}>
              <RadioGroupItem value="animated" /> animated (grow up/down)
            </Label>
          </RadioGroup>
        </Section>

        <Separator />

        <Section title="Layout">
          <span className="text-xs text-muted-foreground">horizontal</span>
          <RadioGroup
            value={horizontal}
            onValueChange={(v) => setHorizontal(v as Horizontal)}
            className="gap-2"
          >
            {(['left', 'center', 'right'] as Horizontal[]).map((h) => (
              <Label key={h} className={optionRow}>
                <RadioGroupItem value={h} /> {h}
              </Label>
            ))}
          </RadioGroup>
          <span className="mt-1 text-xs text-muted-foreground">vertical</span>
          <RadioGroup
            value={vertical}
            onValueChange={(v) => setVertical(v as Vertical)}
            className="gap-2"
          >
            {(['top', 'center', 'bottom'] as Vertical[]).map((v) => (
              <Label key={v} className={optionRow}>
                <RadioGroupItem value={v} /> {v}
              </Label>
            ))}
          </RadioGroup>
        </Section>

        <Separator />

        <Section title="Size">
          {([
            ['minW', 'min width'],
            ['maxW', 'max width'],
            ['minH', 'min height'],
            ['maxH', 'max height'],
          ] as const).map(([key, label]) => (
            <div key={key} className="flex items-center justify-between gap-2 text-sm">
              <span>{label}</span>
              <Input
                type="number"
                value={size[key]}
                onChange={(e) => setSize({ ...size, [key]: Number(e.target.value) || 0 })}
                className="h-7 w-20"
              />
            </div>
          ))}
        </Section>

        <Separator />

        <Section title="Padding">
          {(['top', 'right', 'bottom', 'left'] as (keyof Padding)[]).map((side) => (
            <div key={side} className="flex items-center justify-between gap-2 text-sm">
              <span>{side}</span>
              <Input
                type="number"
                value={padding[side]}
                onChange={(e) => setPadding({ ...padding, [side]: Number(e.target.value) || 0 })}
                className="h-7 w-20"
              />
            </div>
          ))}
        </Section>
      </nav>

      <main
        style={{
          position: 'absolute',
          top: 0,
          left: SIDEBAR_WIDTH,
          right: 0,
          bottom: 0,
          backgroundImage: mainBackground,
          backgroundSize: '24px 24px',
          backgroundPosition: '0 0',
          backgroundRepeat: 'repeat',
          color: 'var(--color-text-primary)',
          overflow: 'hidden',
        }}
      >
        <header
          ref={headerRef}
          style={{
            padding: '1.25rem 1.5rem',
            fontSize: '0.85rem',
            color: 'var(--color-text-secondary)',
            borderBottom: '1px solid var(--color-border)',
          }}
        >
          Sizing demo — anchor for the &quot;hug + element(header)&quot; mode. Pick a theme from the
          Theme menu in the header to restyle the chat.
        </header>

        <div
          style={{
            position: 'absolute',
            top: padding.top,
            right: padding.right,
            bottom: padding.bottom,
            left: padding.left,
            pointerEvents: 'none',
          }}
        >
          {mode === 'inline' && (
            <div className="pc-inline" style={{ pointerEvents: 'auto' }}>
              <InlineChatView
                session={session}
                sizing={sizing}
                className={transparent ? 'pc-transparent' : ''}
              />
            </div>
          )}

          {mode === 'three-pane' && (
            <div style={{ pointerEvents: 'auto', position: 'absolute', inset: 0 }}>
              <ThreePaneChatView
                session={session}
                className={transparent ? 'pc-transparent' : ''}
              />
            </div>
          )}
        </div>

        {mode === 'mobile' && (
          <MobileChatView session={session} open onClose={() => setMode('inline')} />
        )}

        <ContentOverlay open={overlayOpen} onClose={() => setOverlayOpen(false)}>
          <div style={{ flex: 1, minHeight: 0 }} />
        </ContentOverlay>
      </main>
    </ExamplePanel>
  )
}

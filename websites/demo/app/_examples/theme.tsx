'use client'

import { useEffect, useMemo, useState, type ReactNode } from 'react'
import { ExamplePanel } from '../ExamplePanel'
import {
  InlineChatView,
  MockBackend,
  useChatSession,
} from '@adh-sdk/chat'
import '@adh-sdk/chat/css/base.css'
import '@adh-sdk/chat/css/modes/inline.css'
import { themes, type ThemeKey } from '@adh-sdk/themes'
import { useDemoTheme } from '../theme-store'
import { Button } from '@/components/ui/button'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { ScrollArea } from '@/components/ui/scroll-area'
import { noAutofillProps } from '@/lib/autofill'

const SITE_TOKENS = [
  '--color-surface',
  '--color-surface-raised',
  '--color-surface-hover',
  '--color-border',
  '--color-border-subtle',
  '--color-text-primary',
  '--color-text-secondary',
  '--color-text-dim',
  '--color-accent',
  '--color-accent-dim',
  '--color-success',
  '--color-error',
  '--color-info',
]

const CHAT_TOKENS = [
  '--pc-surface',
  '--pc-persona-bg',
  '--pc-persona-border',
  '--pc-persona-text',
  '--pc-persona-name',
  '--pc-user-bg',
  '--pc-user-border',
  '--pc-user-text',
  '--pc-user-name',
  '--pc-input-bg',
  '--pc-input-border',
  '--pc-input-focus',
  '--pc-send-bg',
  '--pc-send-text',
  '--pc-time-color',
]

function Swatch({ token }: { token: string }) {
  return (
    <div className="apt-swatch">
      <div className="apt-swatch-chip" style={{ background: `var(${token})` }} />
      <code>{token}</code>
    </div>
  )
}

function PaletteGrid({ tokens, title }: { tokens: string[]; title: string }) {
  return (
    <div>
      <h3 className="apt-subhead">{title}</h3>
      <div className="apt-swatch-grid">
        {tokens.map((t) => (
          <Swatch key={t} token={t} />
        ))}
      </div>
    </div>
  )
}

const SAMPLE_BACKEND = new MockBackend()
const SAMPLE_PERSONA = { name: 'Claire', avatar: 'C' }

function ChatSample() {
  const session = useChatSession({
    persona: SAMPLE_PERSONA,
    backend: SAMPLE_BACKEND,
    welcomeMessage:
      "Hello! I'm a sample chat — useful for previewing chat surface tokens.",
  })
  useEffect(() => {
    session.sendMessage('How does this theme look in dark mode?')
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [])
  return (
    <div className="apt-chat-sample">
      <InlineChatView session={session} sizing={{ active: { mode: 'fixed' } }} />
    </div>
  )
}

interface Example {
  label: string
  demo: ReactNode
  css: string
}

function CodeBlock({ code }: { code: string }) {
  return (
    <pre className="max-h-[480px] overflow-auto rounded-md border border-border bg-muted p-4 font-mono text-xs leading-relaxed whitespace-pre text-foreground">
      <code>{code}</code>
    </pre>
  )
}

function ExampleCard({ example }: { example: Example }) {
  return (
    <Card>
      <CardHeader>
        <CardTitle className="text-xs font-semibold tracking-wider text-muted-foreground uppercase">
          {example.label}
        </CardTitle>
      </CardHeader>
      <CardContent className="grid gap-4 lg:grid-cols-2">
        <div className="apt-theme-card-demo">{example.demo}</div>
        <div className="min-w-0">
          <CodeBlock code={example.css} />
        </div>
      </CardContent>
    </Card>
  )
}

function ExampleList({ examples }: { examples: Example[] }) {
  return (
    <div className="flex flex-col gap-6">
      {examples.map((ex) => (
        <ExampleCard key={ex.label} example={ex} />
      ))}
    </div>
  )
}

const SWATCH_CSS = `.apt-swatch {
  display: flex;
  align-items: center;
  gap: 0.5rem;
  padding: 0.4rem;
  border: 1px solid var(--color-border-subtle);
  border-radius: 6px;
  background: var(--color-surface-raised);
}
.apt-swatch-chip {
  width: 28px;
  height: 28px;
  border-radius: 4px;
  border: 1px solid var(--color-border-subtle);
}
.apt-swatch code {
  font-family: var(--font-mono);
  font-size: 0.72rem;
  color: var(--color-text-secondary);
}`

const HEADINGS_CSS = `.apt-typography h1 {
  font-family: var(--font-display);
  font-size: 2rem;
}
.apt-typography h2 {
  font-family: var(--font-display);
  font-size: 1.4rem;
}
.apt-typography h3 {
  font-size: 1.1rem;
  font-weight: 600;
}
.apt-typography h4 {
  font-size: 0.95rem;
  font-weight: 600;
  color: var(--color-text-secondary);
}`

const BODY_TEXT_CSS = `.apt-typography p {
  max-width: 70ch;
}
.apt-typography a {
  color: var(--color-accent);
  text-decoration: underline;
}
.apt-typography code {
  font-family: var(--font-mono);
  background: var(--color-surface-raised);
  padding: 0.1em 0.3em;
  border: 1px solid var(--color-border-subtle);
  border-radius: 3px;
}
.apt-small-caps {
  text-transform: uppercase;
  letter-spacing: 0.1em;
  color: var(--color-text-dim);
}`

const BLOCKQUOTE_CSS = `.apt-typography blockquote {
  color: var(--color-text-secondary);
  border-left: 2px solid var(--color-accent);
  font-style: italic;
}
.apt-typography pre {
  font-family: var(--font-mono);
  background: var(--color-surface-raised);
  border: 1px solid var(--color-border-subtle);
  border-radius: 6px;
}`

const SURFACES_CSS = `.apt-card {
  padding: 1rem;
  border-radius: 8px;
}
.apt-surface {
  background: var(--color-surface);
  border: 1px solid var(--color-border);
}
.apt-raised {
  background: var(--color-surface-raised);
  border: 1px solid var(--color-border-subtle);
}
.apt-hover {
  background: var(--color-surface-hover);
  border: 1px solid var(--color-border-subtle);
}`

const BUTTONS_CSS = `.apt-btn-primary {
  background: var(--color-accent);
  color: var(--color-surface);
}
.apt-btn-secondary {
  background: var(--color-surface-raised);
  color: var(--color-text-primary);
  border-color: var(--color-border);
}
.apt-btn-ghost {
  background: transparent;
  color: var(--color-text-secondary);
}`

const INPUTS_CSS = `.apt-controls input[type="text"] {
  border: 1px solid var(--color-border);
  background: var(--color-surface-raised);
  color: var(--color-text-primary);
}
.apt-controls input[type="text"]:focus {
  border-color: var(--color-accent);
  box-shadow: 0 0 0 2px var(--color-accent-dim);
}`

const STATUS_CSS = `.apt-status-success {
  color: var(--color-success);
  border-color: var(--color-success);
  background: color-mix(in srgb, var(--color-success) 12%, transparent);
}
.apt-status-error {
  color: var(--color-error);
  border-color: var(--color-error);
  background: color-mix(in srgb, var(--color-error) 12%, transparent);
}
.apt-status-info {
  color: var(--color-info);
  border-color: var(--color-info);
  background: color-mix(in srgb, var(--color-info) 12%, transparent);
}`

const MOTION_CSS = `.apt-fade-loop {
  animation: apt-fade-loop 2.5s ease-in-out infinite;
}
@keyframes apt-fade-loop {
  0%, 100% { opacity: 1; }
  50%      { opacity: 0.3; }
}

.apt-dots-loop span {
  background: var(--color-accent);
  animation: apt-dots-pulse 1.4s ease-in-out infinite;
}`

const ELEVATION_CSS = `.apt-elevation-card {
  background: color-mix(in srgb, var(--color-surface) 80%, transparent);
  border: 1px solid var(--color-border);
  backdrop-filter: blur(8px);
  box-shadow: 0 8px 24px color-mix(in srgb, var(--color-text-primary) 25%, transparent);
}`

const CHROME_CSS = `.apt-chrome-scroll {
  border: 1px solid var(--color-border);
  background: var(--color-surface-raised);
}
.apt-chrome-caret {
  border: 1px solid var(--color-border);
  background: var(--color-surface-raised);
  color: var(--color-text-primary);
}`

const CHAT_CSS = `/* Chat surface tokens — set per theme:
   --pc-surface, --pc-persona-bg, --pc-persona-border, --pc-persona-text,
   --pc-persona-name, --pc-user-bg, --pc-user-border, --pc-user-text,
   --pc-user-name, --pc-input-bg, --pc-input-border, --pc-input-focus,
   --pc-send-bg, --pc-send-text, --pc-time-color */`

interface Topic {
  id: string
  label: string
  description?: string
  render: (ctx: { activeTheme: ThemeKey }) => ReactNode
}

const TOPICS: Topic[] = [
  {
    id: 'css',
    label: 'CSS',
    description: 'The full CSS source for the active theme variant.',
    render: ({ activeTheme }) => {
      const css = themes[activeTheme].css
      return (
        <div className="apt-theme-css">
          <p className="apt-theme-css-note">
            Source CSS for the active theme variant:{' '}
            <strong>{themes[activeTheme].label}</strong>. Switch the variant from
            the Theme menu in the header to see this update.
          </p>
          <CodeBlock code={css} />
        </div>
      )
    },
  },
  {
    id: 'palette',
    label: 'Color palette',
    description: 'Every color token in the active theme.',
    render: () => (
      <ExampleList
        examples={[
          { label: 'Site tokens', demo: <PaletteGrid tokens={SITE_TOKENS} title="Site" />, css: SWATCH_CSS },
          { label: 'Chat tokens', demo: <PaletteGrid tokens={CHAT_TOKENS} title="Chat" />, css: SWATCH_CSS },
        ]}
      />
    ),
  },
  {
    id: 'typography',
    label: 'Typography',
    description: 'Display, sans, and mono fonts — sizes, weights, decorations.',
    render: () => (
      <ExampleList
        examples={[
          {
            label: 'Headings',
            demo: (
              <div className="apt-typography">
                <h1>The quick brown fox jumps over the lazy dog</h1>
                <h2>Heading 2 — section divider</h2>
                <h3>Heading 3 — sub-section</h3>
                <h4>Heading 4 — minor heading</h4>
              </div>
            ),
            css: HEADINGS_CSS,
          },
          {
            label: 'Body text',
            demo: (
              <div className="apt-typography">
                <p>
                  Body paragraph using the theme&rsquo;s sans font.{' '}
                  <a href="#">Inline link</a> and <code>inline code</code> for
                  monospaced fragments.
                </p>
                <p className="apt-small-caps">Small caps eyebrow label</p>
              </div>
            ),
            css: BODY_TEXT_CSS,
          },
          {
            label: 'Blockquote & code block',
            demo: (
              <div className="apt-typography">
                <blockquote>
                  Blockquote using the theme&rsquo;s quote treatment — typically a
                  quieter color and a left border.
                </blockquote>
                <pre>
                  <code>{`function example(theme: ThemeKey) {\n  return themes[theme].css\n}`}</code>
                </pre>
              </div>
            ),
            css: BLOCKQUOTE_CSS,
          },
        ]}
      />
    ),
  },
  {
    id: 'surfaces',
    label: 'Surfaces',
    description: 'Surface, raised, hover layers with both border tokens.',
    render: () => (
      <ExampleList
        examples={[
          {
            label: 'Layered surfaces',
            demo: (
              <div className="apt-surfaces">
                <div className="apt-card apt-surface">
                  <div className="apt-card-label">surface</div>
                  <div className="apt-card apt-raised">
                    <div className="apt-card-label">surface-raised</div>
                    <div className="apt-card apt-hover">
                      <div className="apt-card-label">surface-hover</div>
                      <div className="apt-card-divider" />
                      <p>Border tokens shown above (border) and below (border-subtle).</p>
                      <div className="apt-card-divider apt-divider-subtle" />
                    </div>
                  </div>
                </div>
              </div>
            ),
            css: SURFACES_CSS,
          },
        ]}
      />
    ),
  },
  {
    id: 'controls',
    label: 'Controls',
    description: 'Buttons, inputs, checkboxes.',
    render: () => (
      <ExampleList
        examples={[
          {
            label: 'Buttons',
            demo: (
              <div className="apt-controls">
                <div className="apt-control-row">
                  <button className="apt-btn apt-btn-primary">Primary</button>
                  <button className="apt-btn apt-btn-secondary">Secondary</button>
                  <button className="apt-btn apt-btn-ghost">Ghost</button>
                </div>
              </div>
            ),
            css: BUTTONS_CSS,
          },
          {
            label: 'Inputs & checkbox',
            demo: (
              <div className="apt-controls">
                <div className="apt-control-row">
                  <input type="text" placeholder="Default input" {...noAutofillProps} />
                  <input type="text" placeholder="Focused input — click to focus" {...noAutofillProps} />
                </div>
                <label className="apt-control-row">
                  <input type="checkbox" defaultChecked /> Checkbox
                </label>
              </div>
            ),
            css: INPUTS_CSS,
          },
        ]}
      />
    ),
  },
  {
    id: 'status',
    label: 'Status',
    description: 'Success, error, info callouts.',
    render: () => (
      <ExampleList
        examples={[
          {
            label: 'Status callouts',
            demo: (
              <div className="apt-status-stack">
                <div className="apt-status apt-status-success">Save succeeded — your changes are persisted.</div>
                <div className="apt-status apt-status-error">Could not connect — retry in a few seconds.</div>
                <div className="apt-status apt-status-info">A new version of the toolkit is available.</div>
              </div>
            ),
            css: STATUS_CSS,
          },
        ]}
      />
    ),
  },
  {
    id: 'motion',
    label: 'Motion',
    description: 'Animations and transitions the theme defines.',
    render: () => (
      <ExampleList
        examples={[
          {
            label: 'Looping animations',
            demo: (
              <div className="apt-motion">
                <div className="apt-fade-loop">Fade-in animation (replays every 2.5s)</div>
                <div className="apt-dots-loop">
                  <span></span>
                  <span></span>
                  <span></span>
                </div>
                <p className="apt-motion-note">
                  Themes can disable motion entirely (e.g., terminal). If you see no movement, that&rsquo;s intentional.
                </p>
              </div>
            ),
            css: MOTION_CSS,
          },
        ]}
      />
    ),
  },
  {
    id: 'elevation',
    label: 'Elevation',
    description: 'Shadows and backdrop filters.',
    render: () => (
      <ExampleList
        examples={[
          {
            label: 'Elevated card',
            demo: (
              <div className="apt-elevation-stage">
                <div className="apt-elevation-bg" />
                <div className="apt-elevation-card">
                  <h3>Elevated card</h3>
                  <p>Drop shadow + (when defined) backdrop-filter blur, layered over a translucent surface.</p>
                </div>
              </div>
            ),
            css: ELEVATION_CSS,
          },
        ]}
      />
    ),
  },
  {
    id: 'chrome',
    label: 'Decorative chrome',
    description: 'Selection, scrollbar, caret.',
    render: () => (
      <ExampleList
        examples={[
          {
            label: 'Selection, scrollbar, caret',
            demo: (
              <div className="apt-chrome">
                <p className="apt-chrome-select">Select this sentence with your cursor to see ::selection styling.</p>
                <div className="apt-chrome-scroll">
                  <p>Scrollable inner panel — drag to see the theme&rsquo;s scrollbar treatment.</p>
                  <p>Line two.</p>
                  <p>Line three.</p>
                  <p>Line four.</p>
                  <p>Line five.</p>
                  <p>Line six.</p>
                  <p>Line seven.</p>
                  <p>Line eight.</p>
                </div>
                <input type="text" defaultValue="Caret color appears when this input is focused" className="apt-chrome-caret" {...noAutofillProps} />
              </div>
            ),
            css: CHROME_CSS,
          },
        ]}
      />
    ),
  },
  {
    id: 'chat',
    label: 'Chat sample',
    description: 'A compact chat surface using the theme.',
    render: () => (
      <ExampleList
        examples={[
          {
            label: 'Inline chat',
            demo: <ChatSample />,
            css: CHAT_CSS,
          },
        ]}
      />
    ),
  },
]

export default function ThemeExample() {
  const [activeTheme] = useDemoTheme()
  const [topicId, setTopicId] = useState<string>(TOPICS[0].id)
  const topic = useMemo(
    () => TOPICS.find((t) => t.id === topicId) ?? TOPICS[0],
    [topicId],
  )

  return (
    <ExamplePanel style={{ padding: 0 }}>
      <div className="flex h-full min-h-0 bg-background text-foreground">
        <aside className="flex w-56 shrink-0 flex-col border-r border-border bg-card" aria-label="Theme topics">
          <p className="px-4 pt-4 pb-2 text-xs font-semibold tracking-wider text-muted-foreground uppercase">
            Topics
          </p>
          <ScrollArea className="min-h-0 flex-1">
            <div className="flex flex-col gap-1 px-2 pb-3">
              {TOPICS.map((t) => (
                <Button
                  key={t.id}
                  variant={t.id === topic.id ? 'secondary' : 'ghost'}
                  size="sm"
                  className="justify-start font-normal"
                  aria-pressed={t.id === topic.id}
                  onClick={() => setTopicId(t.id)}
                >
                  {t.label}
                </Button>
              ))}
            </div>
          </ScrollArea>
        </aside>

        <section className="flex min-w-0 flex-1 flex-col overflow-hidden bg-background">
          <header className="shrink-0 border-b border-border px-8 pt-6 pb-3">
            <h1 className="font-serif text-2xl">{topic.label}</h1>
            {topic.description && (
              <p className="mt-1 max-w-[60ch] text-sm text-muted-foreground">
                {topic.description}
              </p>
            )}
          </header>
          <div className="min-h-0 flex-1 overflow-y-auto px-8 py-6">
            {topic.render({ activeTheme })}
          </div>
        </section>
      </div>
    </ExamplePanel>
  )
}

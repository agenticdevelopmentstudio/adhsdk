import type { ReactNode } from "react"
import { File, Globe, Image as ImageIcon } from "lucide-react"

import { EmptyState } from "../components/empty-state"
import { ExternalLink } from "../components/external-link"
import { cn } from "../lib/utils"

// A list of links: an icon by kind, the title as a new-tab link, a muted
// description, and for an image a bounded thumbnail that links to it. A
// missing row shows the title struck through and dim, with no link at all.

export interface LinkItem {
  title: ReactNode
  href?: string
  description?: ReactNode
  kind?: "url" | "file"
  /** An image: Image icon, and a thumbnail when `href` is set. */
  image?: boolean
  /** The target is gone: struck-through title, no link, no thumbnail. */
  missing?: boolean
}

export interface LinkListProps {
  links: LinkItem[]
  /** Shown when there are no links. */
  emptyLabel?: string
  className?: string
}

export function LinkList({ links, emptyLabel = "No links yet.", className }: LinkListProps) {
  if (links.length === 0) return <EmptyState title={emptyLabel} className={className} />
  return (
    <ul className={cn("flex flex-col gap-3", className)}>
      {links.map((link, i) => {
        const Icon = link.image ? ImageIcon : link.kind === "file" ? File : Globe
        const href = link.missing ? undefined : link.href
        return (
          <li key={i} className="flex items-start gap-2 text-sm">
            <Icon aria-hidden className="mt-0.5 size-4 shrink-0 text-apt-text-muted" />
            <div className="flex min-w-0 flex-col gap-1">
              <div className="flex items-baseline gap-2">
                {link.missing ? (
                  <span className="text-apt-text-dim line-through">{link.title}</span>
                ) : href ? (
                  <ExternalLink href={href} glyph={false} className="whitespace-normal text-sm">
                    {link.title}
                  </ExternalLink>
                ) : (
                  <span className="text-apt-text">{link.title}</span>
                )}
                {link.missing && <span className="text-xs text-apt-text-dim">missing</span>}
              </div>
              {link.description && <div className="text-xs text-apt-text-muted">{link.description}</div>}
              {link.image && href && (
                <a
                  href={href}
                  target="_blank"
                  rel="noopener noreferrer"
                  tabIndex={-1}
                  className="block w-fit rounded-md outline-none focus-visible:ring-2 focus-visible:ring-apt-gold/40"
                >
                  <img
                    src={href}
                    alt=""
                    loading="lazy"
                    className="max-h-48 rounded-md border border-apt-border"
                  />
                </a>
              )}
            </div>
          </li>
        )
      })}
    </ul>
  )
}

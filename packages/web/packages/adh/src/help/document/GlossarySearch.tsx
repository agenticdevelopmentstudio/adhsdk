'use client'

/**
 * The Glossary pane: every term, with a search field that narrows the list as the reader types.
 * A term matches when each word typed is in its name or its definition. Each term lists the
 * tutorials that use it, and carries an anchor (`#<term id>`) so a tutorial can link straight to it.
 *
 * Its own tsup entry, imported by package path from the server DocumentDetail, so its
 * 'use client' marks this module only.
 */

import { useMemo, useState, type ReactNode } from 'react'
import Link from 'next/link'
import { StatCard } from '@adh-sdk/ui/blocks'
import { SearchFilterBar } from '@adh-sdk/ui/components/search-filter-bar'
import { termMatches, type GlossaryTerm } from './parts'
import { TermBlock } from './TermBlock'
import type { DocRef } from './model'

export function GlossarySearch({
  terms,
  tutorials,
  title,
  icon,
}: {
  terms: GlossaryTerm[]
  tutorials: Record<string, DocRef>
  title: string
  icon?: ReactNode
}) {
  const [query, setQuery] = useState('')
  const shown = useMemo(() => terms.filter((term) => termMatches(term, query)), [terms, query])

  return (
    <StatCard title={title} icon={icon} className="bg-apt-surface-2">
      <div className="flex flex-col gap-4">
        <SearchFilterBar
          search={{
            value: query,
            onChange: setQuery,
            label: 'Search the glossary',
            placeholder: 'Search terms and definitions',
          }}
        />
        <p className="font-mono text-[11px] text-apt-text-dim" aria-live="polite">
          {shown.length === terms.length
            ? `${terms.length} terms`
            : `${shown.length} of ${terms.length} terms`}
        </p>
        {shown.length ? (
          <dl className="flex flex-col gap-3" data-testid="glossary-terms">
            {shown.map((term) => (
              <TermBlock key={term.id} term={term} anchor>
                {term.tutorials.length ? (
                    <p className="text-sm text-apt-text-dim">
                      <span className="font-semibold text-apt-text">Tutorials: </span>
                      {term.tutorials.map((id, i) => (
                        <span key={id}>
                          {i ? ', ' : null}
                          <Link
                            href={tutorials[id]?.href ?? '#'}
                            className="text-apt-gold underline-offset-2 hover:underline"
                          >
                            {tutorials[id]?.name ?? id}
                          </Link>
                        </span>
                      ))}
                    </p>
                ) : null}
              </TermBlock>
            ))}
          </dl>
        ) : (
          <p className="text-sm text-apt-text-dim">No term matches “{query}”.</p>
        )}
      </div>
    </StatCard>
  )
}

/**
 * One glossary term and its definition, set apart in a block of its own with the term in gold.
 * The Glossary pane and a tutorial's Definitions pane both draw a term with it, inside a `<dl>`.
 *
 * No directive and no hooks: the server DocumentDetail and the client GlossarySearch each import
 * it, and it renders the same in either.
 */

import type { ReactNode } from "react";
import Link from "next/link";

export function TermBlock({
  term,
  href,
  anchor = false,
  arrived = false,
  children,
}: {
  term: { id: string; titleHtml: string; html: readonly string[] };
  /** Where the term's name links to, such as its place in the Glossary. */
  href?: string;
  /** Whether the block carries the term's id, so `#<term id>` scrolls to it. */
  anchor?: boolean;
  /** Whether a link just arrived at this term, which outlines it. */
  arrived?: boolean;
  /** Anything to show under the definition, such as the tutorials that use the term. */
  children?: ReactNode;
}) {
  const name = <span dangerouslySetInnerHTML={{ __html: term.titleHtml }} />;
  return (
    <div
      id={anchor ? term.id : undefined}
      data-arrived={arrived || undefined}
      className="doc-term scroll-mt-6 flex flex-col gap-2 rounded-md border border-apt-border bg-apt-surface px-4 py-3.5"
    >
      <dt className="text-[1.1rem] font-[650] leading-snug text-apt-gold">
        {href ? (
          <Link href={href} className="underline-offset-4 hover:underline">
            {name}
          </Link>
        ) : (
          name
        )}
      </dt>
      <dd className="flex flex-col gap-2">
        {term.html.map((html, i) => (
          <div key={i} className="doc-copy" dangerouslySetInnerHTML={{ __html: html }} />
        ))}
        {children}
      </dd>
    </div>
  );
}

/**
 * The Glossary pane: every term, with a search field that narrows the list as the reader types.
 * A term matches when each word typed is in its name or its definition. Each term lists the
 * tutorials that use it, and carries an anchor (`#<term id>`) so a tutorial can link straight to it.
 *
 * Its own tsup entry, imported by package path from the server DocumentDetail, so its
 * 'use client' marks this module only.
 */
import { type ReactNode } from 'react';
import { type GlossaryTerm } from './parts';
import type { DocRef } from './model';
export declare function GlossarySearch({ terms, tutorials, title, icon, }: {
    terms: GlossaryTerm[];
    tutorials: Record<string, DocRef>;
    title: string;
    icon?: ReactNode;
}): import("react").JSX.Element;
//# sourceMappingURL=GlossarySearch.d.ts.map
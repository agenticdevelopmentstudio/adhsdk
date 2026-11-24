/**
 * One glossary term and its definition, set apart in a block of its own with the term in gold.
 * The Glossary pane and a tutorial's Definitions pane both draw a term with it, inside a `<dl>`.
 *
 * No directive and no hooks: the server DocumentDetail and the client GlossarySearch each import
 * it, and it renders the same in either.
 */
import type { ReactNode } from "react";
export declare function TermBlock({ term, href, anchor, arrived, children, }: {
    term: {
        id: string;
        titleHtml: string;
        html: readonly string[];
    };
    /** Where the term's name links to, such as its place in the Glossary. */
    href?: string;
    /** Whether the block carries the term's id, so `#<term id>` scrolls to it. */
    anchor?: boolean;
    /** Whether a link just arrived at this term, which outlines it. */
    arrived?: boolean;
    /** Anything to show under the definition, such as the tutorials that use the term. */
    children?: ReactNode;
}): import("react").JSX.Element;
//# sourceMappingURL=TermBlock.d.ts.map
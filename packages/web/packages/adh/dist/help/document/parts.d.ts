/**
 * How a tutorials document is read out of the cards content-buildr writes. Pure: no React, no
 * Next, so the model and its tests use it alike.
 *
 * A tutorial's card is split into the panes its list shows, by a convention the
 * fishlamp-tutorial-writer skill documents and nothing else needs to know:
 *
 * - **Overview**: the blurb, then the `## Description` prose before its first `###`, then the
 *   card's `## Links` as its References and a button onto the API explorer showing the routes
 *   the card's `## API` names (see `apiRoutesOf`).
 * - **Definitions**: the glossary's terms that link to the tutorial.
 * - **Steps**: each `###` section of `## Description`, its heading the step's title.
 *
 * The glossary is one entry of the same document. Each `###` section of its `## Description` is a
 * term, and a term's related tutorials are the ones its closing `Tutorials:` paragraph links to.
 * One definition per term, read by both the Glossary pane and every tutorial's Definitions pane.
 */
/** A pane of a tutorial, after its Overview. */
export type TutorialPart = "definitions" | "steps";
/** The panes a tutorial's list offers after its Overview, in order. */
export declare const TUTORIAL_PARTS: readonly {
    id: TutorialPart;
    label: string;
}[];
/** One `###` section of a card's description. */
export interface DocSection {
    /** A stable id for the section, from its heading's text. */
    id: string;
    /** The heading as plain text. */
    title: string;
    /** The heading's own rendered HTML, which may hold code or links. */
    titleHtml: string;
    /** The blocks under the heading, up to the next one. */
    html: string[];
}
/** One action within a step: an item of the step's numbered list. */
export interface Substep {
    /** `<step id>/<n>`, n counting from 1. */
    id: string;
    /** The item's rendered HTML. */
    html: string;
}
/**
 * One step of a tutorial. A step whose body holds a numbered list of two or more items has those
 * items as its sub-steps, each ticked on its own; `before` and `after` are the blocks either side
 * of that list. A step with no such list has no sub-steps, and its blocks are all in `before`.
 */
export interface TutorialStep extends DocSection {
    before: string[];
    substeps: Substep[];
    after: string[];
}
/** One term of the glossary. */
export interface GlossaryTerm extends DocSection {
    /** The definition as plain text, for searching. */
    text: string;
    /** The ids of the tutorials the definition links to, in the order it names them. */
    tutorials: string[];
}
/** Markup as the words a reader sees. */
export declare function plainText(html: string): string;
/** A lowercase, hyphenated id from a heading's words. */
export declare function slugOf(text: string): string;
/** A description's blocks split at each `###`: the prose before the first one, and each section. */
export declare function sectionsOf(blocks: readonly string[]): {
    lead: string[];
    sections: DocSection[];
};
/** The top-level items of a list's inner HTML, an item's own nested lists kept inside it. */
export declare function listItems(inner: string): string[];
/** A section as a tutorial step: its first numbered list of two or more items is its sub-steps. */
export declare function stepOf(section: DocSection): TutorialStep;
/** The ids of the tutorials `html` links to, from `/tutorials/<id>` links under `base`. */
export declare function tutorialLinks(html: string, base: string, known: ReadonlySet<string>): string[];
/**
 * The glossary's terms, read from its card's description. A term's tutorials are the links in its
 * closing `Tutorials:` paragraph, which is lifted out of the definition because the panes that
 * show a term list its tutorials themselves. A link to a tutorial anywhere else in a definition
 * is prose, and does not count.
 */
export declare function glossaryOf(description: readonly string[], base: string, tutorialIds: ReadonlySet<string>): GlossaryTerm[];
/** The glossary's terms that a tutorial's Definitions pane shows. */
export declare function termsFor(terms: readonly GlossaryTerm[], tutorialId: string): GlossaryTerm[];
/** Whether `term` matches what a reader typed: every word, in its name or its definition. */
export declare function termMatches(term: Pick<GlossaryTerm, "title" | "text">, query: string): boolean;
/** A route a tutorial's `## API` names: its path, and its method when the prose gives one. */
export interface ApiRoute {
    method?: string;
    path: string;
}
/**
 * The routes a card's `## API` names, in order. content-buildr wants a method in code of its own,
 * so the prose reads "a `GET` or `PUT` of `/ecosystem/client-auth/{id}`": each method code waits
 * for the next code that starts with `/`, and is that route's method. A path with no method
 * before it stands for every method on that path. A query string is not part of the route.
 */
export declare function apiRoutesOf(blocks: readonly string[]): ApiRoute[];
//# sourceMappingURL=parts.d.ts.map
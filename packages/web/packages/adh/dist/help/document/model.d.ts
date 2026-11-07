/**
 * A help document the help site builds with content-buildr: Hub Features under `/hub`, Tutorials
 * under `/tutorials`. Each is read from the two files content-buildr writes for it: `index.json`,
 * the tree of entries, and `bodies.json`, one card per entry that has a page of its own. Both are
 * built from a content tree in adhcontent's `content/adhubwebsite/`, so nothing here is content.
 * {@link contentDocument} turns one tree into the rails its route shows, and resolves a route's
 * path to the entry and card it reads.
 *
 * A document with {@link DocSource.tutorials} set is a tutorials document: one of its root entries
 * is the Glossary, and every other root page is a tutorial, listed as its panes (Overview,
 * Definitions, Steps, API, References). How a card is split into those panes is `./parts`.
 *
 * Not `server-only` itself, so the package's tests can load it; the site module that hands it
 * `bodies` is, because `bodies` holds every card and must never reach a client bundle.
 */
import { type ApiRoute, type GlossaryTerm, type TutorialPart, type TutorialStep } from "./parts";
/** One entry of the tree: a row in a list, and — when `told` — a card of its own. */
export interface DocNode {
    id: string;
    label: string;
    /** The entry's published address, when it has one. */
    addr: string;
    /** Whether the entry has a card (a page of its own) in `bodies`. */
    told: boolean;
    /** The heading this entry was listed under on its parent's page. Rows that share one form a
     *  group; the rail draws the heading over each group. */
    listHeading?: string;
    /** The route path that opens this entry: its ancestors' ids, then its own. */
    open: string[];
    children: DocNode[];
    /** Set on a tutorial's pane: which pane it is. The pane reads its tutorial's card. */
    part?: TutorialPart;
    /** Set on a tutorial's pane: the id of the tutorial it is a pane of. */
    owner?: string;
}
/** What a row stands for, when it is more than a page or a list: it chooses the row's glyph. */
export type DocItemKind = "glossary" | "tutorial" | TutorialPart;
/** One row of a rail. */
export interface DocItem {
    id: string;
    label: string;
    /** The route path the row leads to. */
    open: string[];
    /** Whether the row opens a further list. */
    opens: boolean;
    /** Whether the entry has an Overview of its own beside its list. */
    overview: boolean;
    /** A group heading to draw under this row — the heading the NEXT row's group carries. */
    section?: string;
    /** Whether to draw a plain divider under this row, with no heading. */
    divider?: boolean;
    kind?: DocItemKind;
}
/** One list of the stack: the root list, or the list under a chosen entry. */
export interface DocRail {
    id: string;
    title: string;
    items: DocItem[];
    selectedId: string | null;
    /** The route path of the list itself — where clearing its selection goes. */
    above: string[];
    /** Whether the list opens on its owner's Overview when nothing in it is chosen. */
    overview: boolean;
}
/** Where something on a card came from, when it is not this entry's own words. */
export interface DocRef {
    name: string;
    href: string;
}
export interface DocLink {
    kind: "site" | "github" | "web";
    name: string;
    url: string | null;
    note: string | null;
}
export type DocTechKind = "languages" | "frameworks" | "data" | "hosting" | "services" | "protocols" | "platforms" | "tooling";
export interface DocTechTerm {
    name: string;
    url: string | null;
}
export interface DocScreenshot {
    src: string;
    alt: string;
    caption: string | null;
}
/** An entry's card: everything its page says, as rendered HTML blocks. */
export interface DocCard {
    /** The entry this one is a part of, when it is not a root entry. */
    crumb: DocRef | null;
    name: string;
    addr: string;
    blurb: string;
    borrowed: DocRef | null;
    description: string[];
    /** What a program can do with the feature, and where the reference is. */
    api: string[];
    links: DocLink[];
    tech: {
        stack: {
            kind: DocTechKind;
            terms: DocTechTerm[];
        }[];
        notes: string[];
        from: DocRef | null;
    };
    screenshots: DocScreenshot[];
}
/** The pane of a tutorial a route shows. */
export interface TutorialView {
    /** The tutorial's id: the key its saved progress is kept under. */
    id: string;
    part: "overview" | TutorialPart;
    /** The description's prose before its first step. */
    lead: string[];
    steps: TutorialStep[];
    /** The glossary's terms that link to this tutorial. */
    terms: GlossaryTerm[];
    /** Where the Glossary is, for the Definitions pane to point at. */
    glossary: DocRef;
    /** The routes the card's `## API` names, which the Overview's API button shows. */
    api: ApiRoute[];
}
/** The Glossary, when a route shows it. */
export interface GlossaryView {
    terms: GlossaryTerm[];
    /** Every tutorial a term can link to, by id: its name and its route. */
    tutorials: Record<string, DocRef>;
}
/** A resolved document route. */
export interface DocView {
    rails: DocRail[];
    /** The entry the route names, or null at the root list. */
    entry: DocNode | null;
    /** The card the route reads, or null when it shows a list and nothing chosen. */
    card: DocCard | null;
    /** The page's title: the card's name, and the pane's when the route is one of a tutorial's. */
    title: string;
    /** The path (after the document's base) this route is canonically published at. A list whose owner has a
     *  page of its own lands on that page wide (`defaultSelectedId` replaces the URL with its
     *  Overview), so the bare list route and the Overview route are one document at two addresses;
     *  the Overview one is the canonical, and the bare one points at it rather than competing. */
    canonical: string[];
    /** Set when the route shows a pane of a tutorial. */
    tutorial: TutorialView | null;
    /** Set when the route shows the Glossary. */
    glossary: GlossaryView | null;
}
/** The last path segment that opens an entry's own card beside its list. */
export declare const OVERVIEW_ID = "~overview";
/** What one built document is: where it is served, what its root list is called, and its files. */
export interface DocSource {
    /** The help topic id the document is (`hub`, `tutorials`): it selects the topic's row in the
     *  help roots rail. */
    topicId: string;
    /** The route the document is served under, such as `/hub`. */
    base: string;
    /** The root list's title, and the page title where a route names no entry. */
    title: string;
    /** The heading of the card holding a page's `## Description`. */
    descriptionTitle: string;
    /** content-buildr's `index.json` for the document. */
    index: unknown;
    /** content-buildr's `bodies.json` for the document. */
    bodies: unknown;
    /** Where the document is built from, named in the error when nothing was built. */
    builtFrom: string;
    /** Set for a tutorials document: the id of its root entry that is the Glossary. */
    tutorials?: {
        glossaryId: string;
    };
}
/** One built document, resolved: every route it serves, and what each one shows. */
export interface ContentDocument {
    topicId: string;
    base: string;
    title: string;
    descriptionTitle: string;
    /** Every route path under {@link base}, for prerendering. */
    paths(): string[][];
    /** Every route under {@link base} that is its own canonical address: the ones the sitemap lists. */
    canonicalPaths(): string[][];
    /** Resolve a route to what it shows, or null for a path the tree does not hold. */
    view(asked: string[]): DocView | null;
    /** The route of a path under {@link base}. */
    href(segments: string[]): string;
}
export declare function contentDocument(source: DocSource): ContentDocument;
//# sourceMappingURL=model.d.ts.map
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

import {
  TUTORIAL_PARTS,
  apiRoutesOf,
  glossaryOf,
  sectionsOf,
  stepOf,
  termsFor,
  type ApiRoute,
  type GlossaryTerm,
  type TutorialPart,
  type TutorialStep,
} from "./parts";

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

export type DocTechKind =
  | "languages"
  | "frameworks"
  | "data"
  | "hosting"
  | "services"
  | "protocols"
  | "platforms"
  | "tooling";

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
    stack: { kind: DocTechKind; terms: DocTechTerm[] }[];
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
export const OVERVIEW_ID = "~overview";
const OVERVIEW_LABEL = "Overview";
/** The key `bodies` holds the root page under. */
const ROOT_KEY = "";

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
  tutorials?: { glossaryId: string };
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

/** Whether an entry has both a list and a card, so its card is reached through an Overview row. */
function hasOverview(node: DocNode): boolean {
  return node.told && node.children.length > 0;
}

/** The card of a page the tree says has one. A told entry with no card is a broken build. */
function cardOf(bodies: Record<string, DocCard>, id: string, title: string): DocCard {
  const card = bodies[id];
  if (!card) throw new Error(`the ${title} document lists "${id}" as a page but holds no card for it.`);
  return card;
}

/** What a tutorials document knows beyond its tree: the glossary, and each tutorial's parts. */
interface TutorialsIndex {
  glossaryId: string;
  terms: GlossaryTerm[];
  tutorialIds: Set<string>;
}

/**
 * The tree with each tutorial given its panes as children, and what they were read from. A pane
 * is listed only when it has something in it: Definitions when a glossary term links to the
 * tutorial, and Steps when its description has a `###`. The card's API and References are shown
 * on its Overview, so they are not panes.
 */
function withTutorialParts(
  tree: DocNode[],
  bodies: Record<string, DocCard>,
  base: string,
  glossaryId: string,
  title: string,
): { tree: DocNode[]; index: TutorialsIndex } {
  const glossary = tree.find((node) => node.id === glossaryId);
  if (!glossary || !glossary.told) {
    throw new Error(
      `the ${title} document has no "${glossaryId}" root page to be its Glossary — add it to the root's children.`,
    );
  }
  const tutorialIds = new Set(
    tree.filter((node) => node.id !== glossaryId && node.told && !node.children.length).map((n) => n.id),
  );
  const terms = glossaryOf(cardOf(bodies, glossaryId, title).description, base, tutorialIds);

  const out = tree.map((node): DocNode => {
    if (!tutorialIds.has(node.id)) return node;
    const card = cardOf(bodies, node.id, title);
    const has: Record<TutorialPart, boolean> = {
      definitions: termsFor(terms, node.id).length > 0,
      steps: sectionsOf(card.description).sections.length > 0,
    };
    const children = TUTORIAL_PARTS.filter((part) => has[part.id]).map(
      (part): DocNode => ({
        id: part.id,
        label: part.label,
        addr: node.addr,
        told: true,
        open: [...node.open, part.id],
        children: [],
        part: part.id,
        owner: node.id,
      }),
    );
    return { ...node, children };
  });
  return { tree: out, index: { glossaryId, terms, tutorialIds } };
}

export function contentDocument(source: DocSource): ContentDocument {
  const { topicId, base, title, descriptionTitle } = source;
  const built = source.index as DocNode[];
  const bodies = source.bodies as Record<string, DocCard>;

  // A guard that cannot find its targets must FAIL, not pass (repo CLAUDE.md). An empty tree
  // here means content-buildr wrote nothing (a broken manifest, a build that never ran), and
  // without this the site would prerender a single empty list, list nothing in the sitemap, and
  // deploy green.
  if (built.length === 0) {
    throw new Error(
      `the ${title} document holds no entries: it was not built (${source.builtFrom} → content-buildr).`,
    );
  }

  const { tree, index: tutorials } = source.tutorials
    ? withTutorialParts(built, bodies, base, source.tutorials.glossaryId, title)
    : { tree: built, index: null };

  const rootTold = (): boolean => bodies[ROOT_KEY] != null;
  const href = (segments: string[]): string => [base, ...segments].join("/");

  function kindOf(node: DocNode): DocItemKind | undefined {
    if (node.part) return node.part;
    if (!tutorials) return undefined;
    if (node.id === tutorials.glossaryId) return "glossary";
    if (tutorials.tutorialIds.has(node.id)) return "tutorial";
    return undefined;
  }

  function paths(): string[][] {
    const out: string[][] = [];
    if (rootTold()) out.push([OVERVIEW_ID]);
    const walk = (nodes: DocNode[], here: string[]): void => {
      for (const node of nodes) {
        const path = [...here, node.id];
        out.push(path);
        if (hasOverview(node)) out.push([...path, OVERVIEW_ID]);
        walk(node.children, path);
      }
    };
    walk(tree, []);
    return out;
  }

  /** The bare base (`[]`) and every list whose owner has a page point at that page instead. */
  function canonicalPaths(): string[][] {
    return [[], ...paths()].filter((path) => {
      const resolved = view(path);
      return resolved != null && resolved.canonical.join("/") === path.join("/");
    });
  }

  function railOf(
    id: string,
    railTitle: string,
    owner: DocNode | null,
    above: string[],
    selectedId: string | null,
  ): DocRail {
    const nodes = owner ? owner.children : tree;
    const told = owner ? owner.told : rootTold();
    const items: DocItem[] = told
      ? [
          {
            id: OVERVIEW_ID,
            label: OVERVIEW_LABEL,
            open: [...above, OVERVIEW_ID],
            opens: false,
            overview: false,
          },
        ]
      : [];
    let heading: string | undefined;
    for (const node of nodes) {
      // A group heading is drawn under the row before the group starts. The first group's heading
      // lands under the Overview row; with no Overview row there is nothing to hang it on.
      const last = items.at(-1);
      if (node.listHeading && node.listHeading !== heading && last) last.section = node.listHeading;
      heading = node.listHeading;
      items.push({
        id: node.id,
        label: node.label,
        open: node.open,
        opens: node.children.length > 0,
        overview: hasOverview(node),
        kind: kindOf(node),
      });
    }
    // The Glossary serves every tutorial, so a divider sets it apart from the tutorials below it.
    const glossaryRow = items.findIndex((item) => item.kind === "glossary");
    const belowGlossary = items[glossaryRow + 1];
    if (glossaryRow >= 0 && belowGlossary && !items[glossaryRow]!.section) {
      items[glossaryRow]!.divider = true;
    }
    return { id, title: railTitle, items, selectedId, above, overview: told };
  }

  function tutorialView(node: DocNode, part: TutorialView["part"]): TutorialView | null {
    if (!tutorials || !tutorials.tutorialIds.has(node.id)) return null;
    const card = cardOf(bodies, node.id, title);
    const { lead, sections } = sectionsOf(card.description);
    return {
      id: node.id,
      part,
      lead,
      steps: sections.map(stepOf),
      terms: termsFor(tutorials.terms, node.id),
      glossary: { name: cardOf(bodies, tutorials.glossaryId, title).name, href: href([tutorials.glossaryId]) },
      api: apiRoutesOf(card.api),
    };
  }

  function glossaryView(): GlossaryView | null {
    if (!tutorials) return null;
    const named: Record<string, DocRef> = {};
    for (const node of tree) {
      if (tutorials.tutorialIds.has(node.id)) named[node.id] = { name: node.label, href: href(node.open) };
    }
    return { terms: tutorials.terms, tutorials: named };
  }

  /** `asked` is the path after the base; it may end in the Overview marker. */
  function view(asked: string[]): DocView | null {
    const overview = asked.at(-1) === OVERVIEW_ID;
    const path = overview ? asked.slice(0, -1) : asked;

    const trail: DocNode[] = [];
    let nodes = tree;
    for (const id of path) {
      const node = nodes.find((n) => n.id === id);
      if (!node) return null;
      trail.push(node);
      nodes = node.children;
    }

    const rails: DocRail[] = [
      railOf(
        "level-0",
        title,
        null,
        [],
        trail[0]?.id ?? (overview && path.length === 0 ? OVERVIEW_ID : null),
      ),
    ];
    trail.forEach((node, depth) => {
      if (!node.children.length) return;
      const below =
        trail[depth + 1]?.id ?? (overview && depth === trail.length - 1 ? OVERVIEW_ID : null);
      rails.push(railOf(`level-${depth + 1}`, node.label, node, path.slice(0, depth + 1), below));
    });

    const entry = trail.at(-1) ?? null;
    if (overview) {
      const owner = entry ? hasOverview(entry) : rootTold();
      if (!owner) return null;
    }
    const reads = entry
      ? overview || !entry.children.length
        ? (entry.owner ?? entry.id)
        : null
      : overview
        ? ROOT_KEY
        : null;
    // An untold leaf reads no card, by design. Every other route that reads one must find it:
    // a told entry with no card is a broken build, and failing here keeps it out of prerender.
    const told = entry ? entry.told : rootTold();
    const card = reads == null || !told ? null : cardOf(bodies, reads, title);
    // A route that shows an entry is its own canonical, card or not. One that shows a list with
    // nothing chosen is canonical only when the list has no page to land on; otherwise the
    // page's route is.
    const canonical = reads != null || !rails.at(-1)!.overview ? asked : [...asked, OVERVIEW_ID];

    let tutorial: TutorialView | null = null;
    if (entry?.part) tutorial = tutorialView(trail.at(-2)!, entry.part);
    else if (entry && overview) tutorial = tutorialView(entry, "overview");
    const glossary = tutorials && entry?.id === tutorials.glossaryId && trail.length === 1 ? glossaryView() : null;

    const name = card?.name ?? entry?.label ?? title;
    const pageTitle = entry?.part ? `${entry.label}: ${name}` : name;
    return { rails, entry, card, title: pageTitle, canonical, tutorial, glossary };
  }

  return { topicId, base, title, descriptionTitle, paths, canonicalPaths, view, href };
}

// NO "use client" — a server component. Resolves a document route (/hub, /tutorials) to the lists
// it shows and the card it reads, builds the one help stack (the document's lists, one per level)
// and server-renders the card. Reached through documentRoute, which the help site's document
// segments call, so a document's bodies never load on another help page.

import type { ReactNode } from "react";
import {
  Book,
  FileText,
  Folder,
  GraduationCap,
  Info,
  LayoutGrid,
  ListChecks,
  Quote,
  type LucideIcon,
} from "lucide-react";
import {
  HelpMasterDetail,
  type HelpRouteItem,
  type HelpRouteLevel,
} from "@adh-sdk/adh/help/HelpMasterDetail";
import {
  OVERVIEW_ID,
  type ContentDocument,
  type DocItem,
  type DocItemKind,
  type DocRail,
  type DocView,
} from "./model";
import { DocumentDetail } from "./DocumentDetail";

/** The glyphs of the rows a tutorials document adds: the Glossary, a tutorial, and its panes. */
const KIND_ICON: Record<DocItemKind, LucideIcon> = {
  glossary: Book,
  tutorial: GraduationCap,
  definitions: Quote,
  steps: ListChecks,
};

/** The row's glyph: an Overview row an info mark, a row of a tutorials document its kind's, a root
 *  entry a grid, a row that opens a further list a folder, and a page a document. */
function itemIcon(item: DocItem, depth: number): ReactNode {
  if (item.id === OVERVIEW_ID) return <Info size={16} aria-hidden />;
  if (item.kind) {
    const Icon = KIND_ICON[item.kind];
    return <Icon size={16} aria-hidden />;
  }
  if (depth === 0) return <LayoutGrid size={16} aria-hidden />;
  if (item.opens) return <Folder size={16} aria-hidden />;
  return <FileText size={16} aria-hidden />;
}

function routeItem(doc: ContentDocument, item: DocItem, depth: number): HelpRouteItem {
  return {
    id: item.id,
    label: item.label,
    href: doc.href(item.open),
    icon: itemIcon(item, depth),
    dividerAfter: Boolean(item.section || item.divider),
    dividerLabel: item.section,
    // A row with an Overview of its own opens on it, so warm that page as well as the list.
    prefetch: item.overview ? [doc.href([...item.open, OVERVIEW_ID])] : undefined,
  };
}

function routeLevel(doc: ContentDocument, rail: DocRail, depth: number): HelpRouteLevel {
  return {
    key: rail.id,
    title: rail.title,
    items: rail.items.map((item) => routeItem(doc, item, depth)),
    selectedId: rail.selectedId,
    defaultSelectedId: rail.overview ? OVERVIEW_ID : undefined,
    clearHref: doc.href(rail.above),
    itemNoun: "entry",
    overviewHelp: "Choose an entry from the list to read it here.",
  };
}

/** The server-rendered master-detail for one route of `doc`. `view` is the resolved route. */
export function DocumentSurface({ doc, view }: { doc: ContentDocument; view: DocView }) {
  // The stack starts at the document's own root list: the help topics are a page of cards at
  // /home, and the document's card opens onto this list, so a help-topics rail in front of it
  // would offer the choice already made. Clearing it (the breadcrumb root) stays on `doc.base`.
  const levels: HelpRouteLevel[] = view.rails.map((rail, depth) => routeLevel(doc, rail, depth));

  return (
    <HelpMasterDetail
      levels={levels}
      rootLabel={doc.title}
      // The strip names the entry the route is inside. The root list has no entry, and a card
      // names itself with its own h1, so the strip stays bare there rather than repeating it.
      detailTitle={view.entry?.label ?? null}
      ssrDetail
    >
      {view.card ? (
        <DocumentDetail view={view} card={view.card} descriptionTitle={doc.descriptionTitle} />
      ) : null}
    </HelpMasterDetail>
  );
}

import type { DocumentSearchRegistry, DocumentTypeConfig } from '../types'
import { unixToIso } from '../lib/format'
import { MarkdownResultRow } from '../components/markdown/MarkdownResultRow'
import { MarkdownPreview } from '../components/markdown/MarkdownPreview'
import { MarkdownPreviewHeader } from '../components/markdown/MarkdownPreviewHeader'

/**
 * A single cross-author search hit. Defined locally (not imported from the API's shared
 * types package) because this package is self-contained for marketing sites; the wire it
 * is read from is {@link PaperSearchHitWire}, mapped by {@link paperHitFromWire}.
 */
/**
 * The document kind carried by each hit (read from frontmatter by the backend).
 *
 * OPEN union (c16): the two KNOWN kinds keep autocomplete, but `string & {}` lets the
 * type accept ANY string, so registering + using a NEW kind (e.g. `'dataset'`) via
 * {@link registerKindRenderer} type-checks with NO edit to this file (true open/closed
 * extensibility). The `& {}` intersection is the idiom that widens the union to all
 * strings WITHOUT collapsing the literals away (which would kill known-kind completion).
 */
export type PaperKind = 'paper' | 'research' | (string & {})

export interface PaperSearchHit {
  id: string
  title: string
  publicRoute: string
  author: { slug: string; displayName: string | null }
  category: string | null
  tags: string[]
  /** ~200-char match-context excerpt (plain text; no markup). */
  snippet: string
  createdAt: string
  updatedAt: string
  /**
   * Which kind of document this is — `'paper'` | `'research'` | any registered kind —
   * read from the document's frontmatter by the backend. Dispatches the per-kind badge,
   * row subtitle, and extra preview section through {@link kindRendererFor} (c16). The
   * type is open ({@link PaperKind}), so a NEW kind needs no edit here.
   */
  kind: PaperKind
  /** Frontmatter summary line, when present (may be null). */
  summary?: string | null
  /** Frontmatter evaluation line, when present (may be null). */
  evaluation?: string | null
}

/** A hit as `GET /v1/papers` serves it: snake_case, with `created`/`updated` in unix seconds. */
export interface PaperSearchHitWire {
  id: string
  title: string
  public_route?: string | null
  author?: { slug?: string | null; display_name?: string | null } | null
  category?: string | null
  tags?: string[] | null
  snippet?: string | null
  created: number
  updated: number
  kind?: string | null
  summary?: string | null
  evaluation?: string | null
}

/** The hit's wire row as the {@link PaperSearchHit} the view renders, field by field. */
export function paperHitFromWire(wire: unknown): PaperSearchHit {
  const w = wire as PaperSearchHitWire
  return {
    id: w.id,
    title: w.title,
    publicRoute: w.public_route ?? '',
    author: { slug: w.author?.slug ?? '', displayName: w.author?.display_name ?? null },
    category: w.category ?? null,
    tags: w.tags ?? [],
    snippet: w.snippet ?? '',
    createdAt: unixToIso(w.created),
    updatedAt: unixToIso(w.updated),
    kind: w.kind ?? 'paper',
    summary: w.summary ?? null,
    evaluation: w.evaluation ?? null,
  }
}

/**
 * The MARKDOWN document-type config — the single entry in the type registry today.
 * Binds the markdown result-row + preview renderers and identity. The core SearchView
 * is parameterised over this, so a future document type is added by registering
 * another {@link DocumentTypeConfig}, never by editing the core (open/closed).
 */
export const markdownDocumentType: DocumentTypeConfig<PaperSearchHit> = {
  type: 'markdown',
  getId: (hit) => hit.id,
  getTitle: (hit) => hit.title?.trim() || 'Untitled',
  fromWire: paperHitFromWire,
  ResultRow: MarkdownResultRow,
  // c14 — the SINGLE metadata header (title/badge/author/date/summary/evaluation/link),
  // rendered once by the preview dock; the Preview body renders content only.
  PreviewHeader: MarkdownPreviewHeader,
  Preview: MarkdownPreview,
}

/**
 * The document-type registry: looked up by {@link DocumentType}. Markdown is the only
 * entry today. The per-type Hit is erased here (a heterogeneous map cannot preserve it)
 * — the type-safe path is passing a config to `SearchView` directly; this map is for
 * call sites that select by the string type key.
 */
export const DOCUMENT_SEARCH_REGISTRY: DocumentSearchRegistry = {
  markdown: markdownDocumentType as unknown as DocumentTypeConfig,
}

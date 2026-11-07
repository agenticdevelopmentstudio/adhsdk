// The Next route for one content document (Hub Features, Tutorials): `/<base>` is its root list,
// `/<base>/<entry…>` an entry's list or page, and `/<base>/<entry…>/~overview` the page of an entry
// that also has a list. Every path is enumerated from the built tree and prerendered; the segment
// that uses this sets `dynamicParams = false`, so unknown paths 404 statically.

import type { Metadata } from "next";
import { notFound } from "next/navigation";
import { canonicalOnly } from "@adh-sdk/adh-registry/seo";
import type { ContentDocument } from "./model";
import { DocumentSurface } from "./DocumentSurface";

type Params = { params: Promise<{ path?: string[] }> };

export function documentRoute(doc: ContentDocument) {
  function generateStaticParams(): { path: string[] }[] {
    return [{ path: [] }, ...doc.paths().map((path) => ({ path }))];
  }

  async function generateMetadata(props: Params): Promise<Metadata> {
    const { path = [] } = await props.params;
    const view = doc.view(path);
    if (!view) return {};
    const title = view.title;
    // `view.canonical`, not `path`: a list route that lands on its Overview page is that page at a
    // second address, and must say so rather than compete with it (see DocView.canonical).
    return { ...canonicalOnly(doc.href(view.canonical)), title };
  }

  async function Page(props: Params) {
    const { path = [] } = await props.params;
    const view = doc.view(path);
    if (!view) notFound();
    return <DocumentSurface doc={doc} view={view} />;
  }

  return { generateStaticParams, generateMetadata, Page };
}

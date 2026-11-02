'use client'

import { siteProdUrl, siteUrl } from '@adh-sdk/adh-registry'

import { useClientHost } from '../../header/useClientHost'
import type { HelpTopic } from '../topics'

// A document help topic (Hub Features, Tutorials), as shown in the MODAL. Each document is the help
// site's own surface (help.adh.com/<slug>): it is built there, with content-buildr, out of a content
// tree that lives in adhcontent and is read by nothing in this package. So from the modal (mounted on
// every site) we link out to it rather than carry a second copy of a document this package cannot
// build. On the SSR help site the same topic is served by the site's `/<slug>` route.
//
// The link follows the visitor's environment the way the header's cross-site links do (same
// `useClientHost` seam): a staging or local-dev visitor lands on THEIR help site, not production's.
// Until the host is known the production URL stands in, so the server and first client render agree.
export function DocumentTopic({ topic }: { topic: HelpTopic }) {
  const host = useClientHost()
  const path = `/${topic.slug}`
  // `useClientHost` returns host:port on local dev; siteUrl wants the bare hostname.
  const hostname = host?.split(':')[0]
  const href = hostname ? siteUrl('hub-help', path, hostname) : siteProdUrl('hub-help', path)
  return (
    <div className="adh-help-topic adh-help-topic--document">
      <div className="flex flex-col items-center gap-2 text-center">
        {topic.description ? <p>{topic.description}</p> : null}
        <a href={href} target="_blank" rel="noreferrer" className="adh-help-topic__link">
          Open {topic.label} →
        </a>
      </div>
    </div>
  )
}

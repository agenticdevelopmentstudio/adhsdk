import { type HelpTopicId } from './topics';
import { type HelpRouteLevel } from '@adh-sdk/adh/help/HelpMasterDetail';
/** Join a site `basePath` (no trailing slash; `''` or `/` = apex) with a base-relative slug. */
export declare function helpHref(basePath: string, slug: string): string;
/** The stable key of the root level — the help topics — in every stack that starts with it. */
export declare const HELP_ROOT_LEVEL_KEY = "help-root";
/**
 * Level 0 of a help stack that starts at the topics: the help topics, with `selectedId` chosen.
 * {@link HelpSurface} builds it for the markdown routes; a route-driven surface that wants the
 * topics rail in front of it builds the SAME level through this, so its outer rail — topics,
 * labels, hrefs, glyphs, nudge copy, where clearing goes — is identical to every other help route.
 * (Three copies once drifted: the REST API's cleared to the apex while the others cleared to
 * `/home`.) The hub-help site no longer uses it — its areas start at their own lists, the topics
 * being the /home cards — but a host showing the full tree still does.
 */
export declare function helpRootLevel(selectedId: HelpTopicId | null, clearHref: string, basePath?: string): HelpRouteLevel;
/**
 * The server-rendered help master-detail for one route. `slug` is the active base-relative slug
 * (e.g. `overview`, `mcp/connect`); `basePath` is where the surface is mounted (`''` on the help
 * site).
 */
export declare function HelpSurface({ slug, basePath, rootClearHref, startAtArea, }: {
    slug: string;
    basePath?: string;
    /** Start the stack at the active AREA's own list rather than at the help topics: on the help
     *  site the topics are a page of cards (`/home`), so a route under a section (`/mcp/…`) shows
     *  that section's children as its root list, with the section's name as the breadcrumb root
     *  (which clears to the section's own route). A topic with no children of its own (Overview)
     *  has no list to start at and keeps the topics rail — a stack with no level is no stack. The
     *  Help modal keeps the full tree; it has no card page in front of it. */
    startAtArea?: boolean;
    /** Where clearing the ROOT level's selection navigates — the HMDV's own home. Defaults to the
     *  surface apex; a host whose apex is NOT the surface (the help site's `/` is a landing page,
     *  its HMDV root lives at `/home`) passes that route so unselecting everything stays on the
     *  surface instead of bouncing to the landing. */
    rootClearHref?: string;
}): import("react").JSX.Element;
//# sourceMappingURL=HelpSurface.d.ts.map
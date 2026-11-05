import type { MouseEvent, ReactElement, ReactNode } from 'react';
import { type SiteContact } from './identity';
/** A plain link: the directory's entries, and the "This site" column a site passes. */
export type SiteLink = {
    label: string;
    href: string;
};
type Entry = SiteLink & {
    /** A small pill after the label: the platform of a native tool. */
    badge?: string;
    onClick?: (event: MouseEvent<HTMLAnchorElement>) => void;
};
/** Terms and Privacy open in a scrolling dialog over the page (LegalModals); the hrefs stay,
 *  so a modified click, or a browser without the Popover API, still reaches the pages. */
export declare const LEGAL_ENTRIES: Entry[];
export type FamilyFooterProps = {
    /** The build identity ({@link buildVersionLabel}); null when none was baked, and then the
     *  fine print simply has no version. */
    version: ReactNode;
    /** A site's own links, as a "This site" column ahead of the directory. */
    links?: SiteLink[];
    /** Carry the drawer's More Info jump target (MORE_INFO_ANCHOR_ID). For the in-flow landing
     *  footer only: a page holds the id once, and SiteFooter's dialog copy must not repeat it. */
    anchored?: boolean;
    /** Who the Contact column writes to; the hub by default. */
    contact?: SiteContact;
};
/**
 * The family footer: a directory of the whole family, the way a store's site ends. The
 * preview badge heads it; then every group of sites as a column of plain links, the native
 * tools in a column of their own, who makes them, the legal pages, and the address to write to;
 * then one line of fine print with the copyright, the sites overview and the build.
 *
 * It is the landing page's footer (LandingFooter, in flow at the foot of `/`) and, on every
 * other page, what the floating `i` opens in a dialog (SiteFooter). Every link is in
 * the server HTML either way, so it is also the page's crawlable interlink set.
 *
 * Terms, Privacy and All sites open dialogs, and those dialogs are the CALLER's to
 * render, once per page: a dialog inside this footer would be inside SiteFooter's closed
 * dialog, which is `display: none`, and the header's site switcher opens the same sites
 * overview by id.
 */
export declare function FamilyFooter({ version, links, anchored, contact, }: FamilyFooterProps): ReactElement;
export {};
//# sourceMappingURL=FamilyFooter.d.ts.map
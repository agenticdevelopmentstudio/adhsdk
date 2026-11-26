// The Jobs topic sets (phase 9). Plain data, no React and no `use client`, so a server component
// such as a site's console layout can import them (`@adh-sdk/jobs/topics`).

export interface JobsTopic {
  id: string;
  label: string;
  href: string;
}

/** The hub workspace's Jobs topics. Each `href` is the segment the host prefixes with the
 *  workspace (`/<workspace>/jobs/templates`); all three are sub-paths of the one
 *  `/[workspace]/jobs/[[...path]]` route. */
export const jobsTopics: readonly JobsTopic[] = [
  { id: "jobs", label: "Jobs", href: "jobs" },
  { id: "templates", label: "Templates", href: "jobs/templates" },
  { id: "environments", label: "Environments", href: "jobs/environments" },
];

/** The product admin console's Jobs topics. Each `href` is a page route of the `product-sites`
 *  site, where the console lives under `/admin`. There is no Environments page: a product admin
 *  owns no machines. */
export const jobsProductAdminTopics: readonly JobsTopic[] = [
  { id: "status", label: "Status", href: "/admin/jobs" },
  { id: "templates", label: "Templates", href: "/admin/jobs/templates" },
];

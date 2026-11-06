"use client";

import { useEffect, useState, type ReactElement, type ReactNode } from "react";
import { FeatureTitle } from "@adh-sdk/resource";
import { cn } from "../lib/utils";
import { railLinkVariants } from "@adh-sdk/ui/lib/nav-rail";
import { RequestsPane } from "../invitations/RequestsPane";
import { PendingUsersPane } from "../invitations/PendingUsersPane";
import { InvitesPane } from "../invitations/InvitesPane";

// Alphabetical, like every list in the admin console (adminTopics.test.ts holds the rail to the
// same rule). Display order only — the tab that OPENS is DEFAULT_TOPIC, not the first row.
export const INVITATION_TOPICS = [
  { id: "invites", label: "Invites" },
  { id: "pending", label: "Pending Users" },
  { id: "requests", label: "Requests" },
] as const;
const TOPICS = INVITATION_TOPICS;
type TopicId = (typeof TOPICS)[number]["id"];

// Requests, not the first row: incoming requests are the queue an operator comes here to work, and
// a bare `/invitations` has always opened on them (the admin site's invitations e2e specs rely on
// it). Alphabetizing the rows was a display change, not a change to where the pane lands.
const DEFAULT_TOPIC: TopicId = "requests";

export function InvitationsPane({ help }: { help?: ReactNode } = {}): ReactElement {
  const [topic, setTopic] = useState<TopicId>(DEFAULT_TOPIC);

  // Deep-link the active sub-tab: seed from ?tab= on mount (so a shared link / reload
  // restores the tab — and lets each pane's own ?<paramKey>= row selection resolve
  // against the right pane), and mirror it on change via history.replaceState (no
  // remount, no history spam). An absent/unknown ?tab falls back to DEFAULT_TOPIC.
  useEffect(() => {
    const t = new URLSearchParams(window.location.search).get("tab");
    if (t && TOPICS.some((x) => x.id === t)) setTopic(t as TopicId);
  }, []);

  function selectTopic(next: TopicId): void {
    setTopic(next);
    const url = new URL(window.location.href);
    url.searchParams.set("tab", next);
    window.history.replaceState(null, "", url);
  }

  return (
    <div className="flex min-h-0 min-w-0 flex-1 flex-col">
      <FeatureTitle title="Invitations" help={help} />
      <div className="grid min-h-0 min-w-0 flex-1 grid-cols-[200px_1fr] gap-0 px-6 pb-8 pt-2">
        <aside className="overflow-y-auto border-r border-border pr-4 pt-1">
          <nav>
            <ul className="space-y-1">
              {TOPICS.map((t) => (
                <li key={t.id}>
                  <button
                    type="button"
                    onClick={() => selectTopic(t.id)}
                    className={cn(
                      railLinkVariants({ active: topic === t.id }),
                      "w-full text-left",
                    )}
                  >
                    {t.label}
                  </button>
                </li>
              ))}
            </ul>
          </nav>
        </aside>
        <div className="flex min-h-0 min-w-0 flex-col overflow-y-auto pl-6">
          {topic === "requests" && <RequestsPane />}
          {topic === "pending" && <PendingUsersPane />}
          {topic === "invites" && <InvitesPane />}
        </div>
      </div>
    </div>
  );
}

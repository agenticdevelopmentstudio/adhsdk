"use client";

import { useCallback } from "react";
import { RailHostBoundary, StackGroupDetail, useBasePathRoute } from "@adh-sdk/resource";
import { confirmNavigation } from "@adh-sdk/ui/lib/navigation-guard";

import { AdminQueryProvider } from "./AdminQueryProvider";
import { ADMIN_PANES } from "./adminPanes";
import {
  ADMIN_CATEGORIES,
  adminTopicsIn,
  useAdminCategorySelection,
  type AdminTopicId,
} from "./adminTopics";

/**
 * The admin console as a mountable, hierarchical topic/detail feature: a rail of categories
 * (Access, AI Processing, …), then the chosen category's sections (Audit, Invitations, Users, …),
 * beside the selected section's pane.
 *
 * This is the SAME rail `admin.agenticdeveloperhub`'s own `AdminShell` renders, but built on the
 * fleet's shared `StackGroupDetail` / `RailHostBoundary` instead of admin's own
 * `HierarchicalDetailView` call, because that is the shape the hub's features share. The hub
 * mounts it as its Admin workspace at the top-level `/admin`, where no rail host sits above it, so
 * `RailHostBoundary` hosts the stack itself and the categories ARE the root list. Under a host
 * that already owns a merged topic/detail stack the same boundary would instead join it as one
 * more level — nothing here depends on which. The admin site keeps its own `AdminShell` because it
 * IS its site's whole stack, and `HierarchicalDetailView` is the right tool for owning one outright.
 *
 * It brings its own query scope ({@link AdminQueryProvider}), so the panes fetch through the
 * toolkit's client with the admin freshness whatever the host mounts above it.
 *
 * Gating is deliberately NOT this component's job. Whether the signed-in caller may see admin at
 * all, and which of the twelve sections (if fewer than all) they may open, is a host decision —
 * the hub knows the caller's platform role, the admin site's own `(admin)/layout.tsx` already
 * checks it before this ever mounts, and a THIRD host might have a third rule. Baking a check in
 * here would mean every host inherits admin.agenticdeveloperhub's specific notion of who is an
 * admin, which is exactly the coupling extracting this package was meant to remove. A host that
 * needs to hide sections filters `ADMIN_TOPICS` (or `ADMIN_PANES`) before ever reaching this
 * component; this component only ever renders what it is handed.
 */
export function AdminFeature({
  basePath,
  topicId,
}: {
  /** The feature's URL base; every push is `<basePath>/<topicId>`. */
  basePath: string;
  /** The open section, or undefined for the bare topic overview. */
  topicId?: AdminTopicId;
}) {
  const { pushSegment } = useBasePathRoute(basePath);
  // A rail row is a button that pushes — which the shared UnsavedChangesGuard does NOT intercept
  // (it catches anchor clicks and navigations that consult confirmNavigation). Without this a
  // section switch with an editor open dropped its edits silently; the admin site's AdminShell
  // guards its rail the same way (`navigateGuarded`). With no dirty guard mounted it resolves at
  // once, so an ordinary switch is unaffected.
  const selectGuarded = useCallback(
    (id: string | null) => {
      void confirmNavigation().then((ok) => {
        if (ok) pushSegment(id);
      });
    },
    [pushSegment],
  );
  // Closing the open section for a category switch — the same guard, reporting whether it moved so
  // the category selection follows only a navigation that actually happened.
  const leaveTopic = useCallback(async () => {
    if (!(await confirmNavigation())) return false;
    pushSegment(null);
    return true;
  }, [pushSegment]);
  const categorySelection = useAdminCategorySelection(topicId ?? null, leaveTopic);

  return (
    <AdminQueryProvider>
      <RailHostBoundary>
        {/* Two levels: the categories, then the chosen category's sections. The URL still names
            only the section (`<basePath>/<topicId>`) — the category is read off it — so the
            category rail's selection comes from useAdminCategorySelection, not a URL segment. */}
        <StackGroupDetail
          levelId="admin-categories"
          title="Admin"
          itemNoun="admin category"
          urlSelection={categorySelection}
          items={ADMIN_CATEGORIES.map((category) => {
            const CategoryIcon = category.icon;
            return {
              id: category.id,
              label: category.label,
              description: category.description,
              icon: <CategoryIcon size={16} aria-hidden />,
              // Choosing a category opens a further rail (its sections), not a detail.
              leadsTo: "list",
              render: () => (
                // A member's own StackGroupDetail lands as the NEXT rail of the same merged stack
                // (StackLevels advances the depth), not as a rail nested inside this one.
                <StackGroupDetail
                  levelId="admin-topics"
                  title={category.label}
                  itemNoun="admin section"
                  urlSelection={{ selectedId: topicId ?? null, onSelect: selectGuarded }}
                  items={adminTopicsIn(category.id).map((topic) => {
                    const Icon = topic.icon;
                    const Pane = ADMIN_PANES[topic.id];
                    return {
                      id: topic.id,
                      label: topic.label,
                      description: topic.description,
                      icon: <Icon size={16} aria-hidden />,
                      // Every section IS its own detail — none publishes a further rail — so
                      // choosing one is the final choice, same as `leadsTo`'s documented default.
                      // Named explicitly so a reader doesn't have to know the default.
                      leadsTo: "detail",
                      render: () => (
                        // Each pane owns its own fixed FeatureTitle header and scrolling body
                        // (padding included), so this wrapper only has to keep the flex/min-h-0
                        // chain intact — it must NOT add overflow or padding of its own, or the
                        // pane would get two scroll regions nested inside each other.
                        <div className="flex min-h-0 min-w-0 flex-1 flex-col">
                          <Pane help={topic.description} />
                        </div>
                      ),
                    };
                  })}
                />
              ),
            };
          })}
        />
      </RailHostBoundary>
    </AdminQueryProvider>
  );
}

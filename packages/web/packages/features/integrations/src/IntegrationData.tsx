"use client";

import { useCallback } from "react";
import { Table2 } from "lucide-react";
import { CrudDataView, CRUD_TABLES, useExitGuardChannel } from "@adh-sdk/crud";
import { StackGroupDetail } from "@adh-sdk/resource";
import { useRailExitGuard as useWorkspaceExitGuard } from "@adh-sdk/resource";
import { isServiceUnavailable, useResourceList } from "@adh-sdk/data";
import {
  integrationsApi,
  type ConnectionDataResource,
  type SafeConnection,
} from "@adh-sdk/data/integrations";
import { ConnectionDataView } from "./ConnectionDataView";

/** Where a Data table's rows come from: the generic CRUD API (`key` is a CRUD_TABLES key,
 *  filtered to the provider on `filterColumn`), or the per-connection data route
 *  `GET /integrations/{connectionId}/data/{resource}` for the customer-scoped synced tables
 *  that generic CRUD no longer serves. */
type DataTableSource =
  | { kind: "crud"; key: string; filterColumn: string }
  | { kind: "data"; resource: ConnectionDataResource };

interface DataTable {
  id: string;
  label: string;
  source: DataTableSource;
}

const crud = (key: string, label: string, filterColumn: string): DataTable => ({
  id: key,
  label,
  source: { kind: "crud", key, filterColumn },
});
const data = (resource: ConnectionDataResource, label: string): DataTable => ({
  id: `data/${resource}`,
  label,
  source: { kind: "data", resource },
});

/** The Posts + Notifications pair every social provider's worker writes. */
const SOCIAL = [data("social-posts", "Posts"), data("social-notifications", "Notifications")];

/**
 * The synced-data tables each provider's WORKER writes, in display order — drives the
 * integration detail's Data topic. CRUD tables carry the provider-discriminator column
 * (`sourceProvider` on the shared tables, `source` on calendar_events). gmail's mail bodies
 * are excluded from generic CRUD (private), so it browses only its labels.
 */
const PROVIDER_DATA_TABLES: Record<string, DataTable[]> = {
  reddit: [
    data("social-notifications", "Inbox"),
    crud("integration/integration-bookmarks", "Posts", "sourceProvider"),
  ],
  gmail: [data("email-labels", "Labels")],
  "google-photos": [data("media-items", "Media"), data("media-albums", "Albums")],
  bluesky: SOCIAL,
  mastodon: SOCIAL,
  x: SOCIAL,
  facebook: SOCIAL,
  instagram: SOCIAL,
  "google-calendar": [crud("integration/integration-calendar-events", "Events", "source")],
  mailchimp: [
    crud("integration/integration-audiences", "Audiences", "provider"),
    crud("integration/integration-audience-contacts", "Contacts", "provider"),
    crud("integration/integration-campaign-stats", "Campaigns", "provider"),
  ],
  klaviyo: [
    crud("integration/integration-audiences", "Lists", "provider"),
    crud("integration/integration-audience-contacts", "Profiles", "provider"),
    crud("integration/integration-campaign-stats", "Campaigns", "provider"),
  ],
};

/** The provider's browsable synced tables (a CRUD table only when present in CRUD_TABLES, so
 *  a stale key can never render a broken view). Empty ⇒ the caller shows no Data topic. */
export function providerDataTables(providerId: string): DataTable[] {
  return (PROVIDER_DATA_TABLES[providerId] ?? []).filter(
    (t) => t.source.kind === "data" || t.source.key in CRUD_TABLES,
  );
}

/** A data-route table for every connection of the provider in the viewed ecosystem. The
 *  connection list shares ProviderConnections' cache key, so it is usually already loaded. */
function ConnectionDataTables({
  providerId,
  ecosystemId,
  resource,
}: {
  providerId: string;
  ecosystemId?: string;
  resource: ConnectionDataResource;
}) {
  const load = useCallback(
    () => integrationsApi.listConnections(ecosystemId ?? ""),
    [ecosystemId],
  );
  const { items, error } = useResourceList<SafeConnection>(
    `ecosystem:${ecosystemId}:integration-connections`,
    load,
    { reportErrors: false },
  );
  if (!ecosystemId) return <p className="text-sm text-apt-text-muted">No ecosystem selected.</p>;
  if (error && !items) {
    return (
      <p className="text-sm text-apt-text-muted">
        {isServiceUnavailable(error) ? "Service unavailable." : "Couldn't load connected accounts."}
      </p>
    );
  }
  const connections = (items ?? []).filter((c) => c.provider === providerId);
  if (items && connections.length === 0) {
    return <p className="text-sm text-apt-text-muted">No account connected.</p>;
  }
  return (
    <div className="flex min-w-0 flex-col gap-6">
      {connections.map((c) => (
        <div key={c.id} className="flex min-w-0 flex-col gap-2">
          {connections.length > 1 && (
            <span className="text-sm font-medium text-apt-text">
              {c.displayName || c.username || c.externalAccountId}
            </span>
          )}
          <ConnectionDataView connectionId={c.id} resource={resource} />
        </div>
      ))}
    </div>
  );
}

/** The Data topic's pane: one view per synced table, filtered to this provider's rows and
 *  SCOPED to the ecosystem the pane is configuring (the caller's JWT ecosystem is never that
 *  one — see CrudDataView.scopeEcosystemId). A single table renders directly; several publish
 *  one more rail. Staged edits in a CRUD view register an unsaved-work guard so a topic/provider
 *  switch prompts Save/Discard/Cancel instead of silently dropping them. Data-route tables are
 *  read-only. */
export function IntegrationData({
  providerId,
  ecosystemId,
}: {
  providerId: string;
  /** The ecosystem whose synced rows this Data topic browses (the pane's viewed
   *  ecosystem). Absent → the caller's own JWT ecosystem (backend default). */
  ecosystemId?: string;
}) {
  // Bridges the mounted CrudDataView's live guard into one stable proxy, registered
  // with the workspace chrome so ANY gated navigation (topic switch, provider switch,
  // breadcrumb) consults it. Only the active table's view is mounted at a time, so
  // the single channel always reflects the visible editor.
  const { exitGuard, registerGuard } = useExitGuardChannel();
  useWorkspaceExitGuard(exitGuard);
  const tables = providerDataTables(providerId);
  if (tables.length === 0) return null;

  const renderTable = (t: DataTable) => (
    <div className="flex min-h-0 min-w-0 flex-1 flex-col px-6 py-4">
      {t.source.kind === "data" ? (
        <ConnectionDataTables
          providerId={providerId}
          ecosystemId={ecosystemId}
          resource={t.source.resource}
        />
      ) : (
        // providerDataTables kept only keys present in CRUD_TABLES, so the indexed access is
        // non-null despite noUncheckedIndexedAccess.
        <CrudDataView
          meta={CRUD_TABLES[t.source.key]!}
          filter={{ [t.source.filterColumn]: providerId }}
          scopeEcosystemId={ecosystemId}
          onGuardChange={registerGuard}
        />
      )}
    </div>
  );

  if (tables.length === 1) return renderTable(tables[0]!);
  return (
    <StackGroupDetail
      levelId={`integration-data-${providerId}`}
      title="Data"
      items={tables.map((t) => ({
        id: t.id,
        label: t.label,
        icon: <Table2 className="h-4 w-4" />,
        render: () => renderTable(t),
      }))}
    />
  );
}

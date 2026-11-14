"use client";

import { useState, type ReactNode } from "react";
import { FeatureTitle } from "@adh-sdk/resource";
import { SyncTablesEditor } from "@adh-sdk/ecosystem-config";
import { Select } from "@adh-sdk/ui/components/select";
import { useAdminEcosystems } from "../api/admin-ecosystems";

/**
 * Per-ecosystem offline-sync table enrollment for platform staff: pick ANY ecosystem, then edit
 * its enrollment through the backend's admin route family. The list itself is the shared
 * `SyncTablesEditor` the hub's sync page also mounts (with the ecosystem-manager family); this
 * pane adds only what is admin-specific, the picker over every ecosystem.
 */
export function SyncPane({ help }: { help?: ReactNode } = {}) {
  const [ecosystemId, setEcosystemId] = useState("");
  const ecosystems = useAdminEcosystems();

  return (
    <div className="flex min-h-0 min-w-0 flex-1 flex-col">
      <FeatureTitle title="Sync Tables" help={help} />
      <div className="flex min-h-0 min-w-0 flex-1 flex-col overflow-y-auto px-6 pb-8 pt-2">
        <p className="mb-6 max-w-2xl text-sm text-apt-text-muted">
          Choose which catalog tables each ecosystem syncs to offline clients. Syncing a table
          overrides the resource&apos;s platform default for this ecosystem;
          &ldquo;Reset to default&rdquo; removes the override.
        </p>

        {/* Not a list filter: this picks WHAT IS FETCHED, so it sits above the bar rather than in
            it. A control inside the bar reads as one more way to narrow rows already on screen. */}
        <div className="mb-6 w-80">
          <Select
            aria-label="Ecosystem"
            value={ecosystemId}
            onChange={(e) => setEcosystemId(e.target.value)}
          >
            <option value="">Select an ecosystem…</option>
            {(ecosystems.data ?? []).map((eco) => (
              <option key={eco.id} value={eco.id}>
                {eco.name} ({eco.slug})
              </option>
            ))}
          </Select>
        </div>

        {!ecosystemId && (
          <p className="text-apt-text-dim">Select an ecosystem to view its sync tables.</p>
        )}

        {/* Keyed on the ecosystem so the selection goes with it: resource ids are the same catalog
            everywhere, so ticks would otherwise SURVIVE the switch and a bar button pressed
            afterwards would write to an ecosystem whose state the operator never looked at. */}
        {ecosystemId && (
          <SyncTablesEditor key={ecosystemId} ecosystemId={ecosystemId} family="admin" />
        )}
      </div>
    </div>
  );
}

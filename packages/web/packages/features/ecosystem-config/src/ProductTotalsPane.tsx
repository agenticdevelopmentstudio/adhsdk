"use client";

import { BarChart3 } from "lucide-react";

import { useProductTotals } from "@adh-sdk/data/product-admin";
import { StatCard } from "@adh-sdk/ui/blocks";
import { ErrorText } from "@adh-sdk/ui/components/error-text";
import { formatBytes, formatCount } from "@adh-sdk/ui/lib/quantities";

/** The jobs figures: the total, then one per status in name order ("Jobs failed"). */
function jobStats(byStatus: Record<string, number>) {
  const statuses = Object.keys(byStatus).sort();
  const total = statuses.reduce((n, s) => n + (byStatus[s] ?? 0), 0);
  return [
    { label: "Jobs", value: formatCount(total) },
    ...statuses.map((s) => ({ label: `Jobs ${s.replace(/_/g, " ")}`, value: formatCount(byStatus[s] ?? 0) })),
  ];
}

/**
 * A product's TOTALS (phase 6) as a row of figures: counts only, never a person. The hub's Admin
 * site pane shows it to the product's managers, and the product admin site's Totals page to its
 * admins; both read `/product-admin/totals`. Phase 7 adds the customers' jobs by status, a count
 * read through the definer aggregates, never a job.
 */
export function ProductTotalsPane({ ecosystemId }: { ecosystemId: string }) {
  const { data, error, isPending } = useProductTotals(ecosystemId);

  if (error) return <ErrorText error={`Couldn't load the totals: ${error.message}`} />;
  if (isPending || !data) return <p className="text-sm text-apt-text-muted">Loading…</p>;

  return (
    <StatCard
      title="Totals"
      icon={<BarChart3 size={16} aria-hidden />}
      statLayout="strip"
      stats={[
        { label: "Customers", value: formatCount(data.customers) },
        { label: "New in 7 days", value: formatCount(data.new7d) },
        { label: "New in 30 days", value: formatCount(data.new30d) },
        { label: "Active in 7 days", value: formatCount(data.active7d) },
        { label: "Active in 30 days", value: formatCount(data.active30d) },
        { label: "Storage", value: formatBytes(data.storageBytes) },
        ...jobStats(data.jobsByStatus),
        { label: "Invitations waiting", value: formatCount(data.pendingInvitations) },
        { label: "Requests waiting", value: formatCount(data.pendingRequests) },
      ]}
    />
  );
}

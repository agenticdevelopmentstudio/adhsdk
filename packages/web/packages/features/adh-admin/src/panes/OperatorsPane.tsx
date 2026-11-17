"use client";

import { useMemo, useState, type ReactElement, type ReactNode } from "react";
import { useGrantRole, useOperators, useRevokeRole, type Operator } from "../api/admin";
import { Badge } from "@adh-sdk/ui/components/badge";
import { Button } from "@adh-sdk/ui/components/button";
import { AlertModal } from "@adh-sdk/ui/components/alert-modal";
import { errorMessage } from "@adh-sdk/ui/lib/errors";
import { FeatureTitle } from "@adh-sdk/resource";
import { EditableList, useEditableList, type EditableListColumn } from "../components/editable-list";
import { formatDate } from "../lib/timestamps";

/**
 * Operators — every account in the Operators ecosystem, the people who sign in to this console,
 * and which of them hold `admin`.
 *
 * The one action is per row, because it means nothing across a selection: one operator holds
 * `admin` or does not. Revoking the last holder is refused by the backend (409 `last_operator`),
 * and its message is shown as it was sent, since it already says what to do instead.
 */
export function OperatorsPane({ help }: { help?: ReactNode } = {}): ReactElement {
  const { data: operators, isLoading, error } = useOperators();
  const grantRole = useGrantRole();
  const revokeRole = useRevokeRole();
  const [roleError, setRoleError] = useState<string | null>(null);

  const columns: EditableListColumn<Operator>[] = useMemo(
    () => [
      {
        key: "name",
        header: "Operator",
        value: (op) => op.name,
        render: (op) => <span className="truncate font-medium text-apt-text">{op.name || "—"}</span>,
      },
      {
        key: "email",
        header: "Email",
        value: (op) => op.email,
        render: (op) => <span className="font-mono text-xs text-apt-text-muted">{op.email}</span>,
      },
      {
        key: "admin",
        header: "Admin",
        width: "14rem",
        // Sorted by the answer, not by the cell, which is a badge and a button.
        value: (op) => (op.holdsAdmin ? "admin" : ""),
        render: (op) => {
          const label = op.email || op.name || op.id;
          return (
            <span className="flex items-center gap-2">
              {op.holdsAdmin ? <Badge variant="accent">admin</Badge> : null}
              {op.holdsAdmin ? (
                <Button
                  size="xs"
                  variant="destructive-ghost"
                  aria-label={`Revoke admin from ${label}`}
                  disabled={revokeRole.isPending}
                  onClick={() =>
                    revokeRole.mutate(
                      { userId: op.id, role: "admin" },
                      { onError: (e) => setRoleError(errorMessage(e)) },
                    )
                  }
                >
                  Revoke admin
                </Button>
              ) : (
                <Button
                  size="xs"
                  variant="ghost"
                  aria-label={`Grant admin to ${label}`}
                  disabled={grantRole.isPending}
                  onClick={() =>
                    grantRole.mutate(
                      { userId: op.id, capability: "admin" },
                      { onError: (e) => setRoleError(errorMessage(e)) },
                    )
                  }
                >
                  Grant admin
                </Button>
              )}
            </span>
          );
        },
      },
      {
        key: "joined",
        header: "Joined",
        width: "9rem",
        // Sorted by the raw timestamp, shown formatted.
        value: (op) => op.createdAt,
        render: (op) => <span className="text-xs text-apt-text-dim">{formatDate(op.createdAt)}</span>,
      },
    ],
    [grantRole, revokeRole],
  );

  const list = useEditableList<Operator>({
    rows: operators,
    getRowId: (op) => op.id,
    columns,
  });

  return (
    <div className="flex min-h-0 min-w-0 flex-1 flex-col">
      <FeatureTitle
        title="Operators"
        api={{
          method: "GET",
          path: "/v1/auth/capabilities/operators",
          pathValues: {},
          title: "Operators API",
        }}
        help={help}
      />
      <div className="flex min-h-0 min-w-0 flex-1 flex-col overflow-y-auto px-6 pb-8 pt-2">
        <EditableList
          list={list}
          ariaLabel="Operators"
          selectable={false}
          loading={isLoading}
          error={error}
          errorTitle="Couldn't load operators"
          columnWidthsKey="admin-operators"
          describeRow={(op) => op.email}
          searchPlaceholder="Name or email"
          emptyLabel="No operators yet."
          emptyFilteredLabel="No operators match this search."
        />

        {roleError && (
          <AlertModal
            open
            tone="error"
            title="Couldn't change admin"
            description={roleError}
            confirmLabel="OK"
            onConfirm={() => setRoleError(null)}
          />
        )}
      </div>
    </div>
  );
}

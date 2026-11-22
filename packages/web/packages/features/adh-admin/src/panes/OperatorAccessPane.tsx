"use client";

import {
  useCallback,
  useMemo,
  useState,
  type FormEvent,
  type ReactElement,
  type ReactNode,
} from "react";
import { FeatureTitle } from "@adh-sdk/resource";
import { Button } from "@adh-sdk/ui/components/button";
import { Input } from "@adh-sdk/ui/components/input";
import { Label } from "@adh-sdk/ui/components/label";
import { Select } from "@adh-sdk/ui/components/select";
import {
  normalizeOperatorAccessFilters,
  useOperatorAccess,
  useOperators,
  type OperatorAccessEvent,
  type OperatorAccessFilters,
} from "../api/admin";
import {
  EditableList,
  WindowFooter,
  useEditableList,
  type EditableListColumn,
} from "../components/editable-list";
import { formatDateTime } from "../lib/timestamps";

function shortId(id: string | null): string {
  return id ? id.slice(0, 8) : "";
}

/** A row's identity, hoisted: `useEditableList` memoizes on it, so an inline arrow rebuilt it per render. */
const eventId = (e: OperatorAccessEvent): string => e.id;

/** What the filter form holds while the operator edits it. Times are `datetime-local` text. */
interface FilterDraft {
  operatorAccountId: string;
  targetEcosystemId: string;
  from: string;
  to: string;
}

const EMPTY_DRAFT: FilterDraft = {
  operatorAccountId: "",
  targetEcosystemId: "",
  from: "",
  to: "",
};

/** A `datetime-local` value (the browser's local time, no zone) as ISO text, or nothing. */
function localToIso(value: string): string | undefined {
  if (!value) return undefined;
  const ms = Date.parse(value);
  return Number.isNaN(ms) ? undefined : new Date(ms).toISOString();
}

/** 8-4-4-4-12 hex, as the route checks `target_ecosystem_id` (adhbackend lib/uuid.ts UUID_RE). */
const UUID_RE = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

/** What is wrong with a draft, per field. Empty when the draft can be applied. */
interface DraftErrors {
  targetEcosystemId?: string;
  range?: string;
}

/**
 * The draft checked before it is applied. The route answers 400 for a non-uuid ecosystem id, and
 * that error would replace the whole list with a generic load failure that never names the field;
 * a From at or after To is not an error to the server at all, just an empty range, which the list
 * would report as "no operator access recorded", a false answer for an audit log. Both are caught
 * here and shown beside the field instead.
 */
function checkDraft(d: FilterDraft): DraftErrors {
  const errors: DraftErrors = {};
  const eco = d.targetEcosystemId.trim();
  if (eco && !UUID_RE.test(eco)) {
    errors.targetEcosystemId =
      "Enter the whole ecosystem id, e.g. 22222222-2222-4222-8222-222222222222. The list shows only its first 8 characters.";
  }
  const from = localToIso(d.from);
  const to = localToIso(d.to);
  if (from && to && Date.parse(from) >= Date.parse(to)) {
    errors.range = "From must be earlier than To.";
  }
  return errors;
}

/** Whether two filter sets ask the server the same thing, blanks dropped. */
function sameFilters(a: OperatorAccessFilters, b: OperatorAccessFilters): boolean {
  return (
    JSON.stringify(normalizeOperatorAccessFilters(a)) ===
    JSON.stringify(normalizeOperatorAccessFilters(b))
  );
}

/** The draft as the filters the server is asked for. Only this reaches the query key. */
function toFilters(d: FilterDraft): OperatorAccessFilters {
  return {
    operatorAccountId: d.operatorAccountId || undefined,
    targetEcosystemId: d.targetEcosystemId.trim() || undefined,
    from: localToIso(d.from),
    to: localToIso(d.to),
  };
}

export function OperatorAccessPane({
  help,
}: { help?: ReactNode } = {}): ReactElement {
  const [draft, setDraft] = useState<FilterDraft>(EMPTY_DRAFT);
  const [applied, setApplied] = useState<OperatorAccessFilters>({});
  const [errors, setErrors] = useState<DraftErrors>({});
  const log = useOperatorAccess(applied);
  const operators = useOperators();

  // Who, by email: the operator list is a handful of rows, and an unresolved id (an account since
  // removed, or the list not loaded yet) falls back to its short id rather than hiding the row.
  const emailById = useMemo(() => {
    const m = new Map<string, string>();
    for (const o of operators.data ?? []) m.set(o.id, o.email);
    return m;
  }, [operators.data]);
  const who = useCallback(
    (e: OperatorAccessEvent): string =>
      emailById.get(e.operatorAccountId) ?? shortId(e.operatorAccountId),
    [emailById],
  );

  const columns = useMemo<EditableListColumn<OperatorAccessEvent>[]>(
    () => [
      {
        key: "at",
        header: "When",
        width: "12rem",
        // Sorted by the raw timestamp, displayed formatted, as the Audit pane does.
        value: (e) => e.at,
        render: (e) => (
          <span className="whitespace-nowrap text-sm text-apt-text-muted">
            {formatDateTime(e.at)}
          </span>
        ),
      },
      {
        key: "who",
        header: "Who",
        width: "14rem",
        value: who,
        render: (e) => (
          <span
            className="block truncate text-sm text-apt-text"
            title={e.operatorAccountId}
          >
            {who(e)}
          </span>
        ),
      },
      {
        key: "request",
        header: "Request",
        width: "minmax(0,1fr)",
        value: (e) => `${e.method} ${e.path}`,
        render: (e) => (
          <span
            className="block truncate font-mono text-xs text-apt-text"
            title={e.route ?? e.path}
          >
            {e.method} {e.path}
          </span>
        ),
      },
      {
        key: "targetEcosystemId",
        header: "Ecosystem",
        width: "9rem",
        value: (e) => e.targetEcosystemId ?? "",
        render: (e) =>
          e.targetEcosystemId ? (
            <span
              className="font-mono text-xs text-apt-text-muted"
              title={e.targetEcosystemId}
            >
              {shortId(e.targetEcosystemId)}
            </span>
          ) : (
            <span className="text-sm text-apt-text-muted">—</span>
          ),
      },
      {
        key: "requestId",
        header: "Request id",
        width: "9rem",
        value: (e) => e.requestId ?? "",
        render: (e) => (
          <span
            className="font-mono text-xs text-apt-text-muted"
            title={e.requestId ?? undefined}
          >
            {shortId(e.requestId) || "—"}
          </span>
        ),
      },
    ],
    [who],
  );

  const facets = useMemo(
    () => [
      {
        id: "method",
        label: "Method",
        valuesOf: (e: OperatorAccessEvent) => [e.method],
      },
    ],
    [],
  );

  const list = useEditableList<OperatorAccessEvent>({
    rows: log.rows,
    getRowId: eventId,
    columns,
    facets,
    initialSort: { key: "at", dir: "desc" },
  });

  const apply = (ev: FormEvent) => {
    ev.preventDefault();
    const found = checkDraft(draft);
    setErrors(found);
    if (found.targetEcosystemId || found.range) return;
    const next = toFilters(draft);
    // Applying the filters already in force is a request to look again. Setting an equal key
    // would do nothing (react-query hashes it the same and the data is still fresh), so the
    // window is re-read instead, and a row written a moment ago shows up.
    if (sameFilters(next, applied)) log.refresh();
    else setApplied(next);
  };
  // The form is edited freely and takes effect only on Apply, so it can show filters the list is
  // not using. Saying so keeps an operator from reading the list as filtered by what the form shows.
  const pending = !sameFilters(toFilters(draft), applied);
  const clear = () => {
    setDraft(EMPTY_DRAFT);
    setErrors({});
    setApplied({});
  };
  const set = (field: keyof FilterDraft) => (value: string) =>
    setDraft((d) => ({ ...d, [field]: value }));

  return (
    <div className="flex min-h-0 min-w-0 flex-1 flex-col">
      <FeatureTitle title="Operator Access" help={help} />
      <div className="flex min-h-0 min-w-0 flex-1 flex-col overflow-y-auto px-6 pb-8 pt-2">
        <p className="mb-6 max-w-2xl text-sm text-apt-text-muted">
          Every request an operator made with operator access — reaching past
          ecosystem ownership — newest first. The log is written before the
          request reads anything, and nothing can change or remove a row. Narrow
          by operator, ecosystem or time to reach older entries.
        </p>

        <form
          onSubmit={apply}
          aria-label="Filter operator access"
          className="mb-6 flex flex-wrap items-end gap-4"
        >
          <div className="flex flex-col gap-1.5">
            <Label htmlFor="operator-access-operator">Operator</Label>
            <Select
              id="operator-access-operator"
              value={draft.operatorAccountId}
              onChange={(e) => set("operatorAccountId")(e.target.value)}
            >
              <option value="">Any operator</option>
              {(operators.data ?? []).map((o) => (
                <option key={o.id} value={o.id}>
                  {o.email}
                </option>
              ))}
            </Select>
          </div>
          <div className="flex flex-col gap-1.5">
            <Label htmlFor="operator-access-ecosystem">Ecosystem id</Label>
            <Input
              id="operator-access-ecosystem"
              className="w-80 font-mono text-xs"
              placeholder="Any ecosystem"
              value={draft.targetEcosystemId}
              onChange={(e) => set("targetEcosystemId")(e.target.value)}
              aria-invalid={errors.targetEcosystemId ? true : undefined}
              aria-describedby={
                errors.targetEcosystemId
                  ? "operator-access-ecosystem-error"
                  : undefined
              }
            />
          </div>
          <div className="flex flex-col gap-1.5">
            <Label htmlFor="operator-access-from">From</Label>
            <Input
              id="operator-access-from"
              type="datetime-local"
              value={draft.from}
              onChange={(e) => set("from")(e.target.value)}
            />
          </div>
          <div className="flex flex-col gap-1.5">
            <Label htmlFor="operator-access-to">To</Label>
            <Input
              id="operator-access-to"
              type="datetime-local"
              value={draft.to}
              onChange={(e) => set("to")(e.target.value)}
              aria-invalid={errors.range ? true : undefined}
              aria-describedby={
                errors.range ? "operator-access-range-error" : undefined
              }
            />
          </div>
          <Button type="submit">Apply filters</Button>
          <Button type="button" variant="outline" onClick={clear}>
            Clear
          </Button>
          {pending && (
            <span
              className="self-center text-sm text-apt-text-muted"
              role="status"
            >
              Not applied yet: the list still shows the previous filters.
            </span>
          )}
          {(errors.targetEcosystemId || errors.range) && (
            <div className="flex basis-full flex-col gap-1">
              {errors.targetEcosystemId && (
                <span
                  id="operator-access-ecosystem-error"
                  role="alert"
                  className="text-sm text-apt-red"
                >
                  {errors.targetEcosystemId}
                </span>
              )}
              {errors.range && (
                <span
                  id="operator-access-range-error"
                  role="alert"
                  className="text-sm text-apt-red"
                >
                  {errors.range}
                </span>
              )}
            </div>
          )}
        </form>

        {operators.error ? (
          <p role="alert" className="mb-4 text-sm text-apt-red">
            Couldn&apos;t load the operator list, so Who shows short account
            ids and the Operator filter offers no one by name.
          </p>
        ) : null}

        {/* No actions, as on the Audit pane: the log is append-only in the database itself. */}
        <EditableList<OperatorAccessEvent>
          list={list}
          ariaLabel="Operator access events"
          searchPlaceholder="Search the loaded entries"
          emptyLabel="No operator access recorded for these filters."
          emptyFilteredLabel="Nothing in the loaded window matches — load older entries, or widen the filters."
          loading={log.isLoading}
          error={log.error}
          errorTitle="Couldn't load the operator access log"
          columnWidthsKey="admin.operator-access"
          describeRow={(e) =>
            `${e.method} ${e.path} by ${who(e)}, ${formatDateTime(e.at)}`
          }
          footer={
            <WindowFooter
              noun="entries"
              loaded={log.rows.length}
              showing={list.rows.length}
              hasMore={log.hasMore}
              busy={log.isFetchingMore}
              onLoadMore={log.loadMore}
            />
          }
        />
      </div>
    </div>
  );
}

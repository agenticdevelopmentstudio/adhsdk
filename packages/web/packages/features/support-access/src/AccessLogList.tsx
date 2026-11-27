"use client";

import type { ReactElement } from "react";

import { groupAccess, useSupportAccess, type SupportAccessGroup, type SupportSide } from "@adh-sdk/data/support";
import { Button } from "@adh-sdk/ui/components/button";
import { ErrorText } from "@adh-sdk/ui/components/error-text";
import { List, ListItem } from "@adh-sdk/ui/components/list";

const WEEKDAYS = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"];
const MONTHS = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];

const DAY_MS = 24 * 60 * 60 * 1000;

/** Midnight, local time, of the day a `YYYY-MM-DD` key or a Date names. */
const midnight = (d: Date) => new Date(d.getFullYear(), d.getMonth(), d.getDate());
const fromDayKey = (key: string) => {
  const [y, m, d] = key.split("-").map(Number);
  return new Date(y!, (m ?? 1) - 1, d ?? 1);
};

/**
 * When a group of reads happened, as a person says it: "today", "yesterday", "on Tuesday" within
 * the last week, and "on 12 Nov" (with the year when it is not this one) before that.
 */
export function dayPhrase(dayKey: string, now: Date = new Date()): string {
  const day = fromDayKey(dayKey);
  const days = Math.round((midnight(now).getTime() - day.getTime()) / DAY_MS);
  if (days <= 0) return "today";
  if (days === 1) return "yesterday";
  if (days < 7) return `on ${WEEKDAYS[day.getDay()]}`;
  const year = day.getFullYear() === now.getFullYear() ? "" : ` ${day.getFullYear()}`;
  return `on ${day.getDate()} ${MONTHS[day.getMonth()]}${year}`;
}

/** A table as a person reads it: `chat_messages` is "chat messages". */
export const tableWords = (table: string | null): string => (table ? table.replace(/_/g, " ") : "content");

/** "Ana from Support viewed your notes, 3 times on Tuesday." */
export function describeAccess(
  group: SupportAccessGroup,
  who: { name: string; role: string },
  now: Date = new Date(),
): string {
  const name = group.granteeName || who.name;
  const times = group.count === 1 ? "once" : group.count === 2 ? "twice" : `${group.count} times`;
  return `${name} from ${who.role} viewed your ${tableWords(group.table)}, ${times} ${dayPhrase(group.day, now)}`;
}

/**
 * The read log of one grant, grouped by table and day, newest first, a page at a time. The log
 * pages by the backend's cursor; "Show more" fetches the next page and the groups are recounted
 * over everything loaded, so a day split across two pages becomes one line.
 */
export function AccessLogList({
  side,
  grantId,
  granteeName,
  granteeRole,
}: {
  side: SupportSide;
  grantId: string;
  granteeName: string;
  granteeRole: string;
}): ReactElement {
  const log = useSupportAccess(side, grantId);
  const rows = log.data?.pages.flatMap((p) => p.items) ?? [];
  const groups = groupAccess(rows);

  if (log.error) return <ErrorText error={`Couldn't load what was viewed: ${log.error.message}`} />;
  if (log.isPending) return <p className="text-xs text-apt-text-muted">Loading what was viewed…</p>;
  if (groups.length === 0) return <p className="text-xs text-apt-text-muted">Nothing has been viewed yet.</p>;

  return (
    <div className="flex flex-col gap-2">
      <List aria-label={`What ${granteeName} viewed`}>
        {groups.map((g) => (
          <ListItem key={`${g.schema}.${g.table}.${g.day}`} className="text-xs text-apt-text">
            {describeAccess(g, { name: granteeName, role: granteeRole })}
          </ListItem>
        ))}
      </List>
      {log.hasNextPage && (
        <Button
          size="sm"
          variant="ghost"
          className="self-start"
          disabled={log.isFetchingNextPage}
          onClick={() => void log.fetchNextPage()}
        >
          Show more
        </Button>
      )}
    </div>
  );
}

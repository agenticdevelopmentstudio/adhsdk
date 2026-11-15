import { describe, it, expect } from 'vitest';
import { errorsSummary, ERRORS_TOP_COUNT } from '../src/telemetry/errors-summary';
import type { ErrorDTO } from '../src/telemetry/types';

// The Errors card's figures, which status-web used to work out from the raw rows.

const err = (id: string, count: number, active?: boolean): ErrorDTO => ({
  id,
  issueKey: id,
  project: 'p',
  title: id,
  culprit: null,
  level: 'error',
  count,
  userCount: 0,
  firstSeen: null,
  lastSeen: null,
  permalink: null,
  ...(active === undefined ? {} : { active }),
});

describe('errorsSummary', () => {
  it('errors-summary-001 splits active issues from the backlog and totals every event', () => {
    const s = errorsSummary([err('a', 3, true), err('b', 10, false), err('c', 2, true)]);
    expect(s).toMatchObject({ active: 2, backlog: 1, events: 15 });
  });

  it('errors-summary-002 lists only active issues, loudest first, capped', () => {
    const rows = [err('quiet', 1, true), err('old-loud', 99, false), ...Array.from({ length: 6 }, (_, i) => err(`x${i}`, 10 + i, true))];
    const top = errorsSummary(rows).top.map((e) => e.id);
    expect(top).toHaveLength(ERRORS_TOP_COUNT);
    expect(top).toEqual(['x5', 'x4', 'x3', 'x2', 'x1']);
    expect(top).not.toContain('old-loud');
  });

  it('errors-summary-003 never counts an unjudged row as an incident', () => {
    expect(errorsSummary([err('u', 4)])).toMatchObject({ active: 0, backlog: 1, top: [] });
  });

  it('errors-summary-004 is all zeros for no errors', () => {
    expect(errorsSummary([])).toEqual({ active: 0, backlog: 0, events: 0, top: [] });
  });

  it('errors-summary-005 counts an explicitly inactive row as backlog, with its events', () => {
    expect(errorsSummary([err('i', 7, false)])).toEqual({ active: 0, backlog: 1, events: 7, top: [] });
  });

  it('errors-summary-006 keeps input order between equal counts', () => {
    expect(errorsSummary([err('p', 5, true), err('q', 5, true)]).top.map((e) => e.id)).toEqual(['p', 'q']);
  });

  it('errors-summary-007 keeps all five rows when exactly five are active', () => {
    const rows = Array.from({ length: ERRORS_TOP_COUNT }, (_, i) => err(`e${i}`, i + 1, true));
    expect(errorsSummary(rows).top).toHaveLength(ERRORS_TOP_COUNT);
  });

  it('errors-summary-008 does not mutate the input array or its rows', () => {
    const rows = [err('a', 3, true), err('b', 1, false), err('c', 2, true)];
    const copy = structuredClone(rows);
    errorsSummary(rows);
    expect(rows).toEqual(copy);
  });

  it('errors-summary-009 reads a NaN count as 0 in the event total', () => {
    expect(errorsSummary([err('n', Number.NaN, true), err('m', 4, true)]).events).toBe(4);
  });

  it('errors-summary-010 lists the original row objects, unmodified', () => {
    const row = err('o', 2, true);
    expect(errorsSummary([row]).top[0]).toBe(row);
  });

  it('errors-summary-011 cuts equal counts at the cap in input order', () => {
    const rows = Array.from({ length: 6 }, (_, i) => err(`r${i + 1}`, 5, true));
    const s = errorsSummary(rows);
    expect(s.top.map((e) => e.id)).toEqual(['r1', 'r2', 'r3', 'r4', 'r5']);
    expect(s.active).toBe(6);
  });
});

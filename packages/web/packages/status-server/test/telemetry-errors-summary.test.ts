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
  it('splits active issues from the backlog and totals every event', () => {
    const s = errorsSummary([err('a', 3, true), err('b', 10, false), err('c', 2, true)]);
    expect(s).toMatchObject({ active: 2, backlog: 1, events: 15 });
  });

  it('lists only active issues, loudest first, capped', () => {
    const rows = [err('quiet', 1, true), err('old-loud', 99, false), ...Array.from({ length: 6 }, (_, i) => err(`x${i}`, 10 + i, true))];
    const top = errorsSummary(rows).top.map((e) => e.id);
    expect(top).toHaveLength(ERRORS_TOP_COUNT);
    expect(top).toEqual(['x5', 'x4', 'x3', 'x2', 'x1']);
    expect(top).not.toContain('old-loud');
  });

  it('never counts an unjudged row as an incident', () => {
    expect(errorsSummary([err('u', 4)])).toMatchObject({ active: 0, backlog: 1, top: [] });
  });

  it('is all zeros for no errors', () => {
    expect(errorsSummary([])).toEqual({ active: 0, backlog: 0, events: 0, top: [] });
  });
});

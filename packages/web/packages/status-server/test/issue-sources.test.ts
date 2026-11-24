import { describe, it, expect } from 'vitest';
import {
  dropVanishedVercelProjects,
  deployIsBad,
  deployIsResolving,
  deployIsStuck,
  httpIsBad,
  ISSUE_SOURCES,
  nextPlatformStreak,
  platformHealthSource,
  SOURCE_LABEL,
  STUCK_DEPLOY_MS,
  type ConfiguredDeployTargets,
} from '../src/monitor/issue-sources';

const targets = (vercel: string[], railway: string[] = [], cloudflare: string[] = []): ConfiguredDeployTargets => ({
  vercel: new Set(vercel),
  railway: new Set(railway),
  cloudflare: new Set(cloudflare),
});

describe('issue-sources vocabulary', () => {
  it('status-server-monitor-issue-sources-001 labels follow the canonical source order', () => {
    expect(ISSUE_SOURCES.map((s) => SOURCE_LABEL[s])).toEqual([
      'DNS',
      'HTTP',
      'GlitchTip',
      'Vercel',
      'Vercel runtime logs',
      'Cloudflare',
      'Railway',
      'Crunchy Bridge',
    ]);
  });

  it('status-server-monitor-issue-sources-002 both Cloudflare spellings map to cloudflare-pages', () => {
    expect(platformHealthSource('cloudflare')).toBe('cloudflare-pages');
    expect(platformHealthSource('cloudflare-pages')).toBe('cloudflare-pages');
  });

  it('status-server-monitor-issue-sources-003 the platform is trimmed and lower-cased', () => {
    expect(platformHealthSource('  VERCEL  ')).toBe('vercel');
  });

  it('status-server-monitor-issue-sources-004 unmapped platforms resolve to null', () => {
    expect(platformHealthSource(null)).toBeNull();
    expect(platformHealthSource('glitchtip')).toBeNull();
    expect(platformHealthSource('something-unknown')).toBeNull();
  });
});

describe('issue-sources predicates', () => {
  it('status-server-monitor-issue-sources-005 down and degraded HTTP states are bad', () => {
    expect(httpIsBad('down')).toBe(true);
    expect(httpIsBad('degraded')).toBe(true);
    expect(httpIsBad('healthy')).toBe(false);
  });

  it('status-server-monitor-issue-sources-006 only failed deploys are bad', () => {
    expect(deployIsBad('failed')).toBe(true);
    expect(deployIsBad('canceled')).toBe(false);
    expect(deployIsBad('unknown')).toBe(false);
  });

  it('status-server-monitor-issue-sources-007 a build is stuck at or past STUCK_DEPLOY_MS', () => {
    expect(STUCK_DEPLOY_MS).toBe(30 * 60 * 1000);
    expect(deployIsStuck('building', STUCK_DEPLOY_MS - 60_000)).toBe(false);
    expect(deployIsStuck('building', STUCK_DEPLOY_MS + 1)).toBe(true);
  });

  it('status-server-monitor-issue-sources-008 a queued deploy is never stuck', () => {
    expect(deployIsStuck('queued', STUCK_DEPLOY_MS * 10)).toBe(false);
  });

  it('status-server-monitor-issue-sources-009 only success resolves a deploy issue', () => {
    expect(deployIsResolving('success')).toBe(true);
    expect(deployIsResolving('building')).toBe(false);
  });
});

describe('nextPlatformStreak', () => {
  it('status-server-monitor-issue-sources-010 a first failure increments the streak without going bad', () => {
    expect(nextPlatformStreak(0, true)).toEqual({ streak: 1, bad: false });
  });

  it('status-server-monitor-issue-sources-011 the second consecutive failure goes bad', () => {
    expect(nextPlatformStreak(1, true)).toEqual({ streak: 2, bad: true });
  });

  it('status-server-monitor-issue-sources-012 a reachable poll resets the streak', () => {
    expect(nextPlatformStreak(5, false)).toEqual({ streak: 0, bad: false });
  });
});

describe('dropVanishedVercelProjects', () => {
  it('status-server-monitor-issue-sources-013 drops projects missing upstream and reports them', () => {
    const out = dropVanishedVercelProjects(targets(['ghost-project', 'live-project']), new Set(['live-project']));
    expect(out).toEqual({ configured: targets(['live-project']), vanished: ['ghost-project'] });
  });

  it('status-server-monitor-issue-sources-014 an empty live set narrows nothing', () => {
    const configured = targets(['hub-web']);
    const out = dropVanishedVercelProjects(configured, new Set());
    expect(out.configured).toBe(configured);
    expect(out.vanished).toEqual([]);
  });

  it('status-server-monitor-issue-sources-015 a live set naming every owned project vanished narrows nothing', () => {
    const configured = targets(['hub-web']);
    const out = dropVanishedVercelProjects(configured, new Set(['something-else-entirely']));
    expect(out.configured).toBe(configured);
    expect(out.vanished).toEqual([]);
  });

  it('status-server-monitor-issue-sources-016 only the Vercel set is inspected', () => {
    const configured = targets([], ['shared-name']);
    const out = dropVanishedVercelProjects(configured, new Set(['hub-web']));
    expect(out.configured).toBe(configured);
    expect(out.vanished).toEqual([]);
  });
});

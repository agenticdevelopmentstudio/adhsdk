import { describe, it, expect } from 'vitest';
import {
  vercelPhases,
  railwayPhases,
  combinedStatus,
  crunchyPhases,
  isInFlight,
  inFlightSql,
  collapseInFlightBuildSql,
  type BuildPhase,
  type DeployPhase,
  type DeployStatus,
  type Phases,
} from '../src/monitor/deploy-status';

describe('vercelPhases', () => {
  it('maps READY + PROMOTED on production to built+deployed', () => {
    const result = vercelPhases('READY', 'PROMOTED', 'production');
    expect(result.buildPhase).toBe('built');
    expect(result.deployPhase).toBe('deployed');
  });

  it('maps ERROR to failed build with no deploy', () => {
    const result = vercelPhases('ERROR', null, null);
    expect(result.buildPhase).toBe('failed');
    expect(result.deployPhase).toBe('none');
  });

  it('maps READY on non-production (preview) to built+none', () => {
    const result = vercelPhases('READY', null, null);
    expect(result.buildPhase).toBe('built');
    expect(result.deployPhase).toBe('none');
  });

  it('maps CANCELED to canceled+none', () => {
    const result = vercelPhases('CANCELED', null, null);
    expect(result.buildPhase).toBe('canceled');
    expect(result.deployPhase).toBe('none');
  });

  it('maps BUILDING to building+none', () => {
    const result = vercelPhases('BUILDING', null, null);
    expect(result.buildPhase).toBe('building');
    expect(result.deployPhase).toBe('none');
  });

  it('maps QUEUED to queued+none', () => {
    const result = vercelPhases('QUEUED', null, null);
    expect(result.buildPhase).toBe('queued');
    expect(result.deployPhase).toBe('none');
  });

  it('maps READY + ROLLING on production to built+deploying', () => {
    const result = vercelPhases('READY', 'ROLLING', 'production');
    expect(result.buildPhase).toBe('built');
    expect(result.deployPhase).toBe('deploying');
  });
});

describe('railwayPhases', () => {
  it('maps SUCCESS to built+deployed', () => {
    const result = railwayPhases('SUCCESS');
    expect(result.buildPhase).toBe('built');
    expect(result.deployPhase).toBe('deployed');
  });

  it('maps FAILED to failed+none', () => {
    const result = railwayPhases('FAILED');
    expect(result.buildPhase).toBe('failed');
    expect(result.deployPhase).toBe('none');
  });

  it('maps BUILDING to building+none', () => {
    const result = railwayPhases('BUILDING');
    expect(result.buildPhase).toBe('building');
    expect(result.deployPhase).toBe('none');
  });

  it('maps DEPLOYING to built+deploying', () => {
    const result = railwayPhases('DEPLOYING');
    expect(result.buildPhase).toBe('built');
    expect(result.deployPhase).toBe('deploying');
  });

  it('maps REMOVED to canceled+none', () => {
    const result = railwayPhases('REMOVED');
    expect(result.buildPhase).toBe('canceled');
    expect(result.deployPhase).toBe('none');
  });

  it('maps CRASHED to built+deployed (runtime crash is not a deploy failure)', () => {
    const result = railwayPhases('CRASHED');
    expect(result.buildPhase).toBe('built');
    expect(result.deployPhase).toBe('deployed');
  });
});

describe('combinedStatus', () => {
  it('returns "success" when deploy phase is deployed', () => {
    expect(combinedStatus({ buildPhase: 'built', deployPhase: 'deployed' })).toBe('success');
  });

  it('returns "failed" when build phase is failed', () => {
    expect(combinedStatus({ buildPhase: 'failed', deployPhase: 'none' })).toBe('failed');
  });

  it('returns "building" when build phase is building', () => {
    expect(combinedStatus({ buildPhase: 'building', deployPhase: 'none' })).toBe('building');
  });

  it('returns "queued" when build phase is queued', () => {
    expect(combinedStatus({ buildPhase: 'queued', deployPhase: 'none' })).toBe('queued');
  });

  it('returns "canceled" when build phase is canceled', () => {
    expect(combinedStatus({ buildPhase: 'canceled', deployPhase: 'none' })).toBe('canceled');
  });

  it('returns "success" for a built non-prod (staged) deploy with no separate deploy step', () => {
    expect(combinedStatus({ buildPhase: 'built', deployPhase: 'none' })).toBe('success');
  });

  it('returns "building" for in-flight deploy phase', () => {
    expect(combinedStatus({ buildPhase: 'built', deployPhase: 'deploying' })).toBe('building');
  });

  it('returns "unknown" when EITHER lifecycle expired unconfirmable — never re-reads as building', () => {
    expect(combinedStatus({ buildPhase: 'unknown', deployPhase: 'none' })).toBe('unknown');
    expect(combinedStatus({ buildPhase: 'built', deployPhase: 'unknown' })).toBe('unknown');
  });

  it('a failure verdict still wins over an expired other lifecycle', () => {
    expect(combinedStatus({ buildPhase: 'unknown', deployPhase: 'failed' })).toBe('failed');
  });
});

// Conformance vectors for cookbook/status/service/monitor/deploy-status — one test per vector id.
describe('deploy-status conformance vectors', () => {
  const P = (buildPhase: BuildPhase | null, deployPhase: DeployPhase): Phases => ({ buildPhase, deployPhase });
  const BUILDS: (BuildPhase | null)[] = [null, 'queued', 'building', 'built', 'failed', 'canceled', 'unknown'];
  const DEPLOYS: DeployPhase[] = ['none', 'deploying', 'deployed', 'failed', 'unknown'];
  const crossProduct = BUILDS.flatMap((b) => DEPLOYS.map((d) => P(b, d)));

  it('status-server-monitor-deploy-status-001 vercel READY+PROMOTED+production', () => {
    expect(vercelPhases('READY', 'PROMOTED', 'production')).toEqual(P('built', 'deployed'));
  });
  it('status-server-monitor-deploy-status-002 vercel ERROR', () => {
    expect(vercelPhases('ERROR', undefined, undefined)).toEqual(P('failed', 'none'));
  });
  it('status-server-monitor-deploy-status-003 vercel READY non-production', () => {
    expect(vercelPhases('READY', undefined, undefined)).toEqual(P('built', 'none'));
  });
  it('status-server-monitor-deploy-status-004 vercel CANCELED', () => {
    expect(vercelPhases('CANCELED', undefined, undefined)).toEqual(P('canceled', 'none'));
  });
  it('status-server-monitor-deploy-status-005 vercel BUILDING', () => {
    expect(vercelPhases('BUILDING', undefined, undefined)).toEqual(P('building', 'none'));
  });
  it('status-server-monitor-deploy-status-006 vercel QUEUED', () => {
    expect(vercelPhases('QUEUED', undefined, undefined)).toEqual(P('queued', 'none'));
  });
  it('status-server-monitor-deploy-status-007 vercel READY+ROLLING+production', () => {
    expect(vercelPhases('READY', 'ROLLING', 'production')).toEqual(P('built', 'deploying'));
  });
  it('status-server-monitor-deploy-status-008 railway SUCCESS', () => {
    expect(railwayPhases('SUCCESS')).toEqual(P('built', 'deployed'));
  });
  it('status-server-monitor-deploy-status-009 railway FAILED', () => {
    expect(railwayPhases('FAILED')).toEqual(P('failed', 'none'));
  });
  it('status-server-monitor-deploy-status-010 railway BUILDING', () => {
    expect(railwayPhases('BUILDING')).toEqual(P('building', 'none'));
  });
  it('status-server-monitor-deploy-status-011 railway DEPLOYING', () => {
    expect(railwayPhases('DEPLOYING')).toEqual(P('built', 'deploying'));
  });
  it('status-server-monitor-deploy-status-012 railway REMOVED', () => {
    expect(railwayPhases('REMOVED')).toEqual(P('canceled', 'none'));
  });
  it('status-server-monitor-deploy-status-013 railway CRASHED is not a deploy failure', () => {
    expect(railwayPhases('CRASHED')).toEqual(P('built', 'deployed'));
  });
  it('status-server-monitor-deploy-status-014 combined built+deployed is success', () => {
    expect(combinedStatus(P('built', 'deployed'))).toBe('success');
  });
  it('status-server-monitor-deploy-status-015 combined failed build is failed', () => {
    expect(combinedStatus(P('failed', 'none'))).toBe('failed');
  });
  it('status-server-monitor-deploy-status-016 combined building is building', () => {
    expect(combinedStatus(P('building', 'none'))).toBe('building');
  });
  it('status-server-monitor-deploy-status-017 combined queued is queued', () => {
    expect(combinedStatus(P('queued', 'none'))).toBe('queued');
  });
  it('status-server-monitor-deploy-status-018 combined canceled is canceled', () => {
    expect(combinedStatus(P('canceled', 'none'))).toBe('canceled');
  });
  it('status-server-monitor-deploy-status-019 combined built+none (staged) is success', () => {
    expect(combinedStatus(P('built', 'none'))).toBe('success');
  });
  it('status-server-monitor-deploy-status-020 combined built+deploying is building', () => {
    expect(combinedStatus(P('built', 'deploying'))).toBe('building');
  });
  it('status-server-monitor-deploy-status-021 combined unknown outranks the in-flight fallthroughs', () => {
    expect(combinedStatus(P('unknown', 'none'))).toBe('unknown');
    expect(combinedStatus(P('built', 'unknown'))).toBe('unknown');
  });
  it('status-server-monitor-deploy-status-022 combined failed outranks unknown', () => {
    expect(combinedStatus(P('unknown', 'failed'))).toBe('failed');
  });
  it('status-server-monitor-deploy-status-023 crunchy ready is deployed with no build lifecycle', () => {
    expect(crunchyPhases('ready', false)).toEqual(P(null, 'deployed'));
  });
  it('status-server-monitor-deploy-status-024 crunchy ready but suspended is failed', () => {
    expect(crunchyPhases('ready', true)).toEqual(P(null, 'failed'));
  });
  it('status-server-monitor-deploy-status-025 crunchy failed / creation_failed / suspended states are failed', () => {
    for (const s of ['failed', 'creation_failed', 'suspended']) {
      expect(crunchyPhases(s, false)).toEqual(P(null, 'failed'));
    }
  });
  it('status-server-monitor-deploy-status-026 crunchy routine states are deployed', () => {
    expect(crunchyPhases('restarting', false)).toEqual(P(null, 'deployed'));
    expect(crunchyPhases('destroying', false)).toEqual(P(null, 'deployed'));
  });
  it('status-server-monitor-deploy-status-027 crunchy empty or unrecognized state is deployed', () => {
    expect(crunchyPhases('', false)).toEqual(P(null, 'deployed'));
    expect(crunchyPhases('weird_unknown', false)).toEqual(P(null, 'deployed'));
  });
  it('status-server-monitor-deploy-status-028 isInFlight: building, settled, and null build', () => {
    expect(isInFlight('building', 'none')).toBe(true);
    expect(isInFlight('built', 'deployed')).toBe(false);
    expect(isInFlight(null, 'deployed')).toBe(false);
  });
  it('status-server-monitor-deploy-status-029 inFlightSql default prefix', () => {
    expect(inFlightSql()).toBe("(build_phase IN ('building', 'queued') OR deploy_phase = 'deploying')");
  });
  it('status-server-monitor-deploy-status-030 collapseInFlightBuildSql to canceled', () => {
    expect(collapseInFlightBuildSql('canceled')).toBe(
      "CASE WHEN build_phase IN ('building', 'queued') THEN 'canceled' ELSE build_phase END",
    );
  });
  it('status-server-monitor-deploy-status-031 isInFlight matches its definition over the full cross-product', () => {
    for (const { buildPhase, deployPhase } of crossProduct) {
      const expected = buildPhase === 'building' || buildPhase === 'queued' || deployPhase === 'deploying';
      expect(isInFlight(buildPhase, deployPhase), `${buildPhase}/${deployPhase}`).toBe(expected);
    }
  });
  it('status-server-monitor-deploy-status-032 combinedStatus matches the ordered rule list over the full cross-product', () => {
    // Independent restatement of the documented first-match-wins order, as data.
    const rules: [(p: Phases) => boolean, DeployStatus][] = [
      [(p) => p.buildPhase === 'failed' || p.deployPhase === 'failed', 'failed'],
      [(p) => p.buildPhase === 'canceled', 'canceled'],
      [(p) => p.buildPhase === 'unknown' || p.deployPhase === 'unknown', 'unknown'],
      [(p) => p.deployPhase === 'deployed', 'success'],
      [(p) => p.deployPhase === 'deploying', 'building'],
      [(p) => p.buildPhase === 'built', 'success'],
      [(p) => p.buildPhase === 'queued', 'queued'],
    ];
    for (const p of crossProduct) {
      const expected = rules.find(([match]) => match(p))?.[1] ?? 'building';
      expect(combinedStatus(p), `${p.buildPhase}/${p.deployPhase}`).toBe(expected);
    }
  });
});

describe('crunchyPhases', () => {
  it('ready + not suspended → deployed', () => {
    expect(crunchyPhases('ready', false)).toEqual({ buildPhase: null, deployPhase: 'deployed' });
  });
  it('suspended flag → failed even when state is ready', () => {
    expect(crunchyPhases('ready', true)).toEqual({ buildPhase: null, deployPhase: 'failed' });
  });
  it('documented problem states → failed', () => {
    for (const s of ['failed', 'creation_failed', 'suspended']) {
      expect(crunchyPhases(s, false)).toEqual({ buildPhase: null, deployPhase: 'failed' });
    }
  });
  it('routine/transient states → deployed (quieter: maintenance is not a problem)', () => {
    for (const s of ['creating', 'restarting', 'resuming', 'starting', 'restoring',
                     'finalizing', 'replaying', 'destroying', 'suspending']) {
      expect(crunchyPhases(s, false)).toEqual({ buildPhase: null, deployPhase: 'deployed' });
    }
  });
  it('unknown / empty state → deployed (unrecognised is not assumed bad)', () => {
    for (const s of ['', 'weird_unknown']) {
      expect(crunchyPhases(s, false)).toEqual({ buildPhase: null, deployPhase: 'deployed' });
    }
  });
});

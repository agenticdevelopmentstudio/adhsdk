import { describe, it, expect } from 'vitest';
import { envFromProject as canonEnvFromProject } from '@adh-sdk/deploy-platform/canon';
import {
  deployEnv,
  deployLinks,
  envFromBranch,
  envFromProject,
  isRealEnvDeploy,
  isRealEnvDeployRow,
} from '../src/monitor/deploy-view';
import type { DeploymentDTO } from '../src/monitor/types';

// Conformance vectors for cookbook/status/service/monitor/deploy-view.
describe('deploy-view conformance vectors', () => {
  it('status-server-monitor-deploy-view-001: branch table maps the three deploying branches, main is null', () => {
    expect(envFromBranch('prepared')).toBe('testing');
    expect(envFromBranch('staging')).toBe('staging');
    expect(envFromBranch('production')).toBe('production');
    expect(envFromBranch('main')).toBeNull();
  });

  it('status-server-monitor-deploy-view-002: nullish and empty branch answer null', () => {
    expect(envFromBranch(null)).toBeNull();
    expect(envFromBranch(undefined)).toBeNull();
    expect(envFromBranch('')).toBeNull();
  });

  it('status-server-monitor-deploy-view-003: Object.prototype names never leak out of the lookup', () => {
    for (const name of ['constructor', 'toString', 'valueOf', 'hasOwnProperty', '__proto__']) {
      expect(envFromBranch(name)).toBeNull();
      expect(deployEnv('vercel', 'hub-help-testing', 'production', name)).toBe('testing');
    }
  });

  it('status-server-monitor-deploy-view-004: the branch overrides the project name', () => {
    expect(deployEnv('vercel', 'hub', 'production', 'prepared')).toBe('testing');
    expect(deployEnv('vercel', 'hub-help-testing', 'production', 'production')).toBe('production');
  });

  it('status-server-monitor-deploy-view-005: Vercel with no branch reads the project name and ignores storedEnv', () => {
    expect(deployEnv('vercel', 'hub-help-testing', 'production', null)).toBe('testing');
    expect(deployEnv('vercel', 'staging.adh', 'production', null)).toBe('staging');
    expect(deployEnv('vercel', 'hub', 'production', null)).toBe('production');
  });

  it('status-server-monitor-deploy-view-006: non-Vercel with no branch trusts a non-empty storedEnv, else the name', () => {
    expect(deployEnv('railway', 'adh-backend', 'testing', null)).toBe('testing');
    expect(deployEnv('cloudflare-pages', 'temporal-web', '', null)).toBe('production');
  });

  it('status-server-monitor-deploy-view-007: the branch outranks a non-Vercel stored environment', () => {
    expect(deployEnv('railway', 'adh-backend', 'production', 'prepared')).toBe('testing');
  });

  it('status-server-monitor-deploy-view-008: only Vercel with a null or empty environment is not a real deploy', () => {
    expect(isRealEnvDeployRow('vercel', null)).toBe(false);
    expect(isRealEnvDeployRow('vercel', '')).toBe(false);
    expect(isRealEnvDeployRow('vercel', 'production')).toBe(true);
    expect(isRealEnvDeployRow('railway', null)).toBe(true);
    const dto = { platform: 'vercel', environment: null } as unknown as DeploymentDTO;
    expect(isRealEnvDeploy(dto)).toBe(false);
  });

  it('status-server-monitor-deploy-view-009: sourceUrl collapses a Vercel inspector URL and passes others through', () => {
    expect(deployLinks('https://vercel.com/acme/my-project/dpl_abc123', null).sourceUrl).toBe(
      'https://vercel.com/acme/my-project',
    );
    expect(deployLinks('https://dashboard.railway.app/project/xyz', null).sourceUrl).toBe(
      'https://dashboard.railway.app/project/xyz',
    );
    expect(deployLinks(null, null).sourceUrl).toBeNull();
  });

  it('status-server-monitor-deploy-view-010: liveUrl comes from liveHost only, never from the deploy URL', () => {
    expect(deployLinks(null, 'app.example.com').liveUrl).toBe('https://app.example.com');
    const withSource = deployLinks('https://vercel.com/acme/my-project/dpl_abc123', null);
    expect(withSource.sourceUrl).not.toBeNull();
    expect(withSource.liveUrl).toBeNull();
  });

  it('status-server-monitor-deploy-view-011: envFromProject is the canon function, re-exported', () => {
    expect(envFromProject).toBe(canonEnvFromProject);
    expect(envFromProject('docs-staging')).toBe('staging');
    expect(envFromProject('docs-testing')).toBe('testing');
    expect(envFromProject('hub')).toBe('production');
  });
});

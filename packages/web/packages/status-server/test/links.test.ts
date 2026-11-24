import { describe, it, expect } from 'vitest';
import { PLACEHOLDER_URL } from '@adh-sdk/deploy-platform/engine';
import { liveUrl, platformDashboardUrl, siteLinks } from '../src/lib/links';

describe('siteLinks', () => {
  const site = { platform: 'railway', projectName: 'worker' };

  it('has no live link for a deploy-only monitor — the placeholder opens nothing', () => {
    expect(siteLinks(site, [{ url: PLACEHOLDER_URL, environment: 'production' }]).live).toBeNull();
  });

  it('skips the placeholder for an endpoint that has a URL', () => {
    const links = siteLinks(site, [
      { url: PLACEHOLDER_URL, environment: 'production' },
      { url: 'staging.example.test', environment: 'staging' },
    ]);
    expect(links.live).toBe('https://staging.example.test');
  });
});

// Conformance vectors for the links recipe (cookbook/status/service/links).
describe('links conformance vectors', () => {
  it('links-001 liveUrl prepends https:// to a bare host', () => {
    expect(liveUrl('example.com')).toBe('https://example.com');
  });

  it('links-002 liveUrl keeps a URL that already has a scheme', () => {
    expect(liveUrl('https://example.com/path')).toBe('https://example.com/path');
  });

  it('links-003 liveUrl is idempotent', () => {
    expect(liveUrl(liveUrl('example.com'))).toBe('https://example.com');
  });

  it('links-004 vercel dashboard URL from the team id', () => {
    expect(platformDashboardUrl('vercel', 'my-app', { vercelTeamId: 'acme' })).toBe('https://vercel.com/acme/my-app');
  });

  it('links-005 vercel without a team id is null', () => {
    expect(platformDashboardUrl('vercel', 'my-app', { vercelTeamId: null })).toBeNull();
  });

  it('links-006 railway dashboard URL from the project id', () => {
    expect(platformDashboardUrl('railway', 'my-app', { railwayProjectId: 'xyz123' })).toBe(
      'https://railway.app/project/xyz123',
    );
  });

  it('links-007 railway without a project id is null', () => {
    expect(platformDashboardUrl('railway', 'my-app', {})).toBeNull();
  });

  it('links-008 cloudflare dashboard URL from the account id', () => {
    expect(platformDashboardUrl('cloudflare', 'worker-name', { cloudflareAccountId: 'abc123' })).toBe(
      'https://dash.cloudflare.com/abc123/workers/services/view/worker-name',
    );
  });

  it('links-009 cloudflare-pages canonicalizes to cloudflare', () => {
    expect(platformDashboardUrl('cloudflare-pages', 'worker-name', { cloudflareAccountId: 'abc123' })).toBe(
      'https://dash.cloudflare.com/abc123/workers/services/view/worker-name',
    );
  });

  it('links-010 an unknown platform is null', () => {
    expect(platformDashboardUrl('heroku', 'my-app', {})).toBeNull();
  });

  it('links-011 a missing project name is null', () => {
    expect(platformDashboardUrl('vercel', null, { vercelTeamId: 'acme' })).toBeNull();
  });

  it('links-012 the project name is URL-encoded', () => {
    expect(platformDashboardUrl('vercel', 'my app', { vercelTeamId: 'acme' })).toBe('https://vercel.com/acme/my%20app');
  });

  it('links-013 siteLinks prefers the production endpoint', () => {
    expect(
      siteLinks(
        { platform: 'vercel', projectName: 'app' },
        [
          { url: 'dev.example.com', environment: 'dev' },
          { url: 'prod.example.com', environment: 'production' },
        ],
        { vercelTeamId: 'acme' },
      ),
    ).toEqual({ live: 'https://prod.example.com', platform: 'https://vercel.com/acme/app' });
  });

  it('links-014 siteLinks falls back to the first endpoint', () => {
    expect(
      siteLinks({ platform: 'vercel', projectName: 'app' }, [{ url: 'staging.example.com' }], { vercelTeamId: 'acme' }),
    ).toEqual({ live: 'https://staging.example.com', platform: 'https://vercel.com/acme/app' });
  });

  it('links-015 siteLinks with no endpoints has a null live link', () => {
    expect(siteLinks({ platform: 'vercel', projectName: 'app' }, [], { vercelTeamId: 'acme' })).toEqual({
      live: null,
      platform: 'https://vercel.com/acme/app',
    });
  });
});

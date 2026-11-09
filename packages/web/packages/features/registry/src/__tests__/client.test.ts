import { describe, expect, it, vi } from 'vitest';
import { createRegistryClient } from '../client';

const ok = (body: unknown) =>
  new Response(JSON.stringify(body), { status: 200, headers: { 'content-type': 'application/json' } });

/** A /v1 collection page. */
const list = (data: unknown[], hasMore = false) =>
  ok({ object: 'list', data, has_more: hasMore, url: '/v1/x' });

describe('createRegistryClient', () => {
  it('sends a JSON body and the right method for a create', async () => {
    const fetcher = vi.fn().mockResolvedValue(ok({ id: 'r1' }));
    const client = createRegistryClient(fetcher);
    await client.createRegistry({ slug: 'coaches', name: 'Coaches' });
    const [path, init] = fetcher.mock.calls[0]!;
    // `/v1/registries` is the backend route; `/api` is the site's own rewrite prefix.
    expect(path).toBe('/api/v1/registries');
    expect(init.method).toBe('POST');
    expect(JSON.parse(init.body)).toEqual({ slug: 'coaches', name: 'Coaches' });
  });

  it('sends snake_case bodies and updates with POST on the item path', async () => {
    const fetcher = vi.fn().mockResolvedValue(ok({ id: 'r1' }));
    await createRegistryClient(fetcher).updateRegistry('r1', {
      categoryRoot: 'software',
      submissionPolicy: 'reviewed',
      servicesEnabled: true,
      boundSiteId: null,
    });
    const [path, init] = fetcher.mock.calls[0]!;
    expect(path).toBe('/api/v1/registries/r1');
    expect(init.method).toBe('POST');
    expect(JSON.parse(init.body)).toEqual({
      category_root: 'software',
      submission_policy: 'reviewed',
      services_enabled: true,
      bound_site_id: null,
    });
  });

  it('maps a wire registry onto the stable domain row and defaults a missing tags to []', async () => {
    const fetcher = vi.fn().mockResolvedValue(
      list([
        {
          id: 'r1', object: 'registry', slug: 'coaches', name: 'Coaches', purpose: 'p',
          description: 'd', category_root: 'software', entry_term: 'coach',
          visibility: 'public', submission_policy: 'open', services_enabled: true,
          bound_site_id: 'learn',
        },
      ]),
    );
    const { items } = await createRegistryClient(fetcher).listRegistries();
    expect(items).toEqual([
      {
        id: 'r1', slug: 'coaches', name: 'Coaches', purpose: 'p', description: 'd',
        categoryRoot: 'software', entryTerm: 'coach', visibility: 'public',
        submissionPolicy: 'open', tags: [], servicesEnabled: true, boundSiteId: 'learn',
      },
    ]);
  });

  it('walks every page of a collection with starting_after', async () => {
    const fetcher = vi
      .fn()
      .mockResolvedValueOnce(list([{ id: 's1', key: 'a', sort_order: 1 }], true))
      .mockResolvedValueOnce(list([{ id: 's2', key: 'b', sort_order: 2 }]));
    const { items } = await createRegistryClient(fetcher).listSections('r1');
    expect(items.map((i) => [i.id, i.sortOrder])).toEqual([['s1', 1], ['s2', 2]]);
    expect(fetcher.mock.calls[0]![0]).toBe('/api/v1/registries/r1/sections?limit=100');
    expect(fetcher.mock.calls[1]![0]).toBe(
      '/api/v1/registries/r1/sections?limit=100&starting_after=s1',
    );
  });

  it('puts field defs on field_defs and sends snake_case', async () => {
    const fetcher = vi.fn().mockResolvedValue(ok({ id: 'f1', section_id: 's1', sort_order: 3 }));
    const def = await createRegistryClient(fetcher).updateFieldDef('r1', 'f1', {
      sortOrder: 3,
      showIf: { field: 'a', op: 'eq', value: 1 },
      config: { maxLength: 5 },
    });
    const [path, init] = fetcher.mock.calls[0]!;
    expect(path).toBe('/api/v1/registries/r1/field_defs/f1');
    expect(init.method).toBe('POST');
    // `config` is an untyped map: its inner keys keep their spelling.
    expect(JSON.parse(init.body)).toEqual({
      sort_order: 3,
      show_if: { field: 'a', op: 'eq', value: 1 },
      config: { maxLength: 5 },
    });
    expect(def.sectionId).toBe('s1');
    expect(def.sortOrder).toBe(3);
  });

  describe('entries', () => {
    const wireEntry = {
      id: 'e1', object: 'registry_entry', registry_id: 'r1', slug: 'mike',
      display_name: 'Mike', summary: 's', photo_attachment_id: null, provider_type: 'person',
      category: 'c', keywords: ['k'], location_text: 'l', country_code: 'US',
      region_code: 'CA', geo: { lat: 1, lon: 2 }, area_served: { cities: ['x'] },
      delivery_mode: 'virtual', links: [], contact_mode: 'dm', languages: ['en'],
      status: 'draft', visibility: 'public', values: { favourite_colour: 'red' },
      value_visibility: { favourite_colour: 'private' }, created: 1_700_000_000,
    };

    it('maps a wire entry, with created as an ISO createdAt and the maps untouched', async () => {
      const fetcher = vi.fn().mockResolvedValue(ok(wireEntry));
      const row = await createRegistryClient(fetcher).myEntry('r1');
      expect(row.registryId).toBe('r1');
      expect(row.displayName).toBe('Mike');
      expect(row.createdAt).toBe('2023-11-14T22:13:20.000Z');
      expect(row.values).toEqual({ favourite_colour: 'red' });
      expect(row.valueVisibility).toEqual({ favourite_colour: 'private' });
      expect(row.areaServed).toEqual({ cities: ['x'] });
    });

    it('myEntry creates-or-gets with owner=me and the registry in the body', async () => {
      const fetcher = vi.fn().mockResolvedValue(ok(wireEntry));
      await createRegistryClient(fetcher).myEntry('r1');
      const [path, init] = fetcher.mock.calls[0]!;
      expect(path).toBe('/api/v1/registry_entries');
      expect(init.method).toBe('POST');
      expect(JSON.parse(init.body)).toEqual({ registry: 'r1', owner: 'me' });
    });

    it('createEntry sends the registry and a snake_case spine', async () => {
      const fetcher = vi.fn().mockResolvedValue(ok(wireEntry));
      await createRegistryClient(fetcher).createEntry('r1', {
        displayName: 'Mike',
        providerType: 'person',
        valueVisibility: { a: null },
        values: { favourite_colour: 'red' },
      });
      expect(JSON.parse(fetcher.mock.calls[0]![1].body)).toEqual({
        registry: 'r1',
        display_name: 'Mike',
        provider_type: 'person',
        value_visibility: { a: null },
        values: { favourite_colour: 'red' },
      });
    });

    it('updateEntry is a POST on the entry with the registry as a query input', async () => {
      const fetcher = vi.fn().mockResolvedValue(ok(wireEntry));
      await createRegistryClient(fetcher).updateEntry('r1', 'e1', { status: 'published' });
      const [path, init] = fetcher.mock.calls[0]!;
      expect(path).toBe('/api/v1/registry_entries/e1?registry=r1');
      expect(init.method).toBe('POST');
      expect(JSON.parse(init.body)).toEqual({ status: 'published' });
    });

    it('deleteEntry is a DELETE with the registry as a query input', async () => {
      const fetcher = vi.fn().mockResolvedValue(ok({ id: 'e1', object: 'registry_entry', deleted: true }));
      await createRegistryClient(fetcher).deleteEntry('r1', 'e1');
      const [path, init] = fetcher.mock.calls[0]!;
      expect(path).toBe('/api/v1/registry_entries/e1?registry=r1');
      expect(init.method).toBe('DELETE');
    });

    it('services hang off the entry with the registry as a query input', async () => {
      const fetcher = vi.fn().mockResolvedValue(
        ok({
          id: 'sv1', title: 't', description: 'd', pricing_model: 'hourly', price_min: 1,
          price_max: 2, currency: 'USD', unit: 'hr', delivery_mode: 'virtual', sort_order: 0,
        }),
      );
      const row = await createRegistryClient(fetcher).updateService('r1', 'e1', 'sv1', {
        pricingModel: 'hourly',
        priceMin: 1,
      });
      const [path, init] = fetcher.mock.calls[0]!;
      expect(path).toBe('/api/v1/registry_entries/e1/services/sv1?registry=r1');
      expect(init.method).toBe('POST');
      expect(JSON.parse(init.body)).toEqual({ pricing_model: 'hourly', price_min: 1 });
      expect(row.pricingModel).toBe('hourly');
      expect(row.priceMax).toBe(2);
    });
  });

  it('sends no body on a GET', async () => {
    const fetcher = vi.fn().mockResolvedValue(list([]));
    await createRegistryClient(fetcher).listRegistries();
    expect(fetcher.mock.calls[0]![1].body).toBeUndefined();
  });

  it('unwraps the backend error envelope rather than surfacing raw JSON', async () => {
    // The value validators return per-field reasons the registrant has to see, and the
    // backend wraps them in `{ error: { message } }` (app.ts:403). Surfacing the body as
    // text would show the registrant that JSON verbatim.
    const fetcher = vi.fn().mockResolvedValue(
      new Response(JSON.stringify({ error: { message: 'invalid values — bio: Required' } }), {
        status: 400,
        headers: { 'content-type': 'application/json' },
      }),
    );
    await expect(createRegistryClient(fetcher).createEntry('r1', {})).rejects.toThrow('bio: Required');
  });

  it('falls back to the raw text when the body is not the envelope', async () => {
    // A proxy 502 never reaches app.onError, so it is plain text — still better than
    // "502 Bad Gateway" with nothing else.
    const fetcher = vi.fn().mockResolvedValue(new Response('upstream unavailable', { status: 502 }));
    await expect(createRegistryClient(fetcher).listRegistries()).rejects.toThrow(
      'upstream unavailable',
    );
  });

  it('sends no content-type header on a body-less GET', async () => {
    // A header describing a body that doesn't exist would force a CORS preflight on any
    // fetcher pointed at another origin — free to avoid.
    const fetcher = vi.fn().mockResolvedValue(list([]));
    await createRegistryClient(fetcher).listRegistries();
    const [, init] = fetcher.mock.calls[0]!;
    expect(init.headers).toBeUndefined();
  });

  // R6-I1: the three deletes used to call `fetcher` directly and return its raw
  // `Promise<Response>` — a non-ok response resolved SUCCESSFULLY under a bare-`fetch`
  // fetcher, so a 403/404/409/500 was invisible: the builder dropped the row, and the
  // next reload brought it back. Each now routes through the same `ok()` check `json()`
  // uses, so the rejection this test asserts is reachable from every one of the three.
  describe('delete methods reject on a non-ok response', () => {
    const conflict = () =>
      new Response(JSON.stringify({ error: { message: 'still has values' } }), {
        status: 409,
        headers: { 'content-type': 'application/json' },
      });

    it('deleteSection', async () => {
      const fetcher = vi.fn().mockResolvedValue(conflict());
      await expect(createRegistryClient(fetcher).deleteSection('r1', 's1')).rejects.toThrow(
        'still has values',
      );
    });

    it('deleteFieldDef', async () => {
      const fetcher = vi.fn().mockResolvedValue(conflict());
      await expect(createRegistryClient(fetcher).deleteFieldDef('r1', 'f1')).rejects.toThrow(
        'still has values',
      );
    });

    it('deleteService', async () => {
      const fetcher = vi.fn().mockResolvedValue(conflict());
      await expect(createRegistryClient(fetcher).deleteService('r1', 'e1', 'sv1')).rejects.toThrow(
        'still has values',
      );
    });
  });

  it('resolves a successful delete with no value', async () => {
    const fetcher = vi.fn().mockResolvedValue(new Response(null, { status: 204 }));
    await expect(createRegistryClient(fetcher).deleteFieldDef('r1', 'f1')).resolves.toBeUndefined();
  });

  describe('listEntries — the owner review queue', () => {
    it('sends no status filter when none is asked for', async () => {
      const fetcher = vi.fn().mockResolvedValue(list([]));
      await createRegistryClient(fetcher).listEntries('r1');
      expect(fetcher.mock.calls[0]![0]).toBe('/api/v1/registry_entries?registry=r1&limit=100');
    });

    it('puts the status in the query string, not the path', async () => {
      const fetcher = vi.fn().mockResolvedValue(list([]));
      await createRegistryClient(fetcher).listEntries('r1', 'pending');
      expect(fetcher.mock.calls[0]![0]).toBe(
        '/api/v1/registry_entries?registry=r1&status=pending&limit=100',
      );
    });

    it('is a GET with no body', async () => {
      const fetcher = vi.fn().mockResolvedValue(list([]));
      await createRegistryClient(fetcher).listEntries('r1', 'pending');
      const [, init] = fetcher.mock.calls[0]!;
      expect(init.method).toBe('GET');
      expect(init.body).toBeUndefined();
    });

    it('surfaces the backend message on a 403 rather than resolving empty', async () => {
      // The registrant-asking-for-someone-else's-queue case. Resolving `{ items: [] }` here
      // would render an empty queue, which an owner reads as "nothing to review".
      const fetcher = vi.fn().mockResolvedValue(
        new Response(JSON.stringify({ error: { message: 'forbidden' } }), {
          status: 403,
          headers: { 'content-type': 'application/json' },
        }),
      );
      await expect(createRegistryClient(fetcher).listEntries('r1', 'pending')).rejects.toThrow('forbidden');
    });
  });

  it('percent-encodes an id/slug interpolated into the path', async () => {
    const fetcher = vi.fn().mockResolvedValue(ok({ id: 'r1' }));
    await createRegistryClient(fetcher).getRegistry('a b/c');
    const [path] = fetcher.mock.calls[0]!;
    expect(path).toBe('/api/v1/registries/a%20b%2Fc');
  });
});

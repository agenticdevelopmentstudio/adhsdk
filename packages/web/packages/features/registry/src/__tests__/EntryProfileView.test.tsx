import { afterEach, describe, expect, it, vi } from 'vitest';
import { render, screen, waitFor } from '@testing-library/react';
import type { PublicEntry } from '@adh-sdk/registry-profile';
import { EntryProfileView } from '../viewer/EntryProfileView';

/** The anonymous body the server rendered — the shape `PublicEntry` insists on, nothing more. */
function entry(patch: Partial<PublicEntry> = {}): PublicEntry {
  return {
    slug: 'mike',
    displayName: 'Mike',
    summary: 'Builds things',
    photoAttachmentId: null,
    providerType: 'person',
    category: 'software.consulting',
    keywords: [],
    locationText: '',
    countryCode: '',
    regionCode: '',
    geo: null,
    areaServed: {},
    deliveryMode: 'virtual',
    links: [],
    contactMode: 'none',
    languages: [],
    fields: [],
    services: [],
    imageUrls: {},
    ...patch,
  };
}

/** `PublicEntry` as /v1 serves it: snake_case, with the untyped maps keeping their keys. */
const wireEntry = (e: PublicEntry) => ({
  slug: e.slug,
  display_name: e.displayName,
  summary: e.summary,
  photo_attachment_id: e.photoAttachmentId,
  provider_type: e.providerType,
  category: e.category,
  keywords: e.keywords,
  location_text: e.locationText,
  country_code: e.countryCode,
  region_code: e.regionCode,
  geo: e.geo,
  area_served: e.areaServed,
  delivery_mode: e.deliveryMode,
  links: e.links,
  contact_mode: e.contactMode,
  languages: e.languages,
  fields: e.fields,
  services: e.services.map((s) => ({
    title: s.title,
    description: s.description,
    pricing_model: s.pricingModel,
    price_min: s.priceMin,
    price_max: s.priceMax,
    currency: s.currency,
    unit: s.unit,
    delivery_mode: s.deliveryMode,
  })),
  image_urls: e.imageUrls,
});

const page = (body: PublicEntry) =>
  new Response(
    JSON.stringify({
      registry: { slug: 'coaches', name: 'Coaches', bound_site_id: null },
      entry: wireEntry(body),
      json_ld: {},
    }),
    { status: 200, headers: { 'content-type': 'application/json' } },
  );

/** The one field a signed-in reader gets and an anonymous one does not. */
const memberField = {
  key: 'rate',
  label: 'Day rate',
  type: 'text' as const,
  value: '$1,200',
  visibility: 'authenticated' as const,
};

function mount(props: {
  signedIn: boolean;
  fetcher: (path: string, init?: RequestInit) => Promise<Response>;
  entry?: PublicEntry;
  entrySlug?: string;
}) {
  return render(
    <EntryProfileView
      registrySlug="coaches"
      entrySlug={props.entrySlug ?? 'mike'}
      entry={props.entry ?? entry()}
      signedIn={props.signedIn}
      fetcher={props.fetcher}
    />,
  );
}

afterEach(() => {
  vi.restoreAllMocks();
});

describe('EntryProfileView', () => {
  it('renders the server body and asks for nothing when the reader is not signed in', async () => {
    const fetcher = vi.fn();
    mount({ signedIn: false, fetcher });

    expect(screen.getByRole('heading', { name: 'Mike' })).toBeInTheDocument();
    // The assertion that matters is not "no request yet" but "no request at all": the fetch
    // lives in an effect, so a `signedIn` check placed after it would still pass a synchronous
    // read. Flush the microtask queue before looking.
    await Promise.resolve();
    expect(fetcher).not.toHaveBeenCalled();
  });

  it('swaps in the signed-in entry after mount', async () => {
    const fetcher = vi.fn().mockResolvedValue(page(entry({ fields: [memberField] })));
    mount({ signedIn: true, fetcher });

    // Present from the first paint — the anonymous body is what the server rendered, and it
    // must never blank while the wider one is in flight.
    expect(screen.getByRole('heading', { name: 'Mike' })).toBeInTheDocument();
    expect(await screen.findByText('$1,200')).toBeInTheDocument();
    // Marked, not merely shown: an unmarked field reads as public, which is exactly wrong for
    // the one field only members can see.
    expect(screen.getByText('Signed-in members only')).toBeInTheDocument();
  });

  it('asks the signed-in twin for the entry by its resolved slugs, url-encoded', async () => {
    const fetcher = vi.fn().mockResolvedValue(page(entry()));
    mount({ signedIn: true, fetcher, entrySlug: 'a b/c' });

    await waitFor(() => expect(fetcher).toHaveBeenCalled());
    expect(fetcher.mock.calls[0]![0]).toBe('/api/v1/registry_entries/a%20b%2Fc?registry=coaches');
  });

  it('keeps the anonymous body when the signed-in request fails', async () => {
    const warn = vi.spyOn(console, 'warn').mockImplementation(() => {});
    const fetcher = vi.fn().mockResolvedValue(new Response('nope', { status: 401 }));
    mount({ signedIn: true, fetcher });

    await waitFor(() => expect(warn).toHaveBeenCalled());
    // Still a complete, correct profile — the failure mode this component is built to have.
    expect(screen.getByRole('heading', { name: 'Mike' })).toBeInTheDocument();
    expect(screen.queryByText('$1,200')).toBeNull();
  });

  it('drops the previous entry when the reader navigates to another one', async () => {
    const first = page(entry({ fields: [memberField] }));
    // The second entry's request never settles, which is the whole point: it pins the render
    // at the moment where a `wider` left over from the first entry would still be on screen.
    const fetcher = vi
      .fn()
      .mockResolvedValueOnce(first)
      .mockImplementationOnce(() => new Promise<Response>(() => {}));
    const view = mount({ signedIn: true, fetcher });

    expect(await screen.findByText('$1,200')).toBeInTheDocument();

    view.rerender(
      <EntryProfileView
        registrySlug="coaches"
        entrySlug="jane"
        entry={entry({ slug: 'jane', displayName: 'Jane' })}
        signedIn
        fetcher={fetcher}
      />,
    );

    expect(screen.getByRole('heading', { name: 'Jane' })).toBeInTheDocument();
    // Mike's member-only rate under Jane's URL is the bug the effect's leading `setWider(null)`
    // exists to prevent.
    expect(screen.queryByText('$1,200')).toBeNull();
  });

  it('ignores a response that arrives after the reader has moved on', async () => {
    let settleFirst: (res: Response) => void = () => {};
    const fetcher = vi
      .fn()
      .mockImplementationOnce(() => new Promise<Response>((resolve) => { settleFirst = resolve; }))
      .mockImplementationOnce(() => new Promise<Response>(() => {}));
    const view = mount({ signedIn: true, fetcher });

    await waitFor(() => expect(fetcher).toHaveBeenCalledTimes(1));
    view.rerender(
      <EntryProfileView
        registrySlug="coaches"
        entrySlug="jane"
        entry={entry({ slug: 'jane', displayName: 'Jane' })}
        signedIn
        fetcher={fetcher}
      />,
    );

    settleFirst(page(entry({ fields: [memberField] })));
    await waitFor(() => expect(fetcher).toHaveBeenCalledTimes(2));

    expect(screen.getByRole('heading', { name: 'Jane' })).toBeInTheDocument();
    expect(screen.queryByText('$1,200')).toBeNull();
  });
});

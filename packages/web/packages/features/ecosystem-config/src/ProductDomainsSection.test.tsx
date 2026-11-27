// @vitest-environment jsdom
// The Custom domain section of the Product site pane (product sites phase 8), in the mockup's
// states: hidden while the switch is off and while loading; pending, pending with an error (a
// demoted domain), verified, verified and primary, failed and removing; the records table with
// the ownership TXT row and its exact copies; the remove confirm for a primary and not; and the
// human message for every refusal code. Mocks only the data boundary.
import { QueryClient, QueryClientProvider } from "@tanstack/react-query";
import { act, cleanup, fireEvent, render, screen, waitFor, within } from "@testing-library/react";
import type { ReactElement } from "react";
import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";

// The hooks call the module's own `productDomainsApi`, which a mock of the export cannot reach, so
// the mock rebuilds the hooks the same way over a mocked api: the cache behaviour the section
// relies on (an answer written straight into the cache) stays the real react-query's.
vi.mock("@adh-sdk/data/product-sites", async (importOriginal) => {
  const real = await importOriginal<typeof import("@adh-sdk/data/product-sites")>();
  const rq = await import("@tanstack/react-query");
  type Domain = import("@adh-sdk/data/product-sites").ProductDomain;
  const productDomainsApi = {
    list: vi.fn(),
    add: vi.fn(),
    check: vi.fn(),
    setPrimary: vi.fn(),
    remove: vi.fn(),
  };
  const key = real.PRODUCT_DOMAINS_KEY;
  return {
    ProductDomainError: real.ProductDomainError,
    PRODUCT_DOMAINS_KEY: key,
    PRODUCT_SITE_KEY: real.PRODUCT_SITE_KEY,
    productDomainsAvailable: real.productDomainsAvailable,
    productDomainsApi,
    useProductDomains: (eco: string) =>
      rq.useQuery({ queryKey: key(eco), queryFn: () => productDomainsApi.list(eco), retry: false }),
    useAddProductDomain: (eco: string) => {
      const qc = rq.useQueryClient();
      return rq.useMutation({
        mutationFn: (host: string) => productDomainsApi.add(eco, host),
        onSuccess: (d: Domain) => qc.setQueryData<Domain[]>(key(eco), (old) => [...(old ?? []), d]),
      });
    },
    useCheckProductDomain: (eco: string) => {
      const qc = rq.useQueryClient();
      return rq.useMutation({
        mutationFn: (id: string) => productDomainsApi.check(eco, id),
        onSuccess: (d: Domain) =>
          qc.setQueryData<Domain[]>(key(eco), (old) => old?.map((x) => (x.id === d.id ? d : x))),
      });
    },
    useSetPrimaryProductDomain: (eco: string) => {
      const qc = rq.useQueryClient();
      return rq.useMutation({
        mutationFn: ({ domainId, primary }: { domainId: string; primary: boolean }) =>
          productDomainsApi.setPrimary(eco, domainId, primary),
        onSuccess: (ds: Domain[]) => qc.setQueryData(key(eco), ds),
      });
    },
    useRemoveProductDomain: (eco: string) => {
      const qc = rq.useQueryClient();
      return rq.useMutation({
        mutationFn: (id: string) => productDomainsApi.remove(eco, id),
        onSuccess: (_v: void, id: string) =>
          qc.setQueryData<Domain[]>(key(eco), (old) => old?.filter((x) => x.id !== id)),
      });
    },
  };
});

import {
  ProductDomainError,
  productDomainsApi,
  type ProductDomain,
  type ProductSite,
} from "@adh-sdk/data/product-sites";
import { ProductDomainsSection, domainErrorMessage } from "./ProductDomainsSection";

const api = vi.mocked(productDomainsApi);

const SUBDOMAIN = "https://temporal.agenticdeveloperhub.com";
const HOST = "app.temporal.com";

let n = 0;
const eco = () => `eco-${n}`;

const siteOf = (over: Partial<ProductSite> = {}): ProductSite => ({
  ecosystemId: eco(),
  handle: "temporal",
  primaryOrigin: SUBDOMAIN,
  subdomainOrigin: SUBDOMAIN,
  adminEnabled: false,
  adminClientId: null,
  consoleLive: false,
  contentGated: false,
  ...over,
});

const CNAME = { type: "CNAME" as const, name: "app", value: "cname.vercel-dns.com" };
const VERCEL_TXT = { type: "TXT" as const, name: "_vercel", value: "vc-domain-verify=app.temporal.com,7f3a9c2e1b4d6a80" };
const CHALLENGE = {
  type: "TXT" as const,
  name: `_adh-challenge.${HOST}`,
  value: "adh-domain-verification=Zx81kq0Pm3",
};

const domainOf = (over: Partial<ProductDomain> = {}): ProductDomain => ({
  id: "d1",
  host: HOST,
  status: "pending",
  isPrimary: false,
  records: [CNAME, VERCEL_TXT, CHALLENGE],
  misconfigured: true,
  vercelVerified: false,
  error: null,
  createdAt: "2026-11-19T14:05:00.000Z",
  verifiedAt: null,
  checkedAt: new Date(Date.now() - 4 * 60_000).toISOString(),
  expiresAt: "2026-11-26T14:05:00.000Z",
  ...over,
});

const notFound = () => new ProductDomainError(404, "not found", "not_found");

beforeEach(() => {
  n += 1;
  vi.clearAllMocks();
  api.list.mockResolvedValue([]);
});

afterEach(cleanup);

const renderSection = (ui: ReactElement) =>
  render(
    <QueryClientProvider client={new QueryClient({ defaultOptions: { queries: { retry: false } } })}>
      {ui}
    </QueryClientProvider>,
  );

const section = (site: ProductSite = siteOf()) =>
  renderSection(<ProductDomainsSection ecosystemId={eco()} site={site} productName="Temporal" />);

describe("ProductDomainsSection", () => {
  it("renders nothing at all while the switch is off (404 not_found)", async () => {
    api.list.mockRejectedValue(notFound());
    const { container } = section();
    await waitFor(() => expect(api.list).toHaveBeenCalled());
    // Give the rejection a turn to land.
    await new Promise((r) => setTimeout(r, 0));
    expect(container).toBeEmptyDOMElement();
    expect(screen.queryByText("Custom domain")).not.toBeInTheDocument();
  });

  it("renders nothing while loading, so no heading flashes", () => {
    api.list.mockReturnValue(new Promise(() => {}));
    const { container } = section();
    expect(container).toBeEmptyDOMElement();
  });

  it("a load error other than the switch shows the heading and the message", async () => {
    api.list.mockRejectedValue(new ProductDomainError(500, "database unavailable", "internal"));
    section();
    expect(await screen.findByText("Custom domain")).toBeInTheDocument();
    expect(screen.getByRole("alert")).toHaveTextContent("Couldn't load the custom domains: database unavailable");
  });

  it("a failed refetch keeps the loaded list and says it could not be refreshed", async () => {
    api.list.mockResolvedValue([domainOf()]);
    const client = new QueryClient({ defaultOptions: { queries: { retry: false } } });
    render(
      <QueryClientProvider client={client}>
        <ProductDomainsSection ecosystemId={eco()} site={siteOf()} productName="Temporal" />
      </QueryClientProvider>,
    );
    expect(await screen.findByText(HOST)).toBeInTheDocument();
    api.list.mockRejectedValue(new ProductDomainError(500, "database unavailable", "internal"));
    await client.refetchQueries();
    expect(await screen.findByRole("alert")).toHaveTextContent(
      "Couldn't refresh the custom domains: database unavailable",
    );
    expect(screen.getByText(HOST)).toBeInTheDocument();
    expect(screen.getByRole("table", { name: `DNS records for ${HOST}` })).toBeInTheDocument();
    expect(screen.queryByText(/Couldn't load the custom domains/)).not.toBeInTheDocument();
  });

  it("a refetch answering that the switch is off hides the whole section, list and all", async () => {
    api.list.mockResolvedValue([domainOf()]);
    const client = new QueryClient({ defaultOptions: { queries: { retry: false } } });
    const { container } = render(
      <QueryClientProvider client={client}>
        <ProductDomainsSection ecosystemId={eco()} site={siteOf()} productName="Temporal" />
      </QueryClientProvider>,
    );
    expect(await screen.findByText(HOST)).toBeInTheDocument();
    api.list.mockRejectedValue(notFound());
    await client.refetchQueries();
    await waitFor(() => expect(container).toBeEmptyDOMElement());
  });

  it("no domain yet: the intro naming the product, the add field and the guidance", async () => {
    section();
    expect(
      await screen.findByText(
        "Temporal can also answer at a domain you own. Its sign-in, admin console and support pages then work there too, and once the domain is verified you can make it Temporal's primary address.",
      ),
    ).toBeInTheDocument();
    expect(screen.getByLabelText("Domain")).toHaveAttribute("placeholder", "app.example.com");
    expect(screen.getByRole("button", { name: "Add domain" })).toBeDisabled();
    expect(screen.getByText("Use a subdomain")).toBeInTheDocument();
    expect(screen.getByText("On Cloudflare, set the record to DNS only")).toBeInTheDocument();
    expect(screen.getByText("Passkeys and security keys don't work on a custom domain.")).toBeInTheDocument();
  });

  it("without a product name the sentences say this product", async () => {
    renderSection(<ProductDomainsSection ecosystemId={eco()} site={siteOf()} />);
    expect(await screen.findByText(/^This product can also answer at a domain you own\./)).toBeInTheDocument();
  });

  it("adds the trimmed host, and clears the field on success", async () => {
    api.add.mockResolvedValue(domainOf());
    section();
    const field = await screen.findByLabelText("Domain");
    fireEvent.change(field, { target: { value: `  ${HOST}  ` } });
    fireEvent.click(screen.getByRole("button", { name: "Add domain" }));
    await waitFor(() => expect(api.add).toHaveBeenCalledWith(eco(), HOST));
    await waitFor(() => expect(screen.getByLabelText("Domain")).toHaveValue(""));
    expect(await screen.findByText(HOST)).toBeInTheDocument();
  });

  it("a refused add shows the human message under the field", async () => {
    api.add.mockRejectedValue(new ProductDomainError(409, "host taken", "product_domain_taken"));
    section();
    fireEvent.change(await screen.findByLabelText("Domain"), { target: { value: HOST } });
    fireEvent.click(screen.getByRole("button", { name: "Add domain" }));
    expect(await screen.findByRole("alert")).toHaveTextContent("Another product already uses that domain.");
  });

  it("pending: the badge, the waiting text and check line, the records and Check now / Remove", async () => {
    api.list.mockResolvedValue([domainOf()]);
    section();
    expect(await screen.findByText("Pending")).toBeInTheDocument();
    const status = screen.getByRole("status");
    expect(status).toHaveTextContent(/^Added .+\. Waiting for the records below\. Last checked .+; it is checked again every 10 minutes until .+\.$/);
    expect(screen.getByRole("table", { name: `DNS records for ${HOST}` })).toBeInTheDocument();
    expect(screen.getByText("temporal.com")).toBeInTheDocument();
    expect(screen.getByRole("button", { name: `Check ${HOST} now` })).toHaveTextContent("Check now");
    expect(screen.getByRole("button", { name: `Remove ${HOST}` })).toBeInTheDocument();
    expect(screen.queryByRole("button", { name: `Make ${HOST} primary` })).not.toBeInTheDocument();
    // The add field stays while no domain is verified, for a second pending one.
    expect(screen.getByLabelText("Domain")).toBeInTheDocument();
  });

  it("the last-checked time ages once a minute, and the interval stops on unmount", async () => {
    // Only the clock and the interval are faked, so react-query and findBy keep real timeouts.
    vi.useFakeTimers({ toFake: ["Date", "setInterval", "clearInterval"] });
    try {
      vi.setSystemTime(new Date("2026-11-20T10:00:00.000Z"));
      api.list.mockResolvedValue([domainOf({ checkedAt: "2026-11-20T09:56:00.000Z" })]);
      const { unmount } = section();
      expect(await screen.findByText(/Last checked 4 minutes ago;/)).toBeInTheDocument();
      act(() => {
        vi.advanceTimersByTime(60_000);
      });
      expect(screen.getByText(/Last checked 5 minutes ago;/)).toBeInTheDocument();
      unmount();
      expect(vi.getTimerCount()).toBe(0);
    } finally {
      vi.useRealTimers();
    }
  });

  it("a last-checked time in the future (clock skew) reads as now, never as in so many seconds", async () => {
    api.list.mockResolvedValue([domainOf({ checkedAt: new Date(Date.now() + 30_000).toISOString() })]);
    section();
    const line = await screen.findByText(/Last checked /);
    expect(line).toHaveTextContent(/Last checked now;/);
    expect(line).not.toHaveTextContent(/Last checked in /);
  });

  it("pending and never checked: says how often it is checked, without a last-checked time", async () => {
    api.list.mockResolvedValue([domainOf({ checkedAt: null })]);
    section();
    const status = await screen.findByRole("status");
    expect(status).toHaveTextContent(/It is checked every 10 minutes until .+\.$/);
    expect(status).not.toHaveTextContent("Last checked");
  });

  it("a demoted domain (pending with an error) names the problem and never says waiting", async () => {
    api.list.mockResolvedValue([domainOf({ error: "the domain's DNS no longer points at Vercel" })]);
    section();
    const status = await screen.findByRole("status");
    expect(status).toHaveTextContent(
      "The last check found a problem: the domain's DNS no longer points at Vercel. Temporal answers at app.temporal.com only once it is verified.",
    );
    expect(status).not.toHaveTextContent("Waiting");
    expect(screen.getByText("Pending")).toBeInTheDocument();
    expect(screen.getByRole("button", { name: `Check ${HOST} now` })).toBeInTheDocument();
  });

  it("the ownership TXT record is a normal row, with the sentence that it proves the domain is yours", async () => {
    api.list.mockResolvedValue([domainOf()]);
    section();
    const table = await screen.findByRole("table", { name: `DNS records for ${HOST}` });
    const rows = within(table).getAllByRole("row");
    // Header, CNAME, _vercel TXT, then the ownership TXT last.
    expect(rows).toHaveLength(4);
    const last = rows[3] as HTMLElement;
    expect(last).toHaveTextContent("TXT");
    expect(last).toHaveTextContent(CHALLENGE.name);
    expect(last).toHaveTextContent(CHALLENGE.value);
    expect(
      within(last).getByRole("button", { name: `Copy the TXT record name ${CHALLENGE.name}` }),
    ).toBeInTheDocument();
    expect(screen.getByText(/proves the domain is yours\./).textContent).toBe(
      "The TXT record named _adh-challenge proves the domain is yours.",
    );
  });

  it.each([
    [
      "a CNAME under a two-label public suffix",
      "app.example.co.uk",
      [{ type: "CNAME" as const, name: "app", value: "cname.vercel-dns.com" }],
      "example.co.uk",
    ],
    [
      "a CNAME several labels deep",
      "a.b.example.com",
      [{ type: "CNAME" as const, name: "a.b", value: "cname.vercel-dns.com" }],
      "example.com",
    ],
    ["an apex A record", "example.co.uk", [{ type: "A" as const, name: "@", value: "76.76.21.21" }], "example.co.uk"],
    ["no A or CNAME record: the first label dropped", "app.example.com", [CHALLENGE], "example.com"],
  ])("the records lead names the zone the records give: %s", async (_label, host, records, zone) => {
    api.list.mockResolvedValue([domainOf({ host, records })]);
    section();
    const lead = await screen.findByText(/^Create these records at the DNS provider for/);
    expect(lead.textContent).toBe(`Create these records at the DNS provider for ${zone}:`);
  });

  it("copy buttons copy the exact API strings", async () => {
    const writeText = vi.fn().mockResolvedValue(undefined);
    Object.assign(navigator, { clipboard: { writeText } });
    const odd = { type: "CNAME" as const, name: "app ", value: "cname.vercel-dns.com." };
    api.list.mockResolvedValue([domainOf({ records: [odd, CHALLENGE] })]);
    section();
    fireEvent.click(await screen.findByRole("button", { name: "Copy the CNAME record name app " }));
    fireEvent.click(screen.getByRole("button", { name: "Copy the CNAME record value for app " }));
    fireEvent.click(screen.getByRole("button", { name: `Copy the TXT record value for ${CHALLENGE.name}` }));
    await waitFor(() => expect(writeText).toHaveBeenCalledTimes(3));
    expect(writeText).toHaveBeenNthCalledWith(1, "app ");
    expect(writeText).toHaveBeenNthCalledWith(2, "cname.vercel-dns.com.");
    expect(writeText).toHaveBeenNthCalledWith(3, CHALLENGE.value);
  });

  it("Check now sends the domain's id, and the answer replaces the row", async () => {
    api.list.mockResolvedValue([domainOf()]);
    api.check.mockResolvedValue(
      domainOf({ status: "verified", records: [], verifiedAt: "2026-11-19T14:32:00.000Z", vercelVerified: true }),
    );
    section();
    fireEvent.click(await screen.findByRole("button", { name: `Check ${HOST} now` }));
    await waitFor(() => expect(api.check).toHaveBeenCalledWith(eco(), "d1"));
    expect(await screen.findByText("Verified")).toBeInTheDocument();
    expect(screen.queryByRole("table")).not.toBeInTheDocument();
  });

  it("a refused check shows its message under the box", async () => {
    api.list.mockResolvedValue([domainOf()]);
    api.check.mockRejectedValue(new ProductDomainError(429, "slow down", "product_domains_rate_limited"));
    section();
    fireEvent.click(await screen.findByRole("button", { name: `Check ${HOST} now` }));
    expect(await screen.findByRole("alert")).toHaveTextContent("Too many tries in the last hour. Try again later.");
  });

  it("verified: the link, the still-primary subdomain, Make primary and Remove, and no add field", async () => {
    api.list.mockResolvedValue([
      domainOf({ status: "verified", records: [], verifiedAt: "2026-11-19T14:32:00.000Z", vercelVerified: true }),
    ]);
    section();
    expect(await screen.findByText("Verified")).toBeInTheDocument();
    const link = screen.getByRole("link", { name: `https://${HOST}` });
    expect(link).toHaveAttribute("href", `https://${HOST}`);
    expect(screen.getByRole("status")).toHaveTextContent(
      /^Temporal answers at https:\/\/app\.temporal\.com\. Verified .+\. Its primary address is still temporal\.agenticdeveloperhub\.com\.$/,
    );
    expect(screen.getByRole("button", { name: `Make ${HOST} primary` })).toHaveTextContent("Make primary");
    expect(screen.getByRole("button", { name: `Remove ${HOST}` })).toBeInTheDocument();
    expect(screen.queryByRole("button", { name: `Check ${HOST} now` })).not.toBeInTheDocument();
    expect(screen.queryByLabelText("Domain")).not.toBeInTheDocument();
  });

  it("verified while another custom domain is primary: names that domain as the primary, not the subdomain", async () => {
    api.list.mockResolvedValue([
      domainOf({ id: "d2", host: "www.temporal.com", status: "verified", isPrimary: true, records: [] }),
      domainOf({ status: "verified", records: [], verifiedAt: "2026-11-19T14:32:00.000Z" }),
    ]);
    section(siteOf({ primaryOrigin: "https://www.temporal.com" }));
    expect(await screen.findByRole("link", { name: `https://${HOST}` })).toBeInTheDocument();
    const statuses = screen.getAllByRole("status");
    expect(statuses[1]).toHaveTextContent(/Its primary address is still www\.temporal\.com\.$/);
    expect(statuses[1]).not.toHaveTextContent("temporal.agenticdeveloperhub.com");
  });

  it("Make primary sends primary: true, and the answered list replaces the domains", async () => {
    const verified = domainOf({ status: "verified", records: [], verifiedAt: "2026-11-19T14:32:00.000Z" });
    api.list.mockResolvedValue([verified]);
    api.setPrimary.mockResolvedValue([{ ...verified, isPrimary: true }]);
    section();
    fireEvent.click(await screen.findByRole("button", { name: `Make ${HOST} primary` }));
    await waitFor(() => expect(api.setPrimary).toHaveBeenCalledWith(eco(), "d1", true));
    expect(await screen.findByText("Primary")).toBeInTheDocument();
    expect(screen.queryByRole("button", { name: `Make ${HOST} primary` })).not.toBeInTheDocument();
  });

  it("verified and primary: both badges, the primary sentence, and only Remove", async () => {
    api.list.mockResolvedValue([
      domainOf({ status: "verified", isPrimary: true, records: [], verifiedAt: "2026-11-19T14:32:00.000Z" }),
    ]);
    section(siteOf({ primaryOrigin: `https://${HOST}` }));
    expect(await screen.findByText("Primary")).toBeInTheDocument();
    expect(screen.getByText("Verified")).toBeInTheDocument();
    expect(screen.getByRole("status")).toHaveTextContent(
      "app.temporal.com is Temporal's primary address. Customers sign in there, the admin console signs in there, and support emails link there. temporal.agenticdeveloperhub.com still works.",
    );
    expect(screen.queryByRole("button", { name: `Make ${HOST} primary` })).not.toBeInTheDocument();
    expect(screen.queryByRole("button", { name: `Check ${HOST} now` })).not.toBeInTheDocument();
    expect(screen.getByRole("button", { name: `Remove ${HOST}` })).toBeInTheDocument();
  });

  it("failed: the 7-day sentence, the records still shown, Check now and Remove", async () => {
    api.list.mockResolvedValue([domainOf({ status: "failed" })]);
    section();
    expect(await screen.findByText("Failed")).toBeInTheDocument();
    expect(screen.getByRole("status")).toHaveTextContent(
      /^The records below were not found within 7 days of adding the domain on .+, so it is no longer checked by itself\. Create them and choose Check now, or remove the domain\.$/,
    );
    expect(screen.getByRole("table", { name: `DNS records for ${HOST}` })).toBeInTheDocument();
    expect(screen.getByRole("button", { name: `Check ${HOST} now` })).toBeInTheDocument();
  });

  it("failed after its 7 days restarted: names the day it last went back to waiting, not the day it was added", async () => {
    // Added 19 November; demoted (or checked again after failing) on 24 November, so the
    // backend's fresh 7 days end on 1 December.
    api.list.mockResolvedValue([domainOf({ status: "failed", expiresAt: "2026-12-01T09:00:00.000Z" })]);
    section();
    const restarted = new Date("2026-11-24T09:00:00.000Z").toLocaleDateString(undefined, { day: "numeric", month: "long" });
    const status = await screen.findByRole("status");
    expect(status).toHaveTextContent(
      `The records below were not found within 7 days of ${restarted}, when it last went back to waiting, so it is no longer checked by itself. Create them and choose Check now, or remove the domain.`,
    );
    expect(status).not.toHaveTextContent("adding the domain");
  });

  it("failed with an error: adds the problem", async () => {
    api.list.mockResolvedValue([domainOf({ status: "failed", error: "no CNAME found." })]);
    section();
    expect(await screen.findByRole("status")).toHaveTextContent(/The last check found a problem: no CNAME found\.$/);
  });

  it("removing: the neutral badge, the sentence, and only Remove", async () => {
    api.list.mockResolvedValue([domainOf({ status: "removing" })]);
    section();
    expect(await screen.findByText("Removing")).toBeInTheDocument();
    expect(screen.getByRole("status")).toHaveTextContent("Being removed. If this stays, choose Remove again.");
    expect(screen.queryByRole("table")).not.toBeInTheDocument();
    expect(screen.queryByRole("button", { name: `Check ${HOST} now` })).not.toBeInTheDocument();
    expect(screen.getByRole("button", { name: `Remove ${HOST}` })).toBeInTheDocument();
  });

  it("Remove of a domain that is not primary: the short confirm, then the row goes", async () => {
    api.list.mockResolvedValue([domainOf()]);
    api.remove.mockResolvedValue(undefined);
    section();
    fireEvent.click(await screen.findByRole("button", { name: `Remove ${HOST}` }));
    expect(await screen.findByText(`Remove ${HOST}?`)).toBeInTheDocument();
    expect(screen.getByText(`Temporal stops answering at ${HOST} at once.`)).toBeInTheDocument();
    fireEvent.click(screen.getByRole("button", { name: "Remove" }));
    await waitFor(() => expect(api.remove).toHaveBeenCalledWith(eco(), "d1"));
    await waitFor(() => expect(screen.queryByText(HOST)).not.toBeInTheDocument());
  });

  it("Remove of the primary: the confirm says the subdomain becomes primary again", async () => {
    api.list.mockResolvedValue([
      domainOf({ status: "verified", isPrimary: true, records: [], verifiedAt: "2026-11-19T14:32:00.000Z" }),
    ]);
    section(siteOf({ primaryOrigin: `https://${HOST}` }));
    fireEvent.click(await screen.findByRole("button", { name: `Remove ${HOST}` }));
    expect(
      await screen.findByText(
        `Temporal stops answering at ${HOST} at once, and ${SUBDOMAIN} becomes its primary address again. Links to the custom domain stop working.`,
      ),
    ).toBeInTheDocument();
  });

  it("a cancelled remove sends nothing", async () => {
    api.list.mockResolvedValue([domainOf()]);
    section();
    fireEvent.click(await screen.findByRole("button", { name: `Remove ${HOST}` }));
    fireEvent.click(await screen.findByRole("button", { name: "Cancel" }));
    await waitFor(() => expect(screen.queryByText(`Remove ${HOST}?`)).not.toBeInTheDocument());
    expect(api.remove).not.toHaveBeenCalled();
  });

  it("a refused remove closes the modal and shows the message under the box", async () => {
    api.list.mockResolvedValue([domainOf()]);
    api.remove.mockRejectedValue(new ProductDomainError(502, "vercel down", "product_domain_vercel_unavailable"));
    section();
    fireEvent.click(await screen.findByRole("button", { name: `Remove ${HOST}` }));
    fireEvent.click(await screen.findByRole("button", { name: "Remove" }));
    expect(await screen.findByRole("alert")).toHaveTextContent(
      "The domain service didn't answer. Try again in a minute.",
    );
    await waitFor(() => expect(screen.queryByText(`Remove ${HOST}?`)).not.toBeInTheDocument());
  });

  it("a domain already removed elsewhere says so and reads the list again", async () => {
    api.list.mockResolvedValue([domainOf()]);
    api.check.mockRejectedValue(new ProductDomainError(404, "domain not found", "product_domain_not_found"));
    section();
    fireEvent.click(await screen.findByRole("button", { name: `Check ${HOST} now` }));
    expect(await screen.findByRole("alert")).toHaveTextContent("That domain was already removed.");
    await waitFor(() => expect(api.list).toHaveBeenCalledTimes(2));
  });

  it("an error holding markup renders as text, never as HTML", async () => {
    const markup = '<img src=x onerror="alert(1)"><b>bold</b>';
    api.list.mockResolvedValue([domainOf({ error: markup, host: "<i>evil</i>.example.com" })]);
    const { container } = section();
    expect(await screen.findByRole("status")).toHaveTextContent(markup);
    expect(container.querySelector("img")).toBeNull();
    expect(container.querySelector("b")).toBeNull();
    expect(container.querySelector("i")).toBeNull();
    expect(screen.getByText("<i>evil</i>.example.com")).toBeInTheDocument();
  });
});

describe("domainErrorMessage", () => {
  const words = { name: "Temporal", Name: "Temporal", its: "Temporal's" };
  const refusal = (code: string, status = 400) => new ProductDomainError(status, "backend sentence", code);

  it.each([
    ["product_domain_invalid", "That isn't a domain name Temporal can use. Enter one such as app.example.com."],
    ["product_domain_local", "That name only works on a local network. Enter a public domain such as app.example.com."],
    ["product_domain_ours", "That domain belongs to the hub. Enter a domain you own."],
    ["product_domain_limit", "Temporal already has five domains, the most it can have. Remove one to add another."],
    ["product_domain_taken", "Another product already uses that domain."],
    ["product_domain_taken_elsewhere", "That domain is in use on another Vercel account, so it can't be added here."],
    ["product_domain_vercel_unavailable", "The domain service didn't answer. Try again in a minute."],
    ["product_domains_rate_limited", "Too many tries in the last hour. Try again later."],
    ["product_domains_unconfigured", "Custom domains aren't set up on this server yet."],
    ["product_domain_not_verified", "That domain isn't verified yet, so it can't be the primary address."],
    ["product_domain_primary_race", "Another change to the primary address happened at the same time. Try again."],
    ["product_domain_not_found", "That domain was already removed."],
  ])("%s", (code, message) => {
    expect(domainErrorMessage(refusal(code), words)).toBe(message);
  });

  it("names this product without a name", () => {
    expect(domainErrorMessage(refusal("product_domain_limit"))).toBe(
      "This product already has five domains, the most it can have. Remove one to add another.",
    );
  });

  it("a 403 says who may change the domains", () => {
    expect(domainErrorMessage(new ProductDomainError(403, "forbidden", "forbidden"), words)).toBe(
      "Only the product's managers can change its domains.",
    );
  });

  it("an unknown code falls back to the backend's sentence, then to a generic one", () => {
    expect(domainErrorMessage(refusal("something_new"), words)).toBe("backend sentence");
    expect(domainErrorMessage(new ProductDomainError(500, ""), words)).toBe("Something went wrong. Try again.");
    expect(domainErrorMessage("not an error", words)).toBe("Something went wrong. Try again.");
  });
});

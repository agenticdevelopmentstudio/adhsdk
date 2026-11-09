// src/profile/normalize.ts
function iso(seconds) {
  return new Date(seconds * 1e3).toISOString();
}
function personasFromWire(rows) {
  return rows.map((p) => ({
    slug: p.slug,
    name: p.name,
    description: p.description,
    visibility: p.visibility,
    createdAt: iso(p.created)
  }));
}
function principalFromUserCard(body) {
  return {
    slug: body.slug,
    displayName: body.display_name,
    avatarUrl: body.avatar_url,
    createdAt: iso(body.created),
    socialLinks: body.social_links,
    emails: body.emails,
    phones: body.phones,
    addresses: body.addresses.map((a) => ({
      label: a.label,
      line1: a.line1,
      line2: a.line2,
      city: a.city,
      region: a.region,
      postalCode: a.postal_code,
      country: a.country
    })),
    personas: personasFromWire(body.personas),
    kind: "user"
  };
}
function principalFromOrgCard(body) {
  return {
    slug: body.slug,
    displayName: body.display_name,
    createdAt: iso(body.created),
    description: body.description,
    personas: personasFromWire(body.personas),
    avatarUrl: null,
    socialLinks: [],
    emails: [],
    phones: [],
    addresses: [],
    kind: "organization"
  };
}

// src/profile/server.ts
async function fetchPublicPrincipal(slug) {
  const backend = process.env.API_BACKEND_URL?.trim().replace(/\/+$/, "");
  if (!backend) {
    throw new Error(
      "API_BACKEND_URL is not set. Configure it in each Vercel project (and .env.local for local dev, e.g. http://localhost:8080)."
    );
  }
  const encoded = encodeURIComponent(slug);
  const users = await fetch(`${backend}/v1/users?handle=${encoded}`, { next: { revalidate: 30 } });
  if (users.ok) {
    return principalFromUserCard(await users.json());
  }
  if (users.status !== 404) throw new Error(`Failed to fetch profile: ${users.status}`);
  const orgs = await fetch(`${backend}/v1/organizations?slug=${encoded}`, { next: { revalidate: 30 } });
  if (orgs.ok) {
    return principalFromOrgCard(await orgs.json());
  }
  if (orgs.status !== 404) throw new Error(`Failed to fetch profile: ${orgs.status}`);
  return null;
}
export {
  fetchPublicPrincipal
};
//# sourceMappingURL=server.js.map
import type { FieldType, FieldVisibility } from '@adh-sdk/registry-types';

export interface PublicField {
  key: string;
  label: string;
  type: FieldType;
  value: unknown;
  /**
   * The audience this value actually reaches — the tighter of the registry owner's ceiling
   * for the field and the registrant's own setting on this entry.
   *
   * Present so the profile can SAY so, which matters because the difference is invisible
   * from the page itself: an anonymous visitor is served a strictly smaller entry than a
   * signed-in one and has no way to tell, and a registrant checking their own live profile
   * while signed in would otherwise read the wider page as the public one.
   *
   * Never a licence to render and hide. The server strips — a field this viewer is not
   * admitted to has no entry in `fields` at all — so `'private'` cannot appear here, and
   * `'authenticated'` only ever arrives in a response that was itself served to a signed-in
   * reader. Hiding in CSS would leave the value in the markup where View Source finds it.
   */
  visibility: FieldVisibility;
}

export interface PublicService {
  title: string;
  description: string;
  pricingModel: string;
  priceMin: number | null;
  priceMax: number | null;
  currency: string;
  unit: string;
  deliveryMode: string;
}

/**
 * Exactly what the backend's public entry route returns.
 *
 * The server has already applied field visibility: a private field's key, label and value
 * are absent here, not merely flagged. Nothing in this package hides anything.
 */
export interface PublicEntry {
  slug: string;
  displayName: string;
  summary: string;
  photoAttachmentId: string | null;
  providerType: string;
  category: string;
  keywords: string[];
  locationText: string;
  countryCode: string;
  regionCode: string;
  geo: { lat: number; lon: number } | null;
  areaServed: Record<string, unknown>;
  deliveryMode: string;
  links: Array<{ label: string; url: string }>;
  /** 'dm' | 'none'. Never an address — the server does not serialize one. */
  contactMode: string;
  languages: string[];
  fields: PublicField[];
  services: PublicService[];
  /**
   * Attachment id → URL, for the photo and for every `image` field.
   *
   * An attachment id on its own is unusable: every route in the adh backend's
   * `routes/storage.ts` sits behind `jwtAuth`, and a profile page is read by visitors who
   * are not signed in. So the server that serialized this entry resolved the ids it was
   * willing to expose and put the URLs here. An id absent from the map has no image, and
   * that is a normal state, not an error.
   *
   * The URLs are short-lived presigned links. Render them; never persist or cache them.
   */
  imageUrls: Record<string, string>;
}

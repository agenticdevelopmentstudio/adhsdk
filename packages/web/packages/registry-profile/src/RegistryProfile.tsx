import type { FieldVisibility } from '@adh-sdk/registry-types';
import type { ReactNode } from 'react';
import { FieldValue } from './FieldValue';
import { ServiceList } from './ServiceList';
import type { PublicEntry } from './types';

/**
 * How a narrowed audience is NAMED beside the field it applies to, or `null` for the one
 * audience that needs no marking.
 *
 * The marker exists because the narrowing is otherwise invisible: this page renders the
 * same for a registrant reviewing their own live profile as for a stranger, and without a
 * word beside the field they cannot tell that a stranger sees fewer of them.
 *
 * Exhaustive `Record` on purpose — an audience added to `FIELD_VISIBILITIES` and not named
 * here is a compile error rather than a field that silently renders unmarked, which is the
 * failure that matters: an unmarked field reads as public.
 *
 * `private` is here for that exhaustiveness and should never render: the server strips a
 * field the viewer is not admitted to, so a `private` one has no entry in `fields` at all.
 * Naming it honestly, rather than throwing, means a serializer bug shows up as an
 * over-cautious marking instead of a blank profile.
 */
const AUDIENCE_NOTE: Record<FieldVisibility, string | null> = {
  public: null,
  authenticated: 'Signed-in members only',
  private: 'Private',
};

export interface RegistryProfileProps {
  entry: PublicEntry;
  /**
   * OPTIONAL, and normally omitted: by default images come from `entry.imageUrls`, the map
   * the serving backend already resolved. Pass a resolver only when the host has its own
   * way to turn an attachment id into a URL — an embedder proxying through their own CDN,
   * or a storybook fixture. Returning `null` means "no image", and the profile renders
   * without one.
   */
  resolveImageUrl?: (attachmentId: string) => string | null;
  /**
   * The contact affordance, supplied by the host and rendered only when the entry accepts
   * contact. A SLOT rather than a callback: on an adh site it is the hub-messaging
   * composer, on an embedder's own site there is no messaging at all, and this package
   * has no business knowing which it is on.
   */
  contact?: ReactNode;
}

export function RegistryProfile({ entry, resolveImageUrl, contact }: RegistryProfileProps) {
  // One resolver for the photo and for every image field, so a host that overrides one
  // cannot accidentally leave the other reading the default map.
  const urlFor = resolveImageUrl ?? ((id: string) => entry.imageUrls[id] ?? null);
  const photo = entry.photoAttachmentId ? urlFor(entry.photoAttachmentId) : null;

  return (
    <article className="rp">
      <header className="rp__header">
        {photo ? <img className="rp__photo" src={photo} alt="" /> : null}
        <div className="rp__identity">
          <h1 className="rp__name">{entry.displayName}</h1>
          {entry.summary ? <p className="rp__summary">{entry.summary}</p> : null}
          <dl className="rp__meta">
            {entry.category ? (
              <div className="rp__meta-row"><dt>Category</dt><dd>{entry.category}</dd></div>
            ) : null}
            {entry.locationText ? (
              <div className="rp__meta-row"><dt>Location</dt><dd>{entry.locationText}</dd></div>
            ) : null}
            {entry.languages.length > 0 ? (
              <div className="rp__meta-row">
                <dt>Languages</dt><dd>{entry.languages.join(', ')}</dd>
              </div>
            ) : null}
          </dl>
          {entry.keywords.length > 0 ? (
            <ul className="rp__keywords">
              {entry.keywords.map((k) => (
                <li className="rp__keyword" key={k}>{k}</li>
              ))}
            </ul>
          ) : null}
          {entry.contactMode === 'dm' && contact ? (
            <div className="rp__contact">{contact}</div>
          ) : null}
        </div>
      </header>

      {/*
        Every field the server sent is rendered. This component hides nothing: the
        serializer already dropped the private ones, and hiding in CSS would leave the
        values in the markup where View Source finds them.
      */}
      {entry.fields.length > 0 ? (
        <dl className="rp__fields">
          {entry.fields.map((field) => {
            const audience = AUDIENCE_NOTE[field.visibility] ?? null;
            return (
              <div className="rp__field" data-field-key={field.key} key={field.key}>
                <dt className="rp__field-label">
                  {field.label}
                  {/*
                    Inside the <dt>, not floated beside the value: the marking is about the
                    field, and a reader who meets it after the value has already read a
                    number they believed was public.
                  */}
                  {audience ? (
                    <span className="rp__field-audience" data-audience={field.visibility}>
                      {audience}
                    </span>
                  ) : null}
                </dt>
                <dd className="rp__field-value">
                  <FieldValue field={field} resolveImageUrl={urlFor} />
                </dd>
              </div>
            );
          })}
        </dl>
      ) : null}

      <ServiceList services={entry.services} />

      {entry.links.length > 0 ? (
        <nav className="rp__links" aria-label="Elsewhere">
          <ul>
            {entry.links.map((link) => (
              <li key={link.url}>
                <a href={link.url} rel="noopener noreferrer nofollow" target="_blank">
                  {link.label || link.url}
                </a>
              </li>
            ))}
          </ul>
        </nav>
      ) : null}
    </article>
  );
}

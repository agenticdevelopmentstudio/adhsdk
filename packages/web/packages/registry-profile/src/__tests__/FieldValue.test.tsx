import { describe, expect, it } from 'vitest';
import { render } from '@testing-library/react';
import { FieldValue } from '../FieldValue';
import type { PublicField } from '../types';

function field(type: string, value: unknown, label: string): PublicField {
  return { key: 'k', label, type: type as PublicField['type'], value, visibility: 'public' };
}

function html(f: PublicField, resolveImageUrl?: (id: string) => string | null) {
  const { container } = render(<FieldValue field={f} resolveImageUrl={resolveImageUrl} />);
  return container.innerHTML;
}

const LINK_ATTRS = 'rel="noopener noreferrer nofollow" target="_blank"';

describe('FieldValue conformance vectors', () => {
  it('field-value-001 url renders as a link with protocol stripped and security attributes', () => {
    expect(html(field('url', 'https://example.com', 'Website'))).toBe(
      `<a class="rp-field__link" href="https://example.com" ${LINK_ATTRS}>example.com</a>`,
    );
  });

  it('field-value-002 empty text renders nothing', () => {
    expect(html(field('text', '', 'Name'))).toBe('');
  });

  it('field-value-003 email renders as plain text', () => {
    expect(html(field('email', 'user@example.com', 'Email'))).toBe(
      '<span class="rp-field__text">user@example.com</span>',
    );
  });

  it('field-value-004 phone renders as plain text', () => {
    expect(html(field('phone', '+1-555-1234', 'Phone'))).toBe('<span class="rp-field__text">+1-555-1234</span>');
  });

  it('field-value-005 boolean true renders Yes', () => {
    expect(html(field('boolean', true, 'Active'))).toBe('<span class="rp-field__text">Yes</span>');
  });

  it('field-value-006 boolean false renders No', () => {
    expect(html(field('boolean', false, 'Active'))).toBe('<span class="rp-field__text">No</span>');
  });

  it('field-value-007 multi_select renders a tag list', () => {
    expect(html(field('multi_select', ['Option A', 'Option B'], 'Tags'))).toBe(
      '<ul class="rp-field__tags"><li class="rp-field__tag">Option A</li><li class="rp-field__tag">Option B</li></ul>',
    );
  });

  it('field-value-008 empty multi_select renders nothing', () => {
    expect(html(field('multi_select', [], 'Tags'))).toBe('');
  });

  it('field-value-009 image uses the resolver, alt text and class', () => {
    const seen: string[] = [];
    const { container } = render(
      <FieldValue
        field={field('image', 'attachment-123', 'Profile Photo')}
        resolveImageUrl={(id) => {
          seen.push(id);
          return 'https://cdn.example.com/img/attachment-123.jpg';
        }}
      />,
    );
    expect(seen).toEqual(['attachment-123']);
    const img = container.querySelector('img')!;
    expect(container.children).toHaveLength(1);
    expect(img.className).toBe('rp-field__image');
    expect(img.getAttribute('src')).toBe('https://cdn.example.com/img/attachment-123.jpg');
    expect(img.getAttribute('alt')).toBe('Profile Photo');
  });

  it('field-value-010 image with a null resolver result renders nothing', () => {
    expect(html(field('image', 'missing-id', 'Photo'), () => null)).toBe('');
  });

  it('field-value-011 address parts are comma separated', () => {
    expect(
      html(field('address', { line1: '123 Main St', city: 'Springfield', country: 'USA' }, 'Address')),
    ).toBe('<span class="rp-field__text">123 Main St, Springfield, USA</span>');
  });

  it('field-value-012 empty address renders nothing', () => {
    expect(
      html(
        field(
          'address',
          { line1: '', line2: '', city: '', region: '', postalCode: '', country: '' },
          'Address',
        ),
      ),
    ).toBe('');
  });

  it('field-value-013 markdown renders as pre-wrapped text', () => {
    expect(html(field('markdown', '# Hello\nWorld', 'Bio'))).toBe('<p class="rp-field__prose"># Hello\nWorld</p>');
  });

  it('field-value-014 textarea renders as pre-wrapped text', () => {
    expect(html(field('textarea', 'Line 1\nLine 2', 'Notes'))).toBe('<p class="rp-field__prose">Line 1\nLine 2</p>');
  });

  it('field-value-015 delivery value in_person maps to its label', () => {
    expect(html(field('text', 'in_person', 'Delivery'))).toBe('<span class="rp-field__text">In person</span>');
  });

  it('field-value-016 unmapped delivery value renders as is', () => {
    expect(html(field('text', 'custom-value', 'Delivery'))).toBe(
      '<span class="rp-field__text">custom-value</span>',
    );
  });

  it('field-value-017 null text value renders nothing', () => {
    expect(html(field('text', null, 'Optional'))).toBe('');
  });

  it('field-value-018 undefined text value renders nothing', () => {
    expect(html(field('text', undefined, 'Optional'))).toBe('');
  });

  it('field-value-019 date renders as raw text', () => {
    expect(html(field('date', '2026-01-15', 'Start Date'))).toBe('<span class="rp-field__text">2026-01-15</span>');
  });

  it('field-value-020 select renders as raw text', () => {
    expect(html(field('select', 'option-a', 'Status'))).toBe('<span class="rp-field__text">option-a</span>');
  });

  it('field-value-021 http protocol is stripped from the display text only', () => {
    expect(html(field('url', 'http://example.com', 'Website'))).toBe(
      `<a class="rp-field__link" href="http://example.com" ${LINK_ATTRS}>example.com</a>`,
    );
  });

  it('field-value-022 url without a protocol is shown unchanged', () => {
    expect(html(field('url', 'example.com/path', 'Website'))).toBe(
      `<a class="rp-field__link" href="example.com/path" ${LINK_ATTRS}>example.com/path</a>`,
    );
  });

  it('field-value-023 image without a resolver renders nothing', () => {
    expect(html(field('image', 'attachment-1', 'Photo'))).toBe('');
  });

  it('field-value-024 address skips absent parts', () => {
    expect(html(field('address', { line1: '123 Main St', region: 'CA', postalCode: '90210' }, 'Address'))).toBe(
      '<span class="rp-field__text">123 Main St, CA, 90210</span>',
    );
  });

  it('field-value-025 empty email renders an empty span', () => {
    expect(html(field('email', '', 'Email'))).toBe('<span class="rp-field__text"></span>');
  });

  it('field-value-026 null phone renders an empty span', () => {
    expect(html(field('phone', null, 'Phone'))).toBe('<span class="rp-field__text"></span>');
  });

  it('field-value-027 markdown is escaped, never HTML', () => {
    const { container } = render(<FieldValue field={field('markdown', '<script>alert(1)</script>', 'Bio')} />);
    expect(container.innerHTML).toBe('<p class="rp-field__prose">&lt;script&gt;alert(1)&lt;/script&gt;</p>');
    expect(container.querySelector('script')).toBeNull();
  });

  it('field-value-028 boolean is a truthiness test: the string "false" renders Yes', () => {
    expect(html(field('boolean', 'false', 'Active'))).toBe('<span class="rp-field__text">Yes</span>');
  });

  it('field-value-029 null boolean renders No', () => {
    expect(html(field('boolean', null, 'Active'))).toBe('<span class="rp-field__text">No</span>');
  });

  it('field-value-030 javascript: url keeps its text but its href cannot run script', () => {
    const { container } = render(<FieldValue field={field('url', 'javascript:alert(1)', 'Website')} />);
    const a = container.querySelector('a.rp-field__link') as HTMLAnchorElement;
    expect(a).not.toBeNull();
    expect(a.getAttribute('rel')).toBe('noopener noreferrer nofollow');
    expect(a.getAttribute('target')).toBe('_blank');
    expect(a.textContent).toBe('javascript:alert(1)');
    // React 19 swaps a javascript: href for a stub that throws instead of running the payload.
    expect(a.getAttribute('href')).not.toBe('javascript:alert(1)');
    expect(a.getAttribute('href')).toContain('React has blocked a javascript: URL');
  });

  it('field-value-031 empty url renders nothing', () => {
    expect(html(field('url', '', 'Website'))).toBe('');
  });

  it('field-value-032 empty markdown renders an empty paragraph', () => {
    expect(html(field('markdown', '', 'Bio'))).toBe('<p class="rp-field__prose"></p>');
  });

  it('field-value-033 null textarea renders an empty paragraph', () => {
    expect(html(field('textarea', null, 'Notes'))).toBe('<p class="rp-field__prose"></p>');
  });

  it('field-value-034 unknown type renders as text', () => {
    expect(html(field('unrecognized', 'abc', 'Other'))).toBe('<span class="rp-field__text">abc</span>');
  });

  it('field-value-035 protocol stripping is case sensitive', () => {
    expect(html(field('url', 'HTTPS://Example.com', 'Website'))).toBe(
      `<a class="rp-field__link" href="HTTPS://Example.com" ${LINK_ATTRS}>HTTPS://Example.com</a>`,
    );
  });
});

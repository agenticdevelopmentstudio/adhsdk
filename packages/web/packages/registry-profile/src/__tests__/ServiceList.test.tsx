import { describe, expect, it } from 'vitest';
import { render } from '@testing-library/react';
import { ServiceList } from '../ServiceList';
import type { PublicService } from '../types';

function svc(over: Partial<PublicService> & { title: string }): PublicService {
  return {
    description: '',
    pricingModel: '',
    priceMin: null,
    priceMax: null,
    currency: 'USD',
    unit: '',
    deliveryMode: '',
    ...over,
  };
}

function price(over: Partial<PublicService> & { title: string }): string {
  const { container } = render(<ServiceList services={[svc(over)]} />);
  return container.querySelector('.rp-service__price')!.textContent!;
}

describe('ServiceList conformance vectors', () => {
  const web = svc({
    title: 'Web Design',
    description: 'Custom website design',
    pricingModel: 'hourly',
    priceMin: 75,
    priceMax: 150,
  });

  it('service-list-001 renders section, heading and list', () => {
    const { container } = render(<ServiceList services={[web]} />);
    const section = container.querySelector('section.rp-services')!;
    expect(section).not.toBeNull();
    expect(section.querySelector('h2.rp-services__heading')!.textContent).toBe('Services');
    expect(section.querySelector('ul.rp-services__list')).not.toBeNull();
    expect(section.querySelectorAll('ul.rp-services__list > li')).toHaveLength(1);
  });

  it('service-list-002 shows title, description and a priced range with suffix', () => {
    const { container } = render(<ServiceList services={[web]} />);
    expect(container.querySelector('h3')!.textContent).toBe('Web Design');
    expect(container.querySelector('.rp-service__description')!.textContent).toBe('Custom website design');
    expect(container.querySelector('.rp-service__price')!.textContent).toBe('$75–$150 per hour');
  });

  it('service-list-003 free', () => {
    expect(price({ title: 'Consultation', pricingModel: 'free' })).toBe('Free');
  });

  it('service-list-004 barter', () => {
    expect(price({ title: 'Trade Services', pricingModel: 'barter' })).toBe('Trade or barter');
  });

  it('service-list-005 rate on request', () => {
    expect(price({ title: 'Custom Rate', pricingModel: 'hourly' })).toBe('Rate on request');
  });

  it('service-list-006 null description renders no description paragraph', () => {
    const { container } = render(
      <ServiceList services={[svc({ title: 'Service Name', description: null as unknown as string })]} />,
    );
    expect(container.querySelector('.rp-service__description')).toBeNull();
  });

  it('service-list-007 empty services renders nothing', () => {
    const { container } = render(<ServiceList services={[]} />);
    expect(container.innerHTML).toBe('');
  });

  it('service-list-008 renders only semantic elements', () => {
    const { container } = render(
      <ServiceList services={[web, svc({ title: 'Other', pricingModel: 'free', description: 'd' })]} />,
    );
    const tags = new Set(Array.from(container.querySelectorAll('*')).map((e) => e.tagName.toLowerCase()));
    for (const t of tags) expect(['section', 'h2', 'ul', 'li', 'h3', 'p']).toContain(t);
  });

  it('service-list-009 equal bounds render a single value', () => {
    expect(price({ title: 'Equal Bound', pricingModel: 'hourly', priceMin: 100, priceMax: 100 })).toBe(
      '$100 per hour',
    );
  });

  it('service-list-010 min only', () => {
    expect(price({ title: 'Min Only', pricingModel: 'hourly', priceMin: 50 })).toBe('$50 per hour');
  });

  it('service-list-011 max only', () => {
    expect(price({ title: 'Max Only', pricingModel: 'hourly', priceMax: 200 })).toBe('$200 per hour');
  });

  it('service-list-012 per_job suffix', () => {
    expect(price({ title: 'Job Based', pricingModel: 'per_job', priceMin: 300 })).toBe('$300 per job');
  });

  it('service-list-013 per_deliverable suffix', () => {
    expect(price({ title: 'Deliverable Based', pricingModel: 'per_deliverable', priceMin: 500 })).toBe(
      '$500 per deliverable',
    );
  });

  it('service-list-014 subscription suffix', () => {
    expect(price({ title: 'Subscription Based', pricingModel: 'subscription', priceMin: 20 })).toBe(
      '$20 per month',
    );
  });

  it('service-list-015 unknown pricing model has no suffix', () => {
    expect(price({ title: 'Unknown Model', pricingModel: 'quote_only', priceMin: 40 })).toBe('$40');
  });

  it('service-list-016 a zero bound is present, not absent', () => {
    expect(price({ title: 'Zero Min', pricingModel: 'hourly', priceMin: 0 })).toBe('$0 per hour');
  });

  it('service-list-017 empty description renders no description paragraph', () => {
    const { container } = render(
      <ServiceList services={[svc({ title: 'Empty Description', description: '', pricingModel: 'free' })]} />,
    );
    expect(container.querySelector('.rp-service__description')).toBeNull();
  });
});

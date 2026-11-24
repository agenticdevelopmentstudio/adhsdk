import { describe, expect, it } from "vitest";
import character from "@character/character.json";
import rig from "@character/rig.json";
import poses from "@character/poses.json";
import timelines from "@character/timelines.json";
import behavior from "@character/behavior.json";
import sayings from "@character/sayings.json";
import { loadConfig } from "../config/load";
import { createEngine } from "../engine";
import { createSvgRenderer, renderToString } from "./svg";

const config = loadConfig({ character, rig, poses, timelines, behavior, sayings });

describe("renderToString", () => {
  it("avatar-engine-render-005: emits a 400x400 viewBox and one path per display item", () => {
    const list = createEngine({ config, seed: 1 }).tick(0);
    const svg = renderToString(config, list);
    expect(svg).toContain('viewBox="0 0 400 400"');
    expect(svg.match(/<path /g) ?? []).toHaveLength(list.length);
  });

  it("avatar-engine-render-006: writes matrix() in the a,b,c,d,e,f order", () => {
    const list = createEngine({ config, seed: 1 }).tick(0).map((i) => ({
      ...i, m: [1, 2, 3, 4, 5, 6] as const,
    }));
    expect(renderToString(config, list)).toContain("matrix(1,2,3,4,5,6)");
  });

  it("avatar-engine-render-007: strokes unfilled shapes and fills filled ones", () => {
    const list = createEngine({ config, seed: 1 }).tick(0);
    const svg = renderToString(config, list);
    const strokeCount = (svg.match(/stroke="#/g) ?? []).length;
    const fillCount = (svg.match(/fill="#/g) ?? []).length;
    expect(strokeCount).toBe(list.filter((i) => !i.paint.fill).length);
    expect(fillCount).toBe(list.filter((i) => i.paint.fill).length);
  });

  it("avatar-engine-render-008: carries the config's stroke style, not a stylesheet", () => {
    const svg = renderToString(config, createEngine({ config, seed: 1 }).tick(0));
    expect(svg).toContain('stroke-linecap="round"');
    expect(svg).toContain('stroke-linejoin="round"');
    expect(svg).not.toContain("<style");
  });

  it("avatar-engine-render-009: escapes nothing it does not need to and stays stable across renders", () => {
    const list = createEngine({ config, seed: 1 }).tick(0);
    expect(renderToString(config, list)).toBe(renderToString(config, list));
  });
});

// `createSvgRenderer` is the half of this file that actually runs in the product,
// and `renderToString` cannot cover it: they share no code, and the claim that
// distinguishes the renderer — "creates nodes once, then only ever writes
// attributes" — is not observable in a string at all. The suite runs
// `environment: "node"` (see `vitest.config.ts`), so the document is a fake.
// Three methods is genuinely all the renderer calls, which is why a jsdom
// dependency would be a lot of machinery to prove less.

interface FakeEl {
  tag: string;
  attrs: Record<string, string>;
  children: FakeEl[];
  setAttribute(name: string, value: string): void;
  appendChild(child: FakeEl): FakeEl;
  replaceChildren(...kids: FakeEl[]): void;
}

const fakeEl = (tag: string): FakeEl => {
  const node: FakeEl = {
    tag,
    attrs: {},
    children: [],
    setAttribute(name, value) { node.attrs[name] = value; },
    appendChild(child) { node.children.push(child); return child; },
    replaceChildren(...kids) { node.children = kids; },
  };
  return node;
};

// The cast says "structurally a Document as far as this one function is
// concerned". A real `Document` has several hundred other members and the
// renderer touches none of them — asserting that is the point of the test.
const fakeDoc = (): { doc: Document; created: FakeEl[] } => {
  const created: FakeEl[] = [];
  return {
    doc: {
      createElementNS(_ns: string, tag: string): FakeEl {
        const node = fakeEl(tag);
        created.push(node);
        return node;
      },
    } as unknown as Document,
    created,
  };
};

const snapshot = (root: FakeEl): string =>
  JSON.stringify(root.children.map((c) => [c.attrs.d, c.attrs.transform, c.attrs.opacity]));

describe("createSvgRenderer", () => {
  it("avatar-engine-render-010: creates one <path> per item on the first frame, and none on any frame after", () => {
    const engine = createEngine({ config, seed: 1 });
    const { doc, created } = fakeDoc();
    const r = createSvgRenderer(config, doc);
    const root = r.element as unknown as FakeEl;

    r.render(engine.tick(0));
    const n = root.children.length;
    expect(n).toBeGreaterThan(0);
    expect(created).toHaveLength(n + 1); // every path, plus the <svg> itself
    const first = [...root.children];

    for (let t = 1 / 60; t <= 3; t += 1 / 60) r.render(engine.tick(t));

    // Identity, not just count: Plan B swaps this file for CAShapeLayer on the
    // premise that the node set and its paint order are fixed after frame one
    // (Task 12's rule 2). A renderer that rebuilt the tree would still produce
    // the right picture here and be wrong about the thing that is being relied on.
    expect(created).toHaveLength(n + 1);
    expect(root.children).toEqual(first);
  });

  it("rewrites the attributes of those same nodes as the animation runs", () => {
    const engine = createEngine({ config, seed: 1 });
    const { doc } = fakeDoc();
    const r = createSvgRenderer(config, doc);
    const root = r.element as unknown as FakeEl;

    r.render(engine.tick(0));
    const before = snapshot(root);
    r.render(engine.tick(2));

    // The other half of the claim above, and what stops that test from passing on
    // a renderer that creates its nodes and then does nothing forever.
    expect(snapshot(root)).not.toBe(before);
    expect(root.attrs.viewBox).toBe("0 0 400 400");
  });

  it("avatar-engine-render-011: forgets everything on destroy", () => {
    const engine = createEngine({ config, seed: 1 });
    const { doc, created } = fakeDoc();
    const r = createSvgRenderer(config, doc);
    const root = r.element as unknown as FakeEl;

    r.render(engine.tick(0));
    const n = root.children.length;
    r.destroy();
    expect(root.children).toHaveLength(0);

    // A destroy that emptied the element but kept the id -> node map would leave
    // the renderer holding elements attached to nothing, and the next render
    // would write into the void — a blank avatar with no error anywhere.
    r.render(engine.tick(0));
    expect(root.children).toHaveLength(n);
    expect(created).toHaveLength(2 * n + 1);
  });

  it("avatar-engine-render-012: paints exactly what renderToString writes, attribute for attribute", () => {
    // The two render paths now share one attribute source, and this is what
    // holds them there. It is the one property the file cares about that neither
    // describe block above can see: each tests its own path against its own
    // expectations, so a paint attribute added to one path and not the other
    // leaves every other test in this file green while the live avatar and the
    // menu-bar still render diverge.
    const list = createEngine({ config, seed: 1 }).tick(0);
    const { doc } = fakeDoc();
    const r = createSvgRenderer(config, doc);
    const root = r.element as unknown as FakeEl;
    r.render(list);

    const fromString = [...renderToString(config, list).matchAll(/<path ([^>]*)\/>/g)]
      .map((m) => Object.fromEntries(
        [...m[1]!.matchAll(/([\w-]+)="([^"]*)"/g)].map((a) => [a[1]!, a[2]!]),
      ));

    expect(fromString).toHaveLength(root.children.length);
    for (let i = 0; i < fromString.length; i += 1) {
      expect(fromString[i]).toEqual(root.children[i]!.attrs);
    }
    // Both branches are actually exercised, so the agreement above is not the
    // agreement of two paths that only ever saw stroked shapes.
    expect(list.some((i) => i.paint.fill)).toBe(true);
    expect(list.some((i) => !i.paint.fill)).toBe(true);
  });
});

describe("avatar-engine-render conformance vectors without a web counterpart", () => {
  it("avatar-engine-render-014: carries the item alpha as opacity, never in the ink", () => {
    const list = createEngine({ config, seed: 1 }).tick(0).map((i) => ({
      ...i, paint: { ...i.paint, alpha: 0.5, ink: "#abcdef" },
    }));
    const svg = renderToString(config, list);
    const paths = [...svg.matchAll(/<path ([^>]*)\/>/g)].map((m) => m[1]!);
    expect(paths).toHaveLength(list.length);
    for (const p of paths) {
      expect(p).toContain('opacity="0.5"');
      expect(p).toMatch(/(fill|stroke)="#abcdef"/);
      expect(p).not.toMatch(/#[0-9a-f]{8}"/);
    }
  });

  // Swift-only bridges (PlatformShims.swift); the web has no CGAffineTransform, CGColor or CGPath.
  it.skip("avatar-engine-render-001: CGAffineTransform bridge matches Mat.apply (Swift-only)", () => {});
  it.skip("avatar-engine-render-002: live environment reads reduce motion (Swift-only, needs AppKit)", () => {});
  it.skip("avatar-engine-render-003: CGPath.avatarItem builds the display item path (Swift-only)", () => {});
  it.skip("avatar-engine-render-004: StrokeStyle maps onto CoreGraphics caps and joins (Swift-only)", () => {});
  it.skip("avatar-engine-render-013: CGColor.avatarInk parses hex (Swift-only)", () => {});
});

// Every test in packages/data/src lives under a `__tests__/` sibling — no exceptions.
// One `it` per row of cookbook/adh/hub/personas/conformance-test-vectors.md, titled by its trace id.
// The first ten vectors describe the Swift `PersonasModule` (facet navigation, forms, Codable
// decode); the web package has no equivalent module, so they are skipped here and covered by
// PersonasModuleTests.swift.
import { describe, expect, it } from "vitest";
import { canDemoChat } from "../canned";
import { parseChatStatus, resolveChatStatus } from "../chat-status";

const SWIFT_ONLY = "Swift PersonasModule behavior; the web package has no equivalent, covered by PersonasModuleTests.swift";

describe("personas conformance vectors", () => {
  it.skip(`testRootLevelListsPersonas — ${SWIFT_ONLY}`, () => {});
  it.skip(`testPersonaChildIsFacetRail — ${SWIFT_ONLY}`, () => {});
  it.skip(`testIdentityFormValuesAndSave — ${SWIFT_ONLY}`, () => {});
  it.skip(`testIdentityFormValidatesSlug — ${SWIFT_ONLY}`, () => {});
  it.skip(`testIdentityDeleteAction — ${SWIFT_ONLY}`, () => {});
  it.skip(`testBlankTextBecomesNilOnSave — ${SWIFT_ONLY}`, () => {});
  it.skip(`testLLMSaveClearsModelWhenServiceHasNoSuchModel — ${SWIFT_ONLY}`, () => {});
  it.skip(`testUnsupportedFacetsShowNotice — ${SWIFT_ONLY}`, () => {});
  it.skip(`testCreateSpecAndPerform — ${SWIFT_ONLY}`, () => {});
  it.skip("testPersonaDecodesFromWebJSON — Swift Codable decode; web personaFromWire keeps userId/ownerKind/ownerId in PersonaRow", () => {});

  it('canned.test.ts "does not compile the ink — a syntax error still advertises a demo"', () => {
    expect(canDemoChat({ enabled: true, ink: { source: "* [unclosed\n", signInLine: "x" } })).toBe(true);
  });

  it('canned.test.ts "is false for a parked script and for no config at all"', () => {
    expect(
      canDemoChat({
        enabled: false,
        script: { intro: ["hi"], seeded: [], fallbacks: [], onExhausted: "reshuffle" },
      }),
    ).toBe(false);
    expect(canDemoChat(null)).toBe(false);
  });

  it('chat-status.test.ts "drops a malformed words/icons field to an empty list rather than substituting the default"', () => {
    expect(parseChatStatus({ words: 7 })).toEqual({ words: [], icons: [] });
  });

  it('chat-status.test.ts "unions rows tagged with the kind with untagged rows that fit anything"', () => {
    const raw = {
      words: [
        { tags: ["search"], present: "digging", past: "dug" },
        { tags: ["think"], present: "pondering", past: "pondered" },
        { tags: [], present: "working", past: "worked" },
      ],
      icons: [
        { tags: ["search"], frames: ["a", "b"] },
        { tags: ["search"], frames: ["c"] },
        { tags: [], frames: ["o"] },
      ],
    };
    const r = resolveChatStatus(raw, "search");
    expect(r.words.map((w) => w.present)).toEqual(["digging", "working"]);
    expect(r.frames).toEqual(["a", "b"]);
  });
});

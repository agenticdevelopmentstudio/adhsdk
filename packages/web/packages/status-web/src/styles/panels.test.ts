import { describe, it, expect } from "vitest";
import { readFileSync } from "node:fs";
import { resolve } from "node:path";

// An animated `filter` repaints on every frame, and "ok" and "warn" are the
// states a status page is left open in. Their glows must stay fixed.
const css = readFileSync(resolve(__dirname, "panels.css"), "utf8").replace(/\/\*[\s\S]*?\*\//g, "");

function declarations(selector: string): string {
  const rules = [...css.matchAll(/([^{}]+)\{([^{}]*)\}/g)]
    .filter(([, selectors]) => selectors.split(",").some((s) => s.trim() === selector))
    .map(([, , body]) => body);
  expect(rules.length).toBeGreaterThan(0);
  return rules.join(";");
}

describe("panels.css indicator glows", () => {
  it.each([".adh-indicator-ok", ".adh-indicator-warn"])("%s has a fixed glow and no animation", (selector) => {
    const body = declarations(selector);
    expect(body).toMatch(/filter\s*:\s*drop-shadow\(/);
    expect(body).not.toMatch(/animation/);
  });
});

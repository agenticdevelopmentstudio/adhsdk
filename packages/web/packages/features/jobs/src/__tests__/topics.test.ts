// The two topic sets (vectors jobs-001, jobs-002) and the plain-data `./topics` entry (jobs-003).
import { readFileSync } from "node:fs";
import { join } from "node:path";
import { describe, expect, it } from "vitest";

import { jobsProductAdminTopics, jobsTopics } from "../jobs-topics";

const ids = (topics: readonly { id: string }[]) => topics.map((t) => t.id);

describe("jobsTopics (vector jobs-001)", () => {
  it("is Jobs, Templates and Environments in order", () => {
    expect(jobsTopics.map((t) => [t.label, t.href])).toEqual([
      ["Jobs", "jobs"],
      ["Templates", "jobs/templates"],
      ["Environments", "jobs/environments"],
    ]);
  });

  it("has unique ids", () => {
    expect(new Set(ids(jobsTopics)).size).toBe(jobsTopics.length);
  });
});

describe("jobsProductAdminTopics (vector jobs-002)", () => {
  it("is Status and Templates in order, under the console's /admin", () => {
    expect(jobsProductAdminTopics.map((t) => [t.label, t.href])).toEqual([
      ["Status", "/admin/jobs"],
      ["Templates", "/admin/jobs/templates"],
    ]);
  });

  it("has unique ids", () => {
    expect(new Set(ids(jobsProductAdminTopics)).size).toBe(jobsProductAdminTopics.length);
  });
});

describe("the topics entry (vector jobs-003)", () => {
  const source = readFileSync(join(__dirname, "..", "jobs-topics.ts"), "utf8");

  it("imports nothing", () => {
    expect(source).not.toMatch(/^\s*import\s/m);
    expect(source).not.toMatch(/from\s+["']react/);
  });

  it("is not a client module", () => {
    expect(source).not.toMatch(/["']use client["']/);
  });

  it("is the package's ./topics export", () => {
    const pkg = JSON.parse(readFileSync(join(__dirname, "..", "..", "package.json"), "utf8")) as {
      exports: Record<string, { development?: string }>;
    };
    expect(pkg.exports["./topics"]?.development).toBe("./src/jobs-topics.ts");
  });
});

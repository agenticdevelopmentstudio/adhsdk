import { describe, expect, it } from "vitest";
import { ADMIN_PANES } from "../adminPanes";
import {
  ADMIN_CATEGORIES,
  ADMIN_TOPICS,
  adminCategoryOf,
  adminTopicsIn,
  isAdminTopicId,
} from "../adminTopics";
import { INVITATION_TOPICS } from "../panes/InvitationsPane";

// Case-insensitive, so "AI Processing" sorts after "Access" the way a reader expects.
const isAlphabetical = (labels: readonly string[]): boolean =>
  labels.every((l, i) => i === 0 || labels[i - 1].localeCompare(l, "en", { sensitivity: "base" }) <= 0);

describe("every admin list is alphabetical", () => {
  it("the categories", () => {
    expect(isAlphabetical(ADMIN_CATEGORIES.map((c) => c.label))).toBe(true);
  });

  it("the sections, overall and within each category", () => {
    expect(isAlphabetical(ADMIN_TOPICS.map((t) => t.label))).toBe(true);
    for (const c of ADMIN_CATEGORIES) {
      expect(isAlphabetical(adminTopicsIn(c.id).map((t) => t.label))).toBe(true);
    }
  });

  it("the Invitations pane's sub-topics", () => {
    expect(isAlphabetical(INVITATION_TOPICS.map((t) => t.label))).toBe(true);
  });
});

describe("ADMIN_CATEGORIES", () => {
  it("files every section under a real category, and leaves no category empty", () => {
    const ids = new Set(ADMIN_CATEGORIES.map((c) => c.id));
    for (const t of ADMIN_TOPICS) expect(ids.has(t.category)).toBe(true);
    for (const c of ADMIN_CATEGORIES) expect(adminTopicsIn(c.id).length).toBeGreaterThan(0);
  });

  it("reads a section's category off its id", () => {
    expect(adminCategoryOf("reserved-identifiers")).toBe("configuration");
    expect(adminCategoryOf("audit")).toBe("access");
  });
});

describe("ADMIN_TOPICS / ADMIN_PANES", () => {
  it("gives every topic a pane", () => {
    for (const topic of ADMIN_TOPICS) {
      expect(ADMIN_PANES[topic.id]).toBeDefined();
    }
  });

  it("has no pane orphaned from a topic", () => {
    const topicIds = new Set(ADMIN_TOPICS.map((t) => t.id));
    for (const id of Object.keys(ADMIN_PANES)) {
      expect(topicIds.has(id as never)).toBe(true);
    }
  });
});

describe("AI processing topics", () => {
  it("registers ai-nodes and processing-configs, each with a pane", () => {
    for (const id of ["ai-nodes", "processing-configs"]) {
      expect(isAdminTopicId(id)).toBe(true);
      expect(ADMIN_TOPICS.find((t) => t.id === id)?.label).toBeTruthy();
      expect(ADMIN_PANES[id as keyof typeof ADMIN_PANES]).toBeDefined();
    }
  });
});

describe("isAdminTopicId", () => {
  it("accepts every real topic id", () => {
    for (const topic of ADMIN_TOPICS) {
      expect(isAdminTopicId(topic.id)).toBe(true);
    }
  });

  it("rejects an id that isn't a topic", () => {
    expect(isAdminTopicId("nope")).toBe(false);
  });
});

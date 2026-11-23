import { useState } from "react";
import {
  Users,
  Mail,
  Flag,
  Boxes,
  ScrollText,
  MessageSquare,
  MessageCircle,
  Shield,
  UserCheck,
  LockKeyhole,
  Cable,
  FolderSync,
  Gauge,
  Receipt,
  ChartLine,
  ChartPie,
  KeyRound,
  Cpu,
  SlidersHorizontal,
  UserCog,
  BrainCircuit,
  MessagesSquare,
  Settings2,
  Wallet,
  Eye,
  Siren,
  LifeBuoy,
  FileSearch,
  type LucideIcon,
} from "lucide-react";

// Named `adminTopics.ts`, not the bare `topics.ts` the admin site's old admin-shell.tsx would
// suggest: `abstractr` already has `topics`/`topics.tsx` claimed by three other feature packages
// (adh/help, adh-products, games) and blocks a fourth generic collision. The distinctive names
// this repo's newer topic-list modules use (registryTopics.tsx, entryTopics.tsx, heldTopics.ts,
// projectTopics.tsx) are the convention to follow going forward, not the older bare name.

/** The categories the admin console's sections are filed under — the rail's FIRST level. Ids are
 *  never route segments: a URL names only the section, and the category is read off it
 *  ({@link adminCategoryOf}), so no section's URL changed when the categories arrived. */
export type AdminCategoryId =
  | "access"
  | "ai-processing"
  | "communication"
  | "configuration"
  | "usage-costs";

/** The stable ids the admin console's sections have always used as route segments
 *  (`/users`, `/feature-flags`, …) — carried over unchanged from the site's own
 *  `admin-shell.tsx` (now this module) so no existing bookmark or link breaks. */
export type AdminTopicId =
  | "users"
  | "invitations"
  | "feature-flags"
  | "server-bags"
  | "sync"
  | "audit"
  | "messaging"
  | "feedback"
  | "authentication"
  | "llm-providers"
  | "usage"
  | "costs"
  | "usage-overview"
  | "breakdown"
  | "reserved-identifiers"
  | "ai-nodes"
  | "processing-configs"
  | "operator-access"
  | "operators"
  | "security"
  | "support-grants"
  | "break-glass"
  | "support-access";

/** One category row of the rail's first level. */
export type AdminCategory = {
  id: AdminCategoryId;
  label: string;
  description: string;
  icon: LucideIcon;
};

/** One admin section. `id` doubles as the route segment on the admin site (`/<id>`, one
 *  app/(admin)/<id>/page.tsx each). `category` files it under one {@link AdminCategory} — the
 *  rail's second level. */
export type AdminTopic = {
  id: AdminTopicId;
  category: AdminCategoryId;
  label: string;
  description: string;
  icon: LucideIcon;
};

// Seventeen sections in one flat rail was too many to scan, so the rail is two levels: these
// categories, then the sections filed under the chosen one. Alphabetical by label — and
// adminTopics.test.ts fails on any list here that is not, so a new entry cannot drift the order.
export const ADMIN_CATEGORIES: AdminCategory[] = [
  {
    id: "access",
    label: "Access",
    description: "Accounts, operators, invitations, your sign-in security, and the audit trails",
    icon: UserCog,
  },
  {
    id: "ai-processing",
    label: "AI Processing",
    description: "Processing nodes, their configs, and LLM providers",
    icon: BrainCircuit,
  },
  {
    id: "communication",
    label: "Communication",
    description: "Messages sent and feedback received",
    icon: MessagesSquare,
  },
  {
    id: "configuration",
    label: "Configuration",
    description: "Sign-in, flags, config values, sync and held names",
    icon: Settings2,
  },
  {
    id: "usage-costs",
    label: "Usage & Costs",
    description: "Traffic, limits, and what the platform costs to run",
    icon: Wallet,
  },
];

// The admin console's sections, alphabetical by label (the rail shows each category's members in
// this order). There is deliberately no "Dashboard" row: the bare landing IS the stack's topic
// overview, so a Dashboard topic would only point back at the overview it lives on.
export const ADMIN_TOPICS: AdminTopic[] = [
  {
    id: "ai-nodes",
    category: "ai-processing",
    label: "AI Nodes",
    description: "Deployed processing nodes, their config and logs",
    icon: Cpu,
  },
  {
    id: "audit",
    category: "access",
    label: "Audit",
    description: "Access & role change history",
    icon: ScrollText,
  },
  {
    id: "authentication",
    category: "configuration",
    label: "Authentication",
    description: "Providers and access management",
    icon: Shield,
  },
  {
    id: "break-glass",
    category: "access",
    label: "Break Glass",
    description: "Open a support grant at once, in an emergency, with an attestation",
    icon: Siren,
  },
  {
    id: "breakdown",
    category: "usage-costs",
    label: "Breakdown",
    description: "Usage and cost per organization, ecosystem, user or persona",
    icon: ChartPie,
  },
  {
    id: "costs",
    category: "usage-costs",
    label: "Costs",
    description: "Run rate, cost items, and the prices behind them",
    icon: Receipt,
  },
  {
    id: "feature-flags",
    category: "configuration",
    label: "Feature Flags",
    description: "Toggle platform features on and off",
    icon: Flag,
  },
  {
    id: "feedback",
    category: "communication",
    label: "Feedback",
    description: "Review user submissions",
    icon: MessageCircle,
  },
  {
    id: "invitations",
    category: "access",
    label: "Invitations",
    description: "Requests, pending, and sent invites",
    icon: Mail,
  },
  {
    id: "llm-providers",
    category: "ai-processing",
    label: "LLM Providers",
    description: "Provider-template catalog personas connect to",
    icon: Cable,
  },
  {
    id: "messaging",
    category: "communication",
    label: "Messaging",
    description: "Send and track messages",
    icon: MessageSquare,
  },
  {
    id: "operator-access",
    category: "access",
    label: "Operator Access",
    description: "Every request made with operator access, and who made it",
    icon: Eye,
  },
  {
    id: "operators",
    category: "access",
    label: "Operators",
    description: "Who can sign in to this console, and who holds admin",
    icon: UserCheck,
  },
  {
    id: "processing-configs",
    category: "ai-processing",
    label: "Processing Configs",
    description: "LLM config sets that processing jobs run on",
    icon: SlidersHorizontal,
  },
  {
    id: "reserved-identifiers",
    category: "configuration",
    label: "Reserved Identifiers",
    description: "Names held with nothing using them",
    icon: KeyRound,
  },
  {
    id: "security",
    category: "access",
    label: "Security",
    description: "Your passkeys, authenticator app and recovery codes",
    icon: LockKeyhole,
  },
  {
    id: "server-bags",
    category: "configuration",
    label: "Server Bags",
    description: "Global key → JSON config values",
    icon: Boxes,
  },
  {
    id: "support-access",
    category: "access",
    label: "Support Access Log",
    description: "Every read made under a support grant",
    icon: FileSearch,
  },
  {
    id: "support-grants",
    category: "access",
    label: "Support Grants",
    description: "Every support grant: ask for consent, see where each stands, revoke",
    icon: LifeBuoy,
  },
  {
    id: "sync",
    category: "configuration",
    label: "Sync Tables",
    description: "Per-ecosystem offline-sync table enrollment",
    icon: FolderSync,
  },
  {
    id: "usage",
    category: "usage-costs",
    label: "Usage Limits",
    description: "Metering tiers and the enforcement switch",
    icon: Gauge,
  },
  {
    id: "usage-overview",
    category: "usage-costs",
    label: "Usage Overview",
    description: "Platform traffic, time, tokens and direct cost over time",
    icon: ChartLine,
  },
  { id: "users", category: "access", label: "Users", description: "Manage accounts and roles", icon: Users },
];

/** The sections filed under one category, in rail (alphabetical) order. */
export function adminTopicsIn(category: AdminCategoryId): AdminTopic[] {
  return ADMIN_TOPICS.filter((t) => t.category === category);
}

/** The category a section is filed under — how a URL that names only the section opens the
 *  right category above it. */
export function adminCategoryOf(topicId: AdminTopicId): AdminCategoryId {
  // Every id in the union has a row (adminTopics.test.ts asserts it via ADMIN_PANES' exhaustive
  // record), so a miss is a broken table — throw, never guess a category.
  const topic = ADMIN_TOPICS.find((t) => t.id === topicId);
  if (!topic) throw new Error(`adminCategoryOf: no admin topic "${topicId}"`);
  return topic.category;
}

/**
 * The rail's category selection, for a host whose URL names only the SECTION (the admin site's
 * AdminShell).
 *
 * With a section open, its category is the one selected: read off the section, so a deep link or
 * a back button lands with the right category open. With none open, it is whichever category the
 * operator last chose — and closing a section leaves its category open, so they go back to its
 * siblings rather than the top of the rail.
 *
 * `leaveTopic` closes the open section (the host's guarded navigation to its base path) and
 * resolves to whether it did — false when the unsaved-changes guard said stay. Choosing another
 * category while a section is open has to close the section, since a section can only sit under
 * its own category; if the guard refuses, nothing moves.
 *
 * Plain component state. The admin site keeps its shell in a layout, which survives every route
 * change, so nothing has to outlive the component. (A module-level copy once did, for the hub's
 * `/admin/[[...path]]` page, which Next remounted on each route; that host is gone.)
 */
export function useAdminCategorySelection(
  topicId: AdminTopicId | null,
  leaveTopic: () => Promise<boolean>,
): { selectedId: AdminCategoryId | null; onSelect: (id: string | null) => void } {
  const [chosen, setChosen] = useState<AdminCategoryId | null>(() =>
    topicId ? adminCategoryOf(topicId) : null,
  );
  // Following the open section's category is state adjusted DURING render, React's documented
  // pattern for "reset state when a prop changes" — not an effect, which would paint one frame
  // with the stale category first. It is what keeps a section's category open once it closes.
  const [seenTopic, setSeenTopic] = useState(topicId);
  if (topicId !== seenTopic) {
    setSeenTopic(topicId);
    if (topicId) setChosen(adminCategoryOf(topicId));
  }

  const selectedId = topicId ? adminCategoryOf(topicId) : chosen;

  const onSelect = (id: string | null): void => {
    const next = id === null ? null : ADMIN_CATEGORIES.find((c) => c.id === id)?.id ?? null;
    if (topicId === null) {
      setChosen(next);
      return;
    }
    // Re-choosing the open section's own category leaves the section open.
    if (next === selectedId) return;
    void leaveTopic().then((left) => {
      if (left) setChosen(next);
    });
  };

  return { selectedId, onSelect };
}

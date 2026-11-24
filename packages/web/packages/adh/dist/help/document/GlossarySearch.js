'use client'

"use client";

// src/help/document/GlossarySearch.tsx
import { useMemo, useState, useSyncExternalStore } from "react";
import Link2 from "next/link";
import { StatCard } from "@adh-sdk/ui/blocks";
import { SearchFilterBar } from "@adh-sdk/ui/components/search-filter-bar";

// src/help/document/parts.ts
function termMatches(term, query) {
  const words = query.toLowerCase().split(/\s+/).filter(Boolean);
  if (!words.length) return true;
  const haystack = `${term.title} ${term.text}`.toLowerCase();
  return words.every((word) => haystack.includes(word));
}

// src/help/document/TermBlock.tsx
import Link from "next/link";
import { jsx, jsxs } from "react/jsx-runtime";
function TermBlock({
  term,
  href,
  anchor = false,
  arrived = false,
  children
}) {
  const name = /* @__PURE__ */ jsx("span", { dangerouslySetInnerHTML: { __html: term.titleHtml } });
  return /* @__PURE__ */ jsxs(
    "div",
    {
      id: anchor ? term.id : void 0,
      "data-arrived": arrived || void 0,
      className: "doc-term scroll-mt-6 flex flex-col gap-2 rounded-md border border-apt-border bg-apt-surface px-4 py-3.5",
      children: [
        /* @__PURE__ */ jsx("dt", { className: "text-[1.1rem] font-[650] leading-snug text-apt-gold", children: href ? /* @__PURE__ */ jsx(Link, { href, className: "underline-offset-4 hover:underline", children: name }) : name }),
        /* @__PURE__ */ jsxs("dd", { className: "flex flex-col gap-2", children: [
          term.html.map((html, i) => /* @__PURE__ */ jsx("div", { className: "doc-copy", dangerouslySetInnerHTML: { __html: html } }, i)),
          children
        ] })
      ]
    }
  );
}

// src/help/document/GlossarySearch.tsx
import { jsx as jsx2, jsxs as jsxs2 } from "react/jsx-runtime";
function subscribeToHash(changed) {
  window.addEventListener("hashchange", changed);
  window.addEventListener("popstate", changed);
  return () => {
    window.removeEventListener("hashchange", changed);
    window.removeEventListener("popstate", changed);
  };
}
function currentHash() {
  return decodeURIComponent(window.location.hash.slice(1));
}
function GlossarySearch({
  terms,
  tutorials,
  title,
  icon
}) {
  const [query, setQuery] = useState("");
  const arrived = useSyncExternalStore(subscribeToHash, currentHash, () => "");
  const shown = useMemo(() => terms.filter((term) => termMatches(term, query)), [terms, query]);
  return /* @__PURE__ */ jsx2(StatCard, { title, icon, className: "bg-apt-surface-2", children: /* @__PURE__ */ jsxs2("div", { className: "flex flex-col gap-4", children: [
    /* @__PURE__ */ jsx2(
      SearchFilterBar,
      {
        search: {
          value: query,
          onChange: setQuery,
          label: "Search the glossary",
          placeholder: "Search terms and definitions"
        }
      }
    ),
    /* @__PURE__ */ jsx2("p", { className: "font-mono text-[11px] text-apt-text-dim", "aria-live": "polite", children: shown.length === terms.length ? `${terms.length} terms` : `${shown.length} of ${terms.length} terms` }),
    shown.length ? /* @__PURE__ */ jsx2("dl", { className: "flex flex-col gap-3", "data-testid": "glossary-terms", children: shown.map((term) => /* @__PURE__ */ jsx2(TermBlock, { term, anchor: true, arrived: arrived === term.id, children: term.tutorials.length ? /* @__PURE__ */ jsxs2("p", { className: "text-sm text-apt-text-dim", children: [
      /* @__PURE__ */ jsx2("span", { className: "font-semibold text-apt-text", children: "Tutorials: " }),
      term.tutorials.map((id, i) => /* @__PURE__ */ jsxs2("span", { children: [
        i ? ", " : null,
        /* @__PURE__ */ jsx2(
          Link2,
          {
            href: tutorials[id]?.href ?? "#",
            className: "text-apt-gold underline-offset-2 hover:underline",
            children: tutorials[id]?.name ?? id
          }
        )
      ] }, id))
    ] }) : null }, term.id)) }) : /* @__PURE__ */ jsxs2("p", { className: "text-sm text-apt-text-dim", children: [
      "No term matches \u201C",
      query,
      "\u201D."
    ] })
  ] }) });
}
export {
  GlossarySearch
};
//# sourceMappingURL=GlossarySearch.js.map
'use client'

"use client";

// src/help/document/TutorialSteps.tsx
import { useCallback, useEffect, useMemo, useRef, useSyncExternalStore } from "react";
import { StatCard } from "@adh-sdk/ui/blocks";
import { Button } from "@adh-sdk/ui/components/button";
import { Checkbox } from "@adh-sdk/ui/components/checkbox";

// src/help/document/progress.ts
function progressKey(tutorialId) {
  return `adh-help:tutorial-progress:${tutorialId}`;
}
function startOf(steps) {
  return { v: 1, done: [], active: steps[0]?.id ?? null };
}
function readProgress(raw, steps) {
  if (!raw) return startOf(steps);
  try {
    const saved = JSON.parse(raw);
    if (saved?.v !== 1 || !Array.isArray(saved.done)) return startOf(steps);
    const ids = new Set(steps.flatMap((s) => [s.id, ...(s.substeps ?? []).map((sub) => sub.id)]));
    const kept = saved.done.filter((id) => typeof id === "string" && ids.has(id));
    const done = settle(steps, kept);
    const active = typeof saved.active === "string" && steps.some((s) => s.id === saved.active) ? saved.active : nextOpen(steps, done, -1);
    return { v: 1, done, active };
  } catch {
    return startOf(steps);
  }
}
function nextOpen(steps, done, from) {
  for (let k = 1; k <= steps.length; k++) {
    const step = steps[(from + k) % steps.length];
    if (step && !done.includes(step.id)) return step.id;
  }
  return null;
}
function subIds(step) {
  return (step.substeps ?? []).map((sub) => sub.id);
}
function settle(steps, done) {
  const out = [...new Set(done)];
  for (const step of steps) {
    const subs = subIds(step);
    if (!subs.length) continue;
    if (out.includes(step.id)) {
      for (const sub of subs) if (!out.includes(sub)) out.push(sub);
    } else if (subs.every((sub) => out.includes(sub))) {
      out.push(step.id);
    }
  }
  return out;
}
function stepsDone(progress, steps) {
  return steps.filter((step) => progress.done.includes(step.id)).length;
}
function toggle(progress, steps, id, checked) {
  const at = steps.findIndex((s) => s.id === id || subIds(s).includes(id));
  const step = steps[at];
  if (!step) return progress;
  const subs = subIds(step);
  const touched = id === step.id ? [step.id, ...subs] : checked ? [id] : [id, step.id];
  if (!checked) {
    return { v: 1, done: progress.done.filter((d) => !touched.includes(d)), active: step.id };
  }
  const done = settle(steps, [...progress.done, ...touched]);
  return { v: 1, done, active: done.includes(step.id) ? nextOpen(steps, done, at) : step.id };
}

// src/help/document/TutorialSteps.tsx
import { jsx, jsxs } from "react/jsx-runtime";
var memory = /* @__PURE__ */ new Map();
var listeners = /* @__PURE__ */ new Map();
function notify(key) {
  for (const listener of listeners.get(key) ?? []) listener();
}
function load(key) {
  if (memory.has(key)) return memory.get(key) ?? null;
  try {
    return window.localStorage.getItem(key);
  } catch {
    return null;
  }
}
function save(key, progress) {
  const raw = JSON.stringify(progress);
  memory.set(key, raw);
  try {
    window.localStorage.setItem(key, raw);
  } catch {
  }
  notify(key);
}
function subscribe(key, listener) {
  const set = listeners.get(key) ?? /* @__PURE__ */ new Set();
  listeners.set(key, set);
  set.add(listener);
  const fromAnotherTab = (event) => {
    if (event.key !== key) return;
    memory.set(key, event.newValue);
    listener();
  };
  window.addEventListener("storage", fromAnotherTab);
  return () => {
    set.delete(listener);
    window.removeEventListener("storage", fromAnotherTab);
  };
}
function TutorialSteps({
  tutorialId,
  steps,
  title,
  icon
}) {
  const key = progressKey(tutorialId);
  const serverProgress = useMemo(() => startOf(steps), [steps]);
  const readSaved = useMemo(() => {
    let cache = null;
    return () => {
      const raw = load(key);
      if (!cache || cache.raw !== raw) cache = { raw, value: readProgress(raw, steps) };
      return cache.value;
    };
  }, [key, steps]);
  const listen = useCallback((listener) => subscribe(key, listener), [key]);
  const progress = useSyncExternalStore(listen, readSaved, () => serverProgress);
  const follow = useRef(false);
  const rows = useRef(/* @__PURE__ */ new Map());
  const update = useCallback(
    (next, scroll) => {
      follow.current = scroll;
      save(key, next);
    },
    [key]
  );
  useEffect(() => {
    if (!follow.current || !progress.active) return;
    follow.current = false;
    rows.current.get(progress.active)?.scrollIntoView({ behavior: "smooth", block: "nearest" });
  }, [progress.active]);
  const count = stepsDone(progress, steps);
  return /* @__PURE__ */ jsx(
    StatCard,
    {
      title,
      icon,
      className: "bg-apt-surface-2",
      actions: /* @__PURE__ */ jsxs("span", { className: "flex items-center gap-3", children: [
        /* @__PURE__ */ jsxs("span", { className: "font-mono text-[11px] text-apt-text-dim", "aria-live": "polite", children: [
          count,
          " of ",
          steps.length,
          " done"
        ] }),
        /* @__PURE__ */ jsx(
          Button,
          {
            size: "sm",
            variant: "outline",
            onClick: () => update(startOf(steps), true),
            "data-testid": "tutorial-start",
            children: "Start"
          }
        )
      ] }),
      children: /* @__PURE__ */ jsx("ol", { className: "flex flex-col gap-3", "data-testid": "tutorial-steps", children: steps.map((step, i) => {
        const done = progress.done.includes(step.id);
        const active = progress.active === step.id;
        const label = `tutorial-step-${step.id}`;
        return /* @__PURE__ */ jsxs(
          "li",
          {
            ref: (el) => {
              if (el) rows.current.set(step.id, el);
              else rows.current.delete(step.id);
            },
            "aria-current": active ? "step" : void 0,
            "data-done": done || void 0,
            className: `doc-step rounded-lg border p-4 transition-colors ${active ? "border-apt-gold ring-2 ring-apt-gold/25" : "border-apt-border"}`,
            children: [
              /* @__PURE__ */ jsxs("div", { className: "flex items-start gap-3", children: [
                /* @__PURE__ */ jsx(
                  Checkbox,
                  {
                    className: "mt-1",
                    checked: done,
                    onCheckedChange: (checked) => update(toggle(progress, steps, step.id, checked), true),
                    "aria-labelledby": label,
                    "data-testid": "tutorial-step-check"
                  }
                ),
                /* @__PURE__ */ jsxs(
                  "button",
                  {
                    type: "button",
                    id: label,
                    onClick: () => update({ ...progress, active: step.id }, false),
                    className: `text-left text-[1.02rem] font-[650] leading-snug ${done ? "text-apt-text-dim line-through" : "text-apt-text"}`,
                    children: [
                      /* @__PURE__ */ jsxs("span", { className: "mr-2 font-mono text-[12px] text-apt-text-muted", children: [
                        i + 1,
                        "."
                      ] }),
                      /* @__PURE__ */ jsx("span", { dangerouslySetInnerHTML: { __html: step.titleHtml } })
                    ]
                  }
                )
              ] }),
              step.before.length || step.substeps.length || step.after.length ? /* @__PURE__ */ jsxs("div", { className: `mt-3 flex flex-col gap-3 pl-7 ${done ? "opacity-70" : ""}`, children: [
                step.before.map((html, j) => /* @__PURE__ */ jsx("div", { className: "doc-copy", dangerouslySetInnerHTML: { __html: html } }, `b${j}`)),
                step.substeps.length ? /* @__PURE__ */ jsx("ol", { className: "flex flex-col gap-2.5", "data-testid": "tutorial-substeps", children: step.substeps.map((sub, n) => {
                  const subDone = progress.done.includes(sub.id);
                  const subLabel = `tutorial-substep-${sub.id.replace("/", "-")}`;
                  return /* @__PURE__ */ jsxs("li", { "data-done": subDone || void 0, className: "doc-substep flex items-start gap-3", children: [
                    /* @__PURE__ */ jsx(
                      Checkbox,
                      {
                        className: "mt-[5px]",
                        checked: subDone,
                        onCheckedChange: (checked) => update(toggle(progress, steps, sub.id, checked), true),
                        "aria-labelledby": subLabel,
                        "data-testid": "tutorial-substep-check"
                      }
                    ),
                    /* @__PURE__ */ jsxs("div", { id: subLabel, className: `doc-copy flex-1 ${subDone ? "text-apt-text-dim line-through" : ""}`, children: [
                      /* @__PURE__ */ jsxs("span", { className: "mr-2 font-mono text-[12px] text-apt-text-muted", children: [
                        step.start + n,
                        "."
                      ] }),
                      /* @__PURE__ */ jsx("span", { dangerouslySetInnerHTML: { __html: sub.html } })
                    ] })
                  ] }, sub.id);
                }) }) : null,
                step.after.map((html, j) => /* @__PURE__ */ jsx("div", { className: "doc-copy", dangerouslySetInnerHTML: { __html: html } }, `a${j}`))
              ] }) : null
            ]
          },
          step.id
        );
      }) })
    }
  );
}
export {
  TutorialSteps
};
//# sourceMappingURL=TutorialSteps.js.map
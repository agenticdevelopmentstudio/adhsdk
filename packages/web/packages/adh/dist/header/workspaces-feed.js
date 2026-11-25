'use client'

"use client";

// src/header/workspaces-feed.tsx
import {
  createContext,
  useCallback,
  useContext,
  useEffect,
  useLayoutEffect,
  useMemo,
  useRef,
  useState
} from "react";
import { usePathname, useRouter } from "next/navigation";
import { useTokenSubject } from "@adh-sdk/auth/client";
import {
  firstWorkspacePerSlug,
  useWorkspacePreference,
  useWorkspaces,
  workspaceCompositeId,
  workspaceListLabel
} from "@adh-sdk/data";
import { siteUrl, siteProdUrl } from "@adh-sdk/adh-registry";
import {
  WorkspacesMenuProvider,
  useClientHost
} from "@adh-sdk/adh/header";
import { jsx } from "react/jsx-runtime";
var WorkspaceSelectRegistrar = createContext(() => {
});
function useRegisterWorkspaceSelect(select) {
  const register = useContext(WorkspaceSelectRegistrar);
  useLayoutEffect(() => {
    register(select);
    return () => register(null);
  }, [register, select]);
}
function SiteWorkspacesMenuProvider({
  children,
  switchBy = "preference"
}) {
  const subject = useTokenSubject();
  const signedIn = subject != null;
  const { data, isLoading, isError } = useWorkspaces({ enabled: signedIn });
  const byRoute = switchBy === "route";
  const route = useRouteSwitch(byRoute ? data : void 0);
  const pref = usePreferenceSwitch(byRoute ? void 0 : data, signedIn && !byRoute, subject);
  const feed = byRoute ? route : pref;
  const prefPending = !byRoute && pref.pending;
  const value = useMemo(
    () => ({
      workspaces: feed.workspaces,
      loading: byRoute ? !signedIn || isLoading : signedIn && !isError && (isLoading || prefPending),
      error: signedIn && isError,
      select: feed.select,
      // A preference pick records and stays put, so the menu asks no leave-this-page question.
      selectStaysOnPage: byRoute ? void 0 : true,
      everyRoute: !byRoute && signedIn ? true : void 0
    }),
    [feed.workspaces, feed.select, signedIn, isLoading, isError, byRoute, prefPending]
  );
  const menu = /* @__PURE__ */ jsx(WorkspacesMenuProvider, { value, children });
  return byRoute ? /* @__PURE__ */ jsx(WorkspaceSelectRegistrar.Provider, { value: route.register, children: menu }) : menu;
}
var NO_ROWS = [];
function useRouteSwitch(data) {
  const pathname = usePathname() ?? "/";
  const rows = data ?? NO_ROWS;
  const [firstSeg] = pathname.split("/").filter(Boolean);
  const activeSlug = rows.some((w) => w.slug === firstSeg) ? firstSeg : void 0;
  const reachable = useMemo(() => firstWorkspacePerSlug(rows), [rows]);
  const workspaces = useMemo(
    () => reachable.map((w) => ({
      id: workspaceCompositeId(w),
      label: workspaceListLabel(w),
      href: `/${w.slug}`,
      current: w.slug === activeSlug
    })),
    [reachable, activeSlug]
  );
  const router = useRouter();
  const routeSelect = useRef(null);
  const register = useCallback((fn) => {
    routeSelect.current = fn;
  }, []);
  const select = useMemo(() => {
    const slugById = new Map(reachable.map((w) => [workspaceCompositeId(w), w.slug]));
    return (w) => {
      const slug = slugById.get(w.id);
      if (!slug) return;
      if (routeSelect.current) routeSelect.current(slug);
      else router.push(`/${slug}`);
    };
  }, [reachable, router]);
  return { workspaces, select, register };
}
var PREFERENCE_WAIT_MS = 3e3;
function usePreferenceSwitch(data, enabled, subject) {
  const host = useClientHost();
  const { slug: preferred, settled, choose } = useWorkspacePreference({ enabled });
  const owners = useMemo(
    () => firstWorkspacePerSlug((data ?? NO_ROWS).filter((w) => w.type !== "team")),
    [data]
  );
  const preferredRow = owners.some((w) => w.slug === preferred);
  const waiting = enabled && !preferredRow && !settled;
  const [expiredFor, setExpiredFor] = useState(null);
  const [wasWaiting, setWasWaiting] = useState(waiting);
  if (wasWaiting !== waiting) {
    setWasWaiting(waiting);
    if (waiting) setExpiredFor(null);
  }
  useEffect(() => {
    if (!waiting) return;
    const timer = setTimeout(() => setExpiredFor(subject), PREFERENCE_WAIT_MS);
    return () => clearTimeout(timer);
  }, [waiting, subject]);
  const pending = waiting && expiredFor !== subject;
  const currentSlug = preferredRow ? preferred : pending ? void 0 : owners.find((w) => w.type === "individual")?.slug;
  const workspaces = useMemo(
    () => owners.map((w) => {
      const path = `/${w.slug}`;
      return {
        id: workspaceCompositeId(w),
        label: workspaceListLabel(w),
        href: host ? siteUrl("hub", path, host) : siteProdUrl("hub", path),
        current: w.slug === currentSlug
      };
    }),
    [owners, currentSlug, host]
  );
  const select = useMemo(() => {
    const slugById = new Map(owners.map((w) => [workspaceCompositeId(w), w.slug]));
    return (w) => {
      const slug = slugById.get(w.id);
      if (slug) choose(slug);
    };
  }, [owners, choose]);
  return { workspaces, select, pending };
}
export {
  SiteWorkspacesMenuProvider,
  WorkspaceSelectRegistrar,
  useRegisterWorkspaceSelect
};
//# sourceMappingURL=workspaces-feed.js.map
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
import { usePathname } from "next/navigation";
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
  const latest = useRef(select);
  useLayoutEffect(() => {
    latest.current = select;
  });
  useEffect(() => {
    register((slug) => latest.current(slug));
    return () => register(null);
  }, [register]);
}
function SiteWorkspacesMenuProvider({
  children,
  switchBy = "preference"
}) {
  const signedIn = useTokenSubject() != null;
  const { data, isLoading, isError } = useWorkspaces({ enabled: signedIn });
  const byRoute = switchBy === "route";
  const route = useRouteSwitch(byRoute ? data : void 0);
  const pref = usePreferenceSwitch(byRoute ? void 0 : data, signedIn && !byRoute);
  const feed = byRoute ? route : pref;
  const value = useMemo(
    () => ({
      workspaces: feed.workspaces,
      loading: signedIn && isLoading,
      error: signedIn && isError,
      select: feed.select,
      everyRoute: byRoute ? void 0 : true
    }),
    [feed.workspaces, feed.select, signedIn, isLoading, isError, byRoute]
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
  const [routeSelect, setRouteSelect] = useState(null);
  const register = useCallback((fn) => setRouteSelect(() => fn), []);
  const select = useMemo(() => {
    if (!routeSelect) return void 0;
    const slugById = new Map(reachable.map((w) => [workspaceCompositeId(w), w.slug]));
    return (w) => {
      const slug = slugById.get(w.id);
      if (slug) routeSelect(slug);
    };
  }, [routeSelect, reachable]);
  return { workspaces, select, register };
}
function usePreferenceSwitch(data, enabled) {
  const host = useClientHost();
  const { slug: preferred, choose } = useWorkspacePreference({ enabled });
  const owners = useMemo(
    () => firstWorkspacePerSlug((data ?? NO_ROWS).filter((w) => w.type !== "team")),
    [data]
  );
  const currentSlug = owners.some((w) => w.slug === preferred) ? preferred : owners.find((w) => w.type === "individual")?.slug;
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
  return { workspaces, select };
}
export {
  SiteWorkspacesMenuProvider,
  WorkspaceSelectRegistrar,
  useRegisterWorkspaceSelect
};
//# sourceMappingURL=workspaces-feed.js.map
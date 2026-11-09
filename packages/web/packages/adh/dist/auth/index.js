'use client'

"use client";

// src/auth/wired-provider.tsx
import { useState } from "react";
import { captureException as captureException2 } from "@adh-sdk/adh/telemetry/report-error";
import { markRetriedRequest } from "@adh-sdk/adh/telemetry/retry";
import {
  AuthProvider as ToolkitAuthProvider,
  setAuthErrorReporter,
  setAuthRetryMarker
} from "@adh-sdk/auth";

// src/auth/AppearanceSync.tsx
import { useEffect, useRef } from "react";
import { useAuth } from "@adh-sdk/auth";
import { authedJson } from "@adh-sdk/auth/client";
import { adoptAppearance, normalizeAppearance, resetAppearance } from "@adh-sdk/themes";

// src/auth/appearanceWire.ts
var APPEARANCE_INCLUDE_URL = "/api/v1/account?include[]=appearance";
var APPEARANCE_WRITE_URL = "/api/v1/account";
function appearanceFromWire(wire) {
  const w = wire ?? {};
  const out = {};
  if (w.color_mode !== void 0) out.colorMode = w.color_mode;
  if (w.reduce_motion !== void 0) out.reduceMotion = w.reduce_motion;
  if (w.contrast !== void 0) out.contrast = w.contrast;
  if (w.text_size !== void 0) out.textSize = w.text_size;
  if (w.spacing !== void 0) out.spacing = w.spacing;
  if (w.focus_outlines !== void 0) out.focusOutlines = w.focus_outlines;
  if (w.underline_links !== void 0) out.underlineLinks = w.underline_links;
  return out;
}
function appearanceToWire(prefs) {
  return {
    color_mode: prefs.colorMode,
    reduce_motion: prefs.reduceMotion,
    contrast: prefs.contrast,
    text_size: prefs.textSize,
    spacing: prefs.spacing,
    focus_outlines: prefs.focusOutlines,
    underline_links: prefs.underlineLinks
  };
}

// src/auth/AppearanceSync.tsx
import { captureException } from "@adh-sdk/adh/telemetry/report-error";
function AppearanceSync() {
  const { isAuthenticated, isLoading, user } = useAuth();
  const themedFor = useRef(void 0);
  useEffect(() => {
    if (isLoading) return;
    const identity = isAuthenticated ? user?.id ?? null : null;
    if (themedFor.current === identity) return;
    themedFor.current = identity;
    if (!identity) {
      resetAppearance();
      return;
    }
    let live = true;
    authedJson(APPEARANCE_INCLUDE_URL).then((account) => {
      const prefs = appearanceFromWire(account.appearance?.prefs);
      if (live) adoptAppearance(normalizeAppearance(prefs));
    }).catch((err) => {
      if (!live) return;
      themedFor.current = void 0;
      captureException(err);
    });
    return () => {
      live = false;
    };
  }, [isAuthenticated, isLoading, user?.id]);
  return null;
}

// src/auth/wired-provider.tsx
import { jsx, jsxs } from "react/jsx-runtime";
var wired = false;
function wireAdhTelemetry() {
  if (!wired) {
    wired = true;
    setAuthErrorReporter(captureException2);
    setAuthRetryMarker(markRetriedRequest);
  }
  return null;
}
function AuthProvider(props) {
  useState(wireAdhTelemetry);
  return /* @__PURE__ */ jsxs(ToolkitAuthProvider, { ...props, children: [
    /* @__PURE__ */ jsx(AppearanceSync, {}),
    props.children
  ] });
}

// src/auth/useAppearanceSettings.ts
import { useCallback } from "react";
import { useAuth as useAuth2 } from "@adh-sdk/auth";
import { authedRequest } from "@adh-sdk/auth/client";
import { useAppearancePreferences } from "@adh-sdk/themes";
import { captureException as captureException3 } from "@adh-sdk/adh/telemetry/report-error";
function useAppearanceSettings() {
  const { prefs, set: setLocal } = useAppearancePreferences();
  const { isAuthenticated } = useAuth2();
  const set = useCallback(
    (patch) => {
      const next = { ...prefs, ...patch };
      setLocal(patch);
      if (!isAuthenticated) return;
      authedRequest(APPEARANCE_WRITE_URL, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ appearance: appearanceToWire(next) })
      }).catch(captureException3);
    },
    [prefs, setLocal, isAuthenticated]
  );
  return { prefs, set };
}
export {
  AppearanceSync,
  AuthProvider,
  useAppearanceSettings
};
//# sourceMappingURL=index.js.map
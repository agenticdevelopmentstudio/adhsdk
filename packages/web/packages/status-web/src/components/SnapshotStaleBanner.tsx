"use client";
import type { ReactElement } from "react";
import { useLiveSnapshot } from "../hooks/use-live-snapshot";
import { timeAgo } from "../lib/time-ago";
import { BANNER_MONO, bannerBarStyle, bannerColor, type BannerTone } from "./banner-bar";

/**
 * Board-wide "the monitor stopped recording new checks" banner. `generatedAt` is
 * stamped at READ time so a frozen snapshot always looks fresh; `lastCycleAt` (newest
 * persisted probe) is the REAL freshness clock. The SERVER judges the lag and publishes
 * the verdict as `snapshot.freshness`; this banner renders it. The header/home status
 * sign (usePortfolioIndicator) reads the same field, so the two can't disagree. Inert
 * until a probe exists.
 */
export function SnapshotStaleBanner(): ReactElement | null {
  const { snapshot } = useLiveSnapshot();
  const lastCycleAt = snapshot?.freshness.asOf;
  if (!snapshot || !lastCycleAt || snapshot.freshness.state === "fresh") return null;

  const tone: BannerTone = snapshot.freshness.state === "very-stale" ? "red" : "amber";
  const color = bannerColor(tone);
  return (
    <div role="status" style={bannerBarStyle(tone)}>
      <span
        style={{
          fontFamily: BANNER_MONO,
          fontSize: 11,
          fontWeight: 700,
          letterSpacing: "0.06em",
          whiteSpace: "nowrap",
          color,
        }}
      >
        ⚠ MONITORING PAUSED
      </span>
      <span style={{ fontFamily: BANNER_MONO, fontSize: 11.5, color }}>
        status data last refreshed {timeAgo(lastCycleAt, Date.parse(snapshot.generatedAt))} — the
        monitor stopped recording new checks.
      </span>
    </div>
  );
}

'use client'

"use client";

// src/marketing/LandingHeroGate.tsx
import { useFlagEnabled, FLAG } from "@adh-sdk/adh/flags";
function LandingHeroGate({ diagram, fallback }) {
  return useFlagEnabled(FLAG.landingSiteExplorerDiagram) ? diagram : fallback;
}
export {
  LandingHeroGate
};
//# sourceMappingURL=LandingHeroGate.js.map
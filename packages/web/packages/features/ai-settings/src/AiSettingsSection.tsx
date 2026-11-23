"use client";

import type { ReactElement } from "react";
import { ServicesSection, type ServicesSectionProps } from "./ServicesSection";

/** The AI Settings screen: {@link ServicesSection} titled "AI Settings". A host passes
 *  `urlSelection` to make the open service deep-linkable, as it would to ServicesSection. */
export function AiSettingsSection(props: Omit<ServicesSectionProps, "title"> = {}): ReactElement {
  return <ServicesSection {...props} title="AI Settings" />;
}

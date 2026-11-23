"use client";

import { ServicesSection, type ServicesSectionProps } from "./ServicesSection";

/** The AI Settings screen: {@link ServicesSection} titled "AI Settings". A host passes
 *  `urlSelection` to make the open service deep-linkable, as it would to ServicesSection. */
export function AiSettingsSection(props: Omit<ServicesSectionProps, "title"> = {}) {
  return <ServicesSection {...props} title="AI Settings" />;
}

"use client";

import { useState, type ReactNode } from "react";
import { useRouter } from "next/navigation";
import { MessagingSurface, type SendMessageDraft } from "@adh-sdk/adh/messaging";
import { FeatureTitle } from "@adh-sdk/resource";
import { UnsavedChangesGuard } from "@adh-sdk/ui/components/unsaved-changes-guard";
import {
  useMessageLog,
  useSendMessage,
  useMessagingStatus,
  useMessagingTemplates,
} from "../api/admin";
import { MessagingProvidersSection } from "./MessagingProvidersSection";

/**
 * The platform-wide Messaging tool: the platform's own Postmark/Twilio config (the Providers
 * section, `/v1/messaging/providers`), sending email/SMS to any user through it, and the full
 * message log.
 *
 * Everything a reader sees is `MessagingSurface`, which the per-product Messaging pane
 * renders too — this file is the admin-scoped HALF: the `/v1/messaging/{status,messages}`
 * endpoints (gated by isAdmin()) instead of the per-ecosystem ones, and the words that
 * name that scope. The two used to be forked copies of one screen, and had drifted
 * (adh/docs/ui/fleet-ui-audit.md, Tier 6).
 */
export function MessagingPane({ help }: { help?: ReactNode } = {}) {
  const [page, setPage] = useState(1);
  const status = useMessagingStatus();
  const { data: templates } = useMessagingTemplates();
  const log = useMessageLog(page);
  const send = useSendMessage();
  const router = useRouter();
  // The surface reports a half-composed message; this page has to catch it. There is no rail
  // host or SettingsDirtyProvider on this route to register with (the per-product pane has
  // both, which is why it reports through `useReportSettingsDirty` instead), so the guard is
  // mounted directly. Without it the shared prop is left dangling on this half of the split
  // and a click on the admin nav silently throws away a typed message.
  const [dirty, setDirty] = useState(false);
  // The Providers forms hold typed credentials, which a nav click would lose just the same.
  const [providersDirty, setProvidersDirty] = useState(false);

  return (
    <div className="flex min-h-0 min-w-0 flex-1 flex-col">
      <FeatureTitle title="Messaging" help={help} />
      <div className="flex min-h-0 min-w-0 flex-1 flex-col space-y-8 overflow-y-auto px-6 pb-8 pt-2">
        <UnsavedChangesGuard
          when={dirty || providersDirty}
          onNavigate={(href) => router.push(href)}
        />
        <MessagingProvidersSection onDirtyChange={setProvidersDirty} />
        <MessagingSurface
          onDirtyChange={setDirty}
          status={{ data: status.data, isLoading: status.isLoading, isError: status.isError }}
          templates={templates}
          send={{
            mutate: (draft: SendMessageDraft, options) => send.mutate(draft, options),
            isPending: send.isPending,
            isSuccess: send.isSuccess,
            isError: send.isError,
          }}
          log={{ data: log.data, isLoading: log.isLoading }}
          page={page}
          onPageChange={setPage}
          userIdLabel="User ID"
          providerSetupHint={() => (
            <>Configure Postmark/Twilio in Providers above.</>
          )}
        />
      </div>
    </div>
  );
}

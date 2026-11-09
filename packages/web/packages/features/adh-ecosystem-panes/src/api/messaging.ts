"use client";

// Per-ecosystem messaging (the promoted admin Messaging tool). Each product/ecosystem
// sends via ITS OWN connected Postmark/Twilio integration through the backend's /v1/messaging
// routes (`status`, `messages`, `templates`), scoped by the `ecosystem` parameter. Templates
// are shared + static.
//
// The surface (`MessagingSurface`, in @adh-sdk/adh) is typed in camelCase and a numbered log
// page, so the mappers below sit between that and the snake_case, cursor-paged /v1 wire.

import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import type { SuccessBody } from "@adh-sdk/adh-api-types";
import {
  authedJson,
  listAllV1,
  unixToIso,
  withV1Query,
} from "@adh-sdk/auth/client";
import type {
  MessagingLogPageData,
  MessagingLogRow,
  MessagingProviderStatus,
  MessagingTemplateSummary,
  SendMessageDraft,
} from "@adh-sdk/adh/messaging";

type StatusWire = SuccessBody<"/v1/messaging/status", "get">;
type MessageWire = SuccessBody<"/v1/messaging/messages", "get">["data"][number];
type TemplateWire = SuccessBody<"/v1/messaging/templates", "get">["data"][number];
type SendWire = SuccessBody<"/v1/messaging/messages", "post">;

export type MessagingStatus = MessagingProviderStatus;
export type MessageLogEntry = MessagingLogRow;
export type MessageLogPage = MessagingLogPageData;
export type SendMessageRequest = SendMessageDraft;
export type SendMessageResult = SendWire;
export type MessagingTemplateList = MessagingTemplateSummary[];

const STATUS = "/api/v1/messaging/status";
const MESSAGES = "/api/v1/messaging/messages";
const TEMPLATES = "/api/v1/messaging/templates";

export function toStatus(w: StatusWire): MessagingStatus {
  return { email: w.email, sms: w.sms };
}

export function toTemplate(w: TemplateWire): MessagingTemplateSummary {
  return {
    id: w.id,
    name: w.name,
    subject: w.subject,
    htmlBody: w.html_body,
    textBody: w.text_body,
    smsBody: w.sms_body ?? null,
  };
}

export function toLogEntry(w: MessageWire): MessageLogEntry {
  return {
    id: w.id,
    channel: w.channel,
    recipient: w.recipient,
    subject: w.subject ?? null,
    status: w.status,
    createdAt: unixToIso(w.created),
  };
}

/** One numbered page of the log. /v1 pages by cursor and carries no total, so the pane reads the
 *  ecosystem's whole log once and cuts the page here — which also yields the `total` the pager
 *  needs. */
export function toLogPage(all: MessageWire[], page: number, pageSize: number): MessageLogPage {
  const start = (page - 1) * pageSize;
  return {
    items: all.slice(start, start + pageSize).map(toLogEntry),
    total: all.length,
    pageSize,
  };
}

/** The /v1 send body for a draft: snake_case, with the ecosystem named in the body. */
export function toSendBody(
  ecosystemId: string,
  d: SendMessageRequest,
): Record<string, unknown> {
  return {
    ecosystem: ecosystemId,
    user_id: d.userId,
    channel: d.channel,
    recipient: d.recipient,
    subject: d.subject,
    body: d.body,
    template_id: d.templateId,
    template_vars: d.templateVars,
  };
}

export function useMessagingStatus(ecosystemId?: string) {
  return useQuery({
    queryKey: ["messaging", ecosystemId, "status"],
    queryFn: async () =>
      toStatus(
        await authedJson<StatusWire>(withV1Query(STATUS, { ecosystem: ecosystemId as string })),
      ),
    enabled: ecosystemId != null,
  });
}

export function useMessagingTemplates() {
  return useQuery({
    queryKey: ["messaging", "templates"],
    queryFn: async () => (await listAllV1<TemplateWire>(TEMPLATES)).map(toTemplate),
  });
}

export function useMessageLog(ecosystemId: string | undefined, page = 1, pageSize = 20) {
  return useQuery({
    queryKey: ["messaging", ecosystemId, "log"],
    queryFn: () =>
      listAllV1<MessageWire>(withV1Query(MESSAGES, { ecosystem: ecosystemId as string })),
    select: (all) => toLogPage(all, page, pageSize),
    enabled: ecosystemId != null,
  });
}

export function useSendMessage(ecosystemId: string | undefined) {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (data: SendMessageRequest) =>
      authedJson<SendMessageResult>(MESSAGES, {
        method: "POST",
        body: JSON.stringify(toSendBody(ecosystemId as string, data)),
      }),
    onSuccess: () => qc.invalidateQueries({ queryKey: ["messaging", ecosystemId] }),
  });
}

"use client";

import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import type { RequestBody, SuccessBody } from "@adh-sdk/adh-api-types";
import { authedJson, authedRequest, listAllV1 } from "./http";

// ── Providers ────────────────────────────────────────────────────────────

// Spec-typed responses (the serializers in the backend's oauth/repo.ts) AND the
// create/update request bodies (the zod schemas in oauthAdmin.ts) — all derived
// from the OpenAPI spec now, so a backend change to either side fails this file's
// tsc instead of at runtime. (Previously the request shapes + IdentityMapping were
// hand-written; providerBody was enriched so they can come off the spec.)
export type OAuthProvider = SuccessBody<"/v1/oauth/providers", "get">["data"][number];
// `/v1` answers `{ object, [slug]: template }`; the hook below folds that back into `templates`.
export type ProviderTemplate = Exclude<
  SuccessBody<"/v1/oauth/provider_templates", "get">[string],
  string
>;
export type CreateProviderInput = RequestBody<"/v1/oauth/providers", "post">;
export type UpdateProviderInput = RequestBody<"/v1/oauth/providers/{id}", "post">;

export function useProviderTemplates() {
  return useQuery({
    queryKey: ["admin", "oauth", "provider-templates"],
    queryFn: async (): Promise<{ templates: Record<string, ProviderTemplate> }> => {
      const { object: _object, ...templates } = await authedJson<
        { object: string } & Record<string, ProviderTemplate>
      >("/api/v1/oauth/provider_templates");
      return { templates };
    },
  });
}

export function useProviders() {
  return useQuery({
    queryKey: ["admin", "oauth", "providers"],
    queryFn: () => listAllV1<OAuthProvider>("/api/v1/oauth/providers"),
  });
}

export function useProvider(slug: string) {
  return useQuery({
    queryKey: ["admin", "oauth", "providers", slug],
    queryFn: () =>
      authedJson<OAuthProvider>(`/api/v1/oauth/providers/${slug}`),
    enabled: !!slug,
  });
}

export function useCreateProvider() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (input: CreateProviderInput) =>
      authedJson<OAuthProvider>("/api/v1/oauth/providers", {
        method: "POST",
        body: JSON.stringify(input),
      }),
    onSuccess: () =>
      qc.invalidateQueries({ queryKey: ["admin", "oauth", "providers"] }),
  });
}

export function useUpdateProvider() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: ({ slug, ...input }: UpdateProviderInput & { slug: string }) =>
      authedJson<OAuthProvider>(`/api/v1/oauth/providers/${slug}`, {
        method: "POST",
        body: JSON.stringify(input),
      }),
    onSuccess: () =>
      qc.invalidateQueries({ queryKey: ["admin", "oauth", "providers"] }),
  });
}

export function useDeleteProvider() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (slug: string) =>
      authedRequest(`/api/v1/oauth/providers/${slug}`, { method: "DELETE" }),
    onSuccess: () =>
      qc.invalidateQueries({ queryKey: ["admin", "oauth", "providers"] }),
  });
}

// ── Clients ──────────────────────────────────────────────────────────────

// Spec-typed responses + requests; RequestBody forces the correct field names.
export type OAuthClient = SuccessBody<"/v1/oauth/clients", "get">["data"][number];
export type ClientShowResponse = SuccessBody<"/v1/oauth/clients/{id}", "get">;
export type ClientLinkedProvider = ClientShowResponse["providers"][number];
export type CreateClientInput = RequestBody<"/v1/oauth/clients", "post">;
export type CreateClientResponse = SuccessBody<"/v1/oauth/clients", "post", 201>;
export type UpdateClientInput = Partial<RequestBody<"/v1/oauth/clients/{id}", "post">>;

export interface LinkProviderInput {
  clientIdOverride?: string;
  clientSecretOverride?: string;
}

export type LinkProviderResponse = SuccessBody<
  "/v1/oauth/clients/{id}/providers/{provider_id}",
  "post"
>;
export type RotateAppTokenResponse = SuccessBody<
  "/v1/oauth/clients/{id}/rotate_token",
  "post"
>;

export function useClients() {
  return useQuery({
    queryKey: ["admin", "oauth", "clients"],
    queryFn: () => listAllV1<OAuthClient>("/api/v1/oauth/clients"),
  });
}

export function useClient(slug: string) {
  return useQuery({
    queryKey: ["admin", "oauth", "clients", slug],
    queryFn: () =>
      authedJson<ClientShowResponse>(`/api/v1/oauth/clients/${slug}`),
    enabled: !!slug,
  });
}

export function useCreateClient() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (input: CreateClientInput) =>
      authedJson<CreateClientResponse>("/api/v1/oauth/clients", {
        method: "POST",
        body: JSON.stringify(input),
      }),
    onSuccess: () =>
      qc.invalidateQueries({ queryKey: ["admin", "oauth", "clients"] }),
  });
}

export function useUpdateClient() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: ({ slug, ...input }: UpdateClientInput & { slug: string }) =>
      authedJson<OAuthClient>(`/api/v1/oauth/clients/${slug}`, {
        method: "POST",
        body: JSON.stringify(input),
      }),
    onSuccess: () =>
      qc.invalidateQueries({ queryKey: ["admin", "oauth", "clients"] }),
  });
}

export function useDeleteClient() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (slug: string) =>
      authedRequest(`/api/v1/oauth/clients/${slug}`, { method: "DELETE" }),
    onSuccess: () =>
      qc.invalidateQueries({ queryKey: ["admin", "oauth", "clients"] }),
  });
}

export function useLinkProvider() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: ({
      clientSlug,
      providerSlug,
      ...input
    }: LinkProviderInput & { clientSlug: string; providerSlug: string }) =>
      authedJson<LinkProviderResponse>(
        `/api/v1/oauth/clients/${clientSlug}/providers/${providerSlug}`,
        {
          method: "POST",
          body: JSON.stringify({
            client_id_override: input.clientIdOverride,
            client_secret_override: input.clientSecretOverride,
          }),
        },
      ),
    onSuccess: (_, vars) =>
      qc.invalidateQueries({
        queryKey: ["admin", "oauth", "clients", vars.clientSlug],
      }),
  });
}

export function useUnlinkProvider() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: ({
      clientSlug,
      providerSlug,
    }: {
      clientSlug: string;
      providerSlug: string;
    }) =>
      authedRequest(
        `/api/v1/oauth/clients/${clientSlug}/providers/${providerSlug}`,
        { method: "DELETE" },
      ),
    onSuccess: (_, vars) =>
      qc.invalidateQueries({
        queryKey: ["admin", "oauth", "clients", vars.clientSlug],
      }),
  });
}

export function useRotateClientToken() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (slug: string) =>
      authedJson<RotateAppTokenResponse>(
        `/api/v1/oauth/clients/${slug}/rotate_token`,
        { method: "POST" },
      ),
    onSuccess: () =>
      qc.invalidateQueries({ queryKey: ["admin", "oauth", "clients"] }),
  });
}

// ── Auth Methods ─────────────────────────────────────────────────────────

// Spec-typed: a row of GET /v1/auth/methods ({ method, enabled }).
export type AuthMethod = SuccessBody<"/v1/auth/methods", "get">["data"][number];

export function useAuthMethods() {
  return useQuery({
    queryKey: ["admin", "auth-methods"],
    queryFn: () => listAllV1<AuthMethod>("/api/v1/auth/methods"),
  });
}

export function useUpdateAuthMethod() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: ({ method, enabled }: AuthMethod) =>
      authedJson(`/api/v1/auth/methods/${method}`, {
        method: "POST",
        body: JSON.stringify({ enabled }),
      }),
    onSuccess: () =>
      qc.invalidateQueries({ queryKey: ["admin", "auth-methods"] }),
  });
}

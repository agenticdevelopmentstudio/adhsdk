"use client";

import { useState, type FormEvent } from "react";
import { Button } from "@adh-sdk/ui/components/button";
import { Input } from "@adh-sdk/ui/components/input";
import { Badge } from "@adh-sdk/ui/components/badge";
import { ErrorText } from "@adh-sdk/ui/components/error-text";
import { Card, CardContent } from "@adh-sdk/ui/components/card";
import { Field } from "@adh-sdk/ui/blocks/field";
import {
  messagingProviderRows,
  useMessagingProviders,
  useRemoveMessagingProvider,
  useRotateMessagingWebhookSecret,
  useSetMessagingProvider,
  useTestMessagingProvider,
  type MessagingProviderRow,
} from "../api/admin";

const errorText = (err: unknown): string | null =>
  err ? (err instanceof Error ? err.message : String(err)) : null;

/** A config value worth showing on the row: the non-secret fields, as stored. */
function storedValue(row: MessagingProviderRow, key: string): string {
  const v = row.config?.config[key];
  return typeof v === "string" ? v : "";
}

/**
 * The set-or-replace form. Every field starts from what is stored except the secret, which is
 * never sent back to the browser: left blank, the backend keeps the stored one.
 */
function ProviderForm({ row, onDone }: { row: MessagingProviderRow; onDone: () => void }) {
  const set = useSetMessagingProvider();
  const isSet = row.config !== null;
  const [values, setValues] = useState<Record<string, string>>(() =>
    Object.fromEntries(row.fields.map((f) => [f.key, f.secret ? "" : storedValue(row, f.key)])),
  );

  function submit(e: FormEvent) {
    e.preventDefault();
    // A blank optional or kept-secret field is left out rather than sent empty.
    const fields = Object.fromEntries(Object.entries(values).filter(([, v]) => v.trim() !== ""));
    set.mutate({ providerId: row.providerId, fields }, { onSuccess: onDone });
  }

  return (
    <form onSubmit={submit} className="space-y-3" aria-label={`${row.label} settings`}>
      {row.fields.map((f) => (
        <Field
          key={f.key}
          label={f.label}
          hint={f.secret && isSet && row.config?.has_secret ? "Leave blank to keep the stored value." : undefined}
        >
          <Input
            type={f.secret ? "password" : "text"}
            autoComplete="off"
            value={values[f.key] ?? ""}
            placeholder={f.placeholder}
            // A secret is required only when nothing is stored yet.
            required={f.required && !(f.secret && isSet && row.config?.has_secret)}
            onChange={(e) => setValues((prev) => ({ ...prev, [f.key]: e.target.value }))}
          />
        </Field>
      ))}
      <div className="flex items-center gap-2">
        <Button type="submit" disabled={set.isPending}>
          {set.isPending ? "Saving…" : "Save"}
        </Button>
        <Button type="button" variant="ghost" onClick={onDone}>
          Cancel
        </Button>
        <ErrorText error={errorText(set.error)} />
      </div>
    </form>
  );
}

function ProviderRowCard({ row }: { row: MessagingProviderRow }) {
  const [editing, setEditing] = useState(false);
  const [confirmRemove, setConfirmRemove] = useState(false);
  const [to, setTo] = useState("");
  const remove = useRemoveMessagingProvider();
  const test = useTestMessagingProvider();
  const rotate = useRotateMessagingWebhookSecret();
  const isSet = row.config !== null;
  const webhook = row.config?.deliverability_webhook ?? null;

  const testResult = test.data
    ? test.data.status === "sent"
      ? "Test message sent."
      : `Test message failed${test.data.error ? `: ${test.data.error}` : "."}`
    : null;

  return (
    <section
      aria-label={row.label}
      data-provider={row.providerId}
      className="space-y-3 rounded-lg border border-apt-border p-4"
    >
      <div className="flex flex-wrap items-center gap-2">
        <h3 className="font-semibold">{row.label}</h3>
        <span className="text-sm text-apt-text-muted">{row.channel === "email" ? "Email" : "SMS"}</span>
        <Badge variant={isSet ? "success" : "neutral"}>{isSet ? "Set" : "Not set"}</Badge>
      </div>

      {isSet && !editing && (
        <dl className="grid gap-x-4 gap-y-1 text-sm sm:grid-cols-[max-content_1fr]">
          {row.fields.map((f) => (
            <div key={f.key} className="contents">
              <dt className="text-apt-text-muted">{f.label}</dt>
              <dd className="font-mono">
                {f.secret ? (row.config?.has_secret ? "stored" : "missing") : storedValue(row, f.key) || "—"}
              </dd>
            </div>
          ))}
        </dl>
      )}

      {editing ? (
        <ProviderForm row={row} onDone={() => setEditing(false)} />
      ) : (
        <div className="flex flex-wrap items-center gap-2">
          <Button type="button" variant="outline" onClick={() => setEditing(true)}>
            {isSet ? "Replace" : "Set"}
          </Button>
          {isSet &&
            (confirmRemove ? (
              <>
                <Button
                  type="button"
                  variant="destructive"
                  disabled={remove.isPending}
                  onClick={() =>
                    remove.mutate(row.providerId, { onSettled: () => setConfirmRemove(false) })
                  }
                >
                  Confirm remove
                </Button>
                <Button type="button" variant="ghost" onClick={() => setConfirmRemove(false)}>
                  Keep
                </Button>
              </>
            ) : (
              <Button type="button" variant="destructive-ghost" onClick={() => setConfirmRemove(true)}>
                Remove
              </Button>
            ))}
          {isSet && row.canRotateWebhookSecret && (
            <Button
              type="button"
              variant="outline"
              disabled={rotate.isPending}
              onClick={() => rotate.mutate(row.providerId)}
            >
              Rotate webhook secret
            </Button>
          )}
        </div>
      )}
      <ErrorText error={errorText(remove.error) ?? errorText(rotate.error)} />

      {isSet && webhook && (
        <div className="space-y-1 text-sm">
          <p className="text-apt-text-muted">{webhook.instruction}</p>
          <p>
            Webhook URL: <span className="font-mono">{webhook.url}</span>
          </p>
          <p>
            Header <span className="font-mono">{webhook.secret_header}</span>:{" "}
            <span className="font-mono">{webhook.secret ?? "not minted yet"}</span>
          </p>
        </div>
      )}

      {isSet && (
        <form
          className="flex flex-wrap items-end gap-2"
          aria-label={`Test ${row.label}`}
          onSubmit={(e) => {
            e.preventDefault();
            test.mutate({ providerId: row.providerId, ...(to.trim() ? { to: to.trim() } : {}) });
          }}
        >
          <Field
            label={row.testNeedsRecipient ? "Test recipient (required)" : "Test recipient (optional)"}
            hint={row.testNeedsRecipient ? undefined : "Blank sends to your own email."}
          >
            <Input
              value={to}
              onChange={(e) => setTo(e.target.value)}
              required={row.testNeedsRecipient}
              placeholder={row.channel === "sms" ? "+15555550123" : "name@example.com"}
            />
          </Field>
          <Button type="submit" variant="outline" disabled={test.isPending}>
            {test.isPending ? "Sending…" : "Send test"}
          </Button>
          {testResult && (
            <span role="status" className="text-sm text-apt-text-muted">
              {testResult}
            </span>
          )}
          <ErrorText error={errorText(test.error)} />
        </form>
      )}
    </section>
  );
}

/**
 * The platform's own Postmark and Twilio: the providers it sends sign-in codes, MFA, invitations
 * and notifications with. They live here, not in the hub's Settings → Integrations, which refuses
 * them since phase 3.
 */
export function MessagingProvidersSection() {
  const providers = useMessagingProviders();
  const rows = messagingProviderRows(providers.data ?? []);

  return (
    <Card>
      <CardContent className="space-y-4 p-6">
        <h2 className="text-lg font-semibold">Providers</h2>
        {providers.isLoading ? (
          <p className="text-sm text-apt-text-muted">Loading providers…</p>
        ) : providers.isError ? (
          <ErrorText error={`Could not load the providers: ${errorText(providers.error) ?? "unknown error"}`} />
        ) : (
          rows.map((row) => <ProviderRowCard key={row.providerId} row={row} />)
        )}
      </CardContent>
    </Card>
  );
}

"use client";

import { lazy, Suspense, type ReactElement, type ReactNode } from "react";
import { FeatureTitle } from "@adh-sdk/resource";
import { Spinner } from "@adh-sdk/ui/components/spinner";

// Loaded on first render, not imported. Every admin page imports its pane from this package's one
// barrel, and tsup keeps `@adh-sdk/*` external, so a static import here put the whole account
// package (settings panels, @adh-sdk/crud) into every admin route's eager JavaScript although
// only /security uses it. An external dynamic import survives the bundle as `import()`, which
// the host's bundler splits into a chunk of its own.
const SecurityWorkspace = lazy(() =>
  import("@adh-sdk/account").then((m) => ({ default: m.SecurityWorkspace })),
);

/**
 * Security — the signed-in operator's own sign-in security: passkeys, the authenticator app and
 * recovery codes.
 *
 * Unlike every other admin section this one is about the operator, not the platform. It is the
 * account package's SecurityWorkspace under the console's title bar, so an operator manages their
 * factors with the same screen a hub user does.
 *
 * Not text messages. `/account/mfa` follows the operator realm, but `/account/contacts`, where a
 * phone number is added, scopes by the default tenant and so writes to the hub (adh
 * routes/contacts.ts). The SMS row therefore stays off for an operator, and the line under it says
 * so rather than pointing at a Notifications page the console does not have.
 */
export function SecurityPane({ help }: { help?: ReactNode } = {}): ReactElement {
  return (
    <div className="flex min-h-0 min-w-0 flex-1 flex-col">
      <FeatureTitle
        title="Security"
        api={{ method: "GET", path: "/v1/account/mfa", pathValues: {}, title: "Account security API" }}
        help={help}
      />
      <div className="flex min-h-0 min-w-0 flex-1 flex-col overflow-y-auto">
        <Suspense
          fallback={
            <div className="flex flex-1 items-center justify-center py-12">
              <Spinner />
            </div>
          }
        >
          <SecurityWorkspace phoneNote="Text-message sign-in isn't available for operator accounts." />
        </Suspense>
      </div>
    </div>
  );
}

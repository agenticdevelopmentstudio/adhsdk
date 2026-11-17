"use client";

import type { ReactElement, ReactNode } from "react";
import { SecurityWorkspace } from "@adh-sdk/account";
import { FeatureTitle } from "@adh-sdk/resource";

/**
 * Security — the signed-in operator's own sign-in security: passkeys, the authenticator app,
 * SMS and recovery codes.
 *
 * Unlike every other admin section this one is about the operator, not the platform. It is the
 * account package's SecurityWorkspace, mounted unchanged under the console's title bar, so an
 * operator manages their factors with the same screen a hub user does.
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
        <SecurityWorkspace />
      </div>
    </div>
  );
}

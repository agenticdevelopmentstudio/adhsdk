"use client";

import { useId, type ReactElement } from "react";

import type { JobInputSpec, JobInputValues } from "@adh-sdk/data/jobs";
import { Field } from "@adh-sdk/ui/blocks/field";
import { Checkbox } from "@adh-sdk/ui/components/checkbox";
import { Input } from "@adh-sdk/ui/components/input";
import { Select } from "@adh-sdk/ui/components/select";

export interface JobInputsFormProps {
  /** The inputs the template version declares; exactly these are offered. */
  specs: readonly JobInputSpec[];
  values: JobInputValues;
  onChange: (values: JobInputValues) => void;
  disabled?: boolean;
}

/** The values a job gives its template's declared inputs, one field per input. */
export function JobInputsForm({ specs, values, onChange, disabled }: JobInputsFormProps): ReactElement | null {
  const base = useId();
  if (specs.length === 0) return null;
  const set = (key: string, value: unknown) => onChange({ ...values, [key]: value });

  return (
    <div className="flex flex-col gap-3">
      {specs.map((spec) => {
        const id = `${base}-${spec.key}`;
        const label = spec.required ? `${spec.label} (required)` : spec.label;
        const value = values[spec.key];
        if (spec.type === "boolean") {
          return (
            <div key={spec.key} className="flex items-center gap-2">
              <Checkbox
                id={id}
                aria-label={spec.label}
                checked={value === true}
                disabled={disabled}
                onCheckedChange={(checked) => set(spec.key, checked === true)}
              />
              <label htmlFor={id} className="text-sm text-apt-text">
                {label}
              </label>
            </div>
          );
        }
        if (spec.type === "choice") {
          return (
            <Field key={spec.key} label={label}>
              <Select
                aria-label={spec.label}
                value={typeof value === "string" ? value : ""}
                disabled={disabled}
                onChange={(e) => set(spec.key, e.target.value || undefined)}
              >
                <option value="">Choose…</option>
                {(spec.choices ?? []).map((c) => (
                  <option key={c} value={c}>
                    {c}
                  </option>
                ))}
              </Select>
            </Field>
          );
        }
        const hint =
          spec.type === "connection"
            ? "The id of a connection in Integrations."
            : spec.type === "endpoint"
              ? "The id of a webhook endpoint."
              : undefined;
        return (
          <Field key={spec.key} label={label} hint={hint}>
            <Input
              aria-label={spec.label}
              type={spec.type === "number" ? "number" : "text"}
              value={value === undefined || value === null ? "" : String(value)}
              disabled={disabled}
              onChange={(e) => {
                const raw = e.target.value;
                if (raw === "") set(spec.key, undefined);
                else set(spec.key, spec.type === "number" ? Number(raw) : raw);
              }}
            />
          </Field>
        );
      })}
    </div>
  );
}

/** True when every required input has a value. */
export function requiredInputsFilled(specs: readonly JobInputSpec[], values: JobInputValues): boolean {
  return specs.every((s) => {
    if (!s.required) return true;
    const v = values[s.key];
    return v !== undefined && v !== null && v !== "";
  });
}

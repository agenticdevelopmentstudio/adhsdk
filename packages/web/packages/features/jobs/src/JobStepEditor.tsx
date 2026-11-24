"use client";

// The template author's editors: one per step kind, the declared inputs, and a JSON field for the
// free-form parts (an action's payload, an AI step's output schema).

import { useState, type ReactElement } from "react";

import { useUserServices } from "@adh-sdk/ai-settings";
import {
  JOB_STEP_KINDS,
  type JobInputSpec,
  type JobInputType,
  type JobStep,
  type JobStepKind,
  type JobStepModel,
} from "@adh-sdk/data/jobs";
import { Field } from "@adh-sdk/ui/blocks/field";
import { Button } from "@adh-sdk/ui/components/button";
import { Checkbox } from "@adh-sdk/ui/components/checkbox";
import { Input } from "@adh-sdk/ui/components/input";
import { Select } from "@adh-sdk/ui/components/select";
import { Textarea } from "@adh-sdk/ui/components/textarea";

const KIND_LABEL: Record<JobStepKind, string> = {
  ai: "AI",
  action: "Action",
  webhook: "Webhook",
  notify: "Notify",
  wait: "Wait",
  script: "Script",
};

/** A new step of a kind, with the fields it needs filled with placeholders the author replaces. */
export function newStep(kind: JobStepKind, taken: readonly string[]): JobStep {
  let n = taken.length + 1;
  while (taken.includes(`${kind}_${n}`)) n += 1;
  const common = { id: `${kind}_${n}`, name: `${KIND_LABEL[kind]} step` };
  switch (kind) {
    case "ai":
      return { ...common, kind, prompt: "", model: { source: "environment", provider: "local" } };
    case "action":
      return { ...common, kind, connectionId: "", actionType: "" };
    case "webhook":
      return { ...common, kind, endpointId: "" };
    case "notify":
      return { ...common, kind, subject: "", body: "" };
    case "wait":
      return { ...common, kind, delaySeconds: 60 };
    case "script":
      return { ...common, kind, language: "python", source: "", timeoutSeconds: 60 };
  }
}

/** A JSON value edited as text: parsed on each change, the last good value kept while it does not parse. */
function JsonField({
  label,
  value,
  onChange,
  disabled,
}: {
  label: string;
  value: unknown;
  onChange: (value: unknown) => void;
  disabled?: boolean;
}): ReactElement {
  const [text, setText] = useState(() => (value === undefined || value === null ? "" : JSON.stringify(value, null, 2)));
  const [bad, setBad] = useState(false);
  return (
    <Field label={label} error={bad ? "This is not valid JSON." : undefined}>
      <Textarea
        aria-label={label}
        className="font-mono text-xs"
        rows={4}
        value={text}
        disabled={disabled}
        onChange={(e) => {
          const next = e.target.value;
          setText(next);
          if (next.trim() === "") {
            setBad(false);
            onChange(undefined);
            return;
          }
          try {
            onChange(JSON.parse(next));
            setBad(false);
          } catch {
            setBad(true);
          }
        }}
      />
    </Field>
  );
}

function AiModelEditor({
  model,
  onChange,
  disabled,
}: {
  model: JobStepModel;
  onChange: (model: JobStepModel) => void;
  disabled?: boolean;
}): ReactElement {
  const services = useUserServices();
  const list = services.items ?? [];
  const service = model.source === "connection" ? list.find((s) => s.id === model.serviceId) : undefined;
  // Only the models the connection has on; one switched off is not offered.
  const models = (service?.models ?? []).filter((m) => m.available !== false);

  return (
    <div className="flex flex-col gap-3">
      <Field label="Model from">
        <Select
          aria-label="Model from"
          value={model.source}
          disabled={disabled}
          onChange={(e) =>
            onChange(
              e.target.value === "connection"
                ? { source: "connection", serviceId: list[0]?.id ?? "", model: "" }
                : { source: "environment", provider: "local" },
            )
          }
        >
          <option value="connection">A connection in AI Settings</option>
          <option value="environment">The environment's own model</option>
        </Select>
      </Field>
      {model.source === "connection" ? (
        <>
          <Field label="Connection" error={services.error ? "Couldn't load your AI connections." : undefined}>
            <Select
              aria-label="Connection"
              value={model.serviceId}
              disabled={disabled}
              onChange={(e) => onChange({ source: "connection", serviceId: e.target.value, model: "" })}
            >
              <option value="">Choose…</option>
              {list.map((s) => (
                <option key={s.id} value={s.id}>
                  {s.name}
                </option>
              ))}
            </Select>
          </Field>
          <Field label="Model">
            <Select
              aria-label="Model"
              value={model.model}
              disabled={disabled || !service}
              onChange={(e) => onChange({ ...model, model: e.target.value })}
            >
              <option value="">Choose…</option>
              {models.map((m) => (
                <option key={m.id} value={m.id}>
                  {m.displayName ?? m.id}
                </option>
              ))}
            </Select>
          </Field>
        </>
      ) : (
        <>
          <Field label="Provider">
            <Select
              aria-label="Provider"
              value={model.provider}
              disabled={disabled}
              onChange={(e) =>
                onChange({ source: "environment", provider: e.target.value as "local" | "claude-code", model: model.model })
              }
            >
              <option value="local">Local model</option>
              <option value="claude-code">Claude Code</option>
            </Select>
          </Field>
          <Field label="Model name" hint="Optional; the machine's default when empty.">
            <Input
              aria-label="Model name"
              value={model.model ?? ""}
              disabled={disabled}
              onChange={(e) => onChange({ ...model, model: e.target.value || null })}
            />
          </Field>
        </>
      )}
    </div>
  );
}

function KindFields({
  step,
  onChange,
  disabled,
}: {
  step: JobStep;
  onChange: (step: JobStep) => void;
  disabled?: boolean;
}): ReactElement {
  switch (step.kind) {
    case "ai":
      return (
        <>
          <Field label="Prompt">
            <Textarea
              aria-label="Prompt"
              rows={4}
              value={step.prompt}
              disabled={disabled}
              onChange={(e) => onChange({ ...step, prompt: e.target.value })}
            />
          </Field>
          <Field label="Instructions">
            <Textarea
              aria-label="Instructions"
              rows={2}
              value={step.instructions ?? ""}
              disabled={disabled}
              onChange={(e) => onChange({ ...step, instructions: e.target.value || null })}
            />
          </Field>
          <AiModelEditor model={step.model} disabled={disabled} onChange={(model) => onChange({ ...step, model })} />
          <JsonField
            label="Output schema"
            value={step.outputSchema}
            disabled={disabled}
            onChange={(v) => onChange({ ...step, outputSchema: (v as Record<string, unknown> | undefined) ?? null })}
          />
        </>
      );
    case "action":
      return (
        <>
          <Field label="Connection id">
            <Input
              aria-label="Connection id"
              value={step.connectionId}
              disabled={disabled}
              onChange={(e) => onChange({ ...step, connectionId: e.target.value })}
            />
          </Field>
          <Field label="Action" hint="Such as gmail:search.">
            <Input
              aria-label="Action"
              value={step.actionType}
              disabled={disabled}
              onChange={(e) => onChange({ ...step, actionType: e.target.value })}
            />
          </Field>
          <JsonField
            label="Payload"
            value={step.payload}
            disabled={disabled}
            onChange={(v) => onChange({ ...step, payload: v as Record<string, unknown> | undefined })}
          />
        </>
      );
    case "webhook":
      return (
        <>
          <Field label="Endpoint id">
            <Input
              aria-label="Endpoint id"
              value={step.endpointId}
              disabled={disabled}
              onChange={(e) => onChange({ ...step, endpointId: e.target.value })}
            />
          </Field>
          <JsonField
            label="Payload"
            value={step.payload}
            disabled={disabled}
            onChange={(v) => onChange({ ...step, payload: v })}
          />
        </>
      );
    case "notify":
      return (
        <>
          <Field label="Subject">
            <Input
              aria-label="Subject"
              value={step.subject}
              disabled={disabled}
              onChange={(e) => onChange({ ...step, subject: e.target.value })}
            />
          </Field>
          <Field label="Body">
            <Textarea
              aria-label="Body"
              rows={3}
              value={step.body}
              disabled={disabled}
              onChange={(e) => onChange({ ...step, body: e.target.value })}
            />
          </Field>
        </>
      );
    case "wait":
      return (
        <Field label="Wait (seconds)" hint="60 to 86400.">
          <Input
            aria-label="Wait (seconds)"
            type="number"
            min={60}
            max={86400}
            value={step.delaySeconds}
            disabled={disabled}
            onChange={(e) => onChange({ ...step, delaySeconds: Number(e.target.value) })}
          />
        </Field>
      );
    case "script":
      return (
        <>
          <Field label="Language">
            <Select
              aria-label="Language"
              value={step.language}
              disabled={disabled}
              onChange={(e) => onChange({ ...step, language: e.target.value as "node" | "python" })}
            >
              <option value="python">Python</option>
              <option value="node">Node</option>
            </Select>
          </Field>
          <Field label="Source">
            <Textarea
              aria-label="Source"
              className="font-mono text-xs"
              rows={6}
              value={step.source}
              disabled={disabled}
              onChange={(e) => onChange({ ...step, source: e.target.value })}
            />
          </Field>
          <Field label="Timeout (seconds)" hint="At most 900.">
            <Input
              aria-label="Timeout (seconds)"
              type="number"
              min={1}
              max={900}
              value={step.timeoutSeconds}
              disabled={disabled}
              onChange={(e) => onChange({ ...step, timeoutSeconds: Number(e.target.value) })}
            />
          </Field>
        </>
      );
  }
}

export interface JobStepEditorProps {
  step: JobStep;
  index: number;
  count: number;
  /** The validation messages the last publish gave for this step. */
  problems?: readonly string[];
  disabled?: boolean;
  onChange: (step: JobStep) => void;
  onMove: (delta: -1 | 1) => void;
  onRemove: () => void;
}

/** One step of a draft: the fields every step has, then its kind's own. */
export function JobStepEditor({
  step,
  index,
  count,
  problems,
  disabled,
  onChange,
  onMove,
  onRemove,
}: JobStepEditorProps): ReactElement {
  return (
    <li className="flex flex-col gap-3 rounded-md border border-apt-border p-3" data-step-id={step.id}>
      <div className="flex flex-wrap items-center gap-2">
        <span className="text-xs text-apt-text-muted">
          {index + 1}. {KIND_LABEL[step.kind]}
        </span>
        <div className="ml-auto flex gap-1">
          <Button type="button" size="xs" variant="ghost" disabled={disabled || index === 0} onClick={() => onMove(-1)}>
            Up
          </Button>
          <Button
            type="button"
            size="xs"
            variant="ghost"
            disabled={disabled || index === count - 1}
            onClick={() => onMove(1)}
          >
            Down
          </Button>
          <Button type="button" size="xs" variant="ghost" disabled={disabled} onClick={onRemove}>
            Remove
          </Button>
        </div>
      </div>
      {problems && problems.length > 0 ? (
        <ul role="alert" className="text-sm text-apt-red">
          {problems.map((p, i) => (
            <li key={i}>{p}</li>
          ))}
        </ul>
      ) : null}
      <div className="grid gap-3 sm:grid-cols-2">
        <Field label="Step id" hint="Lowercase letters, digits and _.">
          <Input
            aria-label="Step id"
            value={step.id}
            disabled={disabled}
            onChange={(e) => onChange({ ...step, id: e.target.value })}
          />
        </Field>
        <Field label="Step name">
          <Input
            aria-label="Step name"
            value={step.name}
            disabled={disabled}
            onChange={(e) => onChange({ ...step, name: e.target.value })}
          />
        </Field>
        <Field label="On error">
          <Select
            aria-label="On error"
            value={step.onError ?? "fail"}
            disabled={disabled}
            onChange={(e) => onChange({ ...step, onError: e.target.value as "fail" | "continue" })}
          >
            <option value="fail">Fail the run</option>
            <option value="continue">Continue</option>
          </Select>
        </Field>
        <Field label="Attempts" hint="1 to 10.">
          <Input
            aria-label="Attempts"
            type="number"
            min={1}
            max={10}
            value={step.maxAttempts ?? 3}
            disabled={disabled}
            onChange={(e) => onChange({ ...step, maxAttempts: Number(e.target.value) })}
          />
        </Field>
      </div>
      <KindFields step={step} onChange={onChange} disabled={disabled} />
    </li>
  );
}

export function AddStepPicker({
  taken,
  disabled,
  onAdd,
}: {
  taken: readonly string[];
  disabled?: boolean;
  onAdd: (step: JobStep) => void;
}): ReactElement {
  const [kind, setKind] = useState<JobStepKind>("ai");
  return (
    <div className="flex items-end gap-2">
      <Field label="New step">
        <Select aria-label="New step kind" value={kind} disabled={disabled} onChange={(e) => setKind(e.target.value as JobStepKind)}>
          {JOB_STEP_KINDS.map((k) => (
            <option key={k} value={k}>
              {KIND_LABEL[k]}
            </option>
          ))}
        </Select>
      </Field>
      <Button type="button" size="sm" variant="outline" disabled={disabled} onClick={() => onAdd(newStep(kind, taken))}>
        Add step
      </Button>
    </div>
  );
}

const INPUT_TYPES: readonly JobInputType[] = ["text", "number", "boolean", "connection", "endpoint", "choice"];

/** The inputs a template declares: key, label, type, required, and a choice input's values. */
export function JobInputSpecsEditor({
  specs,
  problems,
  disabled,
  onChange,
}: {
  specs: readonly JobInputSpec[];
  problems?: readonly string[];
  disabled?: boolean;
  onChange: (specs: JobInputSpec[]) => void;
}): ReactElement {
  const set = (i: number, patch: Partial<JobInputSpec>) =>
    onChange(specs.map((s, j) => (j === i ? { ...s, ...patch } : s)));
  return (
    <div className="flex flex-col gap-2">
      {problems && problems.length > 0 ? (
        <ul role="alert" className="text-sm text-apt-red">
          {problems.map((p, i) => (
            <li key={i}>{p}</li>
          ))}
        </ul>
      ) : null}
      {specs.length === 0 ? <p className="text-sm text-apt-text-muted">No inputs.</p> : null}
      {specs.map((s, i) => (
        <div key={i} className="flex flex-wrap items-end gap-2 rounded-md border border-apt-border p-2">
          <Field label="Key">
            <Input aria-label="Input key" value={s.key} disabled={disabled} onChange={(e) => set(i, { key: e.target.value })} />
          </Field>
          <Field label="Label">
            <Input
              aria-label="Input label"
              value={s.label}
              disabled={disabled}
              onChange={(e) => set(i, { label: e.target.value })}
            />
          </Field>
          <Field label="Type">
            <Select
              aria-label="Input type"
              value={s.type}
              disabled={disabled}
              onChange={(e) => set(i, { type: e.target.value as JobInputType })}
            >
              {INPUT_TYPES.map((t) => (
                <option key={t} value={t}>
                  {t}
                </option>
              ))}
            </Select>
          </Field>
          {s.type === "choice" ? (
            <Field label="Choices" hint="Comma separated.">
              <Input
                aria-label="Input choices"
                value={(s.choices ?? []).join(", ")}
                disabled={disabled}
                onChange={(e) =>
                  set(i, {
                    choices: e.target.value
                      .split(",")
                      .map((c) => c.trim())
                      .filter(Boolean),
                  })
                }
              />
            </Field>
          ) : null}
          <label className="flex items-center gap-2 pb-2 text-sm text-apt-text">
            <Checkbox
              aria-label="Input required"
              checked={s.required === true}
              disabled={disabled}
              onCheckedChange={(c) => set(i, { required: c === true })}
            />
            Required
          </label>
          <Button
            type="button"
            size="xs"
            variant="ghost"
            disabled={disabled}
            onClick={() => onChange(specs.filter((_, j) => j !== i))}
          >
            Remove
          </Button>
        </div>
      ))}
      <div>
        <Button
          type="button"
          size="sm"
          variant="outline"
          disabled={disabled}
          onClick={() => onChange([...specs, { key: `input_${specs.length + 1}`, label: "Input", type: "text" }])}
        >
          Add input
        </Button>
      </div>
    </div>
  );
}

"use client"

import { useId, useRef, type ChangeEvent, type ReactNode } from "react"
import { Upload } from "lucide-react"

import { cn } from "../lib/utils"
import { Button } from "../components/button"
import { Label } from "../components/label"
import { Textarea } from "../components/textarea"
import { EditorToolbar } from "../components/editor-toolbar"
import { MarkdownQuickReference } from "../components/markdown-quick-reference"
import { fieldCaptionClass } from "../lib/typography"

export interface MarkdownEditorProps {
  /** Controlled markdown source. */
  value: string
  /** Called with the next markdown source as the user types. */
  onChange: (next: string) => void
  /** Caption above the textarea; also the textarea's accessible name. */
  label?: ReactNode
  /** Placeholder shown while the textarea is empty. */
  placeholder?: string
  /** Visible textarea height, in rows. */
  rows?: number
  /** Toggle the browser's native spell-checker on the textarea (default off —
   *  markdown source is full of non-words). */
  spellCheck?: boolean
  /** When set, a built-in "Upload .md" toolbar control reads a chosen file and
   *  reports its text + filename. The caller decides what to do with it (e.g.
   *  set the body and derive a title) — the editor never owns title logic. */
  onUpload?: (text: string, fileName: string) => void
  /** Render the built-in markdown quick-reference control in the toolbar. */
  quickReference?: boolean
  /** Extra toolbar controls, slotted ahead of the built-in controls (e.g. a
   *  future spell-check toggle). */
  toolbarExtras?: ReactNode
  /** Accessible name for the toolbar. */
  toolbarLabel?: string
  className?: string
  /** Extra classes for the textarea. */
  textareaClassName?: string
  /** Disable typing, upload, and toolbar controls. */
  disabled?: boolean
  /** Show the source without letting it be changed: the text stays selectable and
   *  scrollable (unlike `disabled`, which greys it out), and the editing aids, upload and
   *  the quick reference, are not offered, since there is nothing to write. */
  readOnly?: boolean
  /** Where the caption and toolbar go. `"above"` (default) puts them in a row over the
   *  textarea. `"none"` renders the textarea alone, its caption kept as the accessible name
   *  only: for a host that shows {@link MarkdownEditorToolbar} in its own control strip, so
   *  the textarea's top lines up with whatever sits beside it. */
  chrome?: "above" | "none"
  /** Take the height the parent gives instead of a fixed `rows` box: the root becomes a
   *  `min-h-0 flex-1` column and the textarea flexes inside it (and stops offering the
   *  manual resize grip, since the height is no longer the user's to set). `rows` is
   *  ignored. The PARENT must supply a bounded height — a fill editor inside a scroller
   *  has nothing to fill. */
  fill?: boolean
}

/** Read a chosen `.md` file and hand its text + name back to the caller — the
 *  built-in upload control. Keeps the hidden native-input pattern (the only way
 *  to open a file picker; there is no shared file-upload primitive). */
function UploadMarkdownControl({
  onUpload,
  disabled,
}: {
  onUpload: (text: string, fileName: string) => void
  disabled?: boolean
}) {
  const inputRef = useRef<HTMLInputElement>(null)

  async function onFile(event: ChangeEvent<HTMLInputElement>): Promise<void> {
    const file = event.target.files?.[0]
    // Reset the input so re-choosing the same file fires change again.
    event.target.value = ""
    if (!file) return
    const text = await file.text()
    onUpload(text, file.name)
  }

  return (
    <>
      <Button
        type="button"
        variant="outline"
        size="sm"
        disabled={disabled}
        onClick={() => inputRef.current?.click()}
      >
        <Upload data-icon="inline-start" />
        Upload .md
      </Button>
      {/* adh-ui-allow: cs-no-bespoke — a file picker requires a native <input type="file">; there is no shared file-upload primitive, and the editor's upload control mandates it. The input is sr-only/aria-hidden; the visible control is the shared Button above. approved by mike 2026-06-26 */}
      <input
        ref={inputRef}
        type="file"
        accept=".md,.markdown,.txt,text/markdown,text/plain"
        className="sr-only"
        aria-hidden
        tabIndex={-1}
        disabled={disabled}
        onChange={onFile}
      />
    </>
  )
}

export type MarkdownEditorToolbarProps = Pick<
  MarkdownEditorProps,
  "onUpload" | "quickReference" | "toolbarExtras" | "toolbarLabel" | "disabled" | "readOnly"
> & { className?: string }

/** Which controls the toolbar offers. One answer, shared by the editor and any host that
 *  places the toolbar itself, so the two can't disagree about whether there is a toolbar. */
function toolbarControls({
  onUpload,
  quickReference = true,
  toolbarExtras,
  readOnly = false,
}: MarkdownEditorToolbarProps) {
  const upload = !readOnly && Boolean(onUpload)
  const reference = !readOnly && quickReference
  return { upload, reference, any: Boolean(toolbarExtras) || upload || reference }
}

/**
 * The editor's toolbar on its own: the extras slot, the `.md` upload control and the
 * "Reference" quick-reference popover. `MarkdownEditor` renders it above its textarea;
 * `MarkdownDocumentEditor` renders it in its control strip, beside the pane tabs. Renders
 * nothing when there are no controls.
 */
export function MarkdownEditorToolbar(props: MarkdownEditorToolbarProps) {
  const { onUpload, toolbarExtras, toolbarLabel = "Markdown editor toolbar", disabled, className } = props
  const controls = toolbarControls(props)
  if (!controls.any) return null
  return (
    <EditorToolbar ariaLabel={toolbarLabel} className={className}>
      {toolbarExtras}
      {controls.upload && onUpload && (
        <UploadMarkdownControl onUpload={onUpload} disabled={disabled} />
      )}
      {controls.reference && <MarkdownQuickReference />}
    </EditorToolbar>
  )
}

/**
 * The shared markdown **body** editor: a labelled textarea for the raw markdown
 * source, with an editor toolbar row above it (an optional `.md` upload control,
 * a built-in "Reference" quick-reference popover, and a slot for extra controls). The label
 * is associated with the textarea via `htmlFor`, so it is the textarea's
 * accessible name. Controlled via `value` / `onChange`; the editor owns no title
 * or classification fields — those stay with the consuming form.
 *
 * It is the primitive, not the default: a surface that edits a whole document wants
 * `MarkdownDocumentEditor` from `@adh-sdk/markdown`, which composes
 * this with a live preview and a side-by-side layout. Reach for this one when a preview
 * would be noise — a one-line description, a comment box.
 */
export function MarkdownEditor({
  value,
  onChange,
  label = "Markdown body",
  placeholder,
  rows = 16,
  spellCheck = false,
  onUpload,
  quickReference = true,
  toolbarExtras,
  toolbarLabel = "Markdown editor toolbar",
  className,
  textareaClassName,
  disabled,
  readOnly = false,
  chrome = "above",
  fill = false,
}: MarkdownEditorProps) {
  const textareaId = useId()

  return (
    <div className={cn("flex flex-col gap-1.5", fill && "min-h-0 flex-1", className)}>
      {chrome === "above" ? (
        <div className="flex items-center justify-between gap-3">
          <Label htmlFor={textareaId} className={fieldCaptionClass}>
            {label}
          </Label>
          <MarkdownEditorToolbar
            onUpload={onUpload}
            quickReference={quickReference}
            toolbarExtras={toolbarExtras}
            toolbarLabel={toolbarLabel}
            disabled={disabled}
            readOnly={readOnly}
          />
        </div>
      ) : (
        <Label htmlFor={textareaId} className="sr-only">
          {label}
        </Label>
      )}
      <Textarea
        id={textareaId}
        rows={fill ? undefined : rows}
        spellCheck={spellCheck}
        disabled={disabled}
        readOnly={readOnly}
        className={cn(
          "font-mono text-[0.8rem]",
          fill && "min-h-0 flex-1 resize-none",
          textareaClassName,
        )}
        placeholder={placeholder}
        value={value}
        onChange={(e) => onChange(e.target.value)}
      />
    </div>
  )
}

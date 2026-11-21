import type { HTMLAttributes, ReactNode } from "react"

import { Card, CardContent, CardHeader, CardTitle } from "../components/card"
import { cn } from "../lib/utils"

// A card holding a title and a markdown description. `ui` has no markdown
// dependency: the caller passes the renderer, and without one the description
// is plain text with its line breaks kept. Renders nothing when both are empty.

export interface DescriptionCardProps extends Omit<HTMLAttributes<HTMLDivElement>, "title"> {
  title?: string
  description?: string
  /** Renders the description's markdown; omitted, the description is plain text. */
  renderMarkdown?: (markdown: string) => ReactNode
}

export function DescriptionCard({
  title,
  description,
  renderMarkdown,
  className,
  ...rest
}: DescriptionCardProps) {
  if (!title && !description) return null
  return (
    <Card className={cn("gap-4", className)} {...rest}>
      {title && (
        <CardHeader>
          <CardTitle>{title}</CardTitle>
        </CardHeader>
      )}
      {description && (
        <CardContent>
          {renderMarkdown ? (
            renderMarkdown(description)
          ) : (
            <p className="whitespace-pre-wrap text-sm text-apt-text-muted">{description}</p>
          )}
        </CardContent>
      )}
    </Card>
  )
}

import type { ReactNode } from 'react'

export interface GroupProps {
  title?: ReactNode
  hint?: ReactNode
  children?: ReactNode
  className?: string
}

export function Group({ title, hint, children, className }: GroupProps) {
  const cls = ['aws-group', className].filter(Boolean).join(' ')
  return (
    <section className={cls}>
      {/* A ternary, not `&&`: a falsy title or hint (0 included) renders nothing at all. */}
      {title ? <h3 className="aws-group__title">{title}</h3> : null}
      {hint ? <p className="aws-group__hint">{hint}</p> : null}
      <div className="aws-group__body">{children}</div>
    </section>
  )
}

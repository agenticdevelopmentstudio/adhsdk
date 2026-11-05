'use client'

import { useMemo } from 'react'
import { useContent } from '@adh-sdk/model'
import { useSiteConfig } from '@adh-sdk/model'
import { useCurrentRoute } from '@adh-sdk/model'
import { useSearchState } from '@adh-sdk/model'
import { SearchDialog, type SearchDialogProps } from './SearchDialog'

export type SearchDialogConnectedProps = Omit<
  SearchDialogProps,
  'state' | 'onSelect' | 'sectionLabels'
>

export function SearchDialogConnected(props: SearchDialogConnectedProps) {
  const { searchIndex } = useContent()
  const { nav } = useSiteConfig()
  const { navigate } = useCurrentRoute()
  const state = useSearchState(searchIndex)

  const sectionLabels = useMemo(() => {
    const m: Record<string, string> = {}
    for (const s of nav.sections) m[s.key] = s.label
    return m
  }, [nav.sections])

  return (
    <SearchDialog
      {...props}
      state={state}
      sectionLabels={sectionLabels}
      onSelect={(entry) => {
        navigate(entry.slug)
        props.onClose()
      }}
    />
  )
}

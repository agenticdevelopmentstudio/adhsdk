'use client'

import { themeIds, themes, type ThemeKey } from '@adh-sdk/themes'
import { useDemoTheme } from './theme-store'
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from '@/components/ui/select'

/**
 * The demo's theme picker, rebuilt on shadcn's Select. Reads/writes the shared
 * theme store, so it stays in sync wherever it's mounted (currently the Shell
 * header). Switching restyles the demoed artifacts (the scoped `ThemeStyle`
 * stage), not the fixed shadcn chrome.
 */
export function ThemeMenu({ className }: { className?: string }) {
  const [theme, setTheme] = useDemoTheme()
  return (
    <Select value={theme} onValueChange={(v) => setTheme(v as ThemeKey)}>
      <SelectTrigger size="sm" className={className} aria-label="Theme">
        <SelectValue placeholder="Theme" />
      </SelectTrigger>
      <SelectContent position="popper" className="max-h-none">
        {themeIds.map((id) => (
          <SelectItem key={id} value={id}>
            {themes[id].label}
          </SelectItem>
        ))}
      </SelectContent>
    </Select>
  )
}

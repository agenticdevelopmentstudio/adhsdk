/**
 * Next selection index for an up/down key press over a list of length `len`,
 * clamped to [0, len-1]. With no active selection (`current < 0`) the first key
 * press lands on the FIRST item (index 0), not the second. Returns -1 for an
 * empty list. Pure — the single shared source for list keyboard navigation:
 * the activity/commit lists in status-backend and builds-backend, and the topic
 * rail's filter autocomplete.
 *
 * `wrap` steps past either end onto the other instead of clamping — a combobox's
 * suggestions, where Up from the first reaches the last.
 */
export function stepIndex(
  len: number,
  current: number,
  key: "ArrowUp" | "ArrowDown",
  { wrap = false }: { wrap?: boolean } = {},
): number {
  if (len === 0) return -1
  if (current < 0) return 0
  const step = key === "ArrowDown" ? 1 : -1
  if (wrap) return (current + step + len) % len
  return Math.min(len - 1, Math.max(0, current + step))
}

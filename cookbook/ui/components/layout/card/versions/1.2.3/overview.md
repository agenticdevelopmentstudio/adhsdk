
`Card` groups related content inside a single visually-bounded container.

The UI Card family (`packages/web/packages/ui/src/components/card.tsx`) is a compound, slot-based family of six independently composable components (`Card`, `CardHeader`, `CardTitle`, `CardDescription`, `CardContent`, `CardFooter`), each a styled `<div>` that forwards `className` and other props. The UI `Card` itself imposes no required child structure — callers assemble whichever slots they need.


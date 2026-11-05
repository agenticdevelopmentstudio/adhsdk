import type { Metadata } from 'next'
import './globals.css'
import './demo.css'
import { Shell } from './Shell'

const TITLE = 'Agentic Developer Hub SDK — Demo'
const DESCRIPTION =
  'Local demo for the @adh-sdk chat and theme packages.'

export const metadata: Metadata = {
  title: TITLE,
  description: DESCRIPTION,
  icons: { icon: '/favicon.svg' },
}

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode
}>) {
  return (
    <html lang="en" className="dark">
      <head>
        <link rel="preconnect" href="https://fonts.googleapis.com" />
        <link rel="preconnect" href="https://fonts.gstatic.com" crossOrigin="" />
        <link
          rel="stylesheet"
          href="https://fonts.googleapis.com/css2?family=DM+Mono:wght@400&family=Instrument+Serif:ital@0;1&family=Manrope:wght@400;500;600&display=swap"
        />
      </head>
      <body>
        <Shell>{children}</Shell>
      </body>
    </html>
  )
}

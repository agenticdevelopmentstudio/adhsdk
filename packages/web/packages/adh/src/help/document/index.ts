/**
 * @adh-sdk/adh/help/document — the help site's content documents (Hub Features, Tutorials): the
 * model that reads content-buildr's files, the server-rendered master-detail surface, and the Next
 * route a document segment calls.
 *
 * Server modules. The two interactive panes, TutorialSteps and GlossarySearch, are their own
 * `'use client'` entries that DocumentDetail imports by package path.
 *
 * Import the CSS once per site: `@import "@adh-sdk/adh/document.css"` in the site's globals.
 */
export {
  OVERVIEW_ID,
  contentDocument,
  type ContentDocument,
  type DocCard,
  type DocItem,
  type DocItemKind,
  type DocLink,
  type DocNode,
  type DocRail,
  type DocRef,
  type DocScreenshot,
  type DocSource,
  type DocTechKind,
  type DocTechTerm,
  type DocView,
  type GlossaryView,
  type TutorialView,
} from './model'
export {
  TUTORIAL_PARTS,
  glossaryOf,
  plainText,
  sectionsOf,
  slugOf,
  termMatches,
  termsFor,
  tutorialLinks,
  type DocSection,
  type GlossaryTerm,
  type TutorialPart,
  type TutorialStep,
} from './parts'
export { progressKey, readProgress, startOf, toggle, nextOpen, type TutorialProgress } from './progress'
export { DocumentSurface } from './DocumentSurface'
export { DocumentDetail } from './DocumentDetail'
export { documentRoute } from './documentRoute'

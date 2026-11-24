import { featureTsup } from '../tsup.preset'

// `topics` is a SECOND entry: the barrel's chunk carries `use client`, and the topic sets are plain
// data a server-rendered layout imports (`@adh-sdk/jobs/topics`), so they need an entry of their own.
export default featureTsup(['src/index.ts', 'src/jobs-topics.ts'])

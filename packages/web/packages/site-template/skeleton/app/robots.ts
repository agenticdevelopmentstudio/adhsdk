// WRITTEN by @adh-sdk/site-template's assembler — do not edit.
import type { MetadataRoute } from 'next'
import { frameRobots } from '@adh-sdk/site-template'
import { config } from '../src/site/config'

export default function robots(): MetadataRoute.Robots {
  return frameRobots(config)
}

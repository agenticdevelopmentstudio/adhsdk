import { describe, expect, it } from 'vitest'
import { parseRootProps, splitImports } from '../tokens'

describe('splitImports', () => {
  it('tokens-001: pulls a quoted url() import out of the css', () => {
    expect(splitImports('@import url("a.css");body{}')).toEqual({ imports: ['a.css'], rest: 'body{}' })
  })

  it('tokens-002: tolerates whitespace inside url() and before the semicolon', () => {
    expect(splitImports("@import url( 'b.css' ) ;x")).toEqual({ imports: ['b.css'], rest: 'x' })
  })

  it('tokens-003: reads an unquoted url() with no semicolon', () => {
    expect(splitImports('@import url(c.css)x')).toEqual({ imports: ['c.css'], rest: 'x' })
  })

  it('tokens-004: returns imports in source order and removes each', () => {
    expect(splitImports('@import url(a.css);p{}@import url(b.css);q{}')).toEqual({
      imports: ['a.css', 'b.css'],
      rest: 'p{}q{}',
    })
  })

  it('tokens-005: keeps duplicate imports', () => {
    expect(splitImports('@import url(a.css);@import url(a.css);')).toEqual({
      imports: ['a.css', 'a.css'],
      rest: '',
    })
  })

  it('tokens-006: only url() imports are recognised', () => {
    const css = '@import "d.css";p{}'
    expect(splitImports(css)).toEqual({ imports: [], rest: css })
  })

  it('tokens-007: empty input yields nothing and does not throw', () => {
    expect(splitImports('')).toEqual({ imports: [], rest: '' })
  })

  it('tokens-008: an import inside a comment is still extracted', () => {
    expect(splitImports('/* @import url(e.css); */p{}')).toEqual({ imports: ['e.css'], rest: '/*  */p{}' })
  })

  it('tokens-021: is pure, repeated calls return equal results', () => {
    const css = '@import url(a.css);p{}'
    expect(splitImports(css)).toEqual(splitImports(css))
    expect(splitImports(css).imports).toEqual(['a.css'])
  })
})

describe('parseRootProps', () => {
  const entries = (css: string) => [...parseRootProps(css).entries()]

  it('tokens-009: names verbatim, values trimmed, in order', () => {
    expect(entries(':root{--a:1; --B : two words ;}')).toEqual([
      ['--a', '1'],
      ['--B', 'two words'],
    ])
  })

  it('tokens-010: no :root block yields an empty map', () => {
    expect(parseRootProps('body{--a:1;}').size).toBe(0)
    expect(parseRootProps('').size).toBe(0)
  })

  it('tokens-011: only the first :root block is read', () => {
    expect(entries(':root{--a:1;} :root{--b:2;}')).toEqual([['--a', '1']])
  })

  it('tokens-012: a declaration without a final semicolon is dropped', () => {
    expect(entries(':root{--a:1;--b:2}')).toEqual([['--a', '1']])
  })

  it('tokens-013: a duplicate keeps its first position and takes the last value', () => {
    expect(entries(':root{--a:1;--b:2;--a:3;}')).toEqual([
      ['--a', '3'],
      ['--b', '2'],
    ])
  })

  it('tokens-014: a value ends at the first semicolon', () => {
    expect(entries(':root{--i:url(data:image/png;base64,AA);}')).toEqual([['--i', 'url(data:image/png']])
  })

  it('tokens-015: an empty value is kept as the empty string', () => {
    expect(entries(':root{--a: ;}')).toEqual([['--a', '']])
  })

  it('tokens-016: non-custom properties are ignored', () => {
    expect(entries(':root{color:red;--a:1;}')).toEqual([['--a', '1']])
  })

  it('tokens-017: the block ends at the first closing brace', () => {
    expect(entries(':root{--a:1;} p{--b:2;}')).toEqual([['--a', '1']])
  })

  it('tokens-018: the :root selector need not start the css', () => {
    expect(entries('html:root{--a:1;}')).toEqual([['--a', '1']])
  })

  it('tokens-019: comments are not parsed away', () => {
    expect(entries(':root{/* --a:1; */--b:2;}')).toEqual([
      ['--a', '1'],
      ['--b', '2'],
    ])
  })

  it('tokens-020: names are ASCII word characters and hyphens only', () => {
    expect(entries(':root{--é:1;--a_b-c:2;}')).toEqual([['--a_b-c', '2']])
  })

  it('tokens-022: the property match is not anchored', () => {
    expect(entries(':root{x--y:1;}')).toEqual([['--y', '1']])
  })
})

# LLM Wiki Schema

This is a personal knowledge base maintained by an LLM following the [LLM Wiki pattern](https://gist.github.com/karpathy/442a6bf555914893e9891c11519de94f).

## Directory Structure

```
raw/              # Immutable source documents (articles, papers, notes, images)
raw/assets/       # Downloaded images and attachments
wiki/             # LLM-generated and maintained markdown pages
wiki/sources/     # One summary page per ingested source
wiki/entities/    # Pages for people, orgs, products, places
wiki/concepts/    # Pages for ideas, frameworks, techniques
wiki/analyses/    # Comparisons, syntheses, filed query results
wiki/index.md     # Content catalog — read this first to find relevant pages
wiki/log.md       # Chronological append-only operation log
```

## Page Conventions

- All wiki pages use markdown with `[[wikilinks]]` for cross-references.
- Each page has YAML frontmatter:
  ```yaml
  ---
  title: Page Title
  type: source | entity | concept | analysis
  created: YYYY-MM-DD
  updated: YYYY-MM-DD
  tags: [tag1, tag2]
  sources: [source-slug]  # which raw sources informed this page
  ---
  ```
- Filenames are kebab-case slugs (e.g., `transformer-architecture.md`).
- Use `> [!note]` callouts for editorial commentary or open questions.

## Workflows

### Ingest (adding a new source)
1. Read the source document from `raw/`.
2. Discuss key takeaways with the user.
3. Create a summary page in `wiki/sources/`.
4. Update or create entity/concept pages as needed.
5. Update `wiki/index.md` with new entries.
6. Append to `wiki/log.md`.

### Query (answering questions)
1. Read `wiki/index.md` to find relevant pages.
2. Read those pages and synthesize an answer.
3. If the answer is substantial, offer to file it as a new page in `wiki/analyses/`.
4. Update index and log if a new page is created.

### Lint (health check)
1. Scan for contradictions between pages.
2. Find orphan pages (no inbound links).
3. Identify concepts mentioned but lacking their own page.
4. Check for stale claims superseded by newer sources.
5. Suggest new questions or sources to investigate.
6. Update log with findings.

## Guidelines
- The user curates sources and directs analysis. The LLM does all wiki maintenance.
- When in doubt, create a page. Pages are cheap; lost knowledge is expensive.
- Always maintain cross-references. When updating one page, check if related pages need updates.
- Prefer specific, factual claims with source attribution over vague summaries.
- Flag contradictions explicitly rather than silently resolving them.
- All wiki content must be bilingual. Write the complete page in English first, then append a full Chinese (中文) translation at the end of the document under a `---` separator and `# 中文翻译` heading. Keep the English section self-contained and readable on its own — do not interleave languages.

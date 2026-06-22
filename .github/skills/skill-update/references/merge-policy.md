# Skill Update Merge Policy

## Source Discovery

- Scan the workspace for directories whose path ends with `.agents/skills`, `.claude/skills`, `.github/skills`, or the legacy `.agent/skills`.
- Exclude the target `turtle-skills-neo` tree to avoid importing the aggregate back into itself.
- Skip heavy generated directories such as `.git`, `node_modules`, `dist`, `build`, `.next`, `coverage`, and virtual environments.

## Canonical Target

- Treat `turtle-skills-neo/.agents/skills` as the canonical output. This is the directory OpenAI Codex scans (`.agents/skills`, with the trailing `s`), and GitHub Copilot also reads it as a fallback.
- Mirror the canonical output into `turtle-skills-neo/.claude/skills` (Claude Code) and `turtle-skills-neo/.github/skills` (GitHub Copilot).
- Do not delete target-only skills. This keeps locally created aggregate skills, such as `skill-update`, intact.

## Same-Name Skill Handling

Same-name skills are merged file by file.

1. Build candidates by skill name and relative file path.
2. Hash each candidate file.
3. If all hashes are identical, keep one representative.
4. If hashes differ, choose a canonical variant and store non-selected variants.

## Canonical Variant Ranking

For most Markdown and YAML files:

1. Newer Git commit date wins.
2. If tied or unavailable, newer filesystem timestamp wins.
3. If tied, larger file wins.
4. If tied, the variant with more identical copies wins.

For scripts and accumulated project references:

1. Larger file wins, because script and overview reference changes often accumulate capabilities.
2. If tied, newer Git commit date wins.
3. If tied, newer filesystem timestamp wins.
4. If tied, the variant with more identical copies wins.

Accumulated project references include `*-overview` skills and files named `references/implementation-patterns.md` or `references/project-details.md`.

## Conflict Preservation

When a non-canonical variant exists, store one representative copy under:

```text
.skill-variants/{skill-name}/{hash-prefix}/{relative-path}
```

The manifest records:

- selected hash and source
- selected Git date when available
- non-selected hashes
- non-selected representative path
- all sources that shared that variant

## Update Behavior

- Copy only when the target file is missing or the hash differs.
- Keep existing target files when they are already identical.
- Write `.skills-aggregation-manifest.json` only on apply.
- Re-run dry-run after apply to check for remaining changes.

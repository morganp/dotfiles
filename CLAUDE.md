# Dotfiles Repo Instructions

This file contains project-level instructions for maintaining this dotfiles repo.

## Skills Layout

This repo uses `config/shared/skillbook` as the shared skills source for both
Claude and Codex. The skillbook is a Git submodule that tracks its `main`
branch.

- `config/run_stow` updates the skillbook submodule and links the whole directory
  to both `~/.claude/skills` and `~/.codex/skills`.
- Put shared, repo-managed skills in the skillbook, not under
  `config/claude/skills` or another tool-specific directory.
- Local-only skills belong in `config/shared/skillbook/arm-*`; the skillbook's
  `.gitignore` excludes that naming pattern.
- The skillbook's tracked `.system` directory contains shared Codex system
  skills. Treat tool-generated changes there as changes inside the submodule;
  do not silently discard or copy them into the parent repository.
- Commit skill changes in the skillbook repository first, then commit the new
  submodule pointer in this repository.
- When changing the skills layout, update `README.md`, `config/claude/README.md`, and this file so the rules stay current.

## Stow

- Keep `config/run_stow` idempotent.
- Keep the skillbook links pointing to
  `$HOME/dotfiles/config/shared/skillbook`; do not create separate divergent
  Claude and Codex copies.
- Preserve existing local or tool-managed files unless the user explicitly
  asks to replace or remove them. Codex's existing non-symlink skills directory
  is backed up before the shared link is created.

# Global instructions (all projects)

Personal preferences. Applies to every project.

## Delegate to agents
Use specialized subagents; keep the main thread for coordination.
- Search / research: `Explore` agent (filesystem or web).
- Coding / refactoring: a coding subagent, not the main context.
- Planning: `Plan` agent before executing complex tasks.
Sub-agents report findings back, then exit, keeping the main conversation focused.

## Style
Do not use em dashes in comments or generated text.

## OpenSCAD
When creating reusable OpenSCAD shapes, add them to the shared library:
- Repo: https://github.com/morganp/openscad-interesting-shapes
- Local source: `~/Library/Mobile Documents/com~apple~CloudDocs/Documents (home)/3DPrinter/library/interesting-shapes/`
- Installed library: `~/Documents/OpenSCAD/libraries/interesting-shapes/`
- Follow that project's CLAUDE.md workflow: add module to `interesting_shapes.scad`, example file, rendered PNG, README docs.

## Todos
Persist project todos to `todo.md` (or existing `TODO.md` / `TASKS.md`) in the project root, not session-scoped task tools. Check for an existing file first; update in place.

## Version control
Tag releases and 3D models with Semantic Versioning 2.0.0 (https://semver.org).

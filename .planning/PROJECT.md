# init-folder

## What This Is

A Claude Code agent skill that preconfigures blank folders on Windows for agentic development. The skill wraps a PowerShell script that automates project initialization: creating a local git repository, generating a smart .gitignore with interactive project type selection, setting up a GitHub remote repository under github.com/adfra, creating the .planning/ folder for GSD workflows, and making an initial baseline commit.

## Core Value

Eliminate repetitive setup friction when starting new agentic development projects. One command transforms a blank folder into a ready-to-code workspace with proper version control and project planning infrastructure.

## Requirements

### Validated

(None yet — ship to validate)

### Active

- [ ] Git repository initialization in project folder
- [ ] .gitignore creation with minimal base defaults (.env, credentials, .DS_Store, .planning/)
- [ ] Interactive project type selection to extend .gitignore appropriately
- [ ] Remote repository creation on github.com/adfra using folder name
- [ ] Empty .planning/ folder creation for GSD workflow
- [ ] Initial baseline commit with .gitignore
- [ ] gh CLI detection and usage with fallback guidance
- [ ] Clear error handling with actionable guidance

### Out of Scope

- Project-specific config files (package.json, tsconfig.json, etc.) — handled separately per project needs
- Non-Windows platform support — PowerShell script is Windows-specific
- GitHub authentication management — relies on pre-configured gh CLI auth
- Repository renaming after creation — uses folder name at initialization time
- Multi-monorepo workspace setup — single-repo projects only

## Context

User frequently creates new projects and finds manual setup repetitive and flow-breaking. Targets Claude Code environment running on Windows. Leverages GSD (Get Shit Done) workflow which requires .planning/ folder structure. Uses gh CLI as primary interface to GitHub API for repository creation.

## Constraints

- **Platform**: Windows only — PowerShell script required for Windows filesystem and process management
- **GitHub account**: Hardcoded to adfra account — simplifies repo creation, reduces prompts
- **Tool dependency**: Requires gh CLI for GitHub remote creation — needs fallback guidance if missing
- **Invocation**: Claude Code skill interface — must work within Claude Code's AskUserQuestion pattern
- **User interaction**: Requires interactive selection for .gitignore customization — not fully headless

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| PowerShell script implementation | Windows-specific, native access to filesystem and git commands | — Pending |
| Minimal .gitignore base + interactive extension | Balances sensible defaults with project-specific needs | — Pending |
| Folder name as GitHub repo name | Reduces prompts, matches common convention | — Pending |
| Initial baseline commit | Establishes origin properly, enables immediate collaboration | — Pending |
| Fail-with-guidance error handling | User wants clear next steps, not silent failures | — Pending |

## Evolution

This document evolves at phase transitions and milestone boundaries.

**After each phase transition** (via `/gsd-transition`):
1. Requirements invalidated? → Move to Out of Scope with reason
2. Requirements validated? → Move to Validated with phase reference
3. New requirements emerged? → Add to Active
4. Decisions to log? → Add to Key Decisions
5. "What This Is" still accurate? → Update if drifted

**After each milestone** (via `/gsd-complete-milestone`):
1. Full review of all sections
2. Core Value check — still the right priority?
3. Audit Out of Scope — reasons still valid?
4. Update Context with current state

---
*Last updated: 2025-04-25 after initialization*

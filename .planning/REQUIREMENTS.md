# Requirements: init-folder

**Defined:** 2025-04-25
**Core Value:** Eliminate repetitive setup friction when starting new agentic development projects.

## v1 Requirements

Requirements for initial release. Each maps to roadmap phases.

### Git Setup

- [ ] **GIT-01**: Skill creates new git repository in the target project folder
- [ ] **GIT-02**: Skill makes initial baseline commit containing .gitignore

### Gitignore

- [ ] **IGNR-01**: Skill creates .gitignore with minimal base defaults (.env, credentials, .DS_Store, .planning/)
- [ ] **IGNR-02**: Skill presents interactive project type selection using AskUserQuestion
- [ ] **IGNR-03**: Skill extends .gitignore based on selected project type(s)

### GitHub Integration

- [ ] **HUB-01**: Skill creates remote repository on github.com/adfra using folder name
- [ ] **HUB-02**: Skill checks for gh CLI installation before attempting GitHub operations
- [ ] **HUB-03**: Skill provides actionable guidance when gh CLI is not available

### Project Structure

- [ ] **STRUCT-01**: Skill creates empty .planning/ folder for GSD workflow

### Error Handling

- [ ] **ERR-01**: Skill provides clear error messages with actionable guidance for all failure scenarios

## v2 Requirements

Deferred to future release. Tracked but not in current roadmap.

(None identified yet)

## Out of Scope

Explicitly excluded. Documented to prevent scope creep.

| Feature | Reason |
|---------|--------|
| Project-specific config files (package.json, tsconfig.json, etc.) | Handled separately per project needs, not part of baseline setup |
| Non-Windows platform support | PowerShell script is Windows-specific by design |
| GitHub authentication management | Relies on pre-configured gh CLI auth, out of scope for this tool |
| Repository renaming after creation | Uses folder name at initialization, renaming is manual GitHub operation |
| Multi-monorepo workspace setup | Single-repo projects only, monorepos have different requirements |
| .gitignore template management | Uses project type selection, not custom template system |

## Traceability

Which phases cover which requirements. Updated during roadmap creation.

| Requirement | Phase | Status |
|-------------|-------|--------|
| GIT-01 | Phase 1 | Pending |
| GIT-02 | Phase 1 | Pending |
| IGNC-01 | Phase 1 | Pending |
| IGNC-02 | Phase 1 | Pending |
| IGNC-03 | Phase 1 | Pending |
| HUB-01 | Phase 1 | Pending |
| HUB-02 | Phase 1 | Pending |
| HUB-03 | Phase 1 | Pending |
| STRUCT-01 | Phase 1 | Pending |
| ERR-01 | Phase 1 | Pending |

**Coverage:**
- v1 requirements: 10 total
- Mapped to phases: 10
- Unmapped: 0 ✓

---
*Requirements defined: 2025-04-25*
*Last updated: 2025-04-25 after initial definition*

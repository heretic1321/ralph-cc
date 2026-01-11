# PRD: Migrate Ralph from Amp Code to Claude Code

## Introduction

Ralph is an autonomous AI agent loop that repeatedly spawns AI instances to implement PRD-based user stories. Currently, the codebase has partial Amp Code references remaining in `ralph.sh` and skill files. This migration completes the transition to Claude Code CLI, ensuring full compatibility with Claude Code's tooling, session management, and MCP-based browser automation.

## Goals

- Replace all remaining Amp CLI references with Claude Code CLI equivalents
- Update skill files to use Claude Code conventions and session tracking
- Add Playwright MCP references for browser verification in UI stories
- Ensure ralph.sh works with Claude Code's `--dangerously-skip-permissions` flag
- Maintain backward compatibility with existing PRD/progress.txt workflows

## User Stories

### US-001: Update ralph.sh to use Claude Code CLI
**Description:** As a developer, I want ralph.sh to invoke Claude Code instead of Amp so that the loop works with Claude Code CLI.

**Acceptance Criteria:**
- [ ] Replace `amp --dangerously-allow-all` with `claude --dangerously-skip-permissions -p`
- [ ] Pipe prompt.md content correctly to Claude Code CLI
- [ ] Output streams to terminal correctly (tee /dev/stderr)
- [ ] Completion signal detection still works (`<promise>COMPLETE</promise>`)
- [ ] Script runs successfully with `./ralph.sh 1` for a single iteration test

### US-002: Update prd skill for Claude Code
**Description:** As a developer, I want the PRD skill to reference Claude Code patterns so generated PRDs are compatible with Claude Code workflows.

**Acceptance Criteria:**
- [ ] Replace "dev-browser skill" references with "Playwright MCP server" for browser verification
- [ ] Update acceptance criteria examples to use "Verify in browser using Playwright MCP"
- [ ] Keep skill structure and format unchanged
- [ ] Skill file is valid markdown with correct frontmatter

### US-003: Update ralph skill for Claude Code
**Description:** As a developer, I want the Ralph skill to reference Claude Code patterns so it generates correct prd.json files.

**Acceptance Criteria:**
- [ ] Replace "Amp instance" references with "Claude Code instance"
- [ ] Replace "dev-browser skill" with "Playwright MCP server" references
- [ ] Update browser verification criteria to "Verify in browser using Playwright MCP"
- [ ] Keep JSON output format unchanged
- [ ] Skill file is valid markdown with correct frontmatter

### US-004: Add session ID tracking to skill files
**Description:** As a developer, I want skill files to include the session ID command so generated PRDs can reference Claude Code sessions.

**Acceptance Criteria:**
- [ ] Add session ID command block to prd skill (same as prompt.md)
- [ ] Add session ID command block to ralph skill
- [ ] Include instruction to record session ID in progress.txt entries
- [ ] Command works on Linux (uses `stat -c`)

### US-005: Update prompt.md browser testing section
**Description:** As a developer, I want prompt.md to reference Playwright MCP for browser testing so agents know which tool to use.

**Acceptance Criteria:**
- [ ] Update "Browser Testing" section to mention Playwright MCP server
- [ ] Add instruction to install Playwright MCP if not available (`claude mcp add playwright`)
- [ ] Keep the verification workflow (dev server, navigate, verify, screenshot)
- [ ] Maintain existing section structure

## Functional Requirements

- FR-1: `ralph.sh` must use `claude` CLI instead of `amp` CLI
- FR-2: `ralph.sh` must pass prompt via `-p` flag with proper quoting
- FR-3: `ralph.sh` must use `--dangerously-skip-permissions` for autonomous operation
- FR-4: Skill files must reference Playwright MCP for browser automation
- FR-5: Skill files must include session ID retrieval command
- FR-6: All markdown files must be valid and properly formatted

## Non-Goals

- No changes to prd.json format or structure
- No changes to progress.txt format
- No changes to AGENTS.md update workflow
- No multi-platform support for session ID command (Linux only for now)
- No automatic MCP installation (just documentation)

## Technical Considerations

- Claude Code CLI syntax: `claude -p "prompt" --dangerously-skip-permissions`
- Session files stored at: `~/.claude/projects/-<project-path>/<session-uuid>.jsonl`
- Playwright MCP installation: `claude mcp add playwright npx '@playwright/mcp@latest'`

## Success Metrics

- `./ralph.sh 1` completes one iteration successfully with Claude Code
- Generated PRDs reference Playwright MCP for browser verification
- Session IDs can be captured and recorded in progress.txt
- No remaining "Amp" or "ampcode.com" references in codebase

## Open Questions

- Should we add macOS support for session ID command (uses `stat` differently)?
- Should we add a check in ralph.sh to verify Claude Code CLI is installed?

## References

- [Playwright MCP Server](https://github.com/playwright-community/mcp)
- [Claude Code Documentation](https://docs.anthropic.com/en/docs/claude-code)
- [Claude Code Best Practices](https://www.anthropic.com/engineering/claude-code-best-practices)

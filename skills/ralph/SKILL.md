---
name: ralph
description: "Convert PRDs to prd.json format for the Ralph autonomous agent system. Use when you have an existing PRD and need to convert it to Ralph's JSON format. Triggers on: convert this prd, turn this into ralph format, create prd.json from this, ralph json."
---

# Ralph PRD Converter

Converts existing PRDs to the prd.json format that Ralph uses for autonomous execution. Stories are organized as a **dependency tree** to enable parallel execution.

---

## The Job

Take a PRD (markdown file or text) and convert it to `prd.json` in your ralph directory.

---

## Output Format

```json
{
  "project": "[Project Name]",
  "branchName": "ralph/[feature-name-kebab-case]",
  "description": "[Feature description from PRD title/intro]",
  "userStories": [
    {
      "id": "US-001",
      "title": "[Story title]",
      "description": "As a [user], I want [feature] so that [benefit]",
      "acceptanceCriteria": [
        "Criterion 1",
        "Criterion 2",
        "Typecheck passes"
      ],
      "dependsOn": [],
      "passes": false,
      "notes": ""
    },
    {
      "id": "US-002",
      "title": "[Another story]",
      "description": "...",
      "acceptanceCriteria": ["..."],
      "dependsOn": ["US-001"],
      "passes": false,
      "notes": ""
    }
  ]
}
```

### Dependency Tree Structure

Instead of linear `priority`, stories use `dependsOn` to form a tree:

```
        US-001 (dependsOn: [])     ← Root story, runs first
        /     \
   US-002    US-003               ← Both depend on US-001, can run in PARALLEL
   (dependsOn: ["US-001"])
        \     /
        US-004                    ← Depends on both, waits for both
   (dependsOn: ["US-002", "US-003"])
```

**Key rules:**
- Stories with `dependsOn: []` are root stories (run immediately)
- Stories with same dependencies can run in **parallel**
- A story only starts when ALL its dependencies have `passes: true`

---

## Story Size: The Number One Rule

**Each story must be completable in ONE Ralph iteration (one context window).**

Ralph spawns a fresh Claude Code instance per iteration with no memory of previous work. If a story is too big, the LLM runs out of context before finishing and produces broken code.

### Right-sized stories:
- Add a database column and migration
- Add a UI component to an existing page
- Update a server action with new logic
- Add a filter dropdown to a list

### Too big (split these):
- "Build the entire dashboard" - Split into: schema, queries, UI components, filters
- "Add authentication" - Split into: schema, middleware, login UI, session handling
- "Refactor the API" - Split into one story per endpoint or pattern

**Rule of thumb:** If you cannot describe the change in 2-3 sentences, it is too big.

---

## Story Ordering: Dependency Tree

Stories execute based on their `dependsOn` array. A story can only run when ALL its dependencies have `passes: true`.

**Typical dependency layers:**
1. **Root stories** (`dependsOn: []`) - Schema/database changes, migrations
2. **Second layer** - Server actions/backend logic depending on schema
3. **Third layer** - UI components depending on backend
4. **Final layer** - Integration/summary views depending on multiple components

**Example tree:**
```
US-001 (schema)           ← dependsOn: []
    ├── US-002 (API)      ← dependsOn: ["US-001"]
    │       └── US-004    ← dependsOn: ["US-002"]
    └── US-003 (types)    ← dependsOn: ["US-001"]
            └── US-005    ← dependsOn: ["US-003"]
                    └── US-006 ← dependsOn: ["US-004", "US-005"]
```

**Parallel execution:** US-002 and US-003 can run simultaneously. US-004 and US-005 can also run in parallel once their respective dependencies complete.

---

## Acceptance Criteria: Must Be Verifiable

Each criterion must be something Ralph can CHECK, not something vague.

### Good criteria (verifiable):
- "Add `status` column to tasks table with default 'pending'"
- "Filter dropdown has options: All, Active, Completed"
- "Clicking delete shows confirmation dialog"
- "Typecheck passes"
- "Tests pass"

### Bad criteria (vague):
- "Works correctly"
- "User can do X easily"
- "Good UX"
- "Handles edge cases"

### Always include as final criterion:
```
"Typecheck passes"
```

For stories with testable logic, also include:
```
"Tests pass"
```

### For stories that change UI, also include:
```
"Verify in browser using agent-browser skill"
```

Frontend stories are NOT complete until visually verified. Ralph will load the agent-browser skill to navigate to the page, interact with the UI, and confirm changes work.

---

## Conversion Rules

1. **Each user story becomes one JSON entry**
2. **IDs**: Sequential (US-001, US-002, etc.)
3. **dependsOn**: Array of story IDs this story requires (empty `[]` for root stories)
4. **All stories**: `passes: false` and empty `notes`
5. **branchName**: Derive from feature name, kebab-case, prefixed with `ralph/`
6. **Always add**: "Typecheck passes" to every story's acceptance criteria
7. **Identify parallelizable stories**: Stories that share the same dependencies should have identical `dependsOn` arrays

---

## Splitting Large PRDs

If a PRD has big features, split them:

**Original:**
> "Add user notification system"

**Split into:**
1. US-001: Add notifications table to database
2. US-002: Create notification service for sending notifications
3. US-003: Add notification bell icon to header
4. US-004: Create notification dropdown panel
5. US-005: Add mark-as-read functionality
6. US-006: Add notification preferences page

Each is one focused change that can be completed and verified independently.

---

## Example

**Input PRD:**
```markdown
# Task Status Feature

Add ability to mark tasks with different statuses.

## Requirements
- Toggle between pending/in-progress/done on task list
- Filter list by status
- Show status badge on each task
- Persist status in database
```

**Dependency Tree:**
```
        US-001 (schema)
        /     \
   US-002    US-003  ← Can run in PARALLEL (both depend only on US-001)
        \     /
        US-004       ← Depends on both UI stories
```

**Output prd.json:**
```json
{
  "project": "TaskApp",
  "branchName": "ralph/task-status",
  "description": "Task Status Feature - Track task progress with status indicators",
  "userStories": [
    {
      "id": "US-001",
      "title": "Add status field to tasks table",
      "description": "As a developer, I need to store task status in the database.",
      "acceptanceCriteria": [
        "Add status column: 'pending' | 'in_progress' | 'done' (default 'pending')",
        "Generate and run migration successfully",
        "Typecheck passes"
      ],
      "dependsOn": [],
      "passes": false,
      "notes": ""
    },
    {
      "id": "US-002",
      "title": "Display status badge on task cards",
      "description": "As a user, I want to see task status at a glance.",
      "acceptanceCriteria": [
        "Each task card shows colored status badge",
        "Badge colors: gray=pending, blue=in_progress, green=done",
        "Typecheck passes",
        "Verify in browser using agent-browser skill"
      ],
      "dependsOn": ["US-001"],
      "passes": false,
      "notes": ""
    },
    {
      "id": "US-003",
      "title": "Add status toggle to task list rows",
      "description": "As a user, I want to change task status directly from the list.",
      "acceptanceCriteria": [
        "Each row has status dropdown or toggle",
        "Changing status saves immediately",
        "UI updates without page refresh",
        "Typecheck passes",
        "Verify in browser using agent-browser skill"
      ],
      "dependsOn": ["US-001"],
      "passes": false,
      "notes": ""
    },
    {
      "id": "US-004",
      "title": "Filter tasks by status",
      "description": "As a user, I want to filter the list to see only certain statuses.",
      "acceptanceCriteria": [
        "Filter dropdown: All | Pending | In Progress | Done",
        "Filter persists in URL params",
        "Typecheck passes",
        "Verify in browser using agent-browser skill"
      ],
      "dependsOn": ["US-002", "US-003"],
      "passes": false,
      "notes": ""
    }
  ]
}
```

**Note:** US-002 and US-003 can be executed in **parallel** since they both only depend on US-001. This saves time compared to sequential execution.

---

## Archiving Previous Runs

**Before writing a new prd.json, check if there is an existing one from a different feature:**

1. Read the current `prd.json` if it exists
2. Check if `branchName` differs from the new feature's branch name
3. If different AND `progress.txt` has content beyond the header:
   - Create archive folder: `archive/YYYY-MM-DD-feature-name/`
   - Copy current `prd.json` and `progress.txt` to archive
   - Reset `progress.txt` with fresh header

**The ralph.sh script handles this automatically** when you run it, but if you are manually updating prd.json between runs, archive first.

---

## Checklist Before Saving

Before writing prd.json, verify:

- [ ] **Previous run archived** (if prd.json exists with different branchName, archive it first)
- [ ] Each story is completable in one iteration (small enough)
- [ ] **dependsOn arrays are correct** (no circular dependencies, all referenced IDs exist)
- [ ] **Parallelizable stories identified** (stories that can run together have same dependencies)
- [ ] Every story has "Typecheck passes" as criterion
- [ ] UI stories have "Verify in browser using agent-browser skill" as criterion
- [ ] Acceptance criteria are verifiable (not vague)
- [ ] Root stories have `dependsOn: []`

---

## Session Tracking (Claude Code)

When working with Ralph, record your session ID in progress.txt so future iterations can reference your work if needed.

**Getting Session ID**: Run this command to get your current session ID:
```bash
project_encoded=$(pwd | tr '/' '-' | sed 's/^-//')
session_file=$(stat -c '%Y %n' ~/.claude/projects/-${project_encoded}/*.jsonl 2>/dev/null | sort -rn | head -1 | cut -d' ' -f2-)
basename "$session_file" .jsonl
```

Include the session ID in your progress.txt entries:
```
## [Date/Time] - [Story ID]
Session: <session-id>
- What was implemented
- Files changed
- Learnings for future iterations
```

Future iterations can resume context using `claude --resume <session-id>` if deeper context is needed.

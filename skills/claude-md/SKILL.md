---
name: claude-md
description: "Create or update CLAUDE.md for a project. Use after completing a user story to document project-wide learnings, commands, and patterns. Triggers on: update claude.md, create claude.md, document project."
---

# CLAUDE.md Manager

Create and maintain the project's CLAUDE.md file with discovered patterns, commands, and conventions.

---

## The Job

After completing a user story, update CLAUDE.md with any project-wide learnings:
- New commands discovered
- Stack versions confirmed
- Global patterns identified
- Gotchas encountered

**Principle:** Show, don't tell. A code example communicates more than a paragraph.

---

## When to Update

Update CLAUDE.md when you discover:

| Discovery | Section to Update |
|-----------|-------------------|
| New build/test/dev command | Commands |
| Package version matters | Tech Stack |
| Project structure changes | Key Directories |
| Coding pattern to follow | Code Style |
| Something that broke unexpectedly | Known Gotchas |
| Files that shouldn't be touched | Boundaries |

**Don't update** for folder-specific patterns - those go in AGENTS.md.

---

## Creating New CLAUDE.md

If CLAUDE.md doesn't exist, create it with this structure:

```markdown
# [Project Name]

## About This Project

[2-3 sentences: what it does, who it's for]

---

## Tech Stack

- **Framework:** [e.g., Next.js 14.2]
- **Language:** [e.g., TypeScript 5.4]
- **Database:** [e.g., PostgreSQL 16]
- **Styling:** [e.g., Tailwind CSS 3.4]
- **Other:** [e.g., Prisma 5.10]

---

## Key Directories

\`\`\`
src/          → Application code
tests/        → Test files
config/       → Configuration
docs/         → Documentation
\`\`\`

---

## Commands

\`\`\`bash
# Development
npm run dev

# Testing
npm test

# Build
npm run build

# Lint
npm run lint
\`\`\`

---

## Code Style

\`\`\`tsx
// Example of project's preferred patterns
// Add real examples as you discover them
\`\`\`

---

## Workflow

1. Create feature branch from \`main\`
2. Write tests first
3. Implement feature
4. Run quality checks
5. Commit with conventional message

---

## Boundaries

**Always:**
- Run tests before committing
- Follow existing patterns

**Ask first:**
- Changes to database schema
- Modifying public APIs

**Never:**
- Commit secrets or credentials
- Skip quality checks

---

## Known Gotchas

*Add lessons learned here as you encounter them*
```

---

## Updating Existing CLAUDE.md

Read the existing file first, then append or modify the relevant section.

### Adding a Command

```markdown
## Commands

```bash
# Existing commands...

# [NEW] Database migrations
npm run db:migrate
```
```

### Adding to Tech Stack

**Always include version numbers** - this helps with documentation lookups:

```markdown
## Tech Stack

- **Framework:** Next.js 14.2  ← Include version
- **ORM:** Prisma 5.10         ← Include version
```

### Adding a Code Style Example

**Show, don't tell.** One example beats a paragraph of explanation:

```markdown
## Code Style

\`\`\`tsx
// Error handling pattern
try {
  await fetchData()
} catch (e) {
  throw new ApiError(e.message, { cause: e })
}

// API response pattern
return NextResponse.json({ data }, { status: 200 })
\`\`\`
```

### Adding a Gotcha

```markdown
## Known Gotchas

- **Prisma schema changes**: Always run `npx prisma generate` after modifying `schema.prisma`
- **Environment variables**: New env vars need to be added to `.env.example` too
```

### Adding a Boundary

```markdown
## Boundaries

**Never:**
- Modify `/migrations` directly - use Prisma migrate
- Delete test files without replacement
```

---

## Examples of Good Updates

### After discovering a build command:

```markdown
## Commands

```bash
# Build for production (generates optimized bundle)
npm run build

# Preview production build locally
npm run preview
```
```

### After finding a version-specific behavior:

```markdown
## Tech Stack

- **React:** 18.2 (uses automatic JSX runtime - no React import needed)
- **Tailwind:** 3.4 (uses new `size-*` utilities)
```

### After encountering a gotcha:

```markdown
## Known Gotchas

- **Hot reload breaks**: If HMR stops working, delete `.next` folder and restart
- **Type errors on fresh clone**: Run `npm run postinstall` to generate types
```

### After discovering a pattern:

```markdown
## Code Style

\`\`\`tsx
// Server action pattern (Next.js 14+)
'use server'

export async function createUser(formData: FormData) {
  const validated = schema.parse(Object.fromEntries(formData))
  return await db.user.create({ data: validated })
}
\`\`\`
```

---

## Checklist Before Saving

- [ ] Version numbers included for all stack items
- [ ] Code examples used instead of descriptions where possible
- [ ] Only project-wide patterns (not folder-specific)
- [ ] Commands are copy-pasteable
- [ ] Gotchas include the fix, not just the problem

---

## Session Tracking (Claude Code)

**Getting Session ID**: Run this command to get your current session ID:
```bash
project_encoded=$(pwd | tr '/' '-' | sed 's/^-//')
session_file=$(stat -c '%Y %n' ~/.claude/projects/-${project_encoded}/*.jsonl 2>/dev/null | sort -rn | head -1 | cut -d' ' -f2-)
basename "$session_file" .jsonl
```

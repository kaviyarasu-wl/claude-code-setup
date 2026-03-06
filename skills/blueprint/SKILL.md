---
name: blueprint
description: Decompose feature requests into detailed multi-document task plans. Use for breaking down features into atomic implementation tasks with specs, dependency graphs, and ready-to-use prompts. Planning only - never implements code.
allowed-tools: Read, Grep, Glob, Write, Edit, Bash(ls:*), Bash(git log:*), Bash(git diff:*), Bash(wc:*), Bash(tree:*), AskUserQuestion
---

# Blueprint Skill

## Overview

Decompose any feature request into a comprehensive, multi-document implementation plan. Produces an ordered set of atomic task documents, each containing a full specification and a ready-to-use Claude Code prompt. Tech-stack agnostic: auto-detects project conventions before planning.

**Important**: This skill ONLY creates planning documents. It does NOT implement any code. The generated task documents contain prompts you can use later to execute each task.

## Invocation

```
/blueprint <feature description>
/blueprint "Add real-time notifications with WebSocket support"
/blueprint "Multi-tenant billing system with Stripe integration"
```

## What This Skill Does NOT Do

- Does NOT write or modify source code
- Does NOT create migrations, models, components, or any implementation files
- Does NOT run tests or commands beyond readonly operations (ls, git log, tree)
- Does NOT commit changes

The output is documentation only. Implementation happens separately, using the generated prompts.

## Process

### Phase 1: Codebase Reconnaissance

Before any planning, deeply scan the project to understand what exists.

#### 1.1 Detect Tech Stack

Scan for manifest files to identify languages, frameworks, and tooling:

```
package.json          # Node.js / React / Vue / Angular
composer.json         # PHP / Laravel / Symfony
Cargo.toml            # Rust
go.mod                # Go
pyproject.toml        # Python (modern)
requirements.txt      # Python (legacy)
Gemfile               # Ruby / Rails
pom.xml               # Java / Spring
build.gradle          # Java / Kotlin
pubspec.yaml          # Dart / Flutter
*.csproj              # .NET / C#
Makefile              # General build
docker-compose.yml    # Container orchestration
```

#### 1.2 Map Architecture

- Identify directory structure conventions (src/, app/, lib/, internal/, etc.)
- Detect architectural patterns (MVC, DDD, Clean Architecture, Modular Monolith)
- Find config files (tsconfig.json, .eslintrc, phpstan.neon, etc.)
- Check for monorepo indicators (workspaces, lerna.json, turbo.json, packages/)
- Identify test framework and test directory conventions
- Read README.md and any docs/ directory for project context

#### 1.3 Map Related Code

Using Grep and Glob, find existing code that relates to the requested feature:

- Similar feature implementations (pattern references)
- Shared utilities, base classes, traits that should be reused
- Database models/schemas that will be touched
- API routes and middleware relevant to the feature
- Existing test patterns for similar features

#### 1.4 Produce Context Summary

Build an internal context object containing:

- Tech stack and versions
- Architecture pattern
- Directory conventions
- Test framework and conventions
- Related existing code files
- Naming conventions observed

Do NOT write this to disk. Use it to inform all subsequent phases.

### Phase 2: Clarification

**CRITICAL RULE: Never assume. Always ask.**

Use the `AskUserQuestion` tool to resolve ambiguities. Follow these rules strictly.

#### Question Strategy

Ask questions in batched rounds (maximum 4 questions per round). Continue rounds until all doubts are resolved.

**Tier 1 - Always evaluate (ask in Round 1 if unclear):**

1. **Scope Boundaries**
   - What is explicitly IN scope vs OUT of scope?
   - Is this a complete feature or part of a larger initiative?
   - Are there related features being built in parallel?

2. **Primary User Flow**
   - Who are the actors/users? (roles, permissions)
   - What are the primary user flows?
   - Are there admin/management interfaces needed?
   - What happens on error? What feedback does the user see?

3. **Data Model**
   - What new data entities are needed?
   - What existing data is affected?
   - What are the relationships between entities?

4. **Integration Points**
   - Are there existing APIs or services this must integrate with?
   - Are there third-party services involved?

**Tier 2 - Ask in Round 2 if still ambiguous:**

5. **Error Handling**: What should happen when operations fail? User-facing feedback?
6. **Permissions**: Who can access this? Different permission levels?
7. **Performance**: Specific response time, throughput, or concurrency requirements?
8. **Migration/Rollout**: Feature-flagged? Existing data that needs migrating?

**Tier 3 - Ask only if relevant:**

9. **Real-time**: Does any part need real-time updates (WebSocket, SSE, polling)?
10. **Notifications**: Should the system notify users about events?
11. **Analytics**: Do user actions need tracking or measurement?
12. **Localization**: Multiple language support needed?

#### Question Rules

- Never ask about things you can determine from the codebase scan
- Never ask more than 4 questions in a single round
- Order questions by impact (high-impact ambiguities first)
- Provide context for WHY you are asking each question
- Offer default suggestions when you have a reasonable guess
- Stop asking when you have enough clarity to produce a sound plan
- If the feature description is fewer than 10 words or highly ambiguous, ask the user to elaborate BEFORE any planning

#### Question Format

Each question must include:
- The question itself
- Why it matters for the plan (brief reason)
- A suggested default if you have a reasonable guess

### Phase 3: Decomposition

Break the feature into atomic, ordered tasks.

#### 3.1 Decomposition Rules

- **Single Responsibility**: Each task does one logical thing
- **Self-Contained**: A task can be implemented and verified independently
- **Practical Granularity**: Dynamic based on complexity analysis
  - Simple changes can be grouped: "Create migration + model + factory" = 1 task
  - Complex logic must be split: "Build payment processing" = multiple tasks (Stripe setup, webhook handler, payment form, receipt generation)
- **Testable**: Each task has clear acceptance criteria that can be verified
- **Ordered**: Tasks respect dependencies (database before API, API before UI)

#### 3.2 Dependency Analysis

For each task, identify:
- **Blocks**: What tasks must complete before this one can start?
- **Blocked By**: What tasks depend on this one completing?
- **Parallel Candidates**: Tasks with no shared dependencies that can run simultaneously

#### 3.3 Task Categories

Categorize each task as one of:
- `schema` - Database migrations, models, relationships
- `backend` - API endpoints, services, business logic
- `frontend` - UI components, pages, forms
- `integration` - Third-party service connections
- `infrastructure` - Config, environment, deployment
- `testing` - Test suites, fixtures, coverage
- `documentation` - API docs, user guides, READMEs

#### 3.4 Phase Grouping

Group tasks into execution phases:
- Tasks in the same phase can be run in parallel
- Each phase depends on all previous phases completing
- If total tasks exceed 15, add milestone markers

### Phase 4: Document Generation (Final Output - No Implementation)

#### 4.1 Output Directory

```
./docs/features/<feature-slug>/
  00-overview.md
  01-<task-slug>.md
  02-<task-slug>.md
  03-<task-slug>.md
  ...
```

**Slug generation:**
- Lowercase, hyphen-separated
- Max 50 characters
- No special characters
- Descriptive but concise

#### 4.2 Overview Document (00-overview.md)

Use the overview-template.md as reference. Must contain:

1. **Feature Summary**: 2-3 sentence description
2. **Tech Stack Context**: Detected stack, frameworks, key dependencies
3. **Scope**: In-scope and out-of-scope (from clarification phase)
4. **Task List**: Table with task number, name, category, complexity, dependencies, estimated file count
5. **Dependency Graph**: Both Mermaid diagram AND plain text execution order
6. **Key Decisions**: Architectural decisions made during planning
7. **Related Existing Code**: Files that will be modified or referenced
8. **Risk Factors**: Potential challenges with mitigation strategies
9. **Metadata**: Generation date, version, task count

#### 4.3 Task Documents (01-task-name.md, etc.)

Use the task-template.md as reference. Each document has TWO major sections:

**SPEC Section:**
- Goal: One sentence describing what this task accomplishes
- Category: One of the task categories
- Dependencies: Task numbers that must complete first
- Files to Create: Full paths of new files with purpose
- Files to Modify: Full paths of existing files with change description
- Implementation Steps: Numbered steps with technical detail
- Acceptance Criteria: Bullet list of verifiable conditions
- Edge Cases: Failure modes and handling strategy
- Testing Requirements: What tests to write, coverage target
- Notes: Context from codebase scan or clarification

**PROMPT Section:**
- Complete, ready-to-use Claude Code prompt
- References specific files, patterns, and conventions from the codebase
- Includes all context needed to execute WITHOUT reading other task docs
- Structured as: Context -> What to Build -> Files -> Implementation Details -> Acceptance Criteria -> Testing -> Edge Cases
- Includes explicit instructions to verify acceptance criteria after implementation

**Navigation Footer:**
- Link to parent overview
- Previous/Next task links

## Edge Cases

### Existing Documentation Directory
If `./docs/features/<feature-slug>/` already exists:
1. Notify the user that prior docs exist
2. Ask whether to overwrite, create versioned directory (`-v2`), or abort
3. **Never silently overwrite**

### Slug Conflicts
If the generated slug collides with an existing directory:
1. Append incrementing suffix: `feature-name-2`, `feature-name-3`
2. Inform the user of the rename

### Monorepo Detection
If the project is a monorepo (workspaces, packages/, etc.):
1. Ask which package/app the feature targets
2. Scope codebase scanning to that package
3. Note shared packages that might need changes
4. Include package path prefix in all file paths

### Vague Feature Descriptions
If the feature description is fewer than 10 words or highly ambiguous:
1. Do NOT proceed to decomposition
2. Ask the user to elaborate before any planning
3. Prompt: "Can you describe: the user flow, the data involved, and any integrations needed?"

### Very Large Features (>15 tasks)
1. Group into phases/milestones
2. Add a "Phases" section to the overview
3. Mark phase boundaries in the dependency graph

### Empty/New Project
If no source code exists yet:
1. Skip Phase 1.3 (Map Related Code)
2. Ask the user about desired architecture and conventions
3. Generate tasks starting from project scaffolding

### Feature Already Partially Implemented
If Grep finds existing code that partially implements the feature:
1. Flag it to the user
2. Ask: "It appears {component} already exists at {path}. Should the blueprint extend this, replace it, or skip it?"
3. Adjust task list accordingly

### No Git Repository
If `git log` fails (no git repo):
1. Skip git-based analysis
2. Proceed with file-based scanning only
3. Note in overview that version control context was unavailable

### Conflicting Conventions in Codebase
If inconsistent patterns exist (e.g., some controllers use Actions, others don't):
1. Ask the user which pattern to follow
2. Document the decision in the overview's "Key Decisions" section

### Very Small Features (<3 tasks)
1. Still generate the overview + individual task documents
2. Do not artificially split tasks
3. Note in overview: "This is a small feature with minimal decomposition needed"

## Quality Checks

Before finalizing documents, verify ALL of these:

- [ ] Every task has at least one acceptance criterion
- [ ] No circular dependencies exist in the task graph
- [ ] All file paths for modifications reference real directories in the project
- [ ] Each prompt section is self-contained (no "see task X" references)
- [ ] Task numbering is sequential with no gaps
- [ ] Overview dependency graph matches individual task dependency lists
- [ ] Total scope aligns with user's stated requirements (nothing added, nothing missing)
- [ ] Mermaid diagram syntax is valid
- [ ] All slug names are valid (lowercase, hyphens, no special chars)

## Usage

```
/blueprint "User notification system with email and in-app alerts"
/blueprint "Add multi-currency support to the checkout flow"
/blueprint "Build admin dashboard with analytics and user management"
/blueprint "Implement OAuth2 login with Google and GitHub providers"
/blueprint "Real-time collaborative document editing"
```

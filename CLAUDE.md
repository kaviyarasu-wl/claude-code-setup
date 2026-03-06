# Claude Code Configuration

## Skills

| Command | Purpose | Model |
|---------|---------|-------|
| `/api` | Scaffold REST APIs (Laravel + React) | sonnet |
| `/blueprint` | Decompose features into detailed task plans | opus |
| `/debug` | Systematic debugging (Laravel + React) | opus |
| `/deploy` | DevOps automation (Docker, CI/CD, nginx) | sonnet |
| `/migrate` | Database migrations and schema design | sonnet |
| `/n8n` | Build and debug n8n workflows | sonnet |
| `/refactor` | Code refactoring with SOLID principles | opus |
| `/security-scan` | OWASP security checklist | opus |
| `/code-review` | Deep code review for files/directories | opus |
| `/testing` | Generate or improve tests | sonnet |
| `/documentation` | Generate or update documentation | sonnet |
| `/commit` | Conventional commits with co-authorship | - |
| `/review-pr` | PR review with quality/security checklist | opus |
| `/catchup` | Recent git changes summary | - |
| `/context` | Analyze context usage | - |
| `/pr` | Prepare pull request | - |

## Design Pattern Triggers

| When You See | Apply |
|--------------|-------|
| >3 type/mode branches | Strategy |
| Constructor >5 params | Factory/Builder |
| DB queries in business logic | Repository |
| Event source coupled to handlers | Observer |

## Agent Delegation

Delegate to subagents to preserve main context. Each agent runs in its own context window.

| When You Need To | Delegate To | Model |
|------------------|-------------|-------|
| Explore codebase, find files, understand structure | `Explore` (built-in) | - |
| Design architecture, evaluate patterns, plan system design | `elite-project-architect` | opus |
| Build React/Vue/Laravel components, implement features | `elite-fullstack-developer` | opus |
| Design schemas, optimize queries, plan migrations | `elite-database-specialist` | opus |
| Set up CI/CD, Docker, Kubernetes, cloud infra | `elite-devops-automation` | opus |
| Profile performance, find bottlenecks, optimize | `elite-performance-optimizer` | opus |
| Coordinate multi-phase features (PACT workflow) | `elite-project-orchestrator` | opus |
| Run tests and report failures | `test-runner` | haiku |
| Audit dependencies for vulnerabilities | `dependency-auditor` | haiku |
| Research third-party API docs, library usage | `documentation-researcher` | haiku |
| Analyze error logs, stack traces, crashes | `log-analyzer` | sonnet |

### Delegation Rules
- **Always delegate**: file exploration, test running, log analysis, dependency auditing
- **Keep in main context**: current implementation decisions, user communication, small edits
- **Write to file**: when a subagent discovers something important, write to `docs/` not just return text

### PACT Workflow (for multi-file features)
Use `elite-project-orchestrator` to coordinate:
1. **Prepare** → Research requirements, scan codebase → output: `docs/<feature>-research.md`
2. **Architect** → Design solution via `elite-project-architect` → output: `docs/<feature>-architecture.md`
3. **Code** → Implement via `elite-fullstack-developer` → follows architecture doc
4. **Test** → Validate via `/testing` skill → ensures coverage

Each phase MUST read the previous phase's output file before starting.

## Plugins

| Plugin | Use When |
|--------|----------|
| `figma` | Implementing UI from Figma files, connecting components to designs |
| `playwright` | Browser testing, E2E tests, visual verification of UI |
| `code-simplifier` | Reducing complexity in recently modified code |
| `ralph-loop` | Iterative autonomous refinement loops |
| `feature-dev` | Guided feature development with code-explorer, code-architect, code-reviewer |
| `php-lsp` | PHP diagnostics, type checking, autocompletion context |
| `typescript-lsp` | TypeScript diagnostics, type checking, autocompletion context |

## Automated Hooks (runs silently)
- **Auto-format**: Code is formatted after every Write/Edit (prettier, black, gofmt, pint)
- **Syntax validation**: Checked before every Write/Edit
- **Security scan**: Dangerous bash commands are blocked automatically
- **Commit gate**: Debug statements and large files checked before commits

Do NOT manually format or lint - hooks handle it.

## Disabled Plugin Skills (Do Not Use)

These overlap with local skills or agents. Use the alternatives instead:

| Disabled | Use Instead |
|----------|-------------|
| `superpowers:systematic-debugging` | `/debug` |
| `superpowers:executing-plans` | `elite-project-orchestrator` agent |

## Project Setup

Always include these cross-cutting rules in project `CLAUDE.md`:

```markdown
@~/.claude/rules/coding-principles.md
@~/.claude/rules/security.md
@~/.claude/rules/testing.md
@~/.claude/rules/git.md
@~/.claude/rules/refactoring-guardrails.md
@~/.claude/rules/frontend-design.md  # If project has UI
```

Then add language-specific rules:

```markdown
@~/.claude/rules/typescript.md  # TypeScript/JavaScript
@~/.claude/rules/python.md      # Python
@~/.claude/rules/go.md          # Go
@~/.claude/rules/laravel.md     # Laravel/PHP 8.5
```

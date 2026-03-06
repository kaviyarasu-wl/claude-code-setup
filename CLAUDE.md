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

## Disabled Plugin Skills (Do Not Use)

These overlap with local skills or agents. Use the alternatives instead:

| Disabled | Use Instead |
|----------|-------------|
| `superpowers:systematic-debugging` | `/debug` |
| `superpowers:executing-plans` | `elite-project-orchestrator` agent |

## Project Setup

Add language-specific rules in project `CLAUDE.md`:

```markdown
@~/.claude/rules/typescript.md  # TypeScript/JavaScript
@~/.claude/rules/python.md      # Python
@~/.claude/rules/go.md          # Go
@~/.claude/rules/laravel.md     # Laravel/PHP 8.5
```

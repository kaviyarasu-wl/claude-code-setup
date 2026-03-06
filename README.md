# Claude Code Team Configuration

Enterprise-grade configuration for Claude Code that enforces consistent coding standards, security practices, and development workflows across your team. Drop it into ~/.claude/ and every team member gets the same coding experience.

## Quick Start

```bash
git clone https://github.com/your-org/claude-code-config.git ~/.claude
cd ~/.claude
./setup.sh
```

The setup script detects your platform, creates runtime directories, configures git attribution, and verifies prerequisites.

## What is Included

### Rules

Mandatory standards loaded into every Claude Code session.

| File | Purpose |
|------|---------|
| coding-principles.md | Core coding principles and best practices |
| refactoring-guardrails.md | Safe refactoring constraints and checks |
| security.md | Secrets management, input validation, OWASP top 10 |
| testing.md | 80%+ coverage requirements, test structure |
| git.md | Conventional commits, branch naming, PR standards |
| typescript.md | TypeScript/JavaScript strict mode, React patterns |
| python.md | Python 3.9+, type hints, Black/isort formatting |
| go.md | Go 1.21+, error handling, concurrency patterns |
| laravel.md | PHP 8.5, Laravel 12, Eloquent, Pest testing |

### Skills (Slash Commands)

Interactive workflows triggered with /command in Claude Code.

| Command | Purpose |
|---------|---------|
| /code-review | Deep code review for quality and security |
| /commit | Create conventional commit messages |
| /testing | Generate or improve tests |
| /security-scan | Scan for vulnerabilities and secrets |
| /refactor | Safe code refactoring with guardrails |
| /blueprint | Architecture and design planning |
| /debug | Systematic debugging workflow |
| /deploy | Deployment assistance and checklists |
| /api | API design and implementation |
| /migrate | Database migration management |
| /documentation | Generate READMEs, API docs, changelogs |
| /review-pr | PR quality and security checklist |
| /n8n | n8n workflow architecture and automation |

### Agents

Specialized agent configurations for complex multi-step tasks.

| Agent | Purpose |
|-------|---------|
| elite-fullstack-developer | Full-stack implementation across frontend and backend |
| elite-project-architect | System design, architecture decisions, tech stack selection |
| elite-database-specialist | Schema design, query optimization, migrations |
| elite-devops-automation | CI/CD pipelines, infrastructure, containerization |
| elite-performance-optimizer | Profiling, bottleneck analysis, optimization |
| n8n-workflow-architect | n8n automation workflow design and implementation |
| test-runner | Automated test execution and coverage reporting |
| log-analyzer | Log parsing, error pattern detection, diagnostics |

### Hooks

Automated checks that run at key points in the development workflow.

| Hook | Trigger | Purpose |
|------|---------|---------|
| session_start | Session open | Load context, verify environment |
| validate_code | Before save | Lint, type-check, validate patterns |
| security_scan | Before commit | Detect secrets, vulnerabilities |
| pre_commit_gate | Before commit | Run tests, enforce quality gates |
| auto_format | Before save | Apply language-specific formatters |
| notify | On events | Team notifications and alerts |

## Configuration

### Personal Settings

```bash
# Copy the example and fill in your details
cp settings.json.example settings.json
```

The setup script handles this automatically and prompts for your name and email.

### Project-Level Configuration

Create a CLAUDE.md in your project root to add project-specific instructions that layer on top of the global configuration:

```markdown
# Project: My App

## Stack
- Next.js 14, TypeScript, Tailwind CSS
- PostgreSQL with Prisma ORM

## Conventions
- Components in src/components/
- API routes in src/app/api/
```

## Directory Structure

```
~/.claude/
|-- CLAUDE.md                 # Global instructions
|-- settings.json             # Personal settings (git-ignored)
|-- settings.json.example     # Settings template
|-- setup.sh                  # Setup script
|-- README.md
|-- rules/                    # Coding standards
|   |-- coding-principles.md
|   |-- refactoring-guardrails.md
|   |-- security.md
|   |-- testing.md
|   |-- git.md
|   |-- typescript.md
|   |-- python.md
|   |-- go.md
|   +-- laravel.md
|-- skills/                   # Slash command definitions
|   |-- code-review.md
|   |-- commit.md
|   |-- testing.md
|   +-- ...
|-- agents/                   # Agent configurations
|   |-- elite-fullstack-developer.md
|   |-- elite-project-architect.md
|   +-- ...
|-- hooks/                    # Automated workflow hooks
|   |-- session_start.sh
|   |-- validate_code.sh
|   +-- ...
|-- memory/                   # Persistent memory across sessions
|   +-- MEMORY.md
|-- logs/                     # Session logs
|-- debug/                    # Debug output
|-- cache/                    # Temporary cache
|-- todos/                    # Task tracking
|-- plans/                    # Architecture plans
|-- projects/                 # Project-specific overrides
|-- plugins/                  # Plugin configurations
|-- session-env/              # Session environment state
|-- shell-snapshots/          # shell state snapshots
|-- file-history/             # File change tracking
|-- paste-cache/              # Clipboard cache
+-- ide/                      # IDE integration
```

## Updating

Pull the latest configuration and re-run setup:

```bash
cd ~/.claude
git pull
./setup.sh
```

The setup script is idempotent and safe to run multiple times. It will not overwrite your settings.json or memory/MEMORY.md.

## Contributing

### Adding a Rule

1. Create a markdown file in rules/ (e.g., rules/rust.md)
2. Follow the existing format: title, sections with clear guidelines
3. Reference it in CLAUDE.md with @~/.claude/rules/rust.md

### Adding a Skill

1. Create a markdown file in skills/ (e.g., skills/my-command.md)
2. Define the trigger, description, and step-by-step instructions
3. Register it in CLAUDE.md under the Available Skills table

### Adding an Agent

1. Create a markdown file in agents/ (e.g., agents/my-agent.md)
2. Define the agent role, capabilities, and tool access
3. Document it in this README

### Adding a Hook

1. Create a shell script in hooks/ (e.g., hooks/my_hook.sh)
2. Make it executable: chmod +x hooks/my_hook.sh
3. Register it in the hooks configuration

## Supported Platforms

| Platform | Status |
|----------|--------|
| macOS (Apple Silicon) | Fully supported |
| macOS (Intel) | Fully supported |
| Ubuntu / Debian | Fully supported |
| Fedora / RHEL | Fully supported |
| WSL 2 (Windows) | Fully supported |

## Requirements

| Tool | Required | Purpose |
|------|----------|---------|
| Claude Code CLI | Yes | Core CLI tool |
| git | Yes | Version control |
| Node.js | Recommended | JavaScript/TypeScript tooling |
| npm | Recommended | Package management |
| python3 | Recommended | Python development |
| docker | Recommended | Containerized workflows |
| gh | Recommended | GitHub CLI integration |
| jq | Recommended | JSON processing |

## License

MIT

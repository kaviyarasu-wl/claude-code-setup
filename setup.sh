#!/usr/bin/env bash
set -euo pipefail

# Claude Code Team Configuration Setup
# Cross-platform: macOS, Linux, WSL

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m'

check() { printf "${GREEN}✔${NC} %s\n" "$1"; }
warn()  { printf "${YELLOW}⚠${NC} %s\n" "$1"; }
fail()  { printf "${RED}✖${NC} %s\n" "$1"; }
info()  { printf "${BLUE}→${NC} %s\n" "$1"; }
header() { printf "\n${BOLD}%s${NC}\n" "$1"; }

CLAUDE_DIR="${HOME}/.claude"

header "Detecting platform..."

OS="unknown"
case "$(uname -s)" in
    Darwin)  OS="macos"  ;;
    Linux)
        if grep -qiE '(microsoft|wsl)' /proc/version 2>/dev/null; then
            OS="wsl"
        else
            OS="linux"
        fi
        ;;
esac

if [[ "${OS}" == "unknown" ]]; then
    fail "Unsupported operating system: $(uname -s)"
    exit 1
fi
check "Platform detected: ${OS} ($(uname -m))"

header "Checking prerequisites..."

if command -v git &>/dev/null; then
    check "git $(git --version | awk '{print $3}')"
else
    fail "git is required but not installed"
    exit 1
fi

if command -v claude &>/dev/null; then
    check "claude CLI found"
else
    warn "claude CLI not found - see Anthropic docs for install instructions"
fi

header "Verifying configuration files..."

if [[ -f "${CLAUDE_DIR}/CLAUDE.md" ]]; then
    check "CLAUDE.md found"
else
    warn "CLAUDE.md not found in ${CLAUDE_DIR}/ - create one to define project instructions"
fi

if [[ -f "${CLAUDE_DIR}/settings.json" ]]; then
    check "settings.json already exists (skipping copy)"
elif [[ -f "${CLAUDE_DIR}/settings.json.example" ]]; then
    cp "${CLAUDE_DIR}/settings.json.example" "${CLAUDE_DIR}/settings.json"
    check "settings.json created from settings.json.example"
else
    warn "settings.json.example not found - skipping settings setup"
fi

if [[ -f "${CLAUDE_DIR}/settings.json" ]]; then
    header "Configuring git attribution..."

    default_name="$(git config --global user.name 2>/dev/null || echo "")"
    default_email="$(git config --global user.email 2>/dev/null || echo "")"

    read -rp "Your name [${default_name}]: " user_name
    user_name="${user_name:-${default_name}}"

    read -rp "Your email [${default_email}]: " user_email
    user_email="${user_email:-${default_email}}"

    if [[ -n "${user_name}" && -n "${user_email}" ]]; then
        if [[ "${OS}" == "macos" ]]; then
            sed -i '' "s/YOUR_NAME/${user_name}/g" "${CLAUDE_DIR}/settings.json"
            sed -i '' "s/YOUR_EMAIL/${user_email}/g" "${CLAUDE_DIR}/settings.json"
        else
            sed -i "s/YOUR_NAME/${user_name}/g" "${CLAUDE_DIR}/settings.json"
            sed -i "s/YOUR_EMAIL/${user_email}/g" "${CLAUDE_DIR}/settings.json"
        fi
        check "Git attribution set: ${user_name} <${user_email}>"
    else
        warn "Name or email not provided - update settings.json manually"
    fi
fi

header "Creating runtime directories..."

dirs=(memory logs debug session-env shell-snapshots file-history todos plans projects cache plugins paste-cache ide)
for dir in "${dirs[@]}"; do
    mkdir -p "${CLAUDE_DIR}/${dir}"
done
check "Created ${#dirs[@]} runtime directories"

if [[ \! -f "${CLAUDE_DIR}/memory/MEMORY.md" ]]; then
    printf '%s\n' "# Workflow Patterns and Memory" "" "## Discovered Patterns" "<\!-- Patterns recorded here -->" "" "## Project Notes" "<\!-- Per-project notes -->" "" "## Common Commands" "<\!-- Quick reference -->" "" "## Decisions Log" "<\!-- Key decisions -->" > "${CLAUDE_DIR}/memory/MEMORY.md"
    check "Created memory/MEMORY.md"
else
    check "memory/MEMORY.md already exists"
fi

if [[ -d "${CLAUDE_DIR}/hooks" ]]; then
    found_hooks=0
    for hook in "${CLAUDE_DIR}/hooks/"*.sh; do
        [[ -f "${hook}" ]] || continue
        chmod +x "${hook}"
        found_hooks=$((found_hooks + 1))
    done
    if [[ ${found_hooks} -gt 0 ]]; then
        check "Made ${found_hooks} hook(s) executable"
    else
        warn "No hook scripts found in hooks/"
    fi
else
    warn "hooks/ directory not found - skipping"
fi

header "Checking recommended tools..."

tools=(node npm python3 docker gh jq)
missing=()

for tool in "${tools[@]}"; do
    if command -v "${tool}" &>/dev/null; then
        version="$("${tool}" --version 2>/dev/null | head -1 || echo "installed")"
        check "${tool}: ${version}"
    else
        warn "${tool} not found (optional but recommended)"
        missing+=("${tool}")
    fi
done

header "Setup complete\!"

printf "\n"
info "Claude Code team configuration is ready at ${CLAUDE_DIR}/"
printf "\n"

printf "${BOLD}Available Skills (slash commands):${NC}\n"
skills=(
    "/code-review    - Deep code review for quality and security"
    "/commit         - Create conventional commit messages"
    "/testing        - Generate or improve tests"
    "/security-scan  - Scan for vulnerabilities and secrets"
    "/refactor       - Safe code refactoring"
    "/blueprint      - Architecture and design planning"
    "/debug          - Systematic debugging"
    "/deploy         - Deployment assistance"
    "/api            - API design and implementation"
    "/migrate        - Database migration management"
    "/documentation  - Generate READMEs, API docs"
    "/review-pr      - PR quality and security checklist"
    "/n8n            - n8n workflow architecture"
)
for skill in "${skills[@]}"; do
    printf "  ${GREEN}*${NC} %s\n" "${skill}"
done

if [[ ${#missing[@]} -gt 0 ]]; then
    printf "\n"
    warn "Missing optional tools: ${missing[*]}"
    info "Install them for the best experience"
fi

printf "\n"
info "To update: git pull && ./setup.sh"
printf "\n"

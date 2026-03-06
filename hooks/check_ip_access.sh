#!/bin/bash

##############################################################################
# Claude Code IP Access Control Hook (Public IP Version)
# 
# This script checks if the current host's PUBLIC IP address is in the 
# authorized whitelist before allowing Claude Code to execute.
#
# This version checks your REAL internet IP (what websites see), not your
# local network IP. This means:
# - VPN usage will be detected (different public IP)
# - Works consistently across different networks
# - More secure than private IP checking
#
# Exit Codes:
#   0 - IP authorized, allow execution
#   2 - IP not authorized, block execution
#
# Installation:
#   1. Copy this file to ~/.claude/hooks/check_ip_access.sh
#   2. chmod +x ~/.claude/hooks/check_ip_access.sh
#   3. Create ~/.claude/ip_whitelist.txt with authorized PUBLIC IPs
#   4. Configure in ~/.claude/settings.json
##############################################################################

# Configuration
WHITELIST_FILE="$HOME/.claude/ip_whitelist.txt"
LOG_FILE="$HOME/.claude/logs/access_attempts.log"

# Multiple IP lookup services (fallback if one fails)
IP_SERVICES=(
    "https://api.ipify.org"
    "https://icanhazip.com"
    "https://ifconfig.me/ip"
    "https://ipecho.net/plain"
    "https://checkip.amazonaws.com"
)

# Logging function
log_attempt() {
    local status="$1"
    local ip="$2"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    mkdir -p "$(dirname "$LOG_FILE")"
    echo "[$timestamp] Status: $status | Public IP: $ip" >> "$LOG_FILE"
}

# Function to get the public IP address
get_public_ip() {
    local ip=""
    
    # Try each service until one works
    for service in "${IP_SERVICES[@]}"; do
        # Try with curl first
        if command -v curl >/dev/null 2>&1; then
            ip=$(curl -s --max-time 5 "$service" 2>/dev/null | grep -oE '^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$')
            if [ -n "$ip" ]; then
                echo "$ip"
                return 0
            fi
        fi
        
        # Try with wget as fallback
        if command -v wget >/dev/null 2>&1; then
            ip=$(wget -qO- --timeout=5 "$service" 2>/dev/null | grep -oE '^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$')
            if [ -n "$ip" ]; then
                echo "$ip"
                return 0
            fi
        fi
    done
    
    # If all services failed
    return 1
}

# Function to check if IP is in whitelist
is_ip_whitelisted() {
    local ip="$1"
    local whitelist_file="$2"
    
    # Check if whitelist file exists
    if [ ! -f "$whitelist_file" ]; then
        echo "ERROR: Whitelist file not found: $whitelist_file" >&2
        return 1
    fi
    
    # Check for exact match (ignoring comments and empty lines)
    if grep -v '^#' "$whitelist_file" | grep -v '^[[:space:]]*$' | grep -qFx "$ip"; then
        return 0
    fi
    
    # Check for CIDR range matches (requires grepcidr if available)
    if command -v grepcidr >/dev/null 2>&1; then
        # Filter out comments and empty lines, then check CIDR
        local cidr_ranges=$(grep -v '^#' "$whitelist_file" | grep -v '^[[:space:]]*$' | grep '/')
        if [ -n "$cidr_ranges" ]; then
            if echo "$cidr_ranges" | grepcidr <(echo "$ip") >/dev/null 2>&1; then
                return 0
            fi
        fi
    fi
    
    return 1
}

# Function to validate IP address format
is_valid_ip() {
    local ip="$1"
    local stat=1

    if [[ $ip =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]]; then
        local IFS='.'
        read -ra ip_parts <<< "$ip"
        [[ ${ip_parts[0]} -le 255 && ${ip_parts[1]} -le 255 && \
           ${ip_parts[2]} -le 255 && ${ip_parts[3]} -le 255 ]]
        stat=$?
    fi
    
    return $stat
}

##############################################################################
# MAIN EXECUTION
##############################################################################

# Get the public IP address
PUBLIC_IP=$(get_public_ip)

# Check if we successfully got the IP
if [ -z "$PUBLIC_IP" ]; then
    cat >&2 <<EOF
⛔ ═══════════════════════════════════════════════════════════════
   ACCESS DENIED: Unable to Determine Public IP
═══════════════════════════════════════════════════════════════

Cannot retrieve your public IP address. This could mean:
- No internet connection
- All IP lookup services are down
- curl/wget not installed
- Firewall blocking outbound requests

Required tools: curl or wget

To install:
  Ubuntu/Debian: sudo apt-get install curl
  RedHat/CentOS: sudo yum install curl
  MacOS: curl is pre-installed

═══════════════════════════════════════════════════════════════
EOF
    log_attempt "ERROR_NO_IP" "unable_to_retrieve"
    exit 2
fi

# Validate IP format
if ! is_valid_ip "$PUBLIC_IP"; then
    echo "⛔ ACCESS DENIED: Invalid IP address format: $PUBLIC_IP" >&2
    log_attempt "ERROR_INVALID_IP" "$PUBLIC_IP"
    exit 2
fi

# Check if IP is whitelisted
if is_ip_whitelisted "$PUBLIC_IP" "$WHITELIST_FILE"; then
    log_attempt "AUTHORIZED" "$PUBLIC_IP"
    exit 0
else
    # IP not authorized - block execution
    cat >&2 <<EOF
⛔ ═══════════════════════════════════════════════════════════════
   CLAUDE CODE ACCESS DENIED
═══════════════════════════════════════════════════════════════

Your public IP address is not authorized to use Claude Code.

Current Public IP: $PUBLIC_IP
Reason: IP address not in authorized whitelist

This IP represents your internet connection as seen by websites.
If you're using a VPN, this is your VPN's IP address.

Please contact your administrator to add this IP to the whitelist.

To find your current public IP, visit: https://api.ipify.org

═══════════════════════════════════════════════════════════════
EOF
    
    log_attempt "DENIED" "$PUBLIC_IP"
    exit 2
fi

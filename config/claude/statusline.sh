#!/bin/bash
input=$(cat)

# Parse session fields with python3 (jq not required)
IFS='|' read -r MODEL DIR COST PCT DURATION_MS <<< "$(python3 -c "
import sys, json
d = json.load(sys.stdin)
model   = d.get('model', {}).get('display_name', 'unknown')
dir_    = d.get('workspace', {}).get('current_dir', '')
cost    = d.get('cost', {}).get('total_cost_usd', 0) or 0
pct     = int(float(d.get('context_window', {}).get('used_percentage', 0) or 0))
dur_ms  = d.get('cost', {}).get('total_duration_ms', 0) or 0
print(f'{model}|{dir_}|{cost}|{pct}|{int(dur_ms)}')
" <<< "$input")"

CYAN='\033[36m'; GREEN='\033[32m'; YELLOW='\033[33m'; RED='\033[31m'; RESET='\033[0m'

# Context window bar
PCT=${PCT:-0}
if [ "$PCT" -ge 90 ]; then BAR_COLOR="$RED"
elif [ "$PCT" -ge 70 ]; then BAR_COLOR="$YELLOW"
else BAR_COLOR="$GREEN"; fi
FILLED=$((PCT / 10)); EMPTY=$((10 - FILLED))
BAR=$(printf "%${FILLED}s" | tr ' ' '█')$(printf "%${EMPTY}s" | tr ' ' '░')

DURATION_MS=${DURATION_MS:-0}
MINS=$((DURATION_MS / 60000)); SECS=$(((DURATION_MS % 60000) / 1000))

BRANCH=""
[ -n "$DIR" ] && git -C "$DIR" rev-parse --git-dir > /dev/null 2>&1 && \
  BRANCH=" | 🌿 $(git -C "$DIR" branch --show-current 2>/dev/null)"

# --- Real usage from Anthropic API (cached 5 min) ---
USAGE_CACHE="/tmp/claude-usage-cache.json"
WIN_PCT=0; WEEK_PCT=0

NOW_S=$(date +%s)
# Refresh cache if older than 5 minutes
if [ ! -f "$USAGE_CACHE" ] || [ $(( NOW_S - $(date -r "$USAGE_CACHE" +%s 2>/dev/null || echo 0) )) -gt 300 ]; then
  CREDS_FILE="$HOME/.claude/.credentials.json"
  if [ -f "$CREDS_FILE" ]; then
    TOKEN=$(python3 -c "
import json, sys
try:
    d = json.load(open('$CREDS_FILE'))
    print(d['claudeAiOauth']['accessToken'])
except Exception:
    print('')
")
  else
    TOKEN=$(security find-generic-password -s "Claude Code-credentials" -w -g 2>/dev/null | python3 -c "
import sys, json
try:
    d = json.loads(sys.stdin.read())
    print(d['claudeAiOauth']['accessToken'])
except Exception:
    print('')
")
  fi
  if [ -n "$TOKEN" ]; then
    curl -s --max-time 5 \
      -H "Authorization: Bearer $TOKEN" \
      -H "anthropic-beta: oauth-2025-04-20" \
      "https://api.anthropic.com/api/oauth/usage" > "${USAGE_CACHE}.tmp" 2>/dev/null
    if [ -s "${USAGE_CACHE}.tmp" ]; then
      mv "${USAGE_CACHE}.tmp" "$USAGE_CACHE"
    else
      rm -f "${USAGE_CACHE}.tmp"
    fi
  fi
fi

WIN_LEFT="-"; WEEK_LEFT="-"
if [ -f "$USAGE_CACHE" ]; then
  IFS='|' read -r WIN_PCT WEEK_PCT WIN_LEFT WEEK_LEFT <<< "$(python3 -c "
import json, sys
from datetime import datetime, timezone

def remaining(iso):
    if not iso:
        return '-'
    try:
        reset = datetime.fromisoformat(iso)
        secs = int((reset - datetime.now(timezone.utc)).total_seconds())
    except Exception:
        return '-'
    if secs <= 0:
        return 'now'
    d, rem = divmod(secs, 86400)
    h, rem = divmod(rem, 3600)
    m = rem // 60
    if d:
        return f'{d}d {h}h'
    if h:
        return f'{h}h {m}m'
    return f'{m}m'

try:
    d = json.load(open('$USAGE_CACHE'))
    five = int(d.get('five_hour', {}).get('utilization', 0) or 0)
    week = int(d.get('seven_day', {}).get('utilization', 0) or 0)
    five_left = remaining(d.get('five_hour', {}).get('resets_at'))
    week_left = remaining(d.get('seven_day', {}).get('resets_at'))
    print(f'{five}|{week}|{five_left}|{week_left}')
except Exception:
    print('0|0|-|-')
")"
fi

WIN_PCT=${WIN_PCT:-0}; WEEK_PCT=${WEEK_PCT:-0}
WIN_LEFT=${WIN_LEFT:--}; WEEK_LEFT=${WEEK_LEFT:--}

WIN_FILLED=$((WIN_PCT / 10)); WIN_EMPTY=$((10 - WIN_FILLED))
WIN_BAR=$(printf "%${WIN_FILLED}s" | tr ' ' '█')$(printf "%${WIN_EMPTY}s" | tr ' ' '░')

WEEK_FILLED=$((WEEK_PCT / 10)); WEEK_EMPTY=$((10 - WEEK_FILLED))
WEEK_BAR=$(printf "%${WEEK_FILLED}s" | tr ' ' '█')$(printf "%${WEEK_EMPTY}s" | tr ' ' '░')

if [ "$WIN_PCT" -ge 90 ]; then WIN_COLOR="$RED"
elif [ "$WIN_PCT" -ge 70 ]; then WIN_COLOR="$YELLOW"
else WIN_COLOR="$GREEN"; fi

if [ "$WEEK_PCT" -ge 90 ]; then WEEK_COLOR="$RED"
elif [ "$WEEK_PCT" -ge 70 ]; then WEEK_COLOR="$YELLOW"
else WEEK_COLOR="$GREEN"; fi

COST_FMT=$(printf '$%.2f' "${COST:-0}")
DIR_NAME="${DIR##*/}"

echo -e "${CYAN}[$MODEL]${RESET} 📁 ${DIR_NAME}$BRANCH"
echo -e "${BAR_COLOR}${BAR}${RESET} ctx ${PCT}% | ${WIN_COLOR}${WIN_BAR}${RESET} 5hr ${WIN_PCT}% (↻${WIN_LEFT}) | ${WEEK_COLOR}${WEEK_BAR}${RESET} 7d ${WEEK_PCT}% (↻${WEEK_LEFT}) | ${YELLOW}${COST_FMT}${RESET} | ⏱️ ${MINS}m ${SECS}s"

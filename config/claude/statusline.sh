#!/bin/bash
input=$(cat)

MODEL=$(echo "$input" | jq -r '.model.display_name')
DIR=$(echo "$input" | jq -r '.workspace.current_dir')
COST=$(echo "$input" | jq -r '.cost.total_cost_usd // 0')
PCT=$(echo "$input" | jq -r '.context_window.used_percentage // 0' | cut -d. -f1)
DURATION_MS=$(echo "$input" | jq -r '.cost.total_duration_ms // 0')
SESSION_ID=$(echo "$input" | jq -r '.session_id // ""')
OUT_TOKENS=$(echo "$input" | jq -r '.context_window.total_output_tokens // 0')
IN_TOKENS=$(echo "$input" | jq -r '.context_window.total_input_tokens // 0')

CYAN='\033[36m'; GREEN='\033[32m'; YELLOW='\033[33m'; RED='\033[31m'; RESET='\033[0m'

# Pick bar color based on context usage
if [ "$PCT" -ge 90 ]; then BAR_COLOR="$RED"
elif [ "$PCT" -ge 70 ]; then BAR_COLOR="$YELLOW"
else BAR_COLOR="$GREEN"; fi

FILLED=$((PCT / 10)); EMPTY=$((10 - FILLED))
BAR=$(printf "%${FILLED}s" | tr ' ' '█')$(printf "%${EMPTY}s" | tr ' ' '░')

MINS=$((DURATION_MS / 60000)); SECS=$(((DURATION_MS % 60000) / 1000))

BRANCH=""
git -C "$DIR" rev-parse --git-dir > /dev/null 2>&1 && BRANCH=" | 🌿 $(git -C "$DIR" branch --show-current 2>/dev/null)"

# --- Rolling window usage (5-hour and weekly) ---
# Tracks cumulative output tokens per session in a shared log file.
# Limits vary by plan; adjust these values to match your subscription.
FIVE_HR_LIMIT=35000
WEEK_LIMIT=700000
WINDOW_LOG="$HOME/.claude/5hr_token_log.jsonl"
NOW=$(date +%s)
FIVE_HR_AGO=$((NOW - 18000))
WEEK_AGO=$((NOW - 604800))

# Append current session snapshot
if [ -n "$SESSION_ID" ]; then
  echo "{\"ts\":$NOW,\"sid\":\"$SESSION_ID\",\"out\":$OUT_TOKENS}" >> "$WINDOW_LOG"
fi

# Sum output tokens for each window, counting only the MAX per session
# (so a session that grew from 100->200 tokens only counts 200, not 300)
WINDOW_TOKENS=0
WEEK_TOKENS=0
if [ -f "$WINDOW_LOG" ]; then
  read -r WINDOW_TOKENS WEEK_TOKENS <<< "$(awk -v cutoff5="$FIVE_HR_AGO" -v cutoff7="$WEEK_AGO" '
    {
      match($0, /"ts":([0-9]+)/, a); ts = a[1]+0
      match($0, /"sid":"([^"]+)"/, b); sid = b[1]
      match($0, /"out":([0-9]+)/, c); out = c[1]+0
      if (ts >= cutoff5) { if (out > max5[sid]) max5[sid] = out }
      if (ts >= cutoff7) { if (out > max7[sid]) max7[sid] = out }
    }
    END {
      t5 = 0; t7 = 0
      for (s in max5) t5 += max5[s]
      for (s in max7) t7 += max7[s]
      print t5, t7
    }
  ' "$WINDOW_LOG")"

  # Trim log entries older than 7 days (keep file small)
  if (( NOW % 60 == 0 )); then
    awk -v cutoff="$WEEK_AGO" '
      { match($0, /"ts":([0-9]+)/, a); if (a[1]+0 >= cutoff) print }
    ' "$WINDOW_LOG" > "$WINDOW_LOG.tmp" && mv "$WINDOW_LOG.tmp" "$WINDOW_LOG"
  fi
fi

WINDOW_TOKENS=${WINDOW_TOKENS:-0}
WEEK_TOKENS=${WEEK_TOKENS:-0}

WIN_PCT=$(( (WINDOW_TOKENS * 100) / FIVE_HR_LIMIT ))
[ "$WIN_PCT" -gt 100 ] && WIN_PCT=100

WEEK_PCT=$(( (WEEK_TOKENS * 100) / WEEK_LIMIT ))
[ "$WEEK_PCT" -gt 100 ] && WEEK_PCT=100

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

echo -e "${CYAN}[$MODEL]${RESET} 📁 ${DIR##*/}$BRANCH"
COST_FMT=$(printf '$%.2f' "$COST")
echo -e "${BAR_COLOR}${BAR}${RESET} ctx ${PCT}% | ${WIN_COLOR}${WIN_BAR}${RESET} 5hr ${WIN_PCT}% | ${WEEK_COLOR}${WEEK_BAR}${RESET} wk ${WEEK_PCT}% | ${YELLOW}${COST_FMT}${RESET} | ⏱️ ${MINS}m ${SECS}s"


##!/bin/bash
## Example from: https://code.claude.com/docs/en/statusline
## Read JSON data that Claude Code sends to stdin
#input=$(cat)
#
## Extract fields using jq
#MODEL=$(echo "$input" | jq -r '.model.display_name')
#DIR=$(echo "$input" | jq -r '.workspace.current_dir')
## The "// 0" provides a fallback if the field is null
#PCT=$(echo "$input" | jq -r '.context_window.used_percentage // 0' | cut -d. -f1)
#
## Output the status line - ${DIR##*/} extracts just the folder name
#echo "[$MODEL] 📁 ${DIR##*/} | ${PCT}% context"

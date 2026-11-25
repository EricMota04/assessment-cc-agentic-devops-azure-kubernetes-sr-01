#!/usr/bin/env bash
# Enforces the chat-history rule in CLAUDE.md.
#   mark  (UserPromptSubmit): record how many entries .chat-history/log.md has.
#   check (Stop): if no entry was added since the prompt, block the turn once
#                 so Claude appends it; on the retry, warn instead of looping.
# Prints nothing in "mark" mode: UserPromptSubmit stdout becomes model context.
set -u

mode="${1:-}"
input="$(cat)"
root="${CLAUDE_PROJECT_DIR:-$(pwd)}"
log="$root/.chat-history/log.md"

session="$(printf '%s' "$input" \
  | sed -n 's/.*"session_id"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' \
  | head -n 1 | tr -cd 'A-Za-z0-9_-')"
state_dir="${TMPDIR:-/tmp}/claude-chat-log"
state="$state_dir/${session:-default}.count"

entries() {
  if [ -f "$log" ]; then grep -c '^- timestamp: "' "$log"; else echo 0; fi
}

case "$mode" in
  mark)
    mkdir -p "$state_dir" && entries > "$state"
    ;;
  check)
    [ -f "$state" ] || exit 0   # no prompt recorded for this session
    before="$(cat "$state")"
    if [ "$(entries)" -gt "$before" ]; then
      rm -f "$state"
      exit 0
    fi
    if printf '%s' "$input" | grep -q '"stop_hook_active"[[:space:]]*:[[:space:]]*true'; then
      rm -f "$state"
      echo '{"systemMessage":"Chat log: this exchange was not appended to .chat-history/log.md."}'
      exit 0
    fi
    echo '{"decision":"block","reason":"No entry was appended to .chat-history/log.md for this prompt. Append one now in the exact format from the Chat history log section of CLAUDE.md (timestamp, user_prompt, assistant_response_summary, files_affected), then finish."}'
    ;;
esac
exit 0

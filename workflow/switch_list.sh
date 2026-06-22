#!/bin/bash

# Script Filter for `gh-switch`: lists gh accounts on github.com.
# Selecting an item runs switch_do.sh with the chosen username.

QUERY="${1:-}"

GH="$(command -v gh || true)"
if [ -z "$GH" ]; then
  for candidate in /opt/homebrew/bin/gh /usr/local/bin/gh; do
    [ -x "$candidate" ] && GH="$candidate" && break
  done
fi

if [ -z "$GH" ]; then
  cat <<'JSON'
{"items":[{"title":"gh CLI not found","subtitle":"Install with: brew install gh","valid":false}]}
JSON
  exit 0
fi

# Active user on github.com (fast — read from local config, no network).
ACTIVE=$(awk '
  /^github\.com:/         { in_host=1; next }
  /^[^ \t]/               { in_host=0 }
  in_host && /^[ \t]+user:/ { print $2; exit }
' "${HOME}/.config/gh/hosts.yml" 2>/dev/null)

# All known users on github.com, one per line. Parses the `users:` block —
# entries are indented deeper than `users:` itself (typically 8 spaces vs 4).
# Stops when indent shrinks back to the parent level or shallower.
USERS=$(awk '
  /^github\.com:/   { in_host=1; next }
  /^[^ \t]/         { in_host=0 }
  in_host && /^[ \t]+users:/ {
    match($0, /^[ \t]*/); parent_indent = RLENGTH
    in_users=1; next
  }
  in_users {
    match($0, /^[ \t]*/); indent = RLENGTH
    if (indent <= parent_indent) { in_users=0; next }
    # A user line is "<name>:" at this deeper indent.
    if ($1 ~ /:$/) { sub(":", "", $1); print $1 }
  }
' "${HOME}/.config/gh/hosts.yml" 2>/dev/null)

if [ -z "$USERS" ]; then
  cat <<'JSON'
{"items":[{"title":"No gh accounts found","subtitle":"Run: gh auth login --hostname github.com","valid":false}]}
JSON
  exit 0
fi

# Filter by query (case-insensitive substring) and emit JSON.
echo "$USERS" | /usr/bin/python3 -c '
import sys, json
query = (sys.argv[1] if len(sys.argv) > 1 else "").lower().strip()
active = sys.argv[2] if len(sys.argv) > 2 else ""
items = []
for line in sys.stdin:
    user = line.strip()
    if not user: continue
    if query and query not in user.lower(): continue
    is_active = (user == active)
    items.append({
        "uid": user,
        "title": user + (" (active)" if is_active else ""),
        "subtitle": "Already active" if is_active else f"Switch to {user} on github.com",
        "arg": user,
        "autocomplete": user,
        "valid": not is_active,
        "icon": {"path": "repo.png"},
    })
print(json.dumps({"items": items}))
' "$QUERY" "$ACTIVE"

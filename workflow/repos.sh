#!/bin/bash

# Alfred passes the typed query as $1
QUERY="${1:-}"

CACHE_DIR="${HOME}/Library/Caches/org.pupazzo.github-alfred"

# Read active gh user for github.com from local config (fast — no network).
# Falls back to "anon" if hosts.yml is missing or unreadable. Used to scope
# the cache per-account so switching gh accounts doesn't serve stale results.
GH_USER=$(awk '
  /^github\.com:/         { in_host=1; next }
  /^[^ \t]/               { in_host=0 }
  in_host && /^[ \t]+user:/ { print $2; exit }
' "${HOME}/.config/gh/hosts.yml" 2>/dev/null)
GH_USER="${GH_USER:-anon}"

CACHE_FILE="${CACHE_DIR}/repos-${GH_USER}.json"
STALE_SECS=60          # background refresh after this
MAX_AGE_SECS=$((60*60*24))  # block-and-fetch if older than this (or missing)

mkdir -p "$CACHE_DIR"

# Find gh on PATH (covers Intel /usr/local, Apple Silicon /opt/homebrew, custom installs)
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

# How old is the cache (in seconds)? Empty if missing.
cache_age() {
  [ -f "$CACHE_FILE" ] || { echo ""; return; }
  local mtime now
  mtime=$(stat -f %m "$CACHE_FILE" 2>/dev/null || echo 0)
  now=$(date +%s)
  echo $(( now - mtime ))
}

fetch_now() {
  # Paginate through every repo the active gh user can see (personal +
  # collaborator + all org memberships). --paginate auto-walks next links;
  # --jq emits one repo object per line (NDJSON). Post-process in Python
  # to dedupe and wrap as a JSON array.
  GH_HOST=github.com "$GH" api --paginate \
    "user/repos?per_page=100&affiliation=owner,collaborator,organization_member" \
    --jq '.[] | {nameWithOwner: .full_name, description: .description, url: .html_url}' \
    2>/dev/null \
    | /usr/bin/python3 -c '
import sys, json
seen = set()
out = []
for line in sys.stdin:
    line = line.strip()
    if not line:
        continue
    repo = json.loads(line)
    url = repo.get("url")
    if url in seen:
        continue
    seen.add(url)
    out.append(repo)
json.dump(out, sys.stdout)
' > "${CACHE_FILE}.tmp" \
    && [ -s "${CACHE_FILE}.tmp" ] \
    && mv "${CACHE_FILE}.tmp" "$CACHE_FILE"
  rm -f "${CACHE_FILE}.tmp"  # clean up if the write produced an empty/partial file
}

age=$(cache_age)

# Block-and-fetch only when we have nothing usable
if [ -z "$age" ] || [ "$age" -gt "$MAX_AGE_SECS" ]; then
  fetch_now
fi

# Background refresh if cache is stale but usable
if [ -n "$age" ] && [ "$age" -gt "$STALE_SECS" ] && [ "$age" -le "$MAX_AGE_SECS" ]; then
  ( fetch_now >/dev/null 2>&1 & ) </dev/null
fi

if [ ! -f "$CACHE_FILE" ]; then
  cat <<'JSON'
{"items":[{"title":"No repos returned","subtitle":"Run: gh auth status --hostname github.com","valid":false}]}
JSON
  exit 0
fi

/usr/bin/python3 -c '
import sys, json
with open(sys.argv[1]) as f:
    data = json.load(f)

# Split query into whitespace-separated terms; each term must appear
# somewhere in the haystack (org, repo name, or description).
terms = (sys.argv[2] if len(sys.argv) > 2 else "").lower().split()

def score(name, desc, terms):
    """Lower is better. Boost exact repo-name matches; otherwise just match."""
    haystack = (name + " " + desc).lower()
    for t in terms:
        if t not in haystack:
            return None
    if not terms:
        return (2, name.lower())
    repo = name.split("/", 1)[-1].lower()
    full_query = " ".join(terms)
    if repo == full_query:
        return (0, name.lower())
    if full_query in repo:
        return (1, name.lower())
    return (2, name.lower())

ranked = []
for repo in data:
    name = repo.get("nameWithOwner") or ""
    desc = repo.get("description") or ""
    url  = repo.get("url") or ""
    s = score(name, desc, terms)
    if s is None:
        continue
    ranked.append((s, {
        "uid": url,
        "title": name,
        "subtitle": desc,
        "arg": url,
        "autocomplete": name,
        "icon": {"path": "repo.png"},
    }))

ranked.sort(key=lambda x: x[0])
print(json.dumps({"items": [item for _, item in ranked]}))
' "$CACHE_FILE" "$QUERY"

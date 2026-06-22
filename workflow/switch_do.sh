#!/bin/bash

# Runs `gh auth switch` for the picked user, then prints a one-line result
# so Alfred can show a notification (configured on the action's "Post
# Notification" output, or via Large Type fallback).

USER="${1:-}"

if [ -z "$USER" ]; then
  echo "No user provided"
  exit 1
fi

GH="$(command -v gh || true)"
if [ -z "$GH" ]; then
  for candidate in /opt/homebrew/bin/gh /usr/local/bin/gh; do
    [ -x "$candidate" ] && GH="$candidate" && break
  done
fi

if [ -z "$GH" ]; then
  echo "gh CLI not found"
  exit 1
fi

if "$GH" auth switch --hostname github.com --user "$USER" >/dev/null 2>&1; then
  echo "Switched to $USER on github.com"
else
  echo "Failed to switch to $USER (run: gh auth switch --hostname github.com --user $USER)"
  exit 1
fi

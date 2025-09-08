#!/bin/bash

repo_root=$(git rev-parse --show-toplevel 2>/dev/null)
if [ -z "$repo_root" ]; then
  echo "❌ Not inside a git repository"
  exit 1
fi

main_repo=$(git worktree list --porcelain | awk '/^worktree /{print $2; exit}')

if [ "$repo_root" = "$main_repo" ]; then
  echo "✅ Working in main repository"
else
  rel_path=$(realpath --relative-to="$main_repo" "$repo_root")
  echo "❗️🔺 Working in worktree: $rel_path"
fi

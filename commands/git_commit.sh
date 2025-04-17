#!/usr/bin/env bash
function git_commit() {
  local msg="${1:-}"
  if [[ -z "$msg" ]]; then
    echo "Usage: git_commit \"Your commit message\""
    return 1
  fi
  git commit -m "$msg"
}

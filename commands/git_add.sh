#!/usr/bin/env bash
function git_add() {
  local fzf_path="/c/bin/fzf.exe"
  local delta_path="/c/bin/delta.exe"
  local diff_cmd="git diff --color-words"

  # fzf.exe の存在確認
  if [[ ! -x "$fzf_path" ]]; then
    echo "❌ fzf.exe not found: $fzf_path"
    return 1
  fi
  # delta.exe があれば使用
  [[ -x "$delta_path" ]] && diff_cmd="$delta_path"

  # ステータス取得
  local status_raw
  status_raw=$(git status --porcelain)
  if [[ -z "$status_raw" ]]; then
    echo "✅ No changes to add."
    return 0
  fi

  local out q status_lines file
  while out=$(
    git status --porcelain |
    awk '
      { s=substr($0,1,2); f=substr($0,4);
        lbl=(s=="??"?"[untracked]":substr(s,1,1)~/[A-Z]/?"[✅]":"[modified]");
        printf("%-12s %s\n", lbl, f);
      }
    ' | "$fzf_path" --multi --ansi --height=40% --reverse \
                   --header="⏎: toggle stage    Ctrl-D: diff" \
                   --expect=ctrl-d
  ); do
    q=$(head -1 <<< "$out")
    readarray -t status_lines < <(tail -n +2 <<< "$out")
    [[ ${#status_lines[@]} -eq 0 ]] && continue

    for line in "${status_lines[@]}"; do
      file=${line#*] }
      if [[ $q == ctrl-d ]]; then
        echo "🔍 Diff: $file"
        if git diff --cached --name-only | grep -qx -- "$file"; then
          "$diff_cmd" --cached -- "$file" | less -R
        else
          "$diff_cmd" -- "$file" | less -R
        fi
      else
        if git diff --cached --name-only | grep -qx -- "$file"; then
          echo "🔄 Unstage: $file"
          git restore --staged -- "$file"
        else
          echo "➕ Stage: $file"
          git add -- "$file"
        fi
      fi
    done
  done
}

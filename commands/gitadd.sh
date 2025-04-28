#!/usr/bin/env bash
# gitadd : fzf でインタラクティブにステージ／アンステージを切り替える

function gitadd() {
  local fzf_path="/c/bin/fzf.exe"
  local delta_path="/c/bin/delta.exe"

  # ---------- diff viewer ----------
  if [[ -x "$delta_path" ]]; then
    diff_run() { git diff "$@" | "$delta_path"; }
  else
    diff_run() { git diff "$@"; }
  fi

  # fzf.exe の存在確認
  if [[ ! -x "$fzf_path" ]]; then
    echo "❌ fzf.exe not found: $fzf_path"
    return 1
  fi

  # 変更が無ければ終了
  if [[ -z $(git status --porcelain) ]]; then
    echo "✅ No changes to add."
    return 0
  fi

  local out q
  while out=$(
    git status --porcelain=v1 | while IFS= read -r line; do
      status="${line:0:2}"             # XY をそのまま取得（空白保持）
      path_raw="${line:3}"             # パス（3 文字目以降）

      # リネーム対応
      if [[ "$path_raw" == *" -> "* ]]; then
        path="${path_raw##* -> }"
      else
        path="$path_raw"
      fi

      # ラベル判定
      if [[ "$status" == "??" ]]; then
        label="untracked"
        #mark="🔍"
        mark="❓"
      else
        X="${status:0:1}"
        Y="${status:1:1}"
        if   [[ "$X" != " " && "$Y" != " " ]]; then
          label="both"
          mark="🌓"
        elif [[ "$X" != " " ]]; then
          label="staged"
          mark="✅"
        else
          label="not stage"
          mark="🟡"
        fi
      fi

      printf "%s[%s]\t%s\t%s\n" "$mark" "$label" "$status" "$path"
    done | "$fzf_path" --multi --ansi --height=40% --reverse \
                       --with-nth=1,2,3 --delimiter='\t' \
                       --header="⏎: toggle stage    Ctrl-D: diff" \
                       --expect=ctrl-d
  ); do
    q=$(head -n1 <<< "$out")
    mapfile -t selected_lines < <(tail -n +2 <<< "$out")
    [[ ${#selected_lines[@]} -eq 0 ]] && continue

    for line in "${selected_lines[@]}"; do
      label=$(cut -f1 <<< "$line"); label=${label//[\[\]]/}
      file=$(cut -f3 <<< "$line")

      if [[ $q == ctrl-d ]]; then
        echo "🔍 Diff: $file"
        case "$label" in
          staged)      diff_run --cached -- "$file" | less -R ;;
          "not stage") diff_run -- "$file"        | less -R ;;
          both)
            echo "--- staged ---"
            diff_run --cached -- "$file" | less -R
            echo "--- unstaged ---"
            diff_run -- "$file"        | less -R ;;
          untracked)   echo "📄 Untracked file（diff なし）" ;;
          *)           echo "❓ Unknown diff target" ;;
        esac
      else
        # ステージ済みならアンステージ、未ステージならステージ 
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

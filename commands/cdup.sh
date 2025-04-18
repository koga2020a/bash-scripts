function cdup() {
  local base_dir

  if [[ -n "$1" ]]; then
    base_dir="$([[ "$1" == "." ]] && echo "$PWD" || echo "$1")"
  else
    base_dir="/c/src"
  fi

  if [[ ! -d "$base_dir" ]]; then
    echo "❌ ディレクトリが存在しません: $base_dir"
    return 1
  fi

  local dirs=()
  while IFS= read -r dir; do
    [[ -d "$base_dir/$dir" ]] && dirs+=("$dir")
  done < <(ls -1 "$base_dir" 2>/dev/null)

  if [[ ${#dirs[@]} -eq 0 ]]; then
    echo "⚠️ 子ディレクトリが見つかりません: $base_dir"
    return 1
  fi

  local selected
  selected=$(printf "%s\n" "${dirs[@]}" | \
    fzf \
      --header="📁 Base directory: $base_dir" \
      --prompt="Select subdirectory > " \
      --height=40% \
      --reverse \
      --preview="[[ -f '$base_dir/{}/README.md' ]] && cat '$base_dir/{}/README.md' || echo 'README.md not found.'" \
      --preview-window=right:wrap)

  if [[ -n "$selected" ]]; then
    cd "$base_dir/$selected" || echo "❌ 移動に失敗しました"
    echo "📁 現在のディレクトリ: $(pwd)"
  else
    echo "❌ キャンセルされました"
  fi
}

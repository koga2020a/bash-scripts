function gitbranch() {
  # 改行コードの警告を抑制
  git config --global core.autocrlf false

  # Git リポジトリでなければ終了
  if ! git rev-parse --is-inside-work-tree &>/dev/null; then
    echo "❌ このディレクトリは Git リポジトリではありません。"
    return 1
  fi

  # ステータス確認（移動可能かチェック）
  local status_message=""
  if [ "$(git status | grep -E "Changes not staged for commit:|Untracked files:" | wc -l)" -gt 0 ]; then
    status_message="⚠️ 作業ツリーまたはインデックスに未コミットの変更があります。"
  else
    status_message=""  # クリーンなら空白
  fi

  echo "$status_message"

  # ブランチの数を確認
  local branch_count
  branch_count=$(git branch --format='%(refname:short)' | wc -l | tr -d ' ')
  if [ "$branch_count" -eq 1 ]; then
    echo "ℹ️ 現在のブランチ: $(git branch --show-current)"
    echo "ℹ️ 他のブランチが存在しないため、ブランチ切り替えはできません。"
    return 0
  fi

  # ブランチ一覧を取得（HEAD の * を削除、現在のブランチは強調表示）
  local branches=()
  while IFS= read -r line; do
    line="${line/#\*/👉}"  # 現在のブランチを見やすく
    branches+=("$line")
  done < <(git branch --sort=-committerdate)

  # fzf で選択（1行目に警告表示付き）
  local selected
  selected=$( ( [[ -n "$status_message" ]] && echo "$status_message"; printf "%s\n" "${branches[@]}" ) \
    | fzf \
        --prompt="Select branch > " \
        --height=40% \
        --reverse \
        --header-lines=$([[ -n "$status_message" ]] && echo 1 || echo 0) \
        --ansi)

  # キャンセル時
  if [[ -z "$selected" ]]; then
    echo "❌ キャンセルされました。"
    return 1
  fi

  # 警告メッセージを選択された場合は処理しない
  if [[ "$selected" == "$status_message" ]]; then
    echo "⚠️ ブランチ移動できません。まずは変更をコミットまたはスタッシュしてください。"
    return 1
  fi

  # 実際のブランチ名を抽出（👉が付いてる場合も処理）
  local branch_name
  branch_name=$(echo "$selected" | sed 's/^👉 //;s/^..//')

  echo "📦 チェックアウト: $branch_name"
  git checkout "$branch_name"
}

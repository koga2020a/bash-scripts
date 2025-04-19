#!/usr/bin/env bash

function gitsavefile() {
  # コミット履歴を表示し、fzfで選択
  local commit_id=$(git log --pretty=format:"%h %s" | fzf --layout=reverse-list --preview "git show --name-only {1} | grep -v '^commit' | grep -v '^Author:' | grep -v '^Date:' | grep -v '^$'" | awk '{print $1}')

  if [[ -z "$commit_id" ]]; then
    echo "コミットが選択されませんでした"
    return 1
  fi

  # 選択したコミットのファイル一覧を表示（ファイル名のみをフィルタリング）
  local file_path=$(git show --name-only "$commit_id" | grep -v '^commit' | grep -v '^Author:' | grep -v '^Date:' | grep -v '^$' | grep -v '^    ' | fzf --layout=reverse-list --preview "git show $commit_id:{}")

  if [[ -z "$file_path" ]]; then
    echo "ファイルが選択されませんでした"
    return 1
  fi
  # 選択したファイルをプレビュー
  git show "$commit_id:$file_path" | less -R

  # 保存先のファイル名を入力
  read -p "保存先のファイル名を入力してください: " save_path

  if [[ -z "$save_path" ]]; then
    echo "ファイル名が入力されませんでした"
    return 1
  fi

  # ファイルを保存
  git show "$commit_id:$file_path" > "$save_path"
  echo "ファイルを保存しました: $save_path"
}
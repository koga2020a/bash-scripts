function histpick() {
  # `history` コマンドで履歴を取得、行番号を削除して逆順に
  local selected_command
  selected_command=$(history | awk '{$1=""; print substr($0,2)}' | tac | awk '!a[$0]++' | fzf --height=40% --reverse --prompt='History > ')

  if [[ -n "$selected_command" ]]; then
    echo "------------------------------------------------"
    echo -e "--- 選択されたコマンド: \033[32m$selected_command\033[0m"
    echo "---"
    history -s "$selected_command"
    read -p "--- Ctrl+C でキャンセル、Enterで実行 > " _
    eval "$selected_command"
  fi
}

#!/usr/bin/env bash
# Git履歴ブラウザ (Windows Git Bash 対応版)
#
# 機能:
# - コミット履歴の表示と選択
# - 選択したコミットのファイル一覧表示と選択
# - ファイルに対する操作（less表示、cat出力、名前を付けて保存）
#
# 操作方法:
# - ↑/↓：選択肢の移動
# - Enter：選択の確定
# - ESC：前の画面に戻る
# - q：現在の画面を終了


function gitsavefile() {
  # 端末設定の保存と復元
  local old_stty_settings
  old_stty_settings=$(stty -g)
  trap 'stty "$old_stty_settings"; printf "\n"' EXIT

  # 端末設定の初期化
  stty sane
  stty -echo -icanon time 0 min 0

  # Cygwin/MSYS2 Bash では行末の \r を無視する
  shopt -s igncr 2>/dev/null || true

  local commits=() commit_ids=() commit_msgs=() files=()
  local selected_commit="" selected_commit_msg="" selected_file=""
  local current_view="commits"
  local selected_index=0 page_size=10 page_offset=0 total_items=0

  function update_display() {
    clear
    case "$current_view" in
      commits)      display_commits ;;
      files)        display_files ;;
      file_actions) display_file_actions ;;
    esac
  }

  function fetch_commits() {
    # コミット情報取得時に行末の \r を除去
    mapfile -t commit_data < <(
      git log --pretty=format:"%h|%s" -100 \
      | sed 's/\r$//'
    )
    commits=(); commit_ids=(); commit_msgs=()
    for line in "${commit_data[@]}"; do
      id="${line%%|*}"
      msg="${line#*|}"
      commit_ids+=("$id")
      commit_msgs+=("$msg")
      commits+=("$id - $msg")
    done
    total_items=${#commits[@]}
  }

  function display_commits() {
    printf "=== Git コミット履歴ブラウザ ===\n"
    printf "\033[1;36m[モード: コミット一覧]\033[0m ↑/↓: 選択移動, Enter: 選択, ESC/q: 終了\n"
    printf "-------------------------------------\n"
    local end=$((page_offset + page_size))
    (( end > total_items )) && end=$total_items
    for ((i=page_offset; i<end; i++)); do
      if (( i == selected_index )); then
        local id="${commit_ids[i]}"
        local msg="${commit_msgs[i]}"
        printf "\033[1;32m* \033[1;33m%s\033[0m - %s\n" "$id" "$msg"
      else
        local id="${commit_ids[i]}"
        local msg="${commit_msgs[i]}"
        printf "  \033[1;33m%s\033[0m - %s\n" "$id" "$msg"
      fi
    done
    printf "-------------------------------------\n"
    printf "表示: %d-%d / %d\n" $((page_offset+1)) $end $total_items
    (( page_offset > 0 )) && printf "前ページ: ←\n"
    (( end < total_items )) && printf "次ページ: →\n"
  }

  function fetch_files() {
    selected_commit="${commit_ids[selected_index]}"
    selected_commit_msg="${commit_msgs[selected_index]}"
    mapfile -t files < <(
      git show --name-only --pretty=format:"" "$selected_commit" \
      | sed 's/\r$//' \
      | grep -v '^$'
    )
    total_items=${#files[@]}
    selected_index=0; page_offset=0
  }

  function display_files() {
    # 画面をクリア
    clear
    
    # 画面サイズを取得
    local term_width=$(tput cols)
    local term_height=$(tput lines)
    local list_width=$((term_width / 2 - 2))
    
    # 左側にファイル一覧を表示
    printf "=== コミット \033[1;33m%s\033[0m ===\n" "$selected_commit"
    printf "\033[1;36m[コミットメッセージ: \033[0m%s\033[1;36m]\033[0m\n" "$selected_commit_msg"
    printf "\033[1;36m[モード: ファイル一覧]\033[0m ↑/↓: 選択移動, Enter: ファイル操作, ESC: 戻る, q: 終了\n"
    printf "%s\n" "$(printf '%*s' $list_width | tr ' ' '-')"
    
    local end=$((page_offset + page_size))
    (( end > total_items )) && end=$total_items
    
    for ((i=page_offset; i<end; i++)); do
      local file_display="${files[i]}"
      # ファイル名が長すぎる場合は切り詰める
      if (( ${#file_display} > list_width )); then
        file_display="${file_display:0:$((list_width-3))}..."
      fi
      
      if (( i == selected_index )); then
        printf "\033[1;32m* \033[1;35m%s\033[0m\n" "$file_display"
      else
        printf "  \033[1;35m%s\033[0m\n" "$file_display"
      fi
    done
    
    printf "%s\n" "$(printf '%*s' $list_width | tr ' ' '-')"
    printf "表示: %d-%d / %d\n" $((page_offset+1)) $end $total_items
    (( page_offset > 0 )) && printf "前ページ: ←\n"
    (( end < total_items )) && printf "次ページ: →\n"
    
    # 右側にプレビューを表示（枠付き）
    if (( total_items > 0 )); then
      draw_preview_box
      # カーソルを右上に移動 (枠の内側の開始位置)
      printf "\033[4;$((list_width + 5))H"
      printf "\033[1;36m=== プレビュー: \033[1;35m%s\033[1;36m ===\033[0m\n" "${files[selected_index]}"
      preview_file "${files[selected_index]}"
    fi
  }

  function draw_preview_box() {
    local term_width=$(tput cols)
    local term_height=$(tput lines)
    local list_width=$((term_width / 2 - 2))
    local preview_width=$((term_width / 2))
    local preview_height=$((term_height - 6))  # コミットメッセージ行のため1行増やす
    local preview_start_col=$((list_width + 3))
    
    # 枠の上部
    printf "\033[3;${preview_start_col}H\033[1;34m┌"
    for ((i=0; i<preview_width-2; i++)); do
      printf "─"
    done
    printf "┐\033[0m"
    
    # 枠の側面
    for ((i=0; i<preview_height; i++)); do
      printf "\033[$((4 + i));${preview_start_col}H\033[1;34m│\033[0m"
      printf "\033[$((4 + i));$((preview_start_col + preview_width - 1))H\033[1;34m│\033[0m"
    done
    
    # 枠の下部
    printf "\033[$((4 + preview_height));${preview_start_col}H\033[1;34m└"
    for ((i=0; i<preview_width-2; i++)); do
      printf "─"
    done
    printf "┘\033[0m"
  }

  function preview_file() {
    local file="$1"
    local term_width=$(tput cols)
    local term_height=$(tput lines)
    local list_width=$((term_width / 2 - 2))
    local preview_width=$((term_width / 2 - 4))  # 枠の分を考慮
    local preview_height=$((term_height - 9))    # 枠とヘッダーの分を考慮 (コミットメッセージ行のため1行増やす)
    local preview_content
    
    # ファイルコンテンツを一時ファイルに取得
    local tmp="/tmp/git_preview_${selected_commit}_$(basename "$file")"
    git show "$selected_commit:$file" > "$tmp" 2>/dev/null
    
    # ファイルタイプ判定
    local file_type=$(file -b "$tmp")
    
    if [[ "$file_type" == *"text"* || "$file_type" == *"ASCII"* ]]; then
      # テキストファイルの場合は内容を表示
      local line_num=0
      while IFS= read -r line && (( line_num < preview_height )); do
        # カーソルを右側の適切な位置に移動（枠の内側）
        printf "\033[$((6 + line_num));$((list_width + 5))H"
        
        # 行が長すぎる場合は切り詰める
        if (( ${#line} > preview_width )); then
          printf "%s...\n" "${line:0:$((preview_width-3))}"
        else
          printf "%s\n" "$line"
        fi
        
        ((line_num++))
      done < "$tmp"
    else
      # バイナリファイルなどの場合はメッセージを表示
      printf "\033[6;$((list_width + 5))H"
      printf "バイナリファイルはプレビューできません\n"
      printf "\033[7;$((list_width + 5))H"
      printf "ファイルタイプ: %s\n" "$file_type"
    fi
    
    # 一時ファイルを削除
    rm "$tmp"
  }

  function display_file_actions() {
    selected_file="${files[selected_index]}"
    printf "=== ファイル操作: \033[1;35m%s\033[0m ===\n" "$selected_file"
    printf "=== コミット: \033[1;33m%s\033[0m (\033[0m%s\033[0m) ===\n" "$selected_commit" "$selected_commit_msg"
    printf "\033[1;36m[モード: ファイル操作]\033[0m ↑/↓: 選択移動, Enter: 実行, ESC: 戻る, q: 終了\n"
    printf "-------------------------------------\n"
    local actions=("1. less -R で表示" "2. 名前を付けて保存" "3. 戻る")
    for ((i=0; i<${#actions[@]}; i++)); do
      if (( i == action_index )); then
        printf "\033[1;32m* %s\033[0m\n" "${actions[i]}"
      else
        printf "  %s\n" "${actions[i]}"
      fi
    done
  }

  function execute_file_action() {
    printf "\033[2J\033[H"
    printf "選択: \033[1;35m%s\033[0m (コミット: \033[1;33m%s\033[0m - %s)\n" "$selected_file" "$selected_commit" "$selected_commit_msg"
    printf "-------------------------------------\n"
    case $action_index in
      0)
        tmp="/tmp/git_view_${selected_commit}_$(basename "$selected_file")"
        git show "$selected_commit:$selected_file" > "$tmp"
        printf "\033[2J\033[H"; less -R "$tmp"; rm "$tmp"
        ;;
      1)
        # 端末設定を一時的に戻して入力を受け付ける
        stty echo icanon
        printf "\033[2J\033[H"; 
        echo "保存するファイル名を入力:"; 
        read -r save_filename
        # 入力末尾の \r を削除
        save_filename="${save_filename//$'\r'/}"
        if [[ -n "$save_filename" ]]; then
          if git show "$selected_commit:$selected_file" > "$save_filename"; then
            echo "保存しました: $save_filename"
          else
            echo "保存に失敗しました"
          fi
          echo "Enterで戻る"; 
          read -r
        fi
        # 元の端末設定に戻す
        stty -echo -icanon time 0 min 0
        ;;
      2)
        current_view="files"; selected_index=0; return
        ;;
    esac
    current_view="file_actions"; action_index=0
  }

  function main_loop() {
    fetch_commits; update_display
    local action_index=0

    while true; do
      local key
      read -rsn1 key

      if [[ "$key" == $'\r' || "$key" == "" ]]; then
        case "$current_view" in
          commits)      fetch_files; current_view="files" ;;
          files)        current_view="file_actions"; action_index=0 ;;
          file_actions)
            stty "$old_stty_settings"
            execute_file_action
            stty -echo -icanon time 0 min 0
            ;;
        esac
        update_display
        continue
      fi

      if [[ "$key" == $'\e' ]]; then
        read -rsn2 -t 0.1 seq
        if [[ -z "$seq" ]]; then
          case "$current_view" in
            commits)      stty "$old_stty_settings"; clear; return ;;
            files)        current_view="commits"; selected_index=0; page_offset=0; fetch_commits ;;
            file_actions) current_view="files"; selected_index=0 ;;
          esac
        else
          case "$seq" in
            "[A") 
              if [[ "$current_view" == "file_actions" ]]; then
                (( action_index>0 )) && ((action_index--))
              else
                (( selected_index>0 )) && ((selected_index--, page_offset>selected_index&&(page_offset--)))
              fi
              ;;
            "[B") 
              if [[ "$current_view" == "file_actions" ]]; then
                (( action_index<2 )) && ((action_index++))
              else
                (( selected_index<total_items-1 )) && ((selected_index++, selected_index>=page_offset+page_size&&(page_offset++)))
              fi
              ;;
            "[C") (( page_offset+page_size<total_items )) && ((page_offset+=page_size, selected_index<page_offset&&(selected_index=page_offset), selected_index>=page_offset+page_size&&(selected_index=page_offset+page_size-1))) ;;
            "[D") (( page_offset>0 )) && ((page_offset-=page_size<0?(page_offset=0):page_offset, selected_index>=page_offset+page_size&&(selected_index=page_offset+page_size-1), selected_index<page_offset&&(selected_index=page_offset))) ;;
          esac
        fi
        update_display
      elif [[ "$key" == "q" ]]; then
        stty "$old_stty_settings"; clear; return
      fi
    done
  }

  if ! git rev-parse --is-inside-work-tree &>/dev/null; then
    echo "エラー: Git リポジトリではありません。"; return 1
  fi

  main_loop
}
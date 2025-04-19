#!/usr/bin/env bash
set -euo pipefail

# --- 設定 ---
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BASE_DIR="$SCRIPT_DIR"
COMMANDS_DIR="$BASE_DIR/commands"
ENABLED_LIST="$BASE_DIR/enabled_commands.conf"
ALIAS_FILE="$BASE_DIR/.bash_aliases"
BIN_DIR="$BASE_DIR/bin"
BASHRC="$HOME/.bashrc"
MARKER="# bash-scripts-config-start"
MARKER_END="# bash-scripts-config-end"
# ---------------

echo "[setup] 開始: すべてのコマンドを再反映します"

# 改行コードをLFに強制（Windows CRLF 対応）
if command -v dos2unix >/dev/null 2>&1; then
  echo "[setup] 改行コードを修正 (dos2unix)..."
  dos2unix "$COMMANDS_DIR"/*.sh "$ENABLED_LIST" 2>/dev/null || true
fi

# .bash_aliases を再生成
{
  echo "# 自動生成: 有効な bash コマンド"
  while IFS= read -r cmd; do
    [[ "$cmd" =~ ^#|^$ ]] && continue
    echo "source \"$COMMANDS_DIR/${cmd}.sh\""
  done < "$ENABLED_LIST"
} > "$ALIAS_FILE"
echo "[setup] .bash_aliases を再生成しました"

# bin/ を再生成（古いスクリプトを削除）
mkdir -p "$BIN_DIR"
find "$BIN_DIR" -type f -exec rm -f {} \;

while IFS= read -r cmd; do
  [[ "$cmd" =~ ^#|^$ ]] && continue
  WRAPPER="$BIN_DIR/$cmd"
  cat > "$WRAPPER" <<EOF
#!/usr/bin/env bash
source "$COMMANDS_DIR/${cmd}.sh"
${cmd} "\$@"
EOF
  chmod +x "$WRAPPER"
done < "$ENABLED_LIST"
echo "[setup] bin/ 以下のラッパースクリプトを再生成しました"

# .bashrc にエイリアス読み込みと PATH を追加（初回のみ）
if ! grep -Fxq "$MARKER" "$BASHRC"; then
  cat >> "$BASHRC" <<EOF

$MARKER
# load bash-scripts aliases
if [ -f "$ALIAS_FILE" ]; then
  . "$ALIAS_FILE"
fi
# include bin in PATH
export PATH="$BIN_DIR:\$PATH"
$MARKER_END
EOF
  echo "[setup] .bashrc に設定を追加しました"
else
  echo "[setup] .bashrc には既に設定があります（スキップ）"
fi

echo "[setup] 完了 ✅ 'source ~/.bashrc' を忘れずに！"

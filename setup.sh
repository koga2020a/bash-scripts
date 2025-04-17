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
MARKER="# >>> bash-scripts config >>>"
# ---------------

# 1) 有効コマンド一覧から .bash_aliases を生成
{
  echo "# Load enabled bash-scripts commands"
  while IFS= read -r cmd; do
    [[ "$cmd" =~ ^#|^$ ]] && continue
    echo "source \"$COMMANDS_DIR/${cmd}.sh\""
  done < "$ENABLED_LIST"
} > "$ALIAS_FILE"
echo "[setup] Generated $ALIAS_FILE"

# 2) bin/ 以下に wrapper スクリプトを生成
mkdir -p "$BIN_DIR"
while IFS= read -r cmd; do
  [[ "$cmd" =~ ^#|^$ ]] && continue
  cat > "$BIN_DIR/$cmd" <<EOF
#!/usr/bin/env bash
source "$COMMANDS_DIR/${cmd}.sh"
${cmd} "\$@"
EOF
  chmod +x "$BIN_DIR/$cmd"
done < "$ENABLED_LIST"
echo "[setup] Generated wrappers in $BIN_DIR"

# 3) ~/.bashrc に .bash_aliases の読み込みと PATH 追加を追記
if ! grep -Fxq "$MARKER" "$BASHRC"; then
  cat >> "$BASHRC" <<EOF

$MARKER
# load bash-scripts aliases
if [ -f "$ALIAS_FILE" ]; then
  source "$ALIAS_FILE"
fi
# include bin in PATH
export PATH="$BIN_DIR:\$PATH"
# <<< bash-scripts config <<<
EOF
  echo "[setup] Appended alias load and PATH to $BASHRC"
else
  echo "[setup] $BASHRC already contains bash-scripts config. Skipped."
fi

echo "[setup] Done. Reload with: source ~/.bashrc"

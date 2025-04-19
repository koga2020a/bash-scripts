#!/usr/bin/env bash

# 自動で .venv を有効化する関数
function auto_venv_activate() {
    if [ -f "venv/Scripts/activate" ]; then
        # すでに有効化されていなければ
        if [ "$VIRTUAL_ENV" != "$(pwd)/venv" ]; then
            source "venv/Scripts/activate"
            echo "Activated virtual environment: $(pwd)/venv"
        fi
    elif [ -f ".venv/Scripts/activate" ]; then
        # .venv ディレクトリがある場合
        if [ "$VIRTUAL_ENV" != "$(pwd)/.venv" ]; then
            source ".venv/Scripts/activate"
            echo "Activated virtual environment: $(pwd)/.venv"
        fi
    elif [ -n "$VIRTUAL_ENV" ]; then
        # 仮想環境がない場合は無効化
        deactivate
        echo "Deactivated virtual environment"
    fi
}

# cd をオーバーライドして自動チェック
function cd() {
    builtin cd "$@" && auto_venv_activate
}

# Git Bash 起動時にも1回チェック
auto_venv_activate 
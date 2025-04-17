# bash-scripts template

Git Bash (Windows) 向けに、fzf + delta を使った対話的 git 操作などを簡単に追加できるテンプレートです。

## 前提

- fzf.exe, delta.exe を `/c/bin` に配置
- Git Bash 環境

## セットアップ

```bash
cd /c/src/bash_script
bash setup.sh
source ~/.bashrc

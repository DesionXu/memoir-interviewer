#!/bin/bash
# ============================================
# DevEco 工程同步脚本
# 用途：把工作区里的鸿蒙工程复制到"不含空格"的路径，
#       供 DevEco Studio 打开（DevEco/hvigor 不支持含空格的路径）。
#
# 用法（在终端里执行下面一行，注意引号）：
#   bash "/Users/hasu/Downloads/project driven by deepseek herness/scripts/deveco-sync.sh"
#
# 每次代码更新后（我修改并推送后），重新运行本脚本，
# 再回到 DevEco Studio 点右上角 Sync 即可。
# ============================================
set -e

SRC="$(cd "$(dirname "$0")/.." && pwd)/harmony/MemoirInterviewer"
DEST="${DEVECO_PROJECT_DIR:-$HOME/DevEcoProjects/MemoirInterviewer}"

if [ ! -d "$SRC" ]; then
  echo "❌ 找不到源工程：$SRC"
  exit 1
fi

mkdir -p "$(dirname "$DEST")"

# 删除旧副本后整体复制（工程内容以 GitHub 仓库为准，副本内不要手动改代码）
rm -rf "$DEST"
ditto "$SRC" "$DEST"

echo "✅ 已同步到：$DEST"
echo "👉 回到 DevEco Studio → File → Open 打开上面这个文件夹（若已打开，点右上角 Sync 即可）"

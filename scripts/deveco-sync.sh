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

# 注入开发者 API Key（来自仓库根目录 config.js，不进入公开仓库）
CONFIG_JS="$(cd "$SRC/../.." && pwd)/config.js"
if [ -f "$CONFIG_JS" ]; then
  KEY=$(grep -oE 'sk-[a-zA-Z0-9]{10,}' "$CONFIG_JS" | head -1)
  if [ -n "$KEY" ]; then
    sed -i '' "s|'YOUR_API_KEY_HERE'|'$KEY'|" "$DEST/entry/src/main/ets/service/Config.ets"
    echo "✅ 已注入内置 API Key（${KEY:0:6}…）"
  fi
fi

echo "✅ 已同步到：$DEST"

# 自检：确认关键配置已是最新
HV_VERSION=$(grep -o '"modelVersion"[^,]*' "$DEST/hvigor/hvigor-config.json5" 2>/dev/null || echo '缺失')
OHPM_VERSION=$(grep -o '"modelVersion"[^,]*' "$DEST/oh-package.json5" 2>/dev/null || echo '缺失')
echo "自检：hvigor $HV_VERSION | ohpm $OHPM_VERSION"
if [ -f "$DEST/hvigor/hvigor-config.json5" ] && grep -q '"modelVersion" *: *"6.0.0"' "$DEST/oh-package.json5"; then
  echo "✅ 配置一致（6.0.0），可以打开 DevEco 了"
else
  echo "⚠️ 配置版本异常，请把上面两行信息发给开发者"
fi
echo "👉 回到 DevEco Studio → File → Open 打开上面这个文件夹（若已打开，点右上角 Sync 即可）"

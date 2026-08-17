#!/bin/bash
# ============================================
# 一键修改鸿蒙应用包名（bundleName）
# 用法：bash "…/scripts/set-bundle-name.sh" com.dowson.memoir
# 注意：包名必须与 AGC 应用一致且全局唯一；改完后重新构建/同步
# ============================================
set -e

NEW="$1"
if [ -z "$NEW" ] || ! echo "$NEW" | grep -qE '^[a-zA-Z][a-zA-Z0-9_]*(\.[a-zA-Z][a-zA-Z0-9_]*){2,}$'; then
  echo "❌ 包名格式错误。示例：com.dowson.memoir（至少三段，字母/数字/下划线，每段以字母开头）"
  exit 1
fi

FILE="$(cd "$(dirname "$0")/.." && pwd)/harmony/MemoirInterviewer/AppScope/app.json5"
sed -i '' -E "s/\"bundleName\": \"[^\"]*\"/\"bundleName\": \"$NEW\"/" "$FILE"

echo "✅ bundleName 已改为：$NEW"
grep bundleName "$FILE"
echo "👉 记得重新运行 deveco-sync.sh，并在 DevEco 里 Sync；AGC 里的包名也要与此一致"

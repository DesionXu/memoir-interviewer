#!/bin/bash
# ============================================
# 鸿蒙工程命令行构建脚本（无需打开 DevEco Studio）
# 用法：bash "…/scripts/harmony-build.sh" [debug|release]
# 产物：harmony/MemoirInterviewer/entry/build/default/outputs/default/*.hap
# ============================================
set -e

MODE="${1:-debug}"

DEVECO="/Applications/DevEco-Studio.app"
if [ ! -d "$DEVECO" ]; then
  echo "❌ 未找到 DevEco Studio，请确认已安装到 /Applications"
  exit 1
fi

PROJECT="$(cd "$(dirname "$0")/.." && pwd)/harmony/MemoirInterviewer"
cd "$PROJECT"

export DEVECO_SDK_HOME="$DEVECO/Contents/sdk"
export JAVA_HOME="$DEVECO/Contents/jbr/Contents/Home"
export PATH="$DEVECO/Contents/tools/node/bin:$DEVECO/Contents/tools/ohpm/bin:$JAVA_HOME/bin:$PATH"

# hvigor 缓存放到临时目录，避免污染用户主目录（也规避部分权限问题）
export HOME="${HVIGOR_HOME_DIR:-/tmp/hvigor-home}"
export npm_config_cache="/tmp/hvigor-npm-cache"
mkdir -p "$HOME" "$npm_config_cache"

"$DEVECO/Contents/tools/node/bin/node" "$DEVECO/Contents/tools/hvigor/bin/hvigorw.js" \
  --mode module -p product=default -p buildMode="$MODE" assembleHap --no-daemon

echo ""
echo "✅ 构建完成 [mode=$MODE]。产物位于："
ls -lh "$PROJECT/entry/build/default/outputs/default/"*.hap 2>/dev/null || true

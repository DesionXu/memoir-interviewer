#!/bin/bash
# ============================================
# 鸿蒙工程命令行构建脚本（无需打开 DevEco Studio）
# 用法：bash "…/scripts/harmony-build.sh" [debug|release]
# 产物：harmony/MemoirInterviewer/entry/build/default/outputs/default/*.hap
# 特性：
#   - 自动注入内置 API Key（来自仓库根目录 config.js，构建后恢复占位符）
#   - 自动注入本机签名配置（signing.local.json5，构建后恢复，不污染仓库）
#     → release 模式产出可直接上传 AGC 的签名包
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

CONFIG_JS="$(cd "$PROJECT/../.." && pwd)/config.js"
KEY=$(grep -oE 'sk-[a-zA-Z0-9]{10,}' "$CONFIG_JS" 2>/dev/null | head -1)
BP="$PROJECT/build-profile.json5"
CFG_ETS="$PROJECT/entry/src/main/ets/service/Config.ets"
SIGNING="$PROJECT/signing.local.json5"

# 构建结束后恢复所有注入（Key 占位符、build-profile 原样）
restoreAll() {
  [ -f "$BP.bak" ] && mv "$BP.bak" "$BP"
  if [ -n "$KEY" ]; then
    sed -i '' "s|'$KEY'|'YOUR_API_KEY_HERE'|" "$CFG_ETS" 2>/dev/null || true
  fi
}
trap restoreAll EXIT

# 1) 注入内置 API Key
if [ -n "$KEY" ]; then
  sed -i '' "s|'YOUR_API_KEY_HERE'|'$KEY'|" "$CFG_ETS"
  echo "✅ 已注入内置 API Key（${KEY:0:6}…）"
fi

# 2) 注入本机签名配置（signing.local.json5 已 gitignore，不进入仓库）
if [ -f "$SIGNING" ]; then
  python3 - "$BP" "$SIGNING" <<'PYEOF'
import json, shutil, sys
bp, sp = sys.argv[1], sys.argv[2]
shutil.copy(bp, bp + '.bak')
cfg = json.load(open(bp, encoding='utf-8'))
sign = json.load(open(sp, encoding='utf-8'))
cfg['app']['signingConfigs'] = sign.get('signingConfigs', [])
for p in cfg['app'].get('products', []):
    p['signingConfig'] = 'default'
json.dump(cfg, open(bp, 'w', encoding='utf-8'), ensure_ascii=False, indent=2)
print('✅ 已注入本机签名配置')
PYEOF
fi

# 3) 构建
"$DEVECO/Contents/tools/node/bin/node" "$DEVECO/Contents/tools/hvigor/bin/hvigorw.js" \
  --mode module -p product=default -p buildMode="$MODE" assembleHap --no-daemon

echo ""
echo "✅ 构建完成 [mode=$MODE]。产物位于："
ls -lh "$PROJECT/entry/build/default/outputs/default/"*.hap 2>/dev/null || true

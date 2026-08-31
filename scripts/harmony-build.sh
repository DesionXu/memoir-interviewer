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

# 构建结束后恢复 Key 占位符
restoreAll() {
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

# 2) 构建（不注入签名：hvigor 的 SignHap 只认 DevEco 加密密码，签名改用官方 hap-sign-tool 手动完成）
"$DEVECO/Contents/tools/node/bin/node" "$DEVECO/Contents/tools/hvigor/bin/hvigorw.js" \
  --mode module -p product=default -p buildMode="$MODE" assembleHap --no-daemon

# 3) 用官方 hap-sign-tool 对未签名包手动签名（支持明文密码）
if [ -f "$SIGNING" ]; then
  UNSIGNED=$(ls -t "$PROJECT/entry/build/default/outputs/default/"*.hap 2>/dev/null | head -1)
  SIGNED="$PROJECT/entry/build/default/outputs/default/entry-default-signed.hap"
  python3 - "$SIGNING" <<'PYEOF' > /tmp/sign_params.env
import json, sys
m = json.load(open(sys.argv[1], encoding='utf-8'))['signingConfigs'][0]['material']
for k in ('storeFile','storePassword','keyAlias','keyPassword','signAlg','profile','certpath'):
    v = m.get(k, '')
    print(k.upper() + '=' + v.replace(' ', '\\ '))
PYEOF
  if [ -f "$UNSIGNED" ]; then
    . /tmp/sign_params.env
    "$JAVA_HOME/bin/java" -jar "$DEVECO/Contents/sdk/default/openharmony/toolchains/lib/hap-sign-tool.jar" sign-app \
      -mode localSign \
      -keyAlias "$KEYALIAS" \
      -keyPwd "$KEYPASSWORD" \
      -keystoreFile "$STOREFILE" \
      -keystorePwd "$STOREPASSWORD" \
      -appCertFile "$CERTPATH" \
      -profileFile "$PROFILE" \
      -profileSigned 1 \
      -signAlg "$SIGNALG" \
      -inFile "$UNSIGNED" \
      -compatibleVersion 12 \
      -outFile "$SIGNED" \
      && echo "✅ 已签名：$SIGNED"
  fi

  # 4) 打包 .app（AGC 上架要求的格式；工具临时目录在 ~/Downloads/tempHapDir）
  if [ -f "$SIGNED" ]; then
    mkdir -p "$HOME/Downloads/tempHapDir" 2>/dev/null || true
    cat > /tmp/pack.info <<EOF
{
  "summary": {
    "app": {
      "bundleName": "com.dowson.memoir",
      "version": { "code": 1000000, "name": "1.0.0" },
      "vendor": "memoir"
    },
    "modules": [
      {
        "mainAbility": "EntryAbility",
        "deviceType": ["phone", "tablet", "2in1"],
        "apiVersion": { "compatible": 12, "target": 24, "releaseType": "Release" },
        "distributionType": "app_gallery",
        "moduleName": "entry",
        "moduleType": "entry"
      }
    ]
  },
  "packages": [
    {
      "deviceType": ["phone", "tablet", "2in1"],
      "moduleType": "entry",
      "name": "entry",
      "deliveryWithInstall": true
    }
  ]
}
EOF
    APP_OUT="$PROJECT/entry/build/default/outputs/default/entry-default-signed.app"
    "$JAVA_HOME/bin/java" -jar "$DEVECO/Contents/sdk/default/openharmony/toolchains/lib/app_packing_tool.jar" \
      --mode app --pack-info-path /tmp/pack.info --hap-path "$SIGNED" --out-path "$APP_OUT" \
      && echo "✅ 已打包 .app：$APP_OUT"
  fi
fi

echo ""
echo "✅ 构建完成 [mode=$MODE]。产物位于："
ls -lh "$PROJECT/entry/build/default/outputs/default/"*.hap 2>/dev/null || true

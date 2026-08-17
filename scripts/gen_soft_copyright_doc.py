#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
软著源代码文档生成器
====================
按中国版权保护中心要求，源代码文档需：
- 前后各 30 页（总页数超过 60 页时），每页 50 行
- 总页数不足 60 页时提交全部源代码

用法：python3 scripts/gen_soft_copyright_doc.py
输出：docs/soft-copyright-source-code.txt（提交版文档）
注意：config.js / .env 等含密钥文件不会被收录。
"""
import os

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, 'docs', 'soft-copyright-source-code.txt')

FILES = [
    'index.html',
    'memoir.html',
    'server.js',
    'harmony/MemoirInterviewer/AppScope/app.json5',
    'harmony/MemoirInterviewer/AppScope/resources/base/element/string.json',
    'harmony/MemoirInterviewer/build-profile.json5',
    'harmony/MemoirInterviewer/hvigorfile.ts',
    'harmony/MemoirInterviewer/oh-package.json5',
    'harmony/MemoirInterviewer/entry/build-profile.json5',
    'harmony/MemoirInterviewer/entry/hvigorfile.ts',
    'harmony/MemoirInterviewer/entry/oh-package.json5',
    'harmony/MemoirInterviewer/entry/src/main/module.json5',
    'harmony/MemoirInterviewer/entry/src/main/ets/entryability/EntryAbility.ets',
    'harmony/MemoirInterviewer/entry/src/main/ets/pages/Index.ets',
    'harmony/MemoirInterviewer/entry/src/main/ets/pages/Interview.ets',
    'harmony/MemoirInterviewer/entry/src/main/ets/pages/Settings.ets',
    'harmony/MemoirInterviewer/entry/src/main/ets/bridge/HarmonyBridge.ets',
    'harmony/MemoirInterviewer/entry/src/main/ets/service/Config.ets',
    'harmony/MemoirInterviewer/entry/src/main/ets/service/ApiService.ets',
    'harmony/MemoirInterviewer/entry/src/main/ets/service/TtsService.ets',
    'harmony/MemoirInterviewer/entry/src/main/ets/service/AsrService.ets',
    'harmony/MemoirInterviewer/entry/src/main/ets/service/SettingsService.ets',
    'harmony/MemoirInterviewer/entry/src/main/ets/service/PermissionUtil.ets',
    'harmony/MemoirInterviewer/entry/src/main/resources/base/profile/main_pages.json',
    'harmony/MemoirInterviewer/entry/src/main/resources/base/element/string.json',
    'harmony/MemoirInterviewer/entry/src/main/resources/base/element/color.json',
]

LINES_PER_PAGE = 50


def main():
    lines = []
    for f in FILES:
        p = os.path.join(ROOT, f)
        if not os.path.isfile(p):
            print('跳过（不存在）:', f)
            continue
        with open(p, encoding='utf-8') as fh:
            content = fh.read().rstrip('\n')
        lines.append('')
        lines.append('// ==================== 文件：' + f + ' ====================')
        lines.append('')
        lines.extend(content.split('\n'))

    pages = []
    i = 0
    while i < len(lines):
        pages.append(lines[i:i + LINES_PER_PAGE])
        i += LINES_PER_PAGE

    total = len(pages)
    selected = pages if total <= 60 else pages[:30] + pages[-30:]

    with open(OUT, 'w', encoding='utf-8') as fh:
        for idx, page in enumerate(selected, 1):
            fh.write('第 ' + str(idx) + ' 页\n')
            fh.write('\n'.join(page))
            fh.write('\n\n')

    print('源代码总行数:', len(lines))
    print('总页数:', total, '| 提交页数:', len(selected))
    print('输出文件:', OUT)
    # 安全检查：输出中不得包含真实 API Key（形如 sk- 后跟 20 位以上字母数字）
    import re
    with open(OUT, encoding='utf-8') as fh:
        data = fh.read()
    leaks = re.findall(r'sk-[A-Za-z0-9]{20,}', data)
    assert not leaks, '错误：输出中包含疑似 API Key：' + str(leaks)
    print('安全检查：未包含真实 API Key ✓')


if __name__ == '__main__':
    main()

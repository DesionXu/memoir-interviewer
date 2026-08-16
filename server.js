// ============================================
// 回忆录访谈员 · 后端代理服务器（零依赖，Node.js 18+）
//
// 作用：公网部署时，把 DeepSeek API Key 安全地保存在服务器上，
//       浏览器只通过同源 /api/chat 调用，Key 不会暴露给访客。
//
// 运行方式（二选一）：
//   1. 环境变量：  DEEPSEEK_API_KEY=sk-xxx node server.js
//   2. .env 文件： 复制 .env.example 为 .env 并填入 Key，然后 node server.js
// ============================================
const http = require('http');
const fs = require('fs');
const path = require('path');
const url = require('url');

const PORT = process.env.PORT || 3000;

// 读取 API Key：环境变量优先，其次 .env 文件
function loadKey() {
    if (process.env.DEEPSEEK_API_KEY) return process.env.DEEPSEEK_API_KEY.trim();
    try {
        const env = fs.readFileSync(path.join(__dirname, '.env'), 'utf8');
        const m = env.match(/^DEEPSEEK_API_KEY\s*=\s*(.+)$/m);
        if (m) return m[1].trim();
    } catch (e) {}
    return '';
}
const DEEPSEEK_API_KEY = loadKey();
if (!DEEPSEEK_API_KEY) {
    console.warn('⚠️  未找到 DEEPSEEK_API_KEY（请设置环境变量或创建 .env 文件），/api/chat 将不可用');
}

const MIME = {
    '.html': 'text/html; charset=utf-8',
    '.js': 'text/javascript; charset=utf-8',
    '.css': 'text/css; charset=utf-8',
    '.txt': 'text/plain; charset=utf-8',
    '.md': 'text/plain; charset=utf-8',
    '.json': 'application/json; charset=utf-8',
    '.png': 'image/png',
    '.jpg': 'image/jpeg',
    '.svg': 'image/svg+xml',
    '.ico': 'image/x-icon'
};

const server = http.createServer((req, res) => {
    const reqUrl = new url.URL(req.url, 'http://localhost');
    const pathname = decodeURIComponent(reqUrl.pathname);

    // 健康检查（前端用它判断是否走后端代理）
    if (pathname === '/api/health') {
        res.writeHead(200, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify({ ok: true, hasKey: !!DEEPSEEK_API_KEY }));
        return;
    }

    // DeepSeek 代理
    if (pathname === '/api/chat' && req.method === 'POST') {
        if (!DEEPSEEK_API_KEY) {
            res.writeHead(500, { 'Content-Type': 'application/json' });
            res.end(JSON.stringify({ error: '服务器未配置 DEEPSEEK_API_KEY' }));
            return;
        }
        let body = '';
        req.on('data', (c) => {
            body += c;
            if (body.length > 2e6) req.destroy();   // 防止超大请求
        });
        req.on('end', async () => {
            try {
                const upstream = await fetch('https://api.deepseek.com/v1/chat/completions', {
                    method: 'POST',
                    headers: {
                        'Content-Type': 'application/json',
                        'Authorization': `Bearer ${DEEPSEEK_API_KEY}`
                    },
                    body: JSON.stringify({
                        model: 'deepseek-v4-pro',
                        ...JSON.parse(body)
                    })
                });
                const data = await upstream.json();
                res.writeHead(upstream.status, { 'Content-Type': 'application/json' });
                res.end(JSON.stringify(data));
            } catch (e) {
                res.writeHead(500, { 'Content-Type': 'application/json' });
                res.end(JSON.stringify({ error: '代理请求失败：' + e.message }));
            }
        });
        return;
    }

    // 静态文件
    let filePath = pathname === '/' ? '/index.html' : pathname;
    filePath = path.normalize(path.join(__dirname, filePath));
    if (filePath !== __dirname && !filePath.startsWith(__dirname + path.sep)) {
        res.writeHead(403);
        res.end('Forbidden');
        return;
    }
    fs.readFile(filePath, (err, data) => {
        if (err) {
            res.writeHead(404, { 'Content-Type': 'text/plain; charset=utf-8' });
            res.end('Not Found');
            return;
        }
        res.writeHead(200, { 'Content-Type': MIME[path.extname(filePath)] || 'application/octet-stream' });
        res.end(data);
    });
});

server.listen(PORT, () => {
    console.log('📖 回忆录访谈员已启动：http://localhost:' + PORT);
    console.log(DEEPSEEK_API_KEY
        ? '✅ API Key 已加载（安全保存在服务器端）'
        : '⚠️  未配置 API Key，/api/chat 不可用');
});

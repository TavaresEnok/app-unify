const http = require('http');
const cluster = require('cluster');
const os = require('os');

// Porta 3001
const PORT = 3001;
// 10GB para testes de alta performance (10Gbps)
// 2GB (Limite seguro para 32-bit signed int ~2.14GB) para evitar overflow no cliente
const FILE_SIZE = 2 * 1024 * 1024 * 1024 - 1000; // Um pouco menos de 2GB para segurança
const CHUNK_SIZE = 128 * 1024;
const ZERO_BUFFER = Buffer.alloc(CHUNK_SIZE, 0);

if (cluster.isMaster) {
    const numCPUs = os.cpus().length;
    console.log(`🚀 Iniciando Master (PID: ${process.pid})`);
    console.log(`💻 Detectados ${numCPUs} núcleos. Iniciando workers...`);
    console.log(`📂 Tamanho Simulado: 10GB`);

    // Fork workers para cada core
    for (let i = 0; i < numCPUs; i++) {
        cluster.fork();
    }

    cluster.on('exit', (worker, code, signal) => {
        console.log(`Worker ${worker.process.pid} morreu. Iniciando outro...`);
        cluster.fork();
    });
} else {
    // --- WORKER PROCESS ---
    startWorkerServer();
}

function startWorkerServer() {
    const server = http.createServer((req, res) => {
        if (req.url === '/health') {
            res.writeHead(200, { 'Content-Type': 'application/json' });
            res.end(JSON.stringify({ status: 'ok', service: 'speed-test' }));
            return;
        }

        // CORS — restringir a origens conhecidas
        const allowedOrigins = (process.env.ALLOWED_ORIGINS
            || 'http://localhost:5173,http://localhost:8031,http://127.0.0.1:8031')
            .split(',')
            .map((origin) => origin.trim())
            .filter(Boolean);
        const requestOrigin = req.headers.origin || '';
        // Permitir requisições sem origin (app mobile) ou de origens permitidas
        const corsOrigin = (!requestOrigin || allowedOrigins.includes(requestOrigin))
            ? (requestOrigin || '*')
            : '';

        if (corsOrigin) {
            res.setHeader('Access-Control-Allow-Origin', corsOrigin);
        }
        res.setHeader('Access-Control-Allow-Methods', 'GET, POST, HEAD, OPTIONS');
        res.setHeader('Access-Control-Allow-Headers', 'Content-Type');
        res.setHeader('Cache-Control', 'no-store, no-cache, must-revalidate, proxy-revalidate');
        res.setHeader('Pragma', 'no-cache');
        res.setHeader('Expires', '0');

        if (req.method === 'OPTIONS') {
            res.writeHead(204);
            res.end();
            return;
        }

        // --- ROTA DE DOWNLOAD (GET/HEAD) ---
        if (req.method === 'GET' || req.method === 'HEAD') {
            res.setHeader('Content-Type', 'application/octet-stream');
            res.setHeader('Content-Disposition', 'attachment; filename=speedtest.bin');
            res.setHeader('Content-Length', FILE_SIZE);

            if (req.method === 'HEAD') {
                res.writeHead(200);
                res.end();
                return;
            }

            res.writeHead(200);

            let bytesSent = 0;
            const sendChunk = () => {
                while (bytesSent < FILE_SIZE) {
                    if (res.destroyed || res.writableEnded) return;

                    const remaining = FILE_SIZE - bytesSent;
                    const chunkToSend = (remaining < CHUNK_SIZE)
                        ? ZERO_BUFFER.slice(0, remaining)
                        : ZERO_BUFFER;

                    const canContinue = res.write(chunkToSend);
                    bytesSent += chunkToSend.length;

                    if (!canContinue) {
                        res.once('drain', sendChunk);
                        return;
                    }
                }
                if (!res.writableEnded) res.end();
            };
            sendChunk();
            return;
        }

        // --- ROTA DE UPLOAD (POST) ---
        if (req.method === 'POST') {
            req.on('data', (chunk) => { /* blackhole */ });
            req.on('end', () => {
                res.writeHead(200, { 'Content-Type': 'text/plain' });
                res.end('OK');
            });
            return;
        }

        res.writeHead(404);
        res.end('Not Found');
    });

    server.listen(PORT, '0.0.0.0', () => {
        // Worker listening (log omitido para evitar flood)
    });
}

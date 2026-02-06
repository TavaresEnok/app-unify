import express from 'express';
import path from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const app = express();
const port = 5174;

// Serve static files from dist_final with NO CACHE to fix zombie issues
app.use(express.static(path.join(__dirname, 'dist_final'), {
    setHeaders: (res, path) => {
        res.set('Cache-Control', 'no-store, no-cache, must-revalidate, proxy-revalidate');
        res.set('Pragma', 'no-cache');
        res.set('Expires', '0');
    }
}));

// SPA Fallback: Send index.html for any other request
// SPA Fallback: Send index.html for any other request
app.use((req, res) => {
    res.sendFile(path.join(__dirname, 'dist_final', 'index.html'));
});

app.listen(port, '0.0.0.0', () => {
    console.log(`Server running on port ${port} (Serving dist_final)`);
});

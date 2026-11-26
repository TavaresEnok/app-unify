const test = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');

const read = (name) => fs.readFileSync(path.join(__dirname, name), 'utf8');

test('caminho desconhecido responde 404 em vez da página inicial', () => {
    const conf = read('nginx.conf');
    assert.doesNotMatch(conf, /try_files[^;]*\/index\.html;/);
    assert.match(conf, /location \/ \{[^}]*try_files \$uri \$uri\/ =404;/);
    assert.match(conf, /error_page 404 \/404\.html;/);
});

test('a página 404 existe e entra na imagem', () => {
    const page = read('404.html');
    assert.match(page, /Página não encontrada/);
    assert.match(page, /href="\/"/);
    assert.match(read('Dockerfile'), /COPY [^\n]*404\.html/);
});

test('links de APK continuam com 404 próprio', () => {
    const conf = read('nginx.conf');
    assert.match(conf, /location \/public_apks\/f1\/ \{[^}]*try_files \$uri =404;/);
    assert.match(conf, /location \/public_apks\/ \{[^}]*try_files \$uri =404;/);
});

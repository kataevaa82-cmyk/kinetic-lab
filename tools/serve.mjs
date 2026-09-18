import http from 'node:http';
import {createReadStream, existsSync, statSync} from 'node:fs';
import {resolve, extname, relative, isAbsolute} from 'node:path';

const root = resolve('build/web');
const port = Number(process.env.KINETIC_PORT || 8080);
const types = {'.html':'text/html; charset=utf-8','.js':'text/javascript; charset=utf-8','.wasm':'application/wasm','.pck':'application/octet-stream','.png':'image/png','.svg':'image/svg+xml'};
http.createServer((req, res) => {
  let pathname;
  try { pathname = decodeURIComponent(new URL(req.url, 'http://localhost').pathname); }
  catch { res.writeHead(400); res.end(); return; }
  if (pathname === '/sdk.js') {
    // Local preview only; /sdk.js is supplied by Yandex on the portal.
    res.writeHead(200, {'Content-Type':'text/javascript'});
    res.end('/* Local preview. Platform SDK is supplied by Yandex Games when hosted. */');
    return;
  }
  if (pathname === '/favicon.ico') { res.writeHead(204); res.end(); return; }
  const target = resolve(root, '.' + (pathname === '/' ? '/index.html' : pathname));
  const rel = relative(root, target);
  if (rel.startsWith('..') || isAbsolute(rel) || !existsSync(target) || !statSync(target).isFile()) {
    res.writeHead(404); res.end('Not found'); return;
  }
  res.writeHead(200, {'Content-Type':types[extname(target)] || 'application/octet-stream','Content-Length':statSync(target).size,'Cache-Control':'no-cache'});
  createReadStream(target).pipe(res);
}).listen(port, '127.0.0.1', () => console.log(`Kinetic Lab: http://127.0.0.1:${port}`));

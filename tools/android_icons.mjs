/* Launcher icons for the RuStore build, drawn from the same geometry as assets/icon.svg.
   Node only: no image libraries, no binary assets to trust. Run: node tools/android_icons.mjs */
import {deflateSync} from 'node:zlib';
import {writeFileSync, mkdirSync} from 'node:fs';
import {dirname, join} from 'node:path';
import {fileURLToPath} from 'node:url';

const out = join(dirname(fileURLToPath(import.meta.url)), '..', 'assets', 'android');
const SS = 4; // Supersampling factor; every pixel averages SS*SS coverage samples.

// The laboratory robot, in the 256x256 space of assets/icon.svg. Keep the two files in step.
const PLATE = '#0e1721';
const GLYPH = [
  {type:'stroke', points:[[39,65],[69,65],[69,191],[39,191]], width:8, fill:'#45e0bb'},
  {type:'stroke', points:[[217,65],[187,65],[187,191],[217,191]], width:8, fill:'#45e0bb'},
  {type:'rect', x:87, y:75, w:82, h:68, r:22, fill:'#d2e4e5'},
  {type:'rect', x:96, y:96, w:64, h:22, r:9, fill:'#152b34'},
  {type:'stroke', points:[[106,105],[119,105]], width:7, fill:'#45e0bb'},
  {type:'stroke', points:[[136,105],[149,105]], width:7, fill:'#45e0bb'},
  {type:'stroke', points:[[128,73],[128,52]], width:6, fill:'#45e0bb'},
  {type:'circle', cx:128, cy:48, r:7, fill:'#ffbb66'},
  {type:'rect', x:99, y:152, w:58, h:35, r:7, fill:'#45e0bb'},
  {type:'circle', cx:128, cy:169, r:9, fill:'#172631'}
];

const rgb = hex => [parseInt(hex.slice(1,3),16), parseInt(hex.slice(3,5),16), parseInt(hex.slice(5,7),16)];

class Canvas {
  constructor(size) {
    this.size = size;
    this.w = size * SS;
    this.data = new Uint8Array(this.w * this.w * 4); // Straight RGBA; every shape here is opaque.
  }
  // Paints one opaque shape: `inside` answers whether a sample point falls in it.
  paint(color, box, inside) {
    const [r, g, b] = rgb(color);
    const x0 = Math.max(0, Math.floor(box[0])), y0 = Math.max(0, Math.floor(box[1]));
    const x1 = Math.min(this.w, Math.ceil(box[2])), y1 = Math.min(this.w, Math.ceil(box[3]));
    for (let y = y0; y < y1; y++) {
      for (let x = x0; x < x1; x++) {
        if (!inside(x + 0.5, y + 0.5)) continue;
        const i = (y * this.w + x) * 4;
        this.data[i] = r; this.data[i+1] = g; this.data[i+2] = b; this.data[i+3] = 255;
      }
    }
  }
  rect(x, y, w, h, r, color) {
    r = Math.min(r, w / 2, h / 2);
    this.paint(color, [x, y, x + w, y + h], (px, py) => {
      if (px < x || py < y || px > x + w || py > y + h) return false;
      const cx = Math.min(Math.max(px, x + r), x + w - r);
      const cy = Math.min(Math.max(py, y + r), y + h - r);
      const dx = px - cx, dy = py - cy;
      return dx * dx + dy * dy <= r * r;
    });
  }
  circle(cx, cy, r, color) {
    this.paint(color, [cx - r, cy - r, cx + r, cy + r], (px, py) => {
      const dx = px - cx, dy = py - cy;
      return dx * dx + dy * dy <= r * r;
    });
  }
  // Averages the supersampled buffer down and returns straight RGBA rows.
  resolve() {
    const n = this.size, pixels = new Uint8Array(n * n * 4), samples = SS * SS;
    for (let y = 0; y < n; y++) {
      for (let x = 0; x < n; x++) {
        let r = 0, g = 0, b = 0, a = 0;
        for (let sy = 0; sy < SS; sy++) {
          for (let sx = 0; sx < SS; sx++) {
            const i = ((y * SS + sy) * this.w + x * SS + sx) * 4;
            const alpha = this.data[i+3] / 255;
            r += this.data[i] * alpha; g += this.data[i+1] * alpha; b += this.data[i+2] * alpha; a += alpha;
          }
        }
        const o = (y * n + x) * 4;
        // Un-premultiply so the stored colour stays correct along antialiased edges.
        pixels[o] = a > 0 ? Math.round(r / a) : 0;
        pixels[o+1] = a > 0 ? Math.round(g / a) : 0;
        pixels[o+2] = a > 0 ? Math.round(b / a) : 0;
        pixels[o+3] = Math.round((a / samples) * 255);
      }
    }
    return pixels;
  }
}

function png(size, pixels) {
  const raw = Buffer.alloc(size * (size * 4 + 1));
  for (let y = 0; y < size; y++) {
    raw[y * (size * 4 + 1)] = 0; // Filter type 0: the icons are small, compression is not the point.
    Buffer.from(pixels.buffer, y * size * 4, size * 4).copy(raw, y * (size * 4 + 1) + 1);
  }
  const chunk = (name, body) => {
    const block = Buffer.concat([Buffer.from(name, 'ascii'), body]);
    const length = Buffer.alloc(4); length.writeUInt32BE(body.length);
    const crc = Buffer.alloc(4); crc.writeUInt32BE(crc32(block));
    return Buffer.concat([length, block, crc]);
  };
  const ihdr = Buffer.alloc(13);
  ihdr.writeUInt32BE(size, 0); ihdr.writeUInt32BE(size, 4);
  ihdr[8] = 8; ihdr[9] = 6; // 8 bits per channel, truecolour with alpha.
  return Buffer.concat([
    Buffer.from([0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a]),
    chunk('IHDR', ihdr),
    chunk('IDAT', deflateSync(raw, {level: 9})),
    chunk('IEND', Buffer.alloc(0))
  ]);
}

const CRC_TABLE = (() => {
  const table = new Int32Array(256);
  for (let n = 0; n < 256; n++) {
    let c = n;
    for (let k = 0; k < 8; k++) c = c & 1 ? 0xedb88320 ^ (c >>> 1) : c >>> 1;
    table[n] = c;
  }
  return table;
})();
function crc32(buffer) {
  let c = 0xffffffff;
  for (const byte of buffer) c = CRC_TABLE[(c ^ byte) & 0xff] ^ (c >>> 8);
  return (c ^ 0xffffffff) >>> 0;
}

// Expands the axis-aligned strokes of the glyph into plain rectangles, joints included.
function strokeRects(shape) {
  const half = shape.width / 2, rects = [];
  for (let i = 1; i < shape.points.length; i++) {
    const [ax, ay] = shape.points[i-1], [bx, by] = shape.points[i];
    if (ay === by) rects.push([Math.min(ax,bx), ay - half, Math.abs(bx-ax), shape.width]);
    else rects.push([ax - half, Math.min(ay,by), shape.width, Math.abs(by-ay)]);
  }
  // A square at every interior corner reproduces the miter join of a right angle exactly.
  for (let i = 1; i < shape.points.length - 1; i++) {
    const [x, y] = shape.points[i];
    rects.push([x - half, y - half, shape.width, shape.width]);
  }
  return rects;
}

function bounds() {
  let x0 = Infinity, y0 = Infinity, x1 = -Infinity, y1 = -Infinity;
  const grow = (a, b, c, d) => { x0 = Math.min(x0,a); y0 = Math.min(y0,b); x1 = Math.max(x1,c); y1 = Math.max(y1,d); };
  for (const shape of GLYPH) {
    if (shape.type === 'rect') grow(shape.x, shape.y, shape.x + shape.w, shape.y + shape.h);
    else if (shape.type === 'circle') grow(shape.cx - shape.r, shape.cy - shape.r, shape.cx + shape.r, shape.cy + shape.r);
    else for (const [rx, ry, rw, rh] of strokeRects(shape)) grow(rx, ry, rx + rw, ry + rh);
  }
  return {x0, y0, x1, y1};
}

// `scale` and `ox`/`oy` map the 256-unit artwork onto the supersampled canvas.
function drawGlyph(canvas, scale, ox, oy, override) {
  const X = v => ox + v * scale, S = v => v * scale;
  for (const shape of GLYPH) {
    const fill = override || shape.fill;
    if (shape.type === 'rect') canvas.rect(X(shape.x), oy + shape.y * scale, S(shape.w), S(shape.h), S(shape.r), fill);
    else if (shape.type === 'circle') canvas.circle(X(shape.cx), oy + shape.cy * scale, S(shape.r), fill);
    else for (const [rx, ry, rw, rh] of strokeRects(shape)) canvas.rect(X(rx), oy + ry * scale, S(rw), S(rh), 0, fill);
  }
}

// Full icon: the rounded plate of the SVG plus the robot, edge to edge.
function plate(size) {
  const canvas = new Canvas(size);
  const scale = canvas.w / 256;
  canvas.rect(0, 0, canvas.w, canvas.w, 56 * scale, PLATE);
  drawGlyph(canvas, scale, 0, 0, null);
  return png(size, canvas.resolve());
}

// Adaptive layers: Android masks and animates these, so the robot keeps to the safe zone
// (the inner 66% of the 432x432 canvas) and the plate colour moves to its own layer.
function adaptive(size, override, background) {
  const canvas = new Canvas(size);
  if (background) canvas.rect(0, 0, canvas.w, canvas.w, 0, background);
  const box = bounds();
  const safe = canvas.w * 0.61;
  const scale = Math.min(safe / (box.x1 - box.x0), safe / (box.y1 - box.y0));
  const ox = (canvas.w - (box.x1 - box.x0) * scale) / 2 - box.x0 * scale;
  const oy = (canvas.w - (box.y1 - box.y0) * scale) / 2 - box.y0 * scale;
  drawGlyph(canvas, scale, ox, oy, override);
  return png(size, canvas.resolve());
}

mkdirSync(out, {recursive: true});
const files = [
  ['icon-192.png', plate(192)],
  ['icon-foreground-432.png', adaptive(432, null, null)],
  ['icon-background-432.png', (() => { const c = new Canvas(432); c.rect(0, 0, c.w, c.w, 0, PLATE); return png(432, c.resolve()); })()],
  ['icon-monochrome-432.png', adaptive(432, '#ffffff', null)],
  ['store-icon-512.png', plate(512)]
];
for (const [name, data] of files) {
  writeFileSync(join(out, name), data);
  console.log(`${name}  ${(data.length / 1024).toFixed(1)} KiB`);
}

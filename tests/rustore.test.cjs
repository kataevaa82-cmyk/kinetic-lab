/* Guards the RuStore build: the store rejects a package long after the export succeeded,
   so the invariants that matter for moderation are checked here instead. */
const test = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');

const zlib = require('node:zlib');

const root = path.join(__dirname, '..');
const read = name => fs.readFileSync(path.join(root, name), 'utf8');

// Decodes an 8-bit RGBA PNG far enough to read single pixels back.
function decodePng(file) {
  const buffer = fs.readFileSync(file);
  assert.equal(buffer.slice(1, 4).toString(), 'PNG', `${file} is not a PNG`);
  const width = buffer.readUInt32BE(16), height = buffer.readUInt32BE(20);
  assert.equal(buffer[24], 8, `${file} is not 8 bits per channel`);
  assert.equal(buffer[25], 6, `${file} is not truecolour with alpha`);
  const parts = [];
  for (let at = 8; at < buffer.length;) {
    const length = buffer.readUInt32BE(at);
    const name = buffer.slice(at + 4, at + 8).toString('ascii');
    if (name === 'IDAT') parts.push(buffer.slice(at + 8, at + 8 + length));
    at += length + 12;
  }
  const raw = zlib.inflateSync(Buffer.concat(parts));
  const stride = width * 4;
  const pixels = Buffer.alloc(height * stride);
  for (let y = 0; y < height; y++) {
    const filter = raw[y * (stride + 1)];
    const line = raw.slice(y * (stride + 1) + 1, y * (stride + 1) + 1 + stride);
    for (let x = 0; x < stride; x++) {
      const a = x >= 4 ? pixels[y * stride + x - 4] : 0;
      const b = y > 0 ? pixels[(y - 1) * stride + x] : 0;
      const c = x >= 4 && y > 0 ? pixels[(y - 1) * stride + x - 4] : 0;
      let value = line[x];
      if (filter === 1) value += a;
      else if (filter === 2) value += b;
      else if (filter === 3) value += (a + b) >> 1;
      else if (filter === 4) {
        const p = a + b - c, pa = Math.abs(p - a), pb = Math.abs(p - b), pc = Math.abs(p - c);
        value += pa <= pb && pa <= pc ? a : pb <= pc ? b : c;
      }
      pixels[y * stride + x] = value & 0xff;
    }
  }
  return {width, height, alphaAt: (x, y) => pixels[y * stride + x * 4 + 3]};
}

// Minimal reader for the Godot ini dialect: sections plus `key=value` lines.
function sections(text) {
  const result = {};
  let current = null;
  for (const line of text.split(/\r?\n/)) {
    const header = line.match(/^\[(.+)\]$/);
    if (header) { current = result[header[1]] = {}; continue; }
    const pair = line.match(/^([^=;#\s][^=]*)=(.*)$/);
    if (pair && current) current[pair[1].trim()] = pair[2].trim().replace(/^"(.*)"$/, '$1');
  }
  return result;
}

const presets = sections(read('export_presets.cfg'));
const project = sections(read('project.godot'));
const name = Object.keys(presets).find(key => /^preset\.\d+$/.test(key) && presets[key].name === 'RuStore Android');
const preset = presets[name];
const options = presets[`${name}.options`];

test('the RuStore preset exports a signed Android package', () => {
  assert.ok(preset, 'export_presets.cfg has no "RuStore Android" preset');
  assert.equal(preset.platform, 'Android');
  assert.equal(options['package/signed'], 'true');
  assert.match(preset.export_path, /^build\/rustore\/.+\.(apk|aab)$/);
});

test('the build identifies itself as the store build', () => {
  // scripts/platform.gd switches off ads and turns on the exit button on this tag.
  assert.match(preset.custom_features, /\brustore\b/);
  assert.match(read('scripts/platform.gd'), /OS\.has_feature\("rustore"\)/);
});

test('the package asks for no permissions at all', () => {
  // Nothing in the game talks to the network, and a permission nobody uses is a
  // moderation question with no good answer.
  for (const [key, value] of Object.entries(options)) {
    if (key.startsWith('permissions/') && key !== 'permissions/custom_permissions') {
      assert.equal(value, 'false', `${key} must stay off`);
    }
  }
  assert.equal(options['permissions/custom_permissions'], 'PackedStringArray()');
});

test('the application id and version can be published', () => {
  assert.match(options['package/unique_name'], /^[a-z][a-z0-9_]*(\.[a-z][a-z0-9_]*)+$/);
  assert.ok(Number.isInteger(Number(options['version/code'])) && Number(options['version/code']) >= 1);
  // A mismatch here ships a store listing that disagrees with the game's own about screen.
  assert.equal(options['version/name'], project.application['config/version']);
});

test('the game runs on 64-bit devices and stays landscape', () => {
  assert.equal(options['architectures/arm64-v8a'], 'true');
  // 4 is Sensor Landscape; the laboratory needs the width.
  assert.equal(project.display['window/handheld/orientation'], '4');
  assert.equal(options['screen/immersive_mode'], 'true');
});

test('every launcher icon exists at the size Android expects', () => {
  const expected = {
    'launcher_icons/main_192x192': 192,
    'launcher_icons/adaptive_foreground_432x432': 432,
    'launcher_icons/adaptive_background_432x432': 432,
    'launcher_icons/adaptive_monochrome_432x432': 432
  };
  for (const [key, size] of Object.entries(expected)) {
    const file = options[key];
    assert.ok(file && file.startsWith('res://'), `${key} is not set`);
    const buffer = fs.readFileSync(path.join(root, file.slice('res://'.length)));
    assert.equal(buffer.slice(1, 4).toString(), 'PNG', `${file} is not a PNG`);
    assert.equal(buffer.readUInt32BE(16), size, `${file} width`);
    assert.equal(buffer.readUInt32BE(20), size, `${file} height`);
  }
});

test('the Yandex web preset is untouched by the store build', () => {
  const web = Object.values(presets).find(entry => entry.name === 'Yandex Web');
  assert.ok(web, 'the portal preset disappeared');
  assert.equal(web.platform, 'Web');
  assert.equal(web.export_path, 'build/web/index.html');
});

test('the store listing icon is 512x512 and opaque to the edge', () => {
  // RuStore rejects an icon whose contour has transparent or unfilled areas, which
  // rules out the rounded plate the launcher icon uses.
  const icon = decodePng(path.join(root, 'assets/android/store-icon-512.png'));
  assert.equal(icon.width, 512);
  assert.equal(icon.height, 512);
  for (const [x, y] of [[0, 0], [511, 0], [0, 511], [511, 511], [255, 0], [0, 255]]) {
    assert.equal(icon.alphaAt(x, y), 255, `pixel ${x},${y} is not opaque`);
  }
});

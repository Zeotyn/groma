import { test } from 'node:test';
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { spawnSync } from 'node:child_process';
import { run } from './helpers.js';
import { main } from '../main.js';

const pkg = JSON.parse(readFileSync(new URL('../../package.json', import.meta.url)));

test('--help lists the four commands and main flags', async () => {
  const r = await run(['--help']);
  assert.equal(r.code, 0);
  for (const s of ['init', 'update', 'status', 'doctor', '--agents', '--methodology', '--skills', '--yes', '--print', '--dry-run', '--force']) {
    assert.match(r.out, new RegExp(s.replace(/-/g, '\\-')));
  }
});

test('no arguments prints help and exits 2', async () => {
  const r = await run([]);
  assert.equal(r.code, 2);
  assert.match(r.err, /Usage: groma/);
});

test('--version prints the package version', async () => {
  const r = await run(['--version']);
  assert.equal(r.code, 0);
  assert.equal(r.out.trim(), pkg.version);
});

test('unknown command is a usage error', async () => {
  const r = await run(['frobnicate']);
  assert.equal(r.code, 2);
  assert.match(r.err, /unknown command 'frobnicate'/);
});

test('unknown flag is a usage error', async () => {
  const r = await run(['init', '--nope']);
  assert.equal(r.code, 2);
});

test('Node older than 22 exits 3', async () => {
  const err = [];
  const code = await main(['--version'], { stdout: { write() {} }, stderr: { write: (s) => err.push(s) }, stdin: {}, env: {}, nodeVersion: '20.11.0' });
  assert.equal(code, 3);
  assert.match(err.join(''), /Node 22 or newer required/);
});

test('bin/groma.js runs and exits with the code', () => {
  const r = spawnSync(process.execPath, [new URL('../../bin/groma.js', import.meta.url).pathname, '--version'], { encoding: 'utf8' });
  assert.equal(r.status, 0);
  assert.equal(r.stdout.trim(), pkg.version);
});

test('missing project folder is an error', async () => {
  const r = await run(['status', '/nonexistent/groma-test']);
  assert.equal(r.code, 1);
  assert.match(r.err, /not a directory/);
});

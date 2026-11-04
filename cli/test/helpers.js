import { mkdtempSync, mkdirSync, writeFileSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join, dirname } from 'node:path';
import { main } from '../main.js';

export function tmp() {
  return mkdtempSync(join(tmpdir(), 'groma-cli-'));
}

export function write(root, rel, text = '') {
  mkdirSync(dirname(join(root, rel)), { recursive: true });
  writeFileSync(join(root, rel), text);
}

// Run the CLI in-process. Returns { code, out, err }.
export async function run(argv, { env = {}, isTTY = false, ask, home = tmp() } = {}) {
  const out = [];
  const err = [];
  const io = {
    stdout: { write: (s) => out.push(s) },
    stderr: { write: (s) => err.push(s) },
    stdin: { isTTY },
    env: { PATH: process.env.PATH, HOME: home, ...env },
    ask,
  };
  const code = await main(argv, io);
  return { code, out: out.join(''), err: err.join('') };
}

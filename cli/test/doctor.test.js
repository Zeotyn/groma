import { test } from 'node:test';
import assert from 'node:assert/strict';
import { readFileSync, writeFileSync } from 'node:fs';
import { join } from 'node:path';
import { run, tmp } from './helpers.js';

async function initProject() {
  const p = tmp();
  const r = await run(['init', p, '--agents', 'copilot', '--methodology', 'none', '--skills', 'none', '--yes']);
  assert.equal(r.code, 0, r.err);
  return p;
}
// Real PATH so check-prereqs.sh finds git, node and npx.
const env = { PATH: process.env.PATH };

test('status prints the status.sh output', async () => {
  const p = await initProject();
  const r = await run(['status', p], { env });
  assert.equal(r.code, 0, r.err);
  assert.match(r.out, /groma status: nothing open/);
});

test('doctor passes on a fresh init', async () => {
  const p = await initProject();
  const r = await run(['doctor', p], { env });
  assert.equal(r.code, 0, r.out + r.err);
  assert.match(r.out, /config: ok/);
  assert.match(r.out, /generated files: ok/);
});

test('doctor warns about an edited generated file and still exits 0', async () => {
  const p = await initProject();
  writeFileSync(join(p, '.github/skills/groma-survey/SKILL.md'), 'edited');
  const r = await run(['doctor', p], { env });
  assert.equal(r.code, 0, r.out);
  assert.match(r.out, /warning: \.github\/skills\/groma-survey\/SKILL\.md edited since generation/);
});

test('doctor reports an older generated version', async () => {
  const p = await initProject();
  const f = join(p, '.groma/generated.json');
  writeFileSync(f, readFileSync(f, 'utf8').replace(/"groma@[^"]+"/, '"groma@0.0.1"'));
  const r = await run(['doctor', p], { env });
  assert.match(r.out, /groma@0\.0\.1.*npx groma-cli update/);
});

test('doctor fails on an invalid config', async () => {
  const p = await initProject();
  const f = join(p, '.groma/config.yaml');
  writeFileSync(f, readFileSync(f, 'utf8').replace('methodology: none', 'methodology: open-spec'));
  const r = await run(['doctor', p], { env });
  assert.equal(r.code, 1);
  assert.match(r.out, /unknown methodology 'open-spec'/);
});

test('doctor fails without config', async () => {
  const r = await run(['doctor', tmp()], { env });
  assert.equal(r.code, 1);
  assert.match(r.out, /not initialized/);
});

test('doctor exits 3 when a required tool is missing', async () => {
  const p = await initProject();
  const r = await run(['doctor', p], { env: { PATH: '/usr/bin:/bin' } });
  assert.equal(r.code, 3, r.out);
  assert.match(r.out, /node.*missing|missing.*node/);
});

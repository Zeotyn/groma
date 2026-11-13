import { test } from 'node:test';
import assert from 'node:assert/strict';
import { existsSync, readFileSync, writeFileSync, chmodSync } from 'node:fs';
import { join } from 'node:path';
import { parse } from 'yaml';
import { run, tmp, write } from './helpers.js';
import { version } from '../data.js';

function stubs() {
  const bin = tmp();
  const log = join(bin, 'calls.log');
  for (const name of ['npx', 'claude']) {
    write(bin, name, `#!/bin/sh\necho "${name} $*" >> "${log}"\nexit 0\n`);
    chmodSync(join(bin, name), 0o755);
  }
  return { env: { PATH: `${bin}:/usr/bin:/bin` }, calls: () => (existsSync(log) ? readFileSync(log, 'utf8') : '') };
}

async function initProject(extra = []) {
  const p = tmp();
  const s = stubs();
  const r = await run(['init', p, '--agents', 'claude', '--methodology', 'none', '--skills', 'none', '--yes', ...extra], { env: s.env });
  assert.equal(r.code, 0, r.err);
  return { p, s };
}
const cfg = (p) => parse(readFileSync(join(p, '.groma/config.yaml'), 'utf8'));

test('update without config points to init', async () => {
  const r = await run(['update', tmp(), '--yes']);
  assert.equal(r.code, 1);
  assert.match(r.err, /npx groma-cli init/);
});

test('an edited generated skill is kept and reported; --force replaces it', async () => {
  const { p, s } = await initProject();
  const f = join(p, '.claude/skills/groma-survey/SKILL.md');
  writeFileSync(f, 'my edit');
  let r = await run(['update', p, '--yes'], { env: s.env });
  assert.equal(r.code, 0, r.err);
  assert.equal(readFileSync(f, 'utf8'), 'my edit');
  assert.match(r.out, /\.claude\/skills\/groma-survey\/SKILL\.md \(edited, not updated/);
  r = await run(['update', p, '--yes', '--force'], { env: s.env });
  assert.equal(r.code, 0, r.err);
  assert.match(readFileSync(f, 'utf8'), /generatedBy/);
});

test('update bumps initialized_with and refreshes old unchanged copies', async () => {
  const { p, s } = await initProject();
  const c = join(p, '.groma/config.yaml');
  writeFileSync(c, readFileSync(c, 'utf8').replace(/groma@[\d.]+/, 'groma@0.0.1'));
  const r = await run(['update', p, '--yes'], { env: s.env });
  assert.equal(r.code, 0, r.err);
  assert.equal(cfg(p).initialized_with, `groma@${version()}`);
});

test('update re-runs pending steps and marks them done', async () => {
  const p = tmp();
  const s = stubs();
  await run(['init', p, '--agents', 'copilot', '--methodology', 'openspec', '--skills', 'ponytail', '--yes', '--print'], { env: s.env });
  assert.equal(cfg(p).steps.skills, 'pending');
  const r = await run(['update', p, '--yes'], { env: s.env });
  assert.equal(r.code, 0, r.err);
  assert.match(s.calls(), /openspec@1\.16\.0 init --tools github-copilot/);
  assert.match(s.calls(), /skills@1\.7\.6 add .*ponytail/);
  assert.equal(cfg(p).steps.methodology, 'done');
  assert.equal(cfg(p).steps.skills, 'done');
});

test('update leaves agents_via_plugin agents alone and adopts a 0.1 project', async () => {
  const p = tmp();
  // agent-driven 0.1 setup: config, skills copied by hand, no generated.json
  write(p, '.claude/skills/groma/SKILL.md', 'hand copy');
  const { p: ref } = await initProject();
  write(p, '.groma/config.yaml', readFileSync(join(ref, '.groma/config.yaml'), 'utf8'));
  const r = await run(['update', p, '--yes'], { env: stubs().env });
  assert.equal(r.code, 0, r.err);
  assert.equal(readFileSync(join(p, '.claude/skills/groma/SKILL.md'), 'utf8'), 'hand copy');
  assert.match(r.out, /Conflicts:.*\.claude\/skills\/groma /);
  assert.ok(existsSync(join(p, '.claude/skills/groma-detect/SKILL.md')));
});

test('update --dry-run changes nothing', async () => {
  const { p, s } = await initProject();
  const before = readFileSync(join(p, '.groma/generated.json'), 'utf8');
  writeFileSync(join(p, '.claude/skills/groma/SKILL.md'), 'x');
  const r = await run(['update', p, '--yes', '--dry-run', '--force'], { env: s.env });
  assert.equal(r.code, 0, r.err);
  assert.equal(readFileSync(join(p, '.claude/skills/groma/SKILL.md'), 'utf8'), 'x');
  assert.equal(readFileSync(join(p, '.groma/generated.json'), 'utf8'), before);
  assert.match(r.out, /\.claude\/skills\/groma\/SKILL\.md/);
});

test('update retries only the catalog steps that stayed pending', async () => {
  const p = tmp();
  const bin = tmp();
  const log = join(bin, 'calls.log');
  // ponytail's npx install fails once, archify's succeeds
  write(bin, 'npx', `#!/bin/sh\necho "npx $*" >> "${log}"\ncase "$*" in *ponytail*) [ -f "${bin}/ok" ] || exit 1 ;; esac\n`);
  chmodSync(join(bin, 'npx'), 0o755);
  const env = { PATH: `${bin}:/usr/bin:/bin` };
  await run(['init', p, '--agents', 'copilot', '--methodology', 'none', '--skills', 'ponytail,archify', '--workflow', 'none', '--yes'], { env });
  assert.equal(cfg(p).steps.skills, 'pending');
  writeFileSync(join(bin, 'ok'), '');
  writeFileSync(log, '');
  const r = await run(['update', p, '--yes'], { env });
  assert.equal(r.code, 0, r.err);
  assert.match(readFileSync(log, 'utf8'), /ponytail/);
  assert.doesNotMatch(readFileSync(log, 'utf8'), /archify/);
  assert.equal(cfg(p).steps.skills, 'done');
});

test('update makes no copies when the user declined them (skills_copy skipped, no generated.json)', async () => {
  const p = tmp();
  write(p, '.groma/config.yaml', 'schema: 1\ninitialized_with: groma@0.3.0\nagents: [claude]\nmethodology: none\nsteps:\n  skills_copy: skipped\n');
  const r = await run(['update', p, '--yes'], { env: stubs().env });
  assert.equal(r.code, 0, r.err);
  assert.ok(!existsSync(join(p, '.claude')));
  assert.ok(!existsSync(join(p, '.groma/generated.json')));
  assert.match(r.out, /declined/);
});

test('update refuses to downgrade copies of a newer groma; --force alone too, --allow-downgrade goes on', async () => {
  const { p, s } = await initProject();
  const f = join(p, '.groma/generated.json');
  const before = readFileSync(f, 'utf8').replace(/"generatedBy": "[^"]+"/, '"generatedBy": "groma@99.0.0"');
  writeFileSync(f, before);
  const r = await run(['update', p, '--yes'], { env: s.env });
  assert.equal(r.code, 1);
  assert.match(r.err, /99\.0\.0.*newer/);
  assert.equal(readFileSync(f, 'utf8'), before);
  // --force alone still refuses a downgrade
  const forced = await run(['update', p, '--yes', '--force'], { env: s.env });
  assert.equal(forced.code, 1);
  assert.match(forced.err, /--allow-downgrade/);
  assert.equal(readFileSync(f, 'utf8'), before);
  const doc = await run(['doctor', p], { env: s.env });
  assert.match(doc.out, /newer than this CLI.*groma-cli@latest/);
  assert.equal((await run(['update', p, '--yes', '--allow-downgrade'], { env: s.env })).code, 0);
});

test('init refuses before any question when the copies come from a newer groma', async () => {
  const p = tmp();
  write(p, '.groma/generated.json', JSON.stringify({ generatedBy: 'groma@99.0.0', files: {} }));
  let asked = 0;
  const ask = async (q) => { asked++; return q.recommended; };
  const r = await run(['init', p, '--agents', 'claude'], { env: stubs().env, isTTY: true, ask });
  assert.equal(r.code, 1);
  assert.equal(asked, 0);
  assert.match(r.err, /--allow-downgrade/);
  const ok = await run(['init', p, '--agents', 'claude', '--methodology', 'none', '--skills', 'none', '--yes', '--allow-downgrade'], { env: stubs().env });
  assert.equal(ok.code, 0, ok.err);
});

test('update --dry-run names why a file would be removed', async () => {
  const { p, s } = await initProject();
  const f = join(p, '.groma/generated.json');
  const gen = JSON.parse(readFileSync(f, 'utf8'));
  write(p, '.claude/skills/groma-detect/old.md', 'old');
  const { createHash } = await import('node:crypto');
  gen.files['.claude/skills/groma-detect/old.md'] = createHash('sha256').update('old').digest('hex');
  writeFileSync(f, JSON.stringify(gen));
  const r = await run(['update', p, '--yes', '--dry-run'], { env: s.env });
  assert.match(r.out, /groma-detect\/old\.md \(remove, no longer part of groma-detect\)/);
});

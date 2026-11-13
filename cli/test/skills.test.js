import { test } from 'node:test';
import assert from 'node:assert/strict';
import { readFileSync, existsSync, readdirSync } from 'node:fs';
import { join } from 'node:path';
import { loadData, SKILLS_SRC } from '../data.js';
import { planSkills, applySkills, readGenerated, sha256, addGeneratedBy, newerThan } from '../skills.js';
import { tmp, write } from './helpers.js';

const data = loadData();
const tag = `groma@${data.version}`;
const suite = readdirSync(SKILLS_SRC);

function materialize(project, agents, opts = {}) {
  const plan = planSkills({ project, agents, data, generated: readGenerated(project), ...opts });
  applySkills(project, plan, data.version);
  return plan;
}

test('addGeneratedBy adds metadata to the frontmatter', () => {
  assert.equal(addGeneratedBy('---\nname: x\n---\nbody\n', 'groma@1.2.3'), '---\nname: x\nmetadata:\n  generatedBy: groma@1.2.3\n---\nbody\n');
  assert.equal(addGeneratedBy('---\nname: x\nmetadata:\n  a: b\n---\n', 'groma@1'), '---\nname: x\nmetadata:\n  generatedBy: groma@1\n  a: b\n---\n');
});

test('init copies every skill for claude and copilot with generatedBy and hashes', () => {
  const p = tmp();
  materialize(p, ['claude', 'copilot']);
  for (const dir of ['.claude/skills', '.github/skills']) {
    for (const s of suite) assert.ok(existsSync(join(p, dir, s, 'SKILL.md')), `${dir}/${s}`);
    assert.match(readFileSync(join(p, dir, 'groma/SKILL.md'), 'utf8'), new RegExp(`generatedBy: ${tag}`));
  }
  const script = 'groma-detect/scripts/detect.sh';
  assert.equal(readFileSync(join(p, '.claude/skills', script), 'utf8'), readFileSync(join(SKILLS_SRC, script), 'utf8'));
  const gen = readGenerated(p);
  assert.equal(gen.generatedBy, tag);
  const files = Object.keys(gen.files);
  assert.ok(files.includes('.github/skills/groma-detect/scripts/detect.sh'));
  for (const f of files) assert.equal(gen.files[f], sha256(readFileSync(join(p, f))), f);
});

test('a foreign skill folder with the same name is a conflict and stays untouched', () => {
  const p = tmp();
  write(p, '.claude/skills/groma-survey/SKILL.md', 'mine');
  const plan = materialize(p, ['claude']);
  assert.deepEqual(plan.conflicts, ['.claude/skills/groma-survey']);
  assert.equal(readFileSync(join(p, '.claude/skills/groma-survey/SKILL.md'), 'utf8'), 'mine');
  assert.ok(existsSync(join(p, '.claude/skills/groma-detect/SKILL.md')));
  assert.ok(!Object.keys(readGenerated(p).files).some((f) => f.includes('groma-survey')));
});

test('dry planning writes nothing', () => {
  const p = tmp();
  const plan = planSkills({ project: p, agents: ['claude'], data, generated: readGenerated(p) });
  assert.ok(plan.writes.length > 0);
  assert.deepEqual(readdirSync(p), []);
});

test('update replaces unchanged old copies and keeps edited ones', () => {
  const p = tmp();
  materialize(p, ['claude']);
  const gen = readGenerated(p);
  const old = '.claude/skills/groma-detect/SKILL.md';
  const edited = '.claude/skills/groma-survey/SKILL.md';
  // an older generated version, unchanged since generation
  write(p, old, 'old version');
  gen.files[old] = sha256(Buffer.from('old version'));
  write(p, '.groma/generated.json', JSON.stringify(gen));
  // a copy the user edited after generation
  write(p, edited, 'my edit');

  const plan = materialize(p, ['claude']);
  assert.match(readFileSync(join(p, old), 'utf8'), /generatedBy/);
  assert.equal(readFileSync(join(p, edited), 'utf8'), 'my edit');
  assert.deepEqual(plan.edited, [edited]);
  assert.ok(plan.writes.some((w) => w.path === old && w.kind === 'update'));
  // the record keeps the original hash so the edit stays visible
  assert.notEqual(readGenerated(p).files[edited], sha256(Buffer.from('my edit')));

  materialize(p, ['claude'], { force: true });
  assert.match(readFileSync(join(p, edited), 'utf8'), /generatedBy/);
});

test('files of retired skills are removed only when unchanged', () => {
  const p = tmp();
  materialize(p, ['claude']);
  const gen = readGenerated(p);
  write(p, '.claude/skills/groma-old/SKILL.md', 'old');
  write(p, '.claude/skills/groma-old/notes.md', 'edited');
  gen.files['.claude/skills/groma-old/SKILL.md'] = sha256(Buffer.from('old'));
  gen.files['.claude/skills/groma-old/notes.md'] = sha256(Buffer.from('original'));
  write(p, '.groma/generated.json', JSON.stringify(gen));

  // not shipped and not listed as retired: an older or smaller source must not delete it
  const kept = materialize(p, ['claude']);
  assert.deepEqual(kept.removals, []);
  assert.ok(existsSync(join(p, '.claude/skills/groma-old/SKILL.md')));
  assert.ok('.claude/skills/groma-old/SKILL.md' in readGenerated(p).files);

  const plan = materialize(p, ['claude'], { data: { ...data, retired: ['groma-old'] } });
  assert.deepEqual(plan.removals, ['.claude/skills/groma-old/SKILL.md']);
  assert.deepEqual(plan.edited, ['.claude/skills/groma-old/notes.md']);
  assert.ok(!existsSync(join(p, '.claude/skills/groma-old/SKILL.md')));
  assert.ok(existsSync(join(p, '.claude/skills/groma-old/notes.md')));
});

test('files a shipped skill no longer has are removed only when unchanged', () => {
  const p = tmp();
  materialize(p, ['claude']);
  const gen = readGenerated(p);
  write(p, '.claude/skills/groma-detect/old/a.md', 'old');
  write(p, '.claude/skills/groma-detect/notes.md', 'edited');
  gen.files['.claude/skills/groma-detect/old/a.md'] = sha256(Buffer.from('old'));
  gen.files['.claude/skills/groma-detect/notes.md'] = sha256(Buffer.from('original'));
  write(p, '.groma/generated.json', JSON.stringify(gen));
  const plan = materialize(p, ['claude']);
  assert.deepEqual(plan.removals, ['.claude/skills/groma-detect/old/a.md']);
  assert.deepEqual(plan.edited, ['.claude/skills/groma-detect/notes.md']);
  assert.ok(!existsSync(join(p, '.claude/skills/groma-detect/old')));
});

test('newerThan compares generatedBy with the suite version', () => {
  assert.equal(newerThan('groma@0.5.0', '0.4.9'), true);
  assert.equal(newerThan('groma@0.10.0', '0.9.0'), true);
  assert.equal(newerThan('groma@0.4.0', '0.4.0'), false);
  assert.equal(newerThan('groma@0.3.9', '0.4.0'), false);
  assert.equal(newerThan(null, '0.4.0'), false);
});

test('an unchanged copy needs no write', () => {
  const p = tmp();
  materialize(p, ['claude']);
  const plan = planSkills({ project: p, agents: ['claude'], data, generated: readGenerated(p) });
  assert.equal(plan.writes.length, 0);
});

test('deselecting an agent keeps its copies and their records', () => {
  const p = tmp();
  materialize(p, ['claude', 'copilot']);
  const plan = materialize(p, ['claude']);
  assert.deepEqual(plan.removals, []);
  assert.ok(existsSync(join(p, '.github/skills/groma/SKILL.md')));
  assert.ok('.github/skills/groma/SKILL.md' in readGenerated(p).files);
});

test('records outside groma skill folders are never deleted', () => {
  const p = tmp();
  materialize(p, ['claude']);
  const gen = readGenerated(p);
  write(p, 'package.json', '{}');
  write(p, '.claude/skills/other/SKILL.md', 'x');
  gen.files['package.json'] = sha256(Buffer.from('{}'));
  gen.files['.claude/skills/other/SKILL.md'] = sha256(Buffer.from('x'));
  gen.files['.claude/skills/groma/../../../package.json'] = sha256(Buffer.from('{}'));
  write(p, '.groma/generated.json', JSON.stringify(gen));
  const plan = materialize(p, ['claude']);
  assert.deepEqual(plan.removals, []);
  assert.ok(existsSync(join(p, 'package.json')) && existsSync(join(p, '.claude/skills/other/SKILL.md')));
});

test('a file already holding the new content is not reported as edited', () => {
  const p = tmp();
  materialize(p, ['claude']);
  const gen = readGenerated(p);
  gen.files['.claude/skills/groma/SKILL.md'] = sha256(Buffer.from('stale record'));
  write(p, '.groma/generated.json', JSON.stringify(gen));
  const plan = materialize(p, ['claude']);
  assert.deepEqual(plan.edited, []);
  assert.equal(readGenerated(p).files['.claude/skills/groma/SKILL.md'], sha256(readFileSync(join(p, '.claude/skills/groma/SKILL.md'))));
});

import { test } from 'node:test';
import assert from 'node:assert/strict';
import { mkdirSync } from 'node:fs';
import { join } from 'node:path';
import { loadData } from '../data.js';
import { resolveAnswers, detectAgents } from '../answers.js';
import { UsageError } from '../main.js';
import { tmp, write } from './helpers.js';

const data = loadData();

function resolve(flags, { interactive = false, ask, home = tmp(), project = tmp(), projectType = 'brownfield' } = {}) {
  const notes = [];
  const asked = [];
  const askFn = ask ?? (async (q) => { asked.push(q); return q.recommended; });
  return resolveAnswers({ flags, data, project, home, projectType, interactive, ask: askFn, note: (s) => notes.push(s) })
    .then((answers) => ({ answers, asked, notes }));
}

test('fully non-interactive with flags asks nothing', async () => {
  const { answers, asked } = await resolve({ agents: 'claude,copilot', methodology: 'openspec', skills: 'recommended', yes: true });
  assert.equal(asked.length, 0);
  assert.deepEqual(answers.agents, ['claude', 'copilot']);
  assert.equal(answers.methodology, 'openspec');
  assert.equal(answers.workflow, 'superpowers');
  assert.equal(answers.skills.pragmatism, 'ponytail');
  assert.deepEqual(answers.skills.writing, ['anti-ai-slop-writing', 'i-have-adhd']);
  assert.equal(answers.skills.design, 'none'); // --ui defaults to no, design needs a UI
  assert.equal(answers.review, 'autonomous');
});

test('flags plus --yes equal taking the recommended answer interactively', async () => {
  const flags = { agents: 'claude,copilot', methodology: 'openspec', skills: 'recommended' };
  const a = await resolve({ ...flags, yes: true });
  const b = await resolve(flags, { interactive: true });
  assert.deepEqual(a.answers, b.answers);
  assert.deepEqual(b.asked.map((q) => q.key), ['workflow', 'ui', 'review']);
});

test('interactive asks every question once, in order', async () => {
  const { asked } = await resolve({}, { interactive: true });
  assert.deepEqual(asked.map((q) => q.key), ['agents', 'methodology', 'workflow', 'ui', 'skills.writing', 'skills.pragmatism', 'skills.diagrams', 'skills.discovery', 'review']);
});

test('design is asked when the project has a UI', async () => {
  const { asked, answers } = await resolve({ ui: 'yes' }, { interactive: true });
  assert.ok(asked.some((q) => q.key === 'skills.design'));
  assert.equal(answers.has_ui, true);
  assert.equal(answers.skills.design, 'impeccable');
});

test('detected agents are preselected', async () => {
  const home = tmp();
  mkdirSync(join(home, '.claude'));
  mkdirSync(join(home, '.copilot'));
  assert.deepEqual(detectAgents(home, data.agents.agents), ['claude', 'copilot']);
  const { asked } = await resolve({}, { interactive: true, home });
  assert.deepEqual(asked.find((q) => q.key === 'agents').recommended, ['claude', 'copilot']);
});

test('an existing methodology folder is preselected', async () => {
  const project = tmp();
  write(project, '.specify/memory/x.md');
  const { answers } = await resolve({ yes: true }, { project });
  assert.equal(answers.methodology, 'spec-kit');
});

test('without a TTY missing answers fall back to recommended and say so', async () => {
  const { asked, notes, answers } = await resolve({ agents: 'claude' });
  assert.equal(asked.length, 0);
  assert.match(notes.join('\n'), /No TTY: using recommended answers for: methodology, workflow/);
  assert.equal(answers.methodology, 'openspec');
});

test('--agents all and none', async () => {
  assert.deepEqual((await resolve({ agents: 'all', yes: true })).answers.agents, ['claude', 'copilot', 'gemini', 'cursor', 'codex']);
  assert.deepEqual((await resolve({ agents: 'none', yes: true })).answers.agents, []);
});

test('--skills with ids sets matching categories and none elsewhere', async () => {
  const { answers } = await resolve({ skills: 'ponytail,repomix', yes: true });
  assert.equal(answers.skills.pragmatism, 'ponytail');
  assert.equal(answers.skills.discovery, 'repomix');
  assert.deepEqual(answers.skills.writing, ['none']);
  assert.equal(answers.skills.diagrams, 'none');
});

test('--skills none', async () => {
  const { answers } = await resolve({ skills: 'none', yes: true });
  assert.ok(Object.values(answers.skills).every((v) => v === 'none' || (Array.isArray(v) && v[0] === 'none')));
});

for (const [flags, msg] of [
  [{ agents: 'claud' }, /unknown agent 'claud'/],
  [{ methodology: 'openspek' }, /unknown methodology 'openspek'/],
  [{ workflow: 'ponytail' }, /unknown workflow 'ponytail'/],
  [{ skills: 'nope' }, /unknown skill 'nope'/],
  [{ skills: 'graphify,repomix' }, /single-select/],
  [{ review: 'sometimes' }, /--review/],
  [{ ui: 'maybe' }, /--ui/],
]) {
  test(`invalid flag ${JSON.stringify(flags)} is a usage error`, async () => {
    await assert.rejects(resolve({ ...flags, yes: true }), (e) => e instanceof UsageError && msg.test(e.message));
  });
}

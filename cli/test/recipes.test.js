import { test } from 'node:test';
import assert from 'node:assert/strict';
import { loadData } from '../data.js';
import { methodologyStep, skillSteps, pickedSkills } from '../recipes.js';

const data = loadData();
const recommended = {
  agents: ['claude', 'copilot'], workflow: 'superpowers', has_ui: false,
  skills: { design: 'none', writing: ['anti-ai-slop-writing', 'i-have-adhd'], pragmatism: 'ponytail', diagrams: 'archify', discovery: 'graphify' },
};

test('openspec init maps all agents', () => {
  const s = methodologyStep('openspec', ['claude', 'copilot'], data);
  assert.equal(s.command, 'npx --yes @fission-ai/openspec@1.16.0 init --tools claude,github-copilot --no-animation --no-copilot-cloud .');
  assert.equal(s.interactive, false);
  assert.deepEqual(s.detect, ['openspec/']);
});

test('spec-kit uses the first agent only', () => {
  const s = methodologyStep('spec-kit', ['cursor', 'claude'], data);
  assert.match(s.command, /--integration cursor-agent --script sh/);
  assert.equal(s.interactive, true);
});

test('gsd joins flags with spaces and drops agents without an id', () => {
  assert.equal(methodologyStep('gsd', ['claude', 'copilot', 'codex'], data).command, 'npx --yes @opengsd/gsd-core@1.20.0 --claude --codex --local');
});

test('a methodology without a supported agent has no command', () => {
  const s = methodologyStep('gsd', ['copilot'], data);
  assert.equal(s.command, null);
  assert.match(s.reason, /no supported agent/);
});

test('none has no step', () => {
  assert.equal(methodologyStep('none', ['claude'], data), null);
});

test('picked skills follow catalog order, workflow included, none dropped', () => {
  assert.deepEqual(pickedSkills(recommended, data.catalog), ['anti-ai-slop-writing', 'i-have-adhd', 'ponytail', 'superpowers', 'archify', 'graphify']);
});

test('catalog installs for claude and copilot match the skill recipe', () => {
  const lines = skillSteps(recommended, data).flatMap((s) => s.commands);
  assert.deepEqual(lines, [
    "npx --yes skills@1.7.6 add https://github.com/jalaalrd/anti-ai-slop-writing/tree/63255f9bbb75a265dc5786a04535cd033f487756 --skill '*' -a claude-code -a github-copilot -y",
    'claude plugin marketplace add ayghri/i-have-adhd --scope project',
    'claude plugin install i-have-adhd@i-have-adhd --scope project',
    "npx --yes skills@1.7.6 add https://github.com/ayghri/i-have-adhd/tree/v0.4.1 --skill '*' -a github-copilot -y",
    'claude plugin marketplace add DietrichGebert/ponytail --scope project',
    'claude plugin install ponytail@ponytail --scope project',
    "npx --yes skills@1.7.6 add https://github.com/DietrichGebert/ponytail/tree/v5.3.3 --skill '*' -a github-copilot -y",
    'claude plugin install superpowers@claude-plugins-official --scope project',
    "npx --yes skills@1.7.6 add https://github.com/obra/superpowers/tree/v7.0.2 --skill '*' -a github-copilot -y",
    'npx --yes skills@1.7.6 add https://github.com/tt-a1i/archify/tree/v3.2.0 --skill archify -a claude-code -a github-copilot -y',
    'uv tool install graphifyy==0.9.102 && graphify install',
  ]);
});

test('steps carry touched paths, ask flags and post-install hints', () => {
  const steps = skillSteps({ ...recommended, has_ui: true, skills: { ...recommended.skills, design: 'impeccable' } }, data);
  const npx = steps.find((s) => s.commands[0].includes('archify'));
  assert.deepEqual(npx.touches, ['skills-lock.json', '.agents/skills/archify', '.claude/skills/archify']);
  assert.equal(npx.askAlways, false);
  const plugin = steps.find((s) => s.commands.some((c) => c.includes('plugin install ponytail')));
  assert.deepEqual(plugin.touches, ['.claude/settings.json']);
  const custom = steps.find((s) => s.commands[0].startsWith('uv tool'));
  assert.equal(custom.askAlways, true);
  assert.ok(steps.some((s) => s.postInstall === '/impeccable init'));
});

test('no agents: only custom installs remain', () => {
  const lines = skillSteps({ ...recommended, agents: [] }, data).flatMap((s) => s.commands);
  assert.deepEqual(lines, ['uv tool install graphifyy==0.9.102 && graphify install']);
});

test("agents: first takes the first configured agent, even without an id", () => {
  assert.equal(methodologyStep('spec-kit', ['claude', 'cursor'], data).command.includes('--integration claude'), true);
});

test("'*' entries touch any existing skill folder; claude paths only for claude", () => {
  const onlyCopilot = skillSteps({ ...recommended, agents: ['copilot'] }, data);
  const ponytail = onlyCopilot.find((s) => s.skill === 'ponytail');
  assert.deepEqual(ponytail.touches, ['skills-lock.json', '.agents/skills/*']);
  const withClaude = skillSteps(recommended, data).find((s) => s.skill === 'anti-ai-slop-writing');
  assert.deepEqual(withClaude.touches, ['skills-lock.json', '.agents/skills/*', '.claude/skills/*']);
});

test('a plugin entry without claude installs through npx only', () => {
  const steps = skillSteps({ ...recommended, agents: ['copilot'] }, data).filter((s) => s.skill === 'superpowers');
  assert.equal(steps.length, 1);
  assert.match(steps[0].commands[0], /^npx --yes skills@1\.7\.6 add .*superpowers.* -a github-copilot -y$/);
});

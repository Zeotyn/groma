import { test } from 'node:test';
import assert from 'node:assert/strict';
import { spawnSync } from 'node:child_process';
import { parse } from 'yaml';
import { loadData, SKILLS_SRC } from '../data.js';
import { renderConfig, setInConfig } from '../config.js';
import { tmp, write } from './helpers.js';

const data = loadData();
const answers = {
  agents: ['claude', 'copilot'], methodology: 'openspec', workflow: 'superpowers', has_ui: false, review: 'gated',
  skills: { design: 'none', writing: ['anti-ai-slop-writing', 'i-have-adhd'], pragmatism: 'ponytail', diagrams: 'archify', discovery: 'graphify' },
};
const steps = { config: 'done', methodology: 'done', skills: 'pending' };

function validate(text) {
  const p = tmp();
  write(p, 'config.yaml', text);
  return spawnSync('sh', [`${SKILLS_SRC}/groma/scripts/validate-config.sh`, `${p}/config.yaml`, '--catalog', `${SKILLS_SRC}/groma-skills/catalog.yaml`], { encoding: 'utf8' });
}

test('renders every answer and step state', () => {
  const c = parse(renderConfig(data, { name: 'shop', projectType: 'brownfield', answers, steps, agentsViaPlugin: [] }));
  assert.equal(c.initialized_with, `groma@${data.version}`);
  assert.deepEqual(c.project, { name: 'shop', has_ui: false });
  assert.equal(c.project_type, 'brownfield');
  assert.equal(c.methodology, 'openspec');
  assert.equal(c.workflow, 'superpowers');
  assert.deepEqual(c.agents, ['claude', 'copilot']);
  assert.deepEqual(c.skills, answers.skills);
  assert.equal(c.review.mode, 'gated');
  assert.equal(c.steps.config, 'done');
  assert.equal(c.steps.methodology, 'done');
  assert.equal(c.steps.skills, 'pending');
  assert.equal(c.steps.detect, 'pending');
  assert.equal(c.agents_via_plugin, undefined);
});

test('rendered config passes validate-config.sh with the catalog', () => {
  const r = validate(renderConfig(data, { name: 'shop', projectType: 'greenfield', answers, steps, agentsViaPlugin: ['claude'] }));
  assert.equal(r.status, 0, r.stdout);
  assert.match(r.stdout, /errors=0\twarnings=0/);
});

test('agents_via_plugin is recorded', () => {
  const c = parse(renderConfig(data, { name: 'x', projectType: 'greenfield', answers, steps, agentsViaPlugin: ['claude'] }));
  assert.deepEqual(c.agents_via_plugin, ['claude']);
});

test('odd project names are quoted', () => {
  const c = parse(renderConfig(data, { name: 'my app: v2 #1', projectType: 'greenfield', answers, steps, agentsViaPlugin: [] }));
  assert.equal(c.project.name, 'my app: v2 #1');
});

test('setInConfig changes one top-level or step value and keeps comments', () => {
  const text = renderConfig(data, { name: 'x', projectType: 'greenfield', answers, steps, agentsViaPlugin: [] });
  const out = setInConfig(setInConfig(text, 'initialized_with', 'groma@9.9.9'), 'steps.skills', 'done');
  const c = parse(out);
  assert.equal(c.initialized_with, 'groma@9.9.9');
  assert.equal(c.steps.skills, 'done');
  assert.match(out, /# suite version of the last \/groma run/);
});

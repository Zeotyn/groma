import { test } from 'node:test';
import assert from 'node:assert/strict';
import { existsSync, readFileSync, readdirSync, chmodSync, mkdirSync } from 'node:fs';
import { join } from 'node:path';
import { tmpdir } from 'node:os';
import { parse } from 'yaml';
import { spawnSync } from 'node:child_process';
import { run, tmp, write } from './helpers.js';
import { version } from '../data.js';

// PATH with stub `npx`, `claude`, `uv`, `uvx` that log their arguments.
function stubs({ plugins = '' } = {}) {
  const bin = tmp();
  const log = join(bin, 'calls.log');
  for (const name of ['npx', 'claude', 'uv', 'uvx', 'graphify']) {
    write(bin, name, `#!/bin/sh\necho "${name} $*" >> "${log}"\n${name === 'claude' ? `[ "$1 $2" = "plugin list" ] && printf '%s\\n' "${plugins}"\n` : ''}exit 0\n`);
    chmodSync(join(bin, name), 0o755);
  }
  return { env: { PATH: `${bin}:/usr/bin:/bin` }, calls: () => (existsSync(log) ? readFileSync(log, 'utf8') : '') };
}

const FLAGS = ['--agents', 'claude,copilot', '--methodology', 'openspec', '--skills', 'recommended'];

test('init --yes --print materializes skills, writes config and install.sh, runs nothing', async () => {
  const p = tmp();
  const s = stubs();
  const r = await run(['init', p, ...FLAGS, '--yes', '--print'], { env: s.env });
  assert.equal(r.code, 0, r.err);
  assert.equal(s.calls().replace(/^claude plugin list\n/m, ''), '');
  assert.match(readFileSync(join(p, '.claude/skills/groma/SKILL.md'), 'utf8'), new RegExp(`generatedBy: groma@${version()}`));
  assert.ok(existsSync(join(p, '.github/skills/groma-survey/scripts/freshness.sh')));
  const cfg = parse(readFileSync(join(p, '.groma/config.yaml'), 'utf8'));
  assert.equal(cfg.steps.config, 'done');
  assert.equal(cfg.steps.methodology, 'pending');
  assert.equal(cfg.steps.skills, 'pending');
  assert.deepEqual(cfg.agents, ['claude', 'copilot']);
  const sh = readFileSync(join(p, '.groma/install.sh'), 'utf8');
  assert.match(sh, /openspec@1\.16\.0 init --tools claude,github-copilot/);
  assert.match(sh, /claude plugin install ponytail@ponytail --scope project/);
  const lines = r.out.trim().split('\n');
  assert.match(lines.at(-1), /\/groma/);
  assert.match(r.out, /Pending:.*\.groma\/install\.sh/);
});

test('init runs the installers and marks the steps done', async () => {
  const p = tmp();
  const s = stubs();
  const r = await run(['init', p, ...FLAGS, '--skills', 'ponytail', '--yes'], { env: s.env });
  assert.equal(r.code, 0, r.err);
  const calls = s.calls();
  assert.match(calls, /npx --yes @fission-ai\/openspec@1\.16\.0 init --tools claude,github-copilot/);
  assert.match(calls, /claude plugin install ponytail@ponytail --scope project/);
  assert.match(calls, /npx --yes skills@1\.7\.6 add https:\/\/github\.com\/DietrichGebert\/ponytail\/tree\/v5\.3\.3 --skill \* -a github-copilot -y/);
  const cfg = parse(readFileSync(join(p, '.groma/config.yaml'), 'utf8'));
  assert.equal(cfg.steps.methodology, 'done');
  assert.equal(cfg.steps.skills, 'done');
  assert.ok(!existsSync(join(p, '.groma/install.sh')));
});

test('methodology already present: no init, step done', async () => {
  const p = tmp();
  write(p, 'openspec/config.yaml', 'schema: spec-driven\n');
  const s = stubs();
  const r = await run(['init', p, ...FLAGS, '--skills', 'none', '--yes'], { env: s.env });
  assert.equal(r.code, 0, r.err);
  assert.doesNotMatch(s.calls(), /openspec/);
  const cfg = parse(readFileSync(join(p, '.groma/config.yaml'), 'utf8'));
  assert.equal(cfg.methodology, 'openspec');
  assert.equal(cfg.steps.methodology, 'done');
  assert.match(r.out, /already present/);
});

test('an existing skills-lock.json under --yes: npx skills goes to install.sh, step pending', async () => {
  const p = tmp();
  write(p, 'skills-lock.json', '{}');
  const s = stubs();
  const r = await run(['init', p, '--agents', 'copilot', '--methodology', 'none', '--skills', 'archify', '--yes'], { env: s.env });
  assert.equal(r.code, 0, r.err);
  assert.doesNotMatch(s.calls(), /skills@/);
  assert.match(readFileSync(join(p, '.groma/install.sh'), 'utf8'), /skills@1\.7\.6 add .*archify/);
  assert.equal(parse(readFileSync(join(p, '.groma/config.yaml'), 'utf8')).steps.skills, 'pending');
  assert.match(r.out, /skills-lock\.json exists/);
  assert.equal(readFileSync(join(p, 'skills-lock.json'), 'utf8'), '{}');
});

test('--dry-run prints the plan and leaves the folder byte-identical', async () => {
  const p = tmp();
  write(p, 'README.md', 'hi');
  const s = stubs();
  const r = await run(['init', p, ...FLAGS, '--yes', '--dry-run'], { env: s.env });
  assert.equal(r.code, 0, r.err);
  assert.deepEqual(readdirSync(p), ['README.md']);
  assert.match(r.out, /\.claude\/skills\/groma\/SKILL\.md/);
  assert.match(r.out, /\.groma\/config\.yaml/);
  assert.match(r.out, /openspec@1\.16\.0 init/);
  assert.equal(s.calls().replace(/^claude plugin list\n/m, ''), '');
});

test('init refuses an initialized project', async () => {
  const p = tmp();
  write(p, '.groma/config.yaml', 'schema: 1\n');
  const r = await run(['init', p, '--yes'], { env: stubs().env });
  assert.equal(r.code, 1);
  assert.match(r.err, /npx groma-cli update/);
});

test('Claude plugin installed: the skills are still copied and the output says how to switch the plugin off', async () => {
  const p = tmp();
  const s = stubs({ plugins: '  ❯ groma@groma' });
  const r = await run(['init', p, ...FLAGS, '--skills', 'none', '--methodology', 'none', '--yes'], { env: s.env });
  assert.equal(r.code, 0, r.err);
  assert.ok(existsSync(join(p, '.claude/skills/groma/SKILL.md')));
  assert.ok(existsSync(join(p, '.github/skills/groma/SKILL.md')));
  assert.match(r.out, /claude plugin disable groma@groma --scope local/);
  const cfg = parse(readFileSync(join(p, '.groma/config.yaml'), 'utf8'));
  assert.equal(cfg.agents_via_plugin, undefined);
  assert.equal(cfg.steps.skills_copy, 'done');
  // groma prints the command, it never runs it and never writes settings
  assert.doesNotMatch(s.calls(), /plugin disable/);
  assert.ok(!existsSync(join(p, '.claude/settings.local.json')) && !existsSync(join(p, '.claude/settings.json')));
});

test('Claude plugin question: answering no skips the copies and records agents_via_plugin', async () => {
  const p = tmp();
  const s = stubs({ plugins: '  ❯ groma@groma' });
  let question;
  const ask = async (q) => { if (q.key === 'plugin') { question = q; return 'no'; } return q.recommended; };
  const r = await run(['init', p, ...FLAGS, '--skills', 'none', '--methodology', 'none'], { env: s.env, isTTY: true, ask });
  assert.equal(r.code, 0, r.err);
  assert.equal(question.recommended, 'yes');
  assert.ok(!existsSync(join(p, '.claude/skills')));
  assert.ok(existsSync(join(p, '.github/skills/groma/SKILL.md')));
  assert.doesNotMatch(r.out, /plugin disable/);
  const cfg = parse(readFileSync(join(p, '.groma/config.yaml'), 'utf8'));
  assert.deepEqual(cfg.agents_via_plugin, ['claude']);
  assert.equal(cfg.steps.skills_copy, 'done');
});

test('without the plugin there is no hint; skipping the only agent records skills_copy skipped', async () => {
  const p = tmp();
  const r = await run(['init', p, ...FLAGS, '--skills', 'none', '--methodology', 'none', '--yes'], { env: stubs().env });
  assert.doesNotMatch(r.out, /plugin disable/);
  assert.equal(parse(readFileSync(join(p, '.groma/config.yaml'), 'utf8')).steps.skills_copy, 'done');

  const q = tmp();
  const ask = async (x) => (x.key === 'plugin' ? 'no' : x.recommended);
  await run(['init', q, '--agents', 'claude', '--skills', 'none', '--methodology', 'none'], { env: stubs({ plugins: '  ❯ groma@groma' }).env, isTTY: true, ask });
  assert.equal(parse(readFileSync(join(q, '.groma/config.yaml'), 'utf8')).steps.skills_copy, 'skipped');
});

test('a foreign skill folder is reported as conflict and left alone', async () => {
  const p = tmp();
  write(p, '.claude/skills/groma-survey/SKILL.md', 'mine');
  const r = await run(['init', p, ...FLAGS, '--skills', 'none', '--methodology', 'none', '--yes'], { env: stubs().env });
  assert.equal(r.code, 0, r.err);
  assert.equal(readFileSync(join(p, '.claude/skills/groma-survey/SKILL.md'), 'utf8'), 'mine');
  assert.match(r.out, /Conflicts:.*\.claude\/skills\/groma-survey/);
});

test('docs link is appended only to a config the init created', async () => {
  const p = tmp();
  const bin = tmp();
  write(bin, 'npx', '#!/bin/sh\ncase "$*" in *openspec*) mkdir -p openspec && echo "schema: spec-driven" > openspec/config.yaml ;; esac\n');
  chmodSync(join(bin, 'npx'), 0o755);
  mkdirSync(join(p, 'src'));
  const r = await run(['init', p, '--agents', 'copilot', '--methodology', 'openspec', '--skills', 'none', '--yes'], { env: { PATH: `${bin}:/usr/bin:/bin` } });
  assert.equal(r.code, 0, r.err);
  const cfg = readFileSync(join(p, 'openspec/config.yaml'), 'utf8');
  assert.match(cfg, /Product truth lives in docs\//);
  assert.equal(parse(cfg).schema, 'spec-driven');
});

test('folders the methodology init creates do not block catalog installs', async () => {
  const p = tmp();
  const bin = tmp();
  const log = join(bin, 'calls.log');
  write(bin, 'npx', `#!/bin/sh\necho "npx $*" >> "${log}"\ncase "$*" in *openspec*) mkdir -p .claude/skills/openspec-propose .agents/skills/openspec-propose ;; esac\n`);
  chmodSync(join(bin, 'npx'), 0o755);
  const r = await run(['init', p, '--agents', 'claude', '--methodology', 'openspec', '--skills', 'anti-ai-slop-writing', '--workflow', 'none', '--yes'], { env: { PATH: `${bin}:/usr/bin:/bin` } });
  assert.equal(r.code, 0, r.err);
  assert.match(readFileSync(log, 'utf8'), /skills@1\.7\.6 add .*anti-ai-slop-writing/);
  assert.equal(parse(readFileSync(join(p, '.groma/config.yaml'), 'utf8')).steps.skills, 'done');
  assert.match(r.out, /Installed: +anti-ai-slop-writing \(npx skills for claude\)/);
});

test('a plugin step without claude on PATH is pending with a clear reason', async () => {
  const p = tmp();
  const r = await run(['init', p, '--agents', 'claude', '--methodology', 'none', '--skills', 'none', '--workflow', 'superpowers', '--yes'], { env: { PATH: '/usr/bin:/bin' } });
  assert.equal(r.code, 0, r.err);
  assert.match(r.out, /Pending: +superpowers \(plugin for claude\) \(claude not found\)/);
});

test('a pending methodology init carries the docs link into install.sh', async () => {
  const p = tmp();
  const r = await run(['init', p, '--agents', 'copilot', '--methodology', 'openspec', '--skills', 'none', '--yes', '--print'], { env: stubs().env });
  assert.equal(r.code, 0, r.err);
  const sh = readFileSync(join(p, '.groma/install.sh'), 'utf8');
  assert.match(sh, /if \[ ! -e openspec\/config\.yaml \]; then\n  npx --yes @fission-ai\/openspec/);
  assert.match(sh, /Product truth lives in docs\//);
  assert.equal(spawnSync('sh', ['-n', join(p, '.groma/install.sh')]).status, 0);
});

// Repository offer and first commit (c18): no repository above the test folder,
// a git identity only when asked for.
function gitEnv({ identity = true } = {}) {
  const s = stubs();
  const cfg = join(tmp(), 'gitconfig');
  write(cfg, '', identity ? '[user]\n\tname = groma-test\n\temail = test@groma.invalid\n[commit]\n\tgpgsign = false\n' : '');
  return { ...s, env: { ...s.env, PATH: `${s.env.PATH.split(':')[0]}:${process.env.PATH}`, GIT_CONFIG_GLOBAL: cfg, GIT_CONFIG_NOSYSTEM: '1', GIT_CEILING_DIRECTORIES: tmpdir() } };
}
const git = (p, ...args) => spawnSync('git', ['-C', p, ...args], { encoding: 'utf8', env: { ...process.env, GIT_CEILING_DIRECTORIES: tmpdir() } });

test('init --yes outside git, greenfield: repository on main, one commit, clean tree', async () => {
  const p = tmp();
  const r = await run(['init', p, ...FLAGS, '--yes'], { env: gitEnv().env });
  assert.equal(r.code, 0, r.err);
  assert.equal(git(p, 'symbolic-ref', '--short', 'HEAD').stdout.trim(), 'main');
  assert.equal(git(p, 'log', '--format=%s').stdout.trim(), `chore: set up project with groma ${version()}`);
  assert.equal(git(p, 'status', '--porcelain').stdout, '');
  assert.ok(existsSync(join(p, '.gitignore')));
  assert.notEqual(parse(readFileSync(join(p, '.groma/config.yaml'), 'utf8')).git.enabled, false);
  assert.match(r.out.trim().split('\n').at(-1), /\/groma/);
});

test('init --git skip: no repository, git.enabled false', async () => {
  const p = tmp();
  const r = await run(['init', p, ...FLAGS, '--git', 'skip', '--yes'], { env: gitEnv().env });
  assert.equal(r.code, 0, r.err);
  assert.ok(!existsSync(join(p, '.git')));
  assert.equal(parse(readFileSync(join(p, '.groma/config.yaml'), 'utf8')).git.enabled, false);
});

test('init --yes in a brownfield folder outside git takes skip', async () => {
  const p = tmp();
  write(p, 'main.py', 'print(1)\n');
  const r = await run(['init', p, ...FLAGS, '--yes'], { env: gitEnv().env });
  assert.equal(r.code, 0, r.err);
  assert.ok(!existsSync(join(p, '.git')));
  assert.equal(parse(readFileSync(join(p, '.groma/config.yaml'), 'utf8')).git.enabled, false);
});

test('init --commit no: repository without commit', async () => {
  const p = tmp();
  const r = await run(['init', p, ...FLAGS, '--git', 'init', '--commit', 'no', '--yes'], { env: gitEnv().env });
  assert.equal(r.code, 0, r.err);
  assert.ok(existsSync(join(p, '.git')));
  assert.notEqual(git(p, 'rev-parse', '-q', '--verify', 'HEAD').status, 0);
});

test('init without a git identity commits nothing and names the commands', async () => {
  const p = tmp();
  const r = await run(['init', p, ...FLAGS, '--yes'], { env: gitEnv({ identity: false }).env });
  assert.equal(r.code, 0, r.err);
  assert.notEqual(git(p, 'rev-parse', '-q', '--verify', 'HEAD').status, 0);
  assert.match(r.out, /git config user\.name/);
});

test('inside a repository with history: no repository or commit question, no commit', async () => {
  const p = tmp();
  const e = gitEnv();
  spawnSync('git', ['init', '-q', '-b', 'main', p], { env: e.env });
  write(p, 'README.md', 'hi\n');
  spawnSync('git', ['-C', p, 'add', '-A'], { env: e.env });
  spawnSync('git', ['-C', p, 'commit', '-q', '-m', 'first'], { env: e.env });
  const asked = [];
  const ask = async (q) => { asked.push(q.key); return q.recommended; };
  const r = await run(['init', p, ...FLAGS], { env: e.env, isTTY: true, ask });
  assert.equal(r.code, 0, r.err);
  assert.ok(!asked.includes('git') && !asked.includes('commit'), asked.join(','));
  assert.equal(git(p, 'rev-list', '--count', 'HEAD').stdout.trim(), '1');
});

test('--git and --commit reject unknown values', async () => {
  const r = await run(['init', tmp(), ...FLAGS, '--git', 'maybe', '--yes'], { env: gitEnv().env });
  assert.equal(r.code, 2);
  const c = await run(['init', tmp(), ...FLAGS, '--commit', 'maybe', '--yes'], { env: gitEnv().env });
  assert.equal(c.code, 2);
});

test('interactive: asks the repository question, then the commit question, with their recommendations', async () => {
  const p = tmp();
  const asked = [];
  const ask = async (q) => { asked.push(`${q.key}=${q.recommended}`); return q.key === 'commit' ? 'no' : q.recommended; };
  const r = await run(['init', p, ...FLAGS], { env: gitEnv().env, isTTY: true, ask });
  assert.equal(r.code, 0, r.err);
  const git1 = asked.filter((a) => /^(git|commit)=/.test(a));
  assert.deepEqual(git1, ['git=init', 'commit=yes']);
  assert.ok(existsSync(join(p, '.git')));
  assert.notEqual(git(p, 'rev-parse', '-q', '--verify', 'HEAD').status, 0);
});

test('interactive in a brownfield folder: skip is recommended and honoured', async () => {
  const p = tmp();
  write(p, 'main.py', 'print(1)\n');
  const asked = [];
  const ask = async (q) => { asked.push(`${q.key}=${q.recommended}`); return q.recommended; };
  const r = await run(['init', p, ...FLAGS], { env: gitEnv().env, isTTY: true, ask });
  assert.equal(r.code, 0, r.err);
  assert.ok(asked.includes('git=skip'));
  assert.ok(!asked.some((a) => a.startsWith('commit=')));
  assert.ok(!existsSync(join(p, '.git')));
});

test('an existing repository without commits gets no repository question and the first commit', async () => {
  const p = tmp();
  const e = gitEnv();
  spawnSync('git', ['init', '-q', '-b', 'main', p], { env: e.env });
  const r = await run(['init', p, ...FLAGS, '--yes'], { env: e.env });
  assert.equal(r.code, 0, r.err);
  assert.equal(git(p, 'rev-list', '--count', 'HEAD').stdout.trim(), '1');
  assert.ok(!existsSync(join(p, '.gitignore')));
});

test('--print sets up the repository but makes no commit', async () => {
  const p = tmp();
  const r = await run(['init', p, ...FLAGS, '--yes', '--print'], { env: gitEnv().env });
  assert.equal(r.code, 0, r.err);
  assert.ok(existsSync(join(p, '.git')));
  assert.notEqual(git(p, 'rev-parse', '-q', '--verify', 'HEAD').status, 0);
  assert.match(r.out, /no commit \(--print/);
});

test('--dry-run sets up no repository', async () => {
  const p = tmp();
  const r = await run(['init', p, ...FLAGS, '--yes', '--dry-run'], { env: gitEnv().env });
  assert.equal(r.code, 0, r.err);
  assert.deepEqual(readdirSync(p), []);
  assert.match(r.out, /git init -b main/);
});

test('without git on PATH: no question, no repository, init still succeeds', async () => {
  const p = tmp();
  const s = stubs();
  const bin = s.env.PATH.split(':')[0];
  const r = await run(['init', p, ...FLAGS, '--yes'], { env: { ...s.env, PATH: bin } });
  assert.equal(r.code, 0, r.err);
  assert.ok(!existsSync(join(p, '.git')));
  assert.match(r.out, /git not found/);
});

test('a parent repository without commits: named, nothing committed into it', async () => {
  const h = tmp();
  const e = gitEnv();
  spawnSync('git', ['init', '-q', '-b', 'main', h], { env: e.env });
  const p = join(h, 'app');
  mkdirSync(p);
  const r = await run(['init', p, ...FLAGS, '--yes'], { env: e.env });
  assert.equal(r.code, 0, r.err);
  assert.match(r.out, /using the repository at/);
  assert.notEqual(git(h, 'rev-parse', '-q', '--verify', 'HEAD').status, 0);
});

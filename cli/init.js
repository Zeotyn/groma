// groma init: deterministic project setup, then hand-off to /groma.
import { spawnSync } from 'node:child_process';
import { appendFileSync, existsSync, mkdirSync, readFileSync, writeFileSync } from 'node:fs';
import { homedir } from 'node:os';
import { join } from 'node:path';
import { loadData, SKILLS_SRC } from './data.js';
import { resolveAnswers, terminalAsk } from './answers.js';
import { methodologyStep, skillSteps } from './recipes.js';
import { planSkills, applySkills, readGenerated } from './skills.js';
import { renderConfig } from './config.js';
import { onPath, runStep, writeInstallScript } from './exec.js';
import { EXIT } from './main.js';

const CONFIG = '.groma/config.yaml';
export const today = () => new Date().toISOString().slice(0, 10);

function projectType(project) {
  const r = spawnSync('sh', [join(SKILLS_SRC, 'groma-detect/scripts/detect.sh'), project], { encoding: 'utf8' });
  return /^project_type=(\w+)/m.exec(r.stdout ?? '')?.[1] ?? 'greenfield';
}

function claudePluginInstalled(env) {
  if (!onPath('claude', env)) return false;
  const r = spawnSync('claude', ['plugin', 'list'], { encoding: 'utf8', env, timeout: 20000 });
  return /(^|\s)groma@/m.test(r.stdout ?? '');
}

// Shared by init and update: interactive prompt plumbing.
export function prompts(io, flags) {
  const tty = !!io.stdin.isTTY;
  const interactive = tty && !flags.yes;
  const ask = io.ask ?? (interactive ? terminalAsk(io) : null);
  const confirm = async (text) => (await ask({ key: 'confirm', text, select: 'single', options: [{ id: 'yes', hint: '' }, { id: 'no', hint: '' }], recommended: 'no' })) === 'yes';
  return { tty, interactive, ask, confirm, close: () => ask?.close?.() };
}

// Run the methodology and catalog steps. Returns { methodology, skills, pending, notes }.
export async function runSetup({ project, answers, data, flags, io, p, only = ['methodology', 'skills'] }) {
  const ctx = { project, print: !!flags.print, yes: !!flags.yes, tty: p.tty, env: io.env, confirm: p.confirm };
  const out = { methodology: 'done', skills: 'done', pending: [], notes: [], installed: [], postInstall: new Set() };

  if (only.includes('methodology')) {
    const m = methodologyStep(answers.methodology, answers.agents, data);
    if (!m) {
      out.notes.push(`Methodology: ${answers.methodology}`);
    } else if (m.detect.some((d) => existsSync(join(project, d)))) {
      out.notes.push(`Methodology: ${m.id} already present`);
    } else if (!m.command) {
      out.methodology = 'pending';
      out.notes.push(`Methodology: ${m.id} pending (${m.reason})`);
    } else {
      const link = m.docsLink && join(project, m.docsLink.file);
      const linkExisted = link && existsSync(link);
      const r = await runStep({ ...m, commands: [m.command] }, ctx);
      if (r.state === 'done') {
        out.notes.push(`Methodology: ${m.id} initialized`);
        if (link && !linkExisted && existsSync(link)) {
          const keys = [...m.docsLink.append.matchAll(/^(\w+):/gm)].map((k) => k[1]);
          const text = readFileSync(link, 'utf8');
          if (keys.some((k) => new RegExp(`^${k}:`, 'm').test(text))) out.notes.push(`Docs link: ${m.docsLink.file} already has ${keys.join('/')}; add this by hand:\n${m.docsLink.append}`);
          else appendFileSync(link, m.docsLink.append);
        }
      } else {
        out.methodology = 'pending';
        out.pending.push({ label: `methodology ${m.id}`, reason: r.reason, commands: [m.command] });
        out.notes.push(`Methodology: ${m.id} pending (${r.reason})`);
      }
    }
  }

  if (only.includes('skills')) {
    for (const step of skillSteps(answers, data)) {
      const r = await runStep(step, ctx);
      if (step.postInstall) out.postInstall.add(step.postInstall);
      if (r.state === 'done') out.installed.push(step.skill);
      else {
        out.skills = 'pending';
        out.pending.push({ label: step.skill, reason: r.reason, commands: step.commands });
      }
    }
  }
  return out;
}

export function skillSummary(say, plan) {
  if (plan.conflicts.length) say(`Conflicts:   ${plan.conflicts.join(', ')} (not created by groma, left untouched)`);
  if (plan.edited.length) say(`Edited:      ${plan.edited.join(', ')} (edited, not updated; --force replaces)`);
}

export function pendingSummary(say, setup, script) {
  const installed = [...new Set(setup.installed)];
  if (installed.length) say(`Installed:   ${installed.join(', ')}`);
  const byReason = new Map();
  for (const e of setup.pending) byReason.set(e.reason, new Set([...(byReason.get(e.reason) ?? []), e.label]));
  for (const [reason, labels] of byReason) say(`Pending:     ${[...labels].join(', ')} (${reason})`);
  if (script) say(`Pending:     review and run: sh ${script}`);
  for (const c of setup.postInstall) say(`Then:        run ${c} inside your agent`);
}

export default async function init({ project, flags, io, say }) {
  const data = loadData();
  if (existsSync(join(project, CONFIG))) {
    io.stderr.write(`${CONFIG} exists: this project is initialized. Run: npx groma update\n`);
    return EXIT.error;
  }
  const type = projectType(project);
  const p = prompts(io, flags);
  try {
    const answers = await resolveAnswers({ flags, data, project, home: io.env.HOME ?? homedir(), projectType: type, interactive: p.interactive, ask: p.ask, note: say });

    let viaPlugin = [];
    if (answers.agents.includes('claude') && claudePluginInstalled(io.env)) {
      const skip = p.interactive
        ? (await p.ask({ key: 'plugin', text: 'The groma Claude Code plugin is installed. Skip copying the skills for Claude?', select: 'single', options: [{ id: 'yes', hint: 'avoids two copies of every skill' }, { id: 'no', hint: '' }], recommended: 'yes' })) === 'yes'
        : true;
      if (skip) viaPlugin = ['claude'];
    }
    const skillAgents = answers.agents.filter((a) => !viaPlugin.includes(a));
    const plan = planSkills({ project, agents: skillAgents, data, generated: readGenerated(project) });

    if (flags['dry-run']) {
      say('Dry run: nothing is written or run.\n\nWould write:');
      for (const w of plan.writes) say(`  ${w.path}`);
      say(`  ${CONFIG}\n  .groma/generated.json`);
      say('\nWould run (asking first where an installer touches existing files):');
      const m = methodologyStep(answers.methodology, answers.agents, data);
      if (m?.command && !m.detect.some((d) => existsSync(join(project, d)))) say(`  ${m.command}`);
      for (const s of skillSteps(answers, data)) for (const c of s.commands) say(`  ${c}`);
      skillSummary(say, plan);
      say('\nNext: run without --dry-run');
      return EXIT.ok;
    }

    applySkills(project, plan, data.version);
    const setup = await runSetup({ project, answers, data, flags, io, p });
    const script = writeInstallScript(project, setup.pending, today());
    mkdirSync(join(project, '.groma'), { recursive: true });
    writeFileSync(join(project, CONFIG), renderConfig(data, {
      name: project.split(/[\\/]/).pop(), projectType: type, answers, agentsViaPlugin: viaPlugin,
      steps: { config: 'done', methodology: setup.methodology, skills: setup.skills },
    }));

    say(`\ngroma ${data.version} · ${type}`);
    say(`Agents:      ${answers.agents.join(', ') || 'none'}${viaPlugin.length ? ` (${viaPlugin.join(', ')} via plugin)` : ''}`);
    for (const n of setup.notes) say(n);
    say(`Created:     ${plan.writes.length} skill files, ${CONFIG}, .groma/generated.json`);
    skillSummary(say, plan);
    pendingSummary(say, setup, script);
    say('\nNext: open this project in your agent and run /groma');
    return EXIT.ok;
  } finally {
    p.close();
  }
}

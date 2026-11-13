// groma init: deterministic project setup, then hand-off to /groma.
import { spawnSync } from 'node:child_process';
import { appendFileSync, existsSync, mkdirSync, readFileSync, writeFileSync } from 'node:fs';
import { homedir } from 'node:os';
import { basename, join } from 'node:path';
import { loadData, SKILLS_SRC } from './data.js';
import { resolveAnswers, terminalAsk } from './answers.js';
import { methodologyStep, skillSteps } from './recipes.js';
import { planSkills, applySkills, readGenerated } from './skills.js';
import { renderConfig } from './config.js';
import { existingTouches, onPath, runStep, writeInstallScript } from './exec.js';
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

// A project copy plus the enabled plugin lists every skill twice in Claude Code
// (ADR 0050). groma prints the command; it never runs it and never edits settings.
export const PLUGIN_DISABLE = 'claude plugin disable groma@groma --scope local';
const PLUGIN_HINT = `Plugin:      the groma Claude Code plugin is installed too, so Claude Code lists every groma skill twice in this project.\n             To switch the plugin off for this project only, run here: ${PLUGIN_DISABLE}`;

// Shared by init and update: interactive prompt plumbing.
export function prompts(io, flags) {
  const tty = !!io.stdin.isTTY;
  const interactive = tty && !flags.yes;
  const ask = io.ask ?? (interactive ? terminalAsk(io) : null);
  const confirm = async (text) => (await ask({ key: 'confirm', text, select: 'single', options: [{ id: 'yes', hint: '' }, { id: 'no', hint: '' }], recommended: 'no' })) === 'yes';
  return { tty, interactive, ask, confirm, close: () => ask?.close?.() };
}

// Run the methodology and catalog steps. Returns { methodology, skills, pending, notes }.
// `retry`: labels of catalog steps still pending from an earlier run (update);
// steps that already ran are not repeated.
export async function runSetup({ project, answers, data, flags, io, p, only = ['methodology', 'skills'], retry }) {
  const ctx = { project, print: !!flags.print, yes: !!flags.yes, tty: p.tty, env: io.env, confirm: p.confirm };
  const out = { methodology: 'done', skills: 'done', pending: [], notes: [], installed: [], postInstall: new Set() };

  // Judge catalog installs by the project as it was before this run:
  // folders the methodology init creates (openspec-*) do not count.
  const catalog = only.includes('skills')
    ? skillSteps(answers, data).filter((s) => !retry || retry.includes(s.label)).map((s) => ({ ...s, existing: existingTouches(project, s.touches) }))
    : [];

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
        // install.sh also adds the docs link, only when the init creates the file
        const f = m.docsLink?.file;
        const script = f && !linkExisted
          ? `if [ ! -e ${f} ]; then\n  ${m.command}\n  cat >> ${f} <<'GROMA_EOF'\n${m.docsLink.append}GROMA_EOF\nfi`
          : m.command;
        out.pending.push({ label: `methodology ${m.id}`, reason: r.reason, commands: [m.command], script });
        out.notes.push(`Methodology: ${m.id} pending (${r.reason})`);
      }
    }
  }

  if (only.includes('skills')) {
    for (const step of catalog) {
      const r = await runStep(step, ctx);
      if (step.postInstall) out.postInstall.add(step.postInstall);
      if (r.state === 'done') out.installed.push(step.label);
      else {
        out.skills = 'pending';
        out.pending.push({ label: step.label, reason: r.reason, commands: step.commands });
      }
    }
  }
  return out;
}

// Catalog steps that did not run, so update retries only those.
export const PENDING = '.groma/pending.json';
export function savePending(project, setup) {
  const labels = setup.pending.filter((e) => !e.label.startsWith('methodology ')).map((e) => e.label);
  writeFileSync(join(project, PENDING), JSON.stringify(labels, null, 2) + '\n');
}
export function readPending(project) {
  const f = join(project, PENDING);
  return existsSync(f) ? JSON.parse(readFileSync(f, 'utf8')) : undefined;
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
  if (script) say(`Pending:     review and run sh ${script}, or let npx groma-cli update run them`);
  for (const c of setup.postInstall) say(`Then:        run ${c} inside your agent`);
}

export default async function init({ project, flags, io, say }) {
  const data = loadData();
  if (existsSync(join(project, CONFIG))) {
    io.stderr.write(`${CONFIG} exists: this project is initialized. Run: npx groma-cli update\n`);
    return EXIT.error;
  }
  const type = projectType(project);
  const p = prompts(io, flags);
  try {
    const answers = await resolveAnswers({ flags, data, project, home: io.env.HOME ?? homedir(), projectType: type, interactive: p.interactive, ask: p.ask, note: say });

    // The project copy is what the team gets, so it is the default also when
    // the plugin is installed; the user switches the plugin off for this project.
    let viaPlugin = [];
    let pluginHint = false;
    if (answers.agents.includes('claude') && claudePluginInstalled(io.env)) {
      const copy = p.interactive
        ? (await p.ask({ key: 'plugin', text: 'The groma Claude Code plugin is installed. Copy the skills for Claude into the project too?', select: 'single', options: [{ id: 'yes', hint: 'the team gets them with the repository' }, { id: 'no', hint: 'Claude keeps using the plugin, nothing is copied for it' }], recommended: 'yes' })) === 'yes'
        : true;
      if (copy) pluginHint = true;
      else viaPlugin = ['claude'];
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
      if (pluginHint) say(PLUGIN_HINT);
      say('\nNext: run without --dry-run');
      return EXIT.ok;
    }

    applySkills(project, plan, data.version);
    const setup = await runSetup({ project, answers, data, flags, io, p });
    const script = writeInstallScript(project, setup.pending, today());
    mkdirSync(join(project, '.groma'), { recursive: true });
    savePending(project, setup);
    writeFileSync(join(project, CONFIG), renderConfig(data, {
      name: basename(project), projectType: type, answers, agentsViaPlugin: viaPlugin,
      steps: { config: 'done', methodology: setup.methodology, skills: setup.skills, skills_copy: skillAgents.length ? 'done' : 'skipped' },
    }));

    say(`\ngroma ${data.version} · ${type}`);
    say(`Agents:      ${answers.agents.join(', ') || 'none'}${viaPlugin.length ? ` (${viaPlugin.join(', ')} via plugin)` : ''}`);
    for (const n of setup.notes) say(n);
    say(`Created:     ${plan.writes.length} skill files, ${CONFIG}, .groma/generated.json`);
    skillSummary(say, plan);
    if (pluginHint) say(PLUGIN_HINT);
    pendingSummary(say, setup, script);
    say('\nNext: open this project in your agent and run /groma');
    return EXIT.ok;
  } finally {
    p.close();
  }
}

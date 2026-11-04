// groma update: refresh generated skill copies, re-run pending steps.
import { existsSync, readFileSync, writeFileSync } from 'node:fs';
import { join } from 'node:path';
import { parse } from 'yaml';
import { loadData } from './data.js';
import { planSkills, applySkills, readGenerated } from './skills.js';
import { setInConfig } from './config.js';
import { writeInstallScript } from './exec.js';
import { prompts, runSetup, skillSummary, pendingSummary, today, readPending, savePending } from './init.js';
import { EXIT } from './main.js';

const CONFIG = '.groma/config.yaml';

export default async function update({ project, flags, io, say }) {
  const data = loadData();
  const file = join(project, CONFIG);
  if (!existsSync(file)) {
    io.stderr.write(`${CONFIG} not found: run npx groma-cli init first\n`);
    return EXIT.error;
  }
  const text = readFileSync(file, 'utf8');
  const cfg = parse(text);
  const viaPlugin = cfg.agents_via_plugin ?? [];
  const agents = (cfg.agents ?? []).filter((a) => !viaPlugin.includes(a));
  const plan = planSkills({ project, agents, data, generated: readGenerated(project), force: !!flags.force });
  const pendingSteps = ['methodology', 'skills'].filter((s) => cfg.steps?.[s] === 'pending');

  if (flags['dry-run']) {
    say('Dry run: nothing is written or run.\n\nWould write:');
    for (const w of plan.writes) say(`  ${w.path} (${w.kind})`);
    for (const r of plan.removals) say(`  ${r} (remove, retired)`);
    if (pendingSteps.length) say(`Would re-run pending steps: ${pendingSteps.join(', ')}`);
    skillSummary(say, plan);
    return EXIT.ok;
  }

  applySkills(project, plan, data.version);
  const answers = { agents: cfg.agents ?? [], methodology: cfg.methodology, workflow: cfg.workflow, has_ui: !!cfg.project?.has_ui, skills: cfg.skills ?? {} };
  const p = prompts(io, flags);
  let setup = { pending: [], notes: [], installed: [], postInstall: new Set() };
  try {
    if (pendingSteps.length) setup = await runSetup({ project, answers, data, flags, io, p, only: pendingSteps, retry: readPending(project) });
  } finally {
    p.close();
  }
  const script = writeInstallScript(project, setup.pending, today());
  if (pendingSteps.includes('skills')) savePending(project, setup);

  let next = setInConfig(text, 'initialized_with', `groma@${data.version}`);
  for (const s of pendingSteps) next = setInConfig(next, `steps.${s}`, setup[s]);
  writeFileSync(file, next);

  const count = (k) => plan.writes.filter((w) => w.kind === k).length;
  say(`groma ${data.version} · update`);
  say(`Skills:      ${count('update')} updated, ${count('create')} created, ${plan.removals.length} removed`);
  for (const n of setup.notes) say(n);
  skillSummary(say, plan);
  pendingSummary(say, setup, script);
  say(`\nNext: ${script ? `review and run sh ${script}` : 'review the changes (git diff), commit them, and run /groma in your agent for anything still open'}`);
  return EXIT.ok;
}

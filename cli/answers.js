// Answer resolution: flags > interactive answers > recommended.
import { existsSync } from 'node:fs';
import { join } from 'node:path';
import { createInterface } from 'node:readline/promises';
import { UsageError } from './main.js';

const expandHome = (p, home) => p.replace(/^~(?=\/|$)/, home);

export function detectAgents(home, agents) {
  return Object.keys(agents).filter((a) => existsSync(expandHome(agents[a].home_marker, home)));
}

export function detectMethodology(project, methodologies) {
  return Object.keys(methodologies).find((m) => (methodologies[m].detect ?? []).some((p) => existsSync(join(project, p))));
}

const list = (s) => s.split(',').map((x) => x.trim()).filter(Boolean);

function oneOf(value, allowed, what) {
  if (!allowed.includes(value)) throw new UsageError(`unknown ${what} '${value}' (allowed: ${allowed.join(', ')})`);
  return value;
}

// Category picks from --skills; returns { category: value } for every category given.
function skillsFromFlag(flag, categories) {
  const picks = {};
  const ids = flag === 'recommended' || flag === 'none' ? [] : list(flag);
  const known = Object.values(categories).flatMap((c) => c.options);
  for (const id of ids) oneOf(id, known, 'skill');
  for (const [cid, c] of Object.entries(categories)) {
    let v;
    if (flag === 'recommended') v = c.recommended;
    else if (flag === 'none') v = 'none';
    else {
      const hit = c.options.filter((o) => ids.includes(o));
      if (c.select === 'single' && hit.length > 1) throw new UsageError(`category '${cid}' is single-select, got ${hit.join(', ')}`);
      v = c.select === 'single' ? (hit[0] ?? 'none') : hit;
    }
    picks[cid] = c.select === 'multi' ? [v].flat().filter(Boolean) : v;
    if (c.select === 'multi' && picks[cid].length === 0) picks[cid] = ['none'];
  }
  return picks;
}

export async function resolveAnswers({ flags, data, project, home, projectType, interactive, ask, note }) {
  const { agents: agentTable } = data.agents;
  const agentIds = Object.keys(agentTable);
  const { categories, skills: catalogSkills } = data.catalog;
  const { workflow: workflowCat, ...skillCats } = categories;
  const defaulted = [];

  // value from the flag, else ask, else the recommended option
  async function answer(q, fromFlag) {
    if (fromFlag !== undefined) return fromFlag;
    if (interactive) return ask(q);
    defaulted.push(q.key);
    return q.recommended;
  }
  const opt = (id, hint) => ({ id, hint: hint ?? catalogSkills[id]?.description ?? '' });

  let agentsFlag;
  if (flags.agents !== undefined) {
    agentsFlag = flags.agents === 'all' ? agentIds : flags.agents === 'none' ? [] : list(flags.agents).map((a) => oneOf(a, agentIds, 'agent'));
  }
  const agents = await answer({
    key: 'agents', text: 'Which agents does this project use?', select: 'multi',
    options: agentIds.map((a) => opt(a, `skills in ${agentTable[a].skills_dir}`)),
    recommended: detectAgents(home, agentTable),
  }, agentsFlag);

  const methodologyIds = Object.keys(data.methodologies);
  const methodology = await answer({
    key: 'methodology', text: 'Spec methodology?', select: 'single',
    options: methodologyIds.map((m) => opt(m, '')),
    recommended: detectMethodology(project, data.methodologies) ?? 'openspec',
  }, flags.methodology && oneOf(flags.methodology, methodologyIds, 'methodology'));

  const workflow = await answer({
    key: 'workflow', text: `Workflow layer? ${workflowCat.description}`, select: 'single',
    options: workflowCat.options.map((o) => opt(o)), recommended: workflowCat.recommended,
  }, flags.workflow && oneOf(flags.workflow, workflowCat.options, 'workflow'));

  if (flags.ui !== undefined) oneOf(flags.ui, ['yes', 'no'], '--ui value');
  const ui = await answer({
    key: 'ui', text: 'Does the project have a user interface?', select: 'single',
    options: [opt('yes', ''), opt('no', '')], recommended: 'no',
  }, flags.ui);
  const hasUi = ui === 'yes';

  const fromFlag = flags.skills !== undefined ? skillsFromFlag(flags.skills, skillCats) : {};
  const skills = {};
  for (const [cid, c] of Object.entries(skillCats)) {
    const applies = !c.condition || (c.condition === 'has_ui' ? hasUi : c.condition === projectType);
    if (!applies) { skills[cid] = c.select === 'multi' ? ['none'] : 'none'; continue; }
    skills[cid] = await answer({
      key: `skills.${cid}`, text: `${cid[0].toUpperCase()}${cid.slice(1)}: ${c.description}`, select: c.select,
      options: c.options.map((o) => opt(o)), recommended: c.recommended,
    }, fromFlag[cid]);
  }

  if (flags.review !== undefined) oneOf(flags.review, ['autonomous', 'gated'], '--review value');
  const review = await answer({
    key: 'review', text: 'Review loop mode?', select: 'single',
    options: [opt('autonomous', 'reviewer loops run on their own'), opt('gated', 'approval after propose and before archive')],
    recommended: 'autonomous',
  }, flags.review);

  if (defaulted.length && !flags.yes) note(`No TTY: using recommended answers for: ${defaulted.join(', ')}`);
  return { agents, methodology, workflow, has_ui: hasUi, skills, review };
}

// Interactive prompt on the terminal. Enter takes the recommended option.
export function terminalAsk(io) {
  const rl = createInterface({ input: process.stdin, output: process.stdout });
  const ask = async (q) => {
    const rec = [q.recommended].flat();
    const lines = q.options.map((o, i) => `  ${i + 1}. ${o.id}${rec.includes(o.id) ? ' (recommended)' : ''}${o.hint ? `: ${o.hint}` : ''}`);
    const how = q.select === 'multi' ? 'numbers or ids, comma-separated' : 'number or id';
    for (;;) {
      const input = (await rl.question(`\n${q.text}\n${lines.join('\n')}\n(${how}; Enter = recommended) > `)).trim();
      if (!input) return q.recommended;
      const picks = list(input).map((x) => (/^\d+$/.test(x) ? q.options[Number(x) - 1]?.id : x));
      if (picks.every((p) => q.options.some((o) => o.id === p)) && (q.select === 'multi' || picks.length === 1)) {
        return q.select === 'multi' ? picks : picks[0];
      }
      io.stdout.write(`Please answer with ${how} from the list.\n`);
    }
  };
  ask.close = () => rl.close();
  return ask;
}

// Render install commands from methodologies.yaml, agents.yaml and catalog.yaml.

const fill = (template, vars) => template.replace(/\{(\w+)\}/g, (m, k) => (k in vars ? vars[k] : m)).replace(/ {2,}/g, ' ');

export function methodologyStep(id, agents, data) {
  const r = data.methodologies[id];
  if (!r?.init) return null;
  const step = { id, detect: r.detect ?? [], requires: r.requires ?? [], touches: r.touches ?? [], interactive: !!r.interactive, docsLink: r.docs_link ?? null };
  let ids = [];
  if (r.agent_ids) {
    ids = (r.agents === 'first' ? agents.slice(0, 1) : agents).map((a) => r.agent_ids[a]).filter(Boolean);
    if (!ids.length) return { ...step, command: null, reason: `no supported agent among: ${agents.join(', ') || 'none'}` };
  }
  return { ...step, command: fill(r.init, { agents: ids.join(r.separator ?? ',') }) };
}

// Picked catalog skill ids in catalog category order, `none` dropped.
export function pickedSkills(answers, catalog) {
  return Object.keys(catalog.categories)
    .flatMap((cid) => [cid === 'workflow' ? answers.workflow : answers.skills[cid]].flat())
    .filter((id) => id && id !== 'none');
}

// One step per installer call: { skill, commands, touches, askAlways, postInstall }.
export function skillSteps(answers, data) {
  const { agents: table, commands, builtin_marketplaces: builtin = [], touches } = data.agents;
  const steps = [];
  for (const id of pickedSkills(answers, data.catalog)) {
    const e = data.catalog.skills[id];
    const postInstall = e.post_install;
    if (e.install) {
      steps.push({ skill: id, commands: [e.install], touches: [], askAlways: true, postInstall });
      continue;
    }
    const viaPlugin = e.claude_plugin ? answers.agents.filter((a) => table[a].plugins) : [];
    if (viaPlugin.length) {
      const cmds = [];
      if (!builtin.includes(e.marketplace)) cmds.push(fill(commands.plugin_marketplace, { marketplace: e.marketplace }));
      cmds.push(fill(commands.plugin_install, { claude_plugin: e.claude_plugin }));
      steps.push({ skill: id, commands: cmds, touches: touches.claude_plugin ?? [], askAlways: false, postInstall });
    }
    const rest = answers.agents.filter((a) => !viaPlugin.includes(a));
    if (rest.length) {
      const names = e.skills ?? ['*'];
      const skills = names.map((n) => `--skill ${n === '*' ? "'*'" : n}`).join(' ');
      const agents = rest.map((a) => `-a ${table[a].npx_skills_id}`).join(' ');
      // '*' installs unknown names: any existing third-party skill folder counts
      const paths = (touches.npx_skills ?? [])
        .filter((p) => rest.includes('claude') || !p.startsWith(`${table.claude.skills_dir}/`))
        .flatMap((p) => (p.includes('{skill}') ? names.map((n) => p.replace('{skill}', n)) : [p]));
      steps.push({ skill: id, commands: [fill(commands.npx_skills, { source: e.source, ref: e.ref, skills, agents })], touches: paths, askAlways: false, postInstall });
    }
  }
  return steps;
}

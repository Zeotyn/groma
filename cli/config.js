// .groma/config.yaml from the template, edited as text to keep its comments.

const scalar = (v) => (/^[A-Za-z0-9._@/-]+$/.test(String(v)) ? String(v) : JSON.stringify(String(v)));

// Set `key` or `parent.key` (two levels) to a scalar value; comments stay.
export function setInConfig(text, key, value) {
  const [parent, child] = key.includes('.') ? key.split('.') : [null, key];
  const start = parent ? text.search(new RegExp(`^${parent}:`, 'm')) : 0;
  if (start < 0) return text;
  const re = new RegExp(`^(${parent ? '  ' : ''}${child}:[ \\t]*)[^\\s#]+`, 'm');
  return text.slice(0, start) + text.slice(start).replace(re, `$1${scalar(value)}`);
}

export function renderConfig(data, { name, projectType, answers, steps, agentsViaPlugin }) {
  const { skills } = answers;
  const vars = {
    version: data.version,
    project_name: scalar(name),
    has_ui: String(answers.has_ui),
    project_type: projectType,
    methodology: answers.methodology,
    workflow: answers.workflow,
    agents: answers.agents.join(', '),
  };
  for (const [cid, v] of Object.entries(skills)) vars[`skills_${cid}`] = [v].flat().join(', ');
  let text = data.configTemplate.replace(/\{\{(\w+)\}\}/g, (m, k) => vars[k] ?? m);
  if (agentsViaPlugin.length) {
    text = text.replace(/^(agents: .*\n)/m, `$1agents_via_plugin: [${agentsViaPlugin.join(', ')}]  # these agents get the groma skills from the plugin\n`);
  }
  text = setInConfig(text, 'review.mode', answers.review);
  for (const [step, state] of Object.entries(steps)) text = setInConfig(text, `steps.${step}`, state);
  return text;
}

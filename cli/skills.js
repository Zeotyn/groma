// Materialize the groma skills into each agent's project skill folder.
// A file is groma's to replace only when .groma/generated.json lists it and
// its current hash still matches; everything else belongs to the user.
import { createHash } from 'node:crypto';
import { existsSync, mkdirSync, readFileSync, readdirSync, rmdirSync, statSync, unlinkSync, writeFileSync, chmodSync } from 'node:fs';
import { join, dirname } from 'node:path';
import { SKILLS_SRC } from './data.js';

export const GENERATED = '.groma/generated.json';

export const sha256 = (buf) => createHash('sha256').update(buf).digest('hex');

export function readGenerated(project) {
  const f = join(project, GENERATED);
  return existsSync(f) ? JSON.parse(readFileSync(f, 'utf8')) : { generatedBy: null, files: {} };
}

export function addGeneratedBy(text, tag) {
  const end = text.indexOf('\n---', 4);
  if (!text.startsWith('---\n') || end < 0) return text;
  const head = text.slice(0, end + 1);
  const m = /^metadata:[ \t]*\n/m.exec(head);
  if (m) return text.slice(0, m.index + m[0].length) + `  generatedBy: ${tag}\n` + text.slice(m.index + m[0].length);
  return `${head}metadata:\n  generatedBy: ${tag}\n${text.slice(end + 1)}`;
}

function walk(dir, prefix = '') {
  return readdirSync(dir, { withFileTypes: true }).flatMap((e) =>
    e.isDirectory() ? walk(join(dir, e.name), `${prefix}${e.name}/`) : [`${prefix}${e.name}`]);
}

const hashOf = (project, rel) => sha256(readFileSync(join(project, rel)));

// Returns { writes: [{path, content, mode, kind}], edited, conflicts, removals, records }.
// `records` is the generated.json file map after applying the plan.
export function planSkills({ project, agents, data, generated, force = false }) {
  const tag = `groma@${data.version}`;
  const known = generated.files;
  const plan = { writes: [], edited: [], conflicts: [], removals: [], records: {} };
  const skills = readdirSync(SKILLS_SRC, { withFileTypes: true }).filter((e) => e.isDirectory()).map((e) => e.name);

  for (const agent of agents) {
    for (const skill of skills) {
      const dir = `${data.agents.agents[agent].skills_dir}/${skill}`;
      if (existsSync(join(project, dir)) && !Object.keys(known).some((f) => f.startsWith(`${dir}/`))) {
        plan.conflicts.push(dir);
        continue;
      }
      for (const file of walk(join(SKILLS_SRC, skill))) {
        const src = join(SKILLS_SRC, skill, file);
        let content = readFileSync(src);
        if (file === 'SKILL.md') content = Buffer.from(addGeneratedBy(content.toString('utf8'), tag));
        const path = `${dir}/${file}`;
        const hash = sha256(content);
        const write = { path, content, mode: statSync(src).mode };
        if (!existsSync(join(project, path))) {
          plan.writes.push({ ...write, kind: 'create' });
        } else if (!(path in known)) {
          plan.conflicts.push(path);
          continue;
        } else if (hashOf(project, path) === hash) {
          // already the new content
        } else if (hashOf(project, path) !== known[path] && !force) {
          plan.edited.push(path);
          plan.records[path] = known[path];
          continue;
        } else if (hashOf(project, path) !== hash) {
          plan.writes.push({ ...write, kind: 'update' });
        }
        plan.records[path] = hash;
      }
    }
  }

  // Generated files the suite no longer ships. Only paths inside a selected
  // agent's groma* skill folders qualify; other records are carried over.
  const dirs = agents.map((a) => `${data.agents.agents[a].skills_dir}/`);
  const ours = (path) => !path.split('/').includes('..') && dirs.some((d) => path.startsWith(d) && /^groma[^/]*\/./.test(path.slice(d.length)));
  for (const [path, hash] of Object.entries(known)) {
    if (path in plan.records || !existsSync(join(project, path))) continue;
    if (!ours(path)) plan.records[path] = hash;
    else if (hashOf(project, path) === hash) plan.removals.push(path);
    else { plan.edited.push(path); plan.records[path] = hash; }
  }
  return plan;
}

export function applySkills(project, plan, version) {
  for (const w of plan.writes) {
    const f = join(project, w.path);
    mkdirSync(dirname(f), { recursive: true });
    writeFileSync(f, w.content);
    chmodSync(f, w.mode & 0o777);
  }
  for (const path of plan.removals) {
    unlinkSync(join(project, path));
    // drop folders the removal left empty, up to the skill folder's parent
    for (let d = dirname(path); d.split('/').length > 2 && readdirSync(join(project, d)).length === 0; d = dirname(d)) {
      rmdirSync(join(project, d));
    }
  }
  mkdirSync(join(project, '.groma'), { recursive: true });
  const files = Object.fromEntries(Object.entries(plan.records).sort(([a], [b]) => a.localeCompare(b)));
  writeFileSync(join(project, GENERATED), JSON.stringify({ generatedBy: `groma@${version}`, files }, null, 2) + '\n');
}

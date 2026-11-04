// groma doctor: prerequisites, config validation, generated file check.
import { spawnSync } from 'node:child_process';
import { existsSync, readFileSync } from 'node:fs';
import { join } from 'node:path';
import { SKILLS_SRC, version } from './data.js';
import { readGenerated, sha256 } from './skills.js';
import { EXIT } from './main.js';

const sh = (script, args, env) => spawnSync('sh', [join(SKILLS_SRC, script), ...args], { encoding: 'utf8', env });

export default function doctor({ project, io, say }) {
  let errors = 0;

  const pre = sh('groma/scripts/check-prereqs.sh', [], io.env);
  if (pre.error) { say(`prerequisites: cannot run sh (${pre.error.message})`); return EXIT.prereq; }
  const missing = pre.stdout.split('\n').filter((l) => /\t(missing|too_old)\t/.test(l));
  for (const l of missing) say(`tool: ${l.split('\t').join(' · ')}`);
  say(`prerequisites: ${pre.status ? 'missing required tools' : 'ok'}`);

  const config = join(project, '.groma/config.yaml');
  if (!existsSync(config)) {
    say('config: not initialized, run npx groma init');
    errors++;
  } else {
    const v = sh('groma/scripts/validate-config.sh', [config, '--catalog', join(SKILLS_SRC, 'groma-skills/catalog.yaml')], io.env);
    for (const l of v.stdout.split('\n').filter((x) => /^(error|warning)\t/.test(x))) say(`config: ${l.split('\t').join(' ')}`);
    if (v.status) errors++;
    say(`config: ${v.status ? 'invalid' : 'ok'}`);
  }

  const gen = readGenerated(project);
  let warnings = 0;
  if (gen.generatedBy && gen.generatedBy !== `groma@${version()}`) {
    say(`warning: skill copies are ${gen.generatedBy}, this CLI is groma@${version()}: run npx groma update`);
    warnings++;
  }
  for (const [path, hash] of Object.entries(gen.files)) {
    const f = join(project, path);
    if (!existsSync(f)) { say(`warning: ${path} generated but missing`); warnings++; }
    else if (sha256(readFileSync(f)) !== hash) { say(`warning: ${path} edited since generation`); warnings++; }
  }
  say(`generated files: ${warnings ? `${warnings} warning(s)` : 'ok'}`);

  if (errors) return EXIT.error;
  return pre.status ? EXIT.prereq : EXIT.ok;
}

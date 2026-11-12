// groma next: the one next action, same output as next.sh.
import { spawnSync } from 'node:child_process';
import { join } from 'node:path';
import { SKILLS_SRC } from './data.js';

export default function next({ project, flags, io }) {
  const format = flags.json ? ['--json'] : flags.short ? ['--short'] : [];
  const r = spawnSync('sh', [join(SKILLS_SRC, 'groma-methodology/scripts/next.sh'), ...format, project], { encoding: 'utf8', env: io.env });
  if (r.error) { io.stderr.write(`groma: cannot run sh: ${r.error.message}\n`); return 1; }
  io.stdout.write(r.stdout ?? '');
  io.stderr.write(r.stderr ?? '');
  return r.status ?? 1;
}

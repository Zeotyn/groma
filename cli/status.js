// groma status: lifecycle reminders, same output as status.sh.
import { spawnSync } from 'node:child_process';
import { join } from 'node:path';
import { SKILLS_SRC } from './data.js';

export default function status({ project, io }) {
  const r = spawnSync('sh', [join(SKILLS_SRC, 'groma-methodology/scripts/status.sh'), '--root', project], { encoding: 'utf8', env: io.env });
  io.stdout.write(r.stdout ?? '');
  io.stderr.write(r.stderr ?? '');
  return r.status ?? 1;
}

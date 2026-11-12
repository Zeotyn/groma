// groma CLI entry: argument parsing, help, exit codes, dispatch.
import { parseArgs } from 'node:util';
import { statSync } from 'node:fs';
import { resolve } from 'node:path';
import { version } from './data.js';

export const EXIT = { ok: 0, error: 1, usage: 2, prereq: 3 };

const HELP = `Usage: groma <command> [path] [options]

Commands:
  init [path]     set up the project: groma skills, methodology, catalog skills, .groma/config.yaml
  update [path]   refresh generated skill copies, re-run pending steps
  status [path]   lifecycle reminders for open changes
  doctor [path]   check prerequisites, config and generated files
  next [path]     the one next action for this project (--short, --json)

Options for init and update:
  --agents <list|all|none>      claude,copilot,gemini,cursor,codex (default: detected)
  --methodology <id>            openspec | spec-kit | bmad | gsd | none
  --workflow <id>               workflow layer from the catalog, or none
  --skills <recommended|none|id,...>
  --review <autonomous|gated>
  --ui <yes|no>                 the project has a user interface
  -y, --yes                     take the recommended answer for every open question
  --print                       write commands to .groma/install.sh instead of running them
  --dry-run                     show planned files and commands, change nothing
  --force                       update: replace generated files you edited

  -h, --help                    show this help
  -v, --version                 print the groma version

Options for next:
  --short                       at most 20 characters, for a status line
  --json                        rung, short and long text as JSON

[path] defaults to the current directory. After init, open the project in your agent and run /groma.`;

const OPTIONS = {
  help: { type: 'boolean', short: 'h' },
  version: { type: 'boolean', short: 'v' },
  agents: { type: 'string' },
  methodology: { type: 'string' },
  workflow: { type: 'string' },
  skills: { type: 'string' },
  review: { type: 'string' },
  ui: { type: 'string' },
  yes: { type: 'boolean', short: 'y' },
  print: { type: 'boolean' },
  'dry-run': { type: 'boolean' },
  force: { type: 'boolean' },
  short: { type: 'boolean' },
  json: { type: 'boolean' },
};

const COMMANDS = ['init', 'update', 'status', 'doctor', 'next'];

export class UsageError extends Error {}

export async function main(argv, io = defaultIo()) {
  const say = (s = '') => io.stdout.write(s + '\n');
  const fail = (s) => io.stderr.write(s + '\n');

  const major = Number((io.nodeVersion ?? process.versions.node).split('.')[0]);
  if (major < 22) {
    fail(`Node 22 or newer required (found ${io.nodeVersion ?? process.versions.node})`);
    return EXIT.prereq;
  }

  let parsed;
  try {
    parsed = parseArgs({ args: argv, options: OPTIONS, allowPositionals: true, strict: true });
  } catch (e) {
    fail(`${e.message}\n\n${HELP}`);
    return EXIT.usage;
  }
  const { values: flags, positionals } = parsed;
  if (flags.help) { say(HELP); return EXIT.ok; }
  if (flags.version) { say(version()); return EXIT.ok; }

  const [command, path = '.', ...extra] = positionals;
  if (!command) { fail(HELP); return EXIT.usage; }
  if (!COMMANDS.includes(command)) { fail(`unknown command '${command}'\n\n${HELP}`); return EXIT.usage; }
  if (extra.length) { fail(`unexpected argument '${extra[0]}'`); return EXIT.usage; }
  if ((flags.short || flags.json) && command !== 'next') { fail(`--short and --json are only for 'next'`); return EXIT.usage; }

  const project = resolve(io.cwd ?? process.cwd(), path);
  if (!statSync(project, { throwIfNoEntry: false })?.isDirectory()) {
    fail(`not a directory: ${project}`);
    return EXIT.error;
  }

  const ctx = { project, flags, io, say, fail };
  try {
    const mod = await import(`./${command}.js`);
    return await mod.default(ctx);
  } catch (e) {
    if (e instanceof UsageError) { fail(e.message); return EXIT.usage; }
    fail(`groma: ${e.message}`);
    return EXIT.error;
  }
}

function defaultIo() {
  return { stdout: process.stdout, stderr: process.stderr, stdin: process.stdin, env: process.env };
}

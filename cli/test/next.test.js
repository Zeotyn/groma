import { test } from 'node:test';
import assert from 'node:assert/strict';
import { execFileSync } from 'node:child_process';
import { join } from 'node:path';
import { run, tmp, write } from './helpers.js';

const git = (cwd, ...args) => execFileSync('git', args, { cwd, encoding: 'utf8', stdio: ['ignore', 'pipe', 'ignore'] });

function commit(p, n) {
  write(p, 'a.txt', String(n));
  git(p, 'add', '-A');
  git(p, '-c', 'user.name=t', '-c', 'user.email=t@groma.invalid', '-c', 'commit.gpgsign=false', 'commit', '-q', '-m', `c${n}`);
}

// A repo whose main tracks a bare remote, with `ahead` commits not pushed.
function repo(ahead) {
  const root = tmp();
  const p = join(root, 'p');
  git(root, 'init', '-q', '--bare', 'r.git');
  git(root, 'init', '-q', '-b', 'main', 'p');
  commit(p, 0);
  git(p, 'remote', 'add', 'origin', join(root, 'r.git'));
  git(p, 'push', '-q', '-u', 'origin', 'main');
  for (let n = 1; n <= ahead; n++) commit(p, n);
  return p;
}

test('next prints the long line with the command', async () => {
  const r = await run(['next', repo(3)]);
  assert.equal(r.code, 0);
  assert.equal(r.out.trim(), 'Push 3 commits on main: git push');
});

test('next --short prints the pill text', async () => {
  const r = await run(['next', repo(3), '--short']);
  assert.equal(r.code, 0);
  assert.equal(r.out.trim(), 'push 3');
});

test('next --json prints rung, short and long', async () => {
  const r = await run(['next', repo(3), '--json']);
  assert.equal(r.code, 0);
  assert.deepEqual(JSON.parse(r.out), { rung: 6, short: 'push 3', long: 'Push 3 commits on main: git push' });
});

test('next prints nothing and exits 0 when nothing is open', async () => {
  const r = await run(['next', repo(0)]);
  assert.equal(r.code, 0);
  assert.equal(r.out, '');
});

test('--help lists next', async () => {
  const r = await run(['--help']);
  assert.match(r.out, /next \[path\]/);
});

test('next reports when sh cannot be started', async () => {
  const r = await run(['next', tmp()], { env: { PATH: '/nonexistent' } });
  assert.equal(r.code, 1);
  assert.match(r.err, /groma: .*sh/);
});

test('--short and --json belong to next only', async () => {
  for (const argv of [['status', '--short'], ['init', '--json']]) {
    const r = await run(argv);
    assert.equal(r.code, 2);
    assert.match(r.err, /only for 'next'/);
  }
});

#!/usr/bin/env bats

load helpers

SD="$ROOT/skills/groma-survey/scripts/style-drift.sh"
TABLE="$ROOT/skills/groma-lay-out/references/code-style-tools.md"

setup() {
  P="$BATS_TEST_TMPDIR/p"
  make_repo "$P"
}

sd() { run sh "$SD" "$@"; }

# write <path> with printf-style content, creating folders
w() { mkdir -p "$(dirname "$P/$1")"; printf "$2" > "$P/$1"; }

ec() { printf '%s\n' "$@" > "$P/.editorconfig"; }

# --- editorconfig properties ------------------------------------------------------

@test "indent_style = space: files indented with tabs drift" {
  ec '[*.py]' 'indent_style = space'
  w a.py 'def f():\n\treturn 1\n'
  w b.py 'def g():\n    return 2\n'
  w c.py 'class C:\n\tpass\n'
  commit_at "$P" 2025-01-01 init
  sd "$P"
  [ "$status" -eq 0 ]
  assert_output_contains "drift	indent_style	2	a.py c.py"
  assert_output_not_contains "b.py"
}

@test "indent_style = tab: files indented with spaces drift" {
  ec '[Makefile]' 'indent_style = tab'
  w Makefile 'all:\n    echo hi\n'
  commit_at "$P" 2025-01-01 init
  sd "$P"
  assert_output_contains "drift	indent_style	1	Makefile"
}

@test "end_of_line = lf: CRLF files drift" {
  ec '[*]' 'end_of_line = lf'
  w win.txt 'a\r\nb\r\n'
  w unix.txt 'a\nb\n'
  commit_at "$P" 2025-01-01 init
  sd "$P"
  assert_output_contains "drift	end_of_line	1	win.txt"
}

@test "insert_final_newline = true: files without a final newline drift" {
  ec '[*]' 'insert_final_newline = true'
  w no.txt 'no newline'
  w yes.txt 'newline\n'
  commit_at "$P" 2025-01-01 init
  sd "$P"
  assert_output_contains "drift	insert_final_newline	1	no.txt"
}

@test "trim_trailing_whitespace = true: trailing blanks drift" {
  ec '[*]' 'trim_trailing_whitespace = true'
  w t.js 'x = 1;  \n'
  w ok.js 'x = 1;\n'
  commit_at "$P" 2025-01-01 init
  sd "$P"
  assert_output_contains "drift	trim_trailing_whitespace	1	t.js"
}

@test "at most five examples, the count stays exact" {
  ec '[*.py]' 'indent_style = space'
  for i in 1 2 3 4 5 6 7; do w "f$i.py" 'def f():\n\treturn 1\n'; done
  commit_at "$P" 2025-01-01 init
  sd "$P"
  assert_output_contains "drift	indent_style	7	f1.py f2.py f3.py f4.py f5.py"
  assert_output_not_contains "f6.py"
}

@test "clean files: summary only" {
  ec '[*]' 'indent_style = space' 'end_of_line = lf' 'insert_final_newline = true' 'trim_trailing_whitespace = true'
  w a.py 'def f():\n    return 1\n'
  commit_at "$P" 2025-01-01 init
  sd "$P"
  [ "$status" -eq 0 ]
  assert_output_not_contains "drift	"
  assert_output_contains "summary	tools=1	drift=0	unchecked=0"
}

# --- sections ---------------------------------------------------------------------

@test "section globs: a later, more specific section overrides an earlier one" {
  ec '[*]' 'indent_style = space' '[*.{mk,go}]' 'indent_style = tab' '[docs/**]' 'trim_trailing_whitespace = false'
  w a.go 'func f() {\n\treturn\n}\n'
  w b.mk 'x:\n\techo\n'
  w c.py 'def f():\n\treturn 1\n'
  w docs/d.md 'two trailing  \n'
  commit_at "$P" 2025-01-01 init
  sd "$P"
  assert_output_contains "drift	indent_style	1	c.py"
  assert_output_not_contains "a.go"
  assert_output_not_contains "d.md"
}

@test "a glob without a slash matches at any depth, with a slash only from the root" {
  ec '[*.py]' 'indent_style = space' '[lib/*.rb]' 'indent_style = space'
  w deep/x/a.py 'def f():\n\treturn 1\n'
  w lib/b.rb 'def f\n\t1\nend\n'
  w other/lib/c.rb 'def f\n\t1\nend\n'
  commit_at "$P" 2025-01-01 init
  sd "$P"
  assert_output_contains "drift	indent_style	2	deep/x/a.py lib/b.rb"
  assert_output_not_contains "c.rb"
}

@test "untracked and binary files are ignored" {
  ec '[*]' 'indent_style = space' 'insert_final_newline = true'
  w a.py 'def f():\n    return 1\n'
  printf 'PNG\0\0\t\tbinary' > "$P/img.png"
  commit_at "$P" 2025-01-01 init
  w new.py 'def g():\n\treturn 2'
  sd "$P"
  assert_output_not_contains "drift	"
  assert_output_not_contains "new.py"
  assert_output_not_contains "img.png"
}

@test "no .editorconfig: no drift lines" {
  w a.py 'def f():\n\treturn 1  '
  commit_at "$P" 2025-01-01 init
  sd "$P"
  [ "$status" -eq 0 ]
  assert_output_not_contains "drift	"
  assert_output_contains "summary	tools=0	drift=0	unchecked=0"
}

# --- tools and unchecked ----------------------------------------------------------

@test "configured tools are listed with their config path and check command" {
  w .prettierrc '{}\n'
  w eslint.config.js 'export default [];\n'
  w ruff.toml 'line-length = 100\n'
  commit_at "$P" 2025-01-01 init
  sd "$P"
  assert_output_contains "tool	prettier	.prettierrc	npx prettier --check ."
  assert_output_contains "tool	eslint	eslint.config.js	npx eslint ."
  assert_output_contains "tool	ruff	ruff.toml	ruff check ."
  assert_output_contains "tools=3"
}

@test "a tool configured in a manifest section counts, a bare manifest does not" {
  w pyproject.toml '[project]\nname = "x"\n'
  commit_at "$P" 2025-01-01 init
  sd "$P"
  assert_output_not_contains "tool	ruff"
  w pyproject.toml '[project]\nname = "x"\n\n[tool.ruff]\nline-length = 100\n'
  sd "$P"
  assert_output_contains "tool	ruff	pyproject.toml	ruff check ."
}

@test "a configured tool that no workflow or script runs is unchecked" {
  w ruff.toml 'line-length = 100\n'
  commit_at "$P" 2025-01-01 init
  sd "$P"
  assert_output_contains "unchecked	ruff	ruff.toml"
  assert_output_contains "unchecked=1"
}

@test "a check in a GitHub workflow clears unchecked" {
  w ruff.toml 'line-length = 100\n'
  w .github/workflows/ci.yml 'jobs:\n  lint:\n    steps:\n      - run: ruff check .\n'
  commit_at "$P" 2025-01-01 init
  sd "$P"
  assert_output_not_contains "unchecked	ruff"
  assert_output_contains "unchecked=0"
}

@test "a package.json script clears unchecked, a devDependency alone does not" {
  w .prettierrc '{}\n'
  w package.json '{\n  "scripts": { "test": "node --test" },\n  "devDependencies": { "prettier": "3.3.3" }\n}\n'
  commit_at "$P" 2025-01-01 init
  sd "$P"
  assert_output_contains "unchecked	prettier	.prettierrc"
  w package.json '{\n  "scripts": {\n    "test": "node --test",\n    "format": "prettier --check ."\n  },\n  "devDependencies": { "prettier": "3.3.3" }\n}\n'
  sd "$P"
  assert_output_not_contains "unchecked	prettier"
}

@test "a Makefile target clears unchecked" {
  w ruff.toml 'line-length = 100\n'
  w Makefile 'lint:\n\truff check .\n'
  commit_at "$P" 2025-01-01 init
  sd "$P"
  assert_output_not_contains "unchecked	ruff"
}

@test "a tool without a check command is never unchecked" {
  ec '[*]' 'indent_style = space'
  commit_at "$P" 2025-01-01 init
  sd "$P"
  assert_output_contains "tool	editorconfig	.editorconfig	"
  assert_output_not_contains "unchecked	editorconfig"
}

@test "missing reference table: note, no tools, drift still reported" {
  ec '[*.py]' 'indent_style = space'
  w a.py 'def f():\n\treturn 1\n'
  commit_at "$P" 2025-01-01 init
  sd --table "$BATS_TEST_TMPDIR/nope.md" "$P"
  [ "$status" -eq 0 ]
  assert_output_contains "note	style tools not detected (groma-lay-out missing)"
  assert_output_not_contains "tool	editorconfig"
  assert_output_contains "drift	indent_style	1	a.py"
}

# --- fixtures ---------------------------------------------------------------------

@test "django fixture: tab drift against editorconfig and ruff unchecked" {
  sh "$ROOT/tests/fixtures/generate.sh" "$BATS_TEST_TMPDIR/f" python-django-stale-docs >/dev/null
  sd "$BATS_TEST_TMPDIR/f/python-django-stale-docs"
  assert_output_contains "drift	indent_style	3	shop/admin.py shop/forms.py shop/urls.py"
  assert_output_contains "unchecked	ruff	ruff.toml"
  assert_output_contains "tool	editorconfig	.editorconfig"
}

@test "node-prisma fixture: prettier and eslint found, eslint checked by npm run lint" {
  sh "$ROOT/tests/fixtures/generate.sh" "$BATS_TEST_TMPDIR/f" node-prisma >/dev/null
  sd "$BATS_TEST_TMPDIR/f/node-prisma"
  assert_output_contains "tool	prettier	.prettierrc"
  assert_output_contains "tool	eslint	eslint.config.js"
  assert_output_contains "unchecked	prettier	.prettierrc"
  assert_output_not_contains "unchecked	eslint"
}

@test "is read-only" {
  ec '[*]' 'indent_style = space'
  w a.py 'def f():\n\treturn 1\n'
  commit_at "$P" 2025-01-01 init
  sh "$SD" "$P" >/dev/null
  [ -z "$(git -C "$P" status --porcelain)" ]
}

@test "unknown option exits 2" {
  sd --nope "$P"
  [ "$status" -eq 2 ]
}

@test "the shipped table has every tool the tests rely on" {
  for t in editorconfig prettier eslint biome ruff gofmt golangci-lint rustfmt clippy spotless rubocop shellcheck shfmt; do
    grep -qi "| $t |" "$TABLE" || { echo "missing row: $t"; return 1; }
  done
}

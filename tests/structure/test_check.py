"""Unit tests for the structure checks themselves."""
import json
import textwrap
from pathlib import Path

import pytest

import check


@pytest.fixture(autouse=True)
def reset_errors():
    check.errors.clear()
    yield
    check.errors.clear()


def write(p: Path, text: str) -> None:
    p.parent.mkdir(parents=True, exist_ok=True)
    p.write_text(textwrap.dedent(text), encoding="utf-8")


def good_catalog() -> dict:
    return {
        "schema": 1,
        "skills": {
            "ponytail": {"title": "ponytail", "description": "d", "source": "a/b", "ref": "v1"},
        },
        "categories": {
            "pragmatism": {
                "description": "d",
                "select": "single",
                "options": ["ponytail", "none"],
                "recommended": "ponytail",
            }
        },
    }


def test_skill_name_must_match_folder(tmp_path):
    write(tmp_path / "skills/groma-x/SKILL.md", "---\nname: groma-y\ndescription: d\n---\n")
    check.check_skills(tmp_path)
    assert any("does not match folder" in e for e in check.errors)


def test_skill_prefix_required(tmp_path):
    write(tmp_path / "skills/other/SKILL.md", "---\nname: other\ndescription: d\n---\n")
    check.check_skills(tmp_path)
    assert any("start with 'groma-'" in e for e in check.errors)


def test_valid_skill_passes(tmp_path):
    write(tmp_path / "skills/groma-x/SKILL.md", "---\nname: groma-x\ndescription: does x\n---\n")
    check.check_skills(tmp_path)
    assert check.errors == []


def test_broken_link_detected(tmp_path):
    write(tmp_path / "README.md", "see [x](missing.md) and [ok](README.md)\n")
    check.check_links(tmp_path)
    assert check.errors == ["README.md: broken link 'missing.md'"]


def test_links_in_code_blocks_ignored(tmp_path):
    write(tmp_path / "README.md", "```\n[x](missing.md)\n```\n")
    check.check_links(tmp_path)
    assert check.errors == []


def test_valid_catalog_passes():
    check.validate_catalog(good_catalog(), "c")
    assert check.errors == []


def test_catalog_unknown_option():
    c = good_catalog()
    c["categories"]["pragmatism"]["options"] = ["ponytial", "none"]
    c["categories"]["pragmatism"]["recommended"] = "ponytial"
    check.validate_catalog(c, "c")
    assert any("'ponytial' is not defined" in e for e in check.errors)


def test_catalog_requires_none_option():
    c = good_catalog()
    c["categories"]["pragmatism"]["options"] = ["ponytail", "ponytail"]
    check.validate_catalog(c, "c")
    assert any("must include 'none'" in e for e in check.errors)


def test_catalog_unknown_condition():
    c = good_catalog()
    c["categories"]["pragmatism"]["condition"] = "has_gpu"
    check.validate_catalog(c, "c")
    assert any("unknown condition" in e for e in check.errors)


def test_catalog_plugin_needs_marketplace():
    c = good_catalog()
    c["skills"]["ponytail"]["claude_plugin"] = "ponytail@ponytail"
    check.validate_catalog(c, "c")
    assert any("requires 'marketplace'" in e for e in check.errors)


def test_versions_must_match(tmp_path):
    write(tmp_path / ".claude-plugin/plugin.json", json.dumps({"name": "groma", "version": "0.1.0"}))
    write(tmp_path / "gemini-extension.json", json.dumps({"name": "groma", "version": "0.2.0"}))
    check.check_versions(tmp_path)
    assert any("versions differ" in e for e in check.errors)


def test_changelog_release_must_match(tmp_path):
    write(tmp_path / ".claude-plugin/plugin.json", json.dumps({"name": "groma", "version": "0.1.0"}))
    write(tmp_path / "CHANGELOG.md", "## [Unreleased]\n\n## [0.2.0] - 2026-11-04\n")
    check.check_versions(tmp_path)
    assert any("latest release 0.2.0" in e for e in check.errors)


def test_changelog_unreleased_only_is_fine(tmp_path):
    write(tmp_path / ".claude-plugin/plugin.json", json.dumps({"name": "groma", "version": "0.1.0"}))
    write(tmp_path / "CHANGELOG.md", "## [Unreleased]\n")
    check.check_versions(tmp_path)
    assert check.errors == []


def write_manifests(root, **overrides):
    base = {"name": "groma", "version": "0.1.0", "description": "d"}
    for rel in check.REQUIRED_FIELDS:
        write(root / rel, json.dumps({**base, **overrides.get(rel, {})}))
    mp = overrides.get("marketplace", {"name": "groma", "owner": {"name": "o"}, "plugins": [{"name": "groma", "source": "./"}]})
    write(root / ".claude-plugin/marketplace.json", json.dumps(mp))


def test_valid_manifests_pass(tmp_path):
    write_manifests(tmp_path)
    check.check_manifests(tmp_path)
    assert check.errors == []


def test_manifest_missing_description(tmp_path):
    write_manifests(tmp_path, **{"gemini-extension.json": {"description": ""}})
    check.check_manifests(tmp_path)
    assert any("gemini-extension.json: required field 'description'" in e for e in check.errors)


def test_marketplace_plugin_needs_source_and_matching_name(tmp_path):
    write_manifests(tmp_path, marketplace={"name": "groma", "owner": {"name": "o"}, "plugins": [{"name": "other"}]})
    check.check_manifests(tmp_path)
    assert any("plugins[0].source missing" in e for e in check.errors)
    assert any("does not match plugin.json name" in e for e in check.errors)


def test_marketplace_known_bundle_names_pass(tmp_path):
    plugins = [{"name": "groma", "source": "./"}, {"name": "groma-docs", "source": "./"}]
    write_manifests(tmp_path, marketplace={"name": "groma", "owner": {"name": "o"}, "plugins": plugins})
    check.check_manifests(tmp_path)
    assert check.errors == []


def test_marketplace_unknown_prefixed_name_fails(tmp_path):
    plugins = [{"name": "groma", "source": "./"}, {"name": "groma-extra", "source": "./"}]
    write_manifests(tmp_path, marketplace={"name": "groma", "owner": {"name": "o"}, "plugins": plugins})
    check.check_manifests(tmp_path)
    assert any("'groma-extra' does not match plugin.json name" in e for e in check.errors)


def write_skill(root, name):
    write(root / f"skills/{name}/SKILL.md", f"---\nname: {name}\ndescription: d\n---\n")


def good_bundles() -> list[dict]:
    entries = []
    for name, skills in check.BUNDLES.items():
        e = {"name": name, "source": "./", "version": "0.1.0"}
        if skills is not None:
            e["skills"] = [f"./skills/{s}" for s in skills]
        entries.append(e)
    return entries


def write_bundles(root, plugins):
    for skills in check.BUNDLES.values():
        for s in skills or []:
            write_skill(root, s)
    write(root / ".claude-plugin/marketplace.json", json.dumps({"name": "groma", "plugins": plugins}))


def test_bundles_valid_pass(tmp_path):
    write_bundles(tmp_path, good_bundles())
    check.check_bundles(tmp_path)
    assert check.errors == []


def test_bundle_missing_is_named(tmp_path):
    write_bundles(tmp_path, [e for e in good_bundles() if e["name"] != "groma-loop"])
    check.check_bundles(tmp_path)
    assert any("bundle 'groma-loop' missing" in e for e in check.errors)


def test_bundle_with_wrong_skills_fails(tmp_path):
    plugins = good_bundles()
    plugins[1]["skills"] = ["./skills/groma-detect"]
    write_bundles(tmp_path, plugins)
    check.check_bundles(tmp_path)
    assert any("groma-docs: skills must be" in e for e in check.errors)


def test_bundle_skill_folder_must_exist(tmp_path):
    plugins = good_bundles()
    write_bundles(tmp_path, plugins)
    (tmp_path / "skills/groma-loop/SKILL.md").unlink()
    check.check_bundles(tmp_path)
    assert any("./skills/groma-loop has no SKILL.md" in e for e in check.errors)


def test_bundle_needs_root_source_and_version(tmp_path):
    plugins = good_bundles()
    plugins[2]["source"] = "./bundles/loop"
    del plugins[2]["version"]
    write_bundles(tmp_path, plugins)
    check.check_bundles(tmp_path)
    assert any("groma-loop: source must be './'" in e for e in check.errors)
    assert any("groma-loop: version missing" in e for e in check.errors)


def test_bundle_version_must_be_semver(tmp_path):
    plugins = good_bundles()
    plugins[1]["version"] = ""
    plugins[2]["version"] = "latest"
    write_bundles(tmp_path, plugins)
    check.check_bundles(tmp_path)
    assert any("groma-docs: version '' is not SemVer" in e for e in check.errors)
    assert any("groma-loop: version 'latest' is not SemVer" in e for e in check.errors)


def test_bundle_unknown_or_twice_fails(tmp_path):
    plugins = good_bundles() + [{"name": "groma-extra", "source": "./", "version": "0.1.0"}, good_bundles()[0]]
    write_bundles(tmp_path, plugins)
    check.check_bundles(tmp_path)
    assert any("'groma-extra' is not a known bundle" in e for e in check.errors)
    assert any("'groma' listed twice" in e for e in check.errors)


def test_bundle_versions_are_compared(tmp_path):
    plugins = good_bundles()
    plugins[1]["version"] = "0.0.9"
    write(tmp_path / ".claude-plugin/plugin.json", json.dumps({"name": "groma", "version": "0.1.0"}))
    write_bundles(tmp_path, plugins)
    check.check_versions(tmp_path)
    assert any("marketplace.json:groma-docs=0.0.9" in e for e in check.errors)


def write_hooks(root, **overrides):
    def command(script):
        return f'sh "${{CLAUDE_PLUGIN_ROOT}}/skills/groma-m/scripts/{script}" "$CLAUDE_PROJECT_DIR" 2>/dev/null || true'

    hooks = {
        "SessionStart": [{"matcher": "startup|resume|clear|compact", "hooks": [{"type": "command", "command": command("next-session.sh"), "timeout": 10}]}],
        "Stop": [{"hooks": [{"type": "command", "command": command("next-stop.sh").replace(' "$CLAUDE_PROJECT', ' --plugin "$CLAUDE_PROJECT'), "timeout": 10}]}],
    }
    hooks.update(overrides)
    write(root / "hooks/hooks.json", json.dumps({"hooks": {k: v for k, v in hooks.items() if v is not None}}))
    for script in ("next-session.sh", "next-stop.sh"):
        write(root / "skills/groma-m/scripts" / script, "#!/bin/sh\n")


def test_valid_plugin_hooks_pass(tmp_path):
    write_hooks(tmp_path)
    check.check_hooks(tmp_path)
    assert check.errors == []


def test_shipped_plugin_hooks_pass():
    check.check_hooks()
    assert check.errors == []


def test_plugin_hooks_file_missing(tmp_path):
    check.check_hooks(tmp_path)
    assert check.errors == ["hooks/hooks.json: missing"]


def test_plugin_hooks_events_are_fixed(tmp_path):
    write_hooks(tmp_path, UserPromptSubmit=[{"hooks": []}])
    check.check_hooks(tmp_path)
    assert any("must hold exactly ['SessionStart', 'Stop']" in e for e in check.errors)
    check.errors.clear()
    write_hooks(tmp_path, Stop=None)
    check.check_hooks(tmp_path)
    assert any("must hold exactly" in e for e in check.errors)


def test_plugin_hooks_command_must_silence_stderr(tmp_path):
    write_hooks(tmp_path, Stop=[{"hooks": [
        {"type": "command", "command": 'sh "${CLAUDE_PLUGIN_ROOT}/skills/groma-m/scripts/next-stop.sh" "$CLAUDE_PROJECT_DIR" || true', "timeout": 10},
    ]}])
    check.check_hooks(tmp_path)
    assert check.errors == ["hooks/hooks.json: Stop command must end with '2>/dev/null || true', so that a missing script never fails the hook or prints"]


def test_plugin_hooks_session_matcher(tmp_path):
    write_hooks(tmp_path, SessionStart=[{"matcher": "startup", "hooks": [{"type": "command", "command": 'sh "${CLAUDE_PLUGIN_ROOT}/skills/groma-m/scripts/next-session.sh" "$CLAUDE_PROJECT_DIR" || true'}]}])
    check.check_hooks(tmp_path)
    assert any("SessionStart matcher must be 'startup|resume|clear|compact'" in e for e in check.errors)


def test_plugin_hooks_command_must_run_a_shipped_script_and_never_fail(tmp_path):
    write_hooks(tmp_path, Stop=[{"hooks": [
        {"type": "command", "command": 'sh "${CLAUDE_PLUGIN_ROOT}/skills/groma-m/scripts/gone.sh" "$CLAUDE_PROJECT_DIR" || true'},
        {"type": "command", "command": 'sh "${CLAUDE_PLUGIN_ROOT}/skills/groma-m/scripts/next-stop.sh" "$CLAUDE_PROJECT_DIR"'},
        {"type": "command", "command": "sh /abs/next-stop.sh"},
    ]}])
    check.check_hooks(tmp_path)
    assert any("Stop runs skills/groma-m/scripts/gone.sh, which is not a file under skills/" in e for e in check.errors)
    assert any("Stop command must end with '2>/dev/null || true'" in e for e in check.errors)
    assert any("Stop command needs a 'timeout' of 1 to 60 seconds" in e for e in check.errors)
    assert any("Stop command must be of type command and start with" in e for e in check.errors)


def good_agents() -> dict:
    agent = {"skills_dir": ".claude/skills", "home_marker": "~/.claude", "npx_skills_id": "claude-code", "instructions": "CLAUDE.md"}
    hook = {"status": "stable", "event": "Stop", "config": ".claude/settings.local.json", "format": "systemMessage"}
    return {
        "schema": 1,
        "agents": {a: {**agent, "hook": dict(hook)} for a in check.AGENT_IDS},
        "commands": {k: "x" for k in check.AGENT_COMMANDS},
        "touches": {"npx_skills": ["skills-lock.json"], "claude_plugin": [".claude/settings.json"]},
    }


def test_valid_agents_passes():
    check.validate_agents(good_agents(), "a")
    assert check.errors == []


def test_agents_field_missing():
    a = good_agents()
    del a["agents"]["copilot"]["skills_dir"]
    check.validate_agents(a, "a")
    assert any("agents.copilot: 'skills_dir' missing" in e for e in check.errors)


def test_agents_must_cover_every_agent():
    a = good_agents()
    del a["agents"]["codex"]
    check.validate_agents(a, "a")
    assert any("codex" in e for e in check.errors)


def test_agents_command_missing():
    a = good_agents()
    del a["commands"]["npx_skills"]
    check.validate_agents(a, "a")
    assert any("commands.npx_skills" in e for e in check.errors)


def test_agents_hook_missing():
    a = good_agents()
    del a["agents"]["gemini"]["hook"]
    check.validate_agents(a, "a")
    assert any("agents.gemini: hook.status" in e for e in check.errors)


def test_agents_hook_status_invalid():
    a = good_agents()
    a["agents"]["copilot"]["hook"]["status"] = "spike"
    check.validate_agents(a, "a")
    assert any("agents.copilot: hook.status must be one of" in e and "spike" in e for e in check.errors)


def test_agents_hook_needs_event_unless_none():
    a = good_agents()
    del a["agents"]["claude"]["hook"]["event"]
    a["agents"]["cursor"]["hook"] = {"status": "none"}
    check.validate_agents(a, "a")
    assert check.errors == ["a: agents.claude: hook.event missing"]


def good_methodologies() -> dict:
    m = {
        "detect": ["openspec/"],
        "requires": ["npx"],
        "init": "npx x --tools {agents} .",
        "agent_ids": {"claude": "claude"},
        "touches": ["openspec/"],
        "interactive": False,
    }
    data = {"schema": 1, "methodologies": {k: dict(m) for k in check.METHODOLOGY_IDS if k != "none"}}
    data["methodologies"]["none"] = {}
    return data


def test_valid_methodologies_passes():
    check.validate_methodologies(good_methodologies(), "m")
    assert check.errors == []


def test_methodology_unknown_agent_in_agent_ids():
    m = good_methodologies()
    m["methodologies"]["openspec"]["agent_ids"] = {"claud": "claude"}
    check.validate_methodologies(m, "m")
    assert any("unknown agent 'claud'" in e for e in check.errors)


def test_methodology_init_needs_agents_placeholder_with_agent_ids():
    m = good_methodologies()
    m["methodologies"]["openspec"]["init"] = "npx x init ."
    check.validate_methodologies(m, "m")
    assert any("{agents}" in e for e in check.errors)


def test_methodology_missing():
    m = good_methodologies()
    del m["methodologies"]["gsd"]
    check.validate_methodologies(m, "m")
    assert any("'gsd' missing" in e for e in check.errors)


def test_package_json_version_must_match(tmp_path):
    write(tmp_path / ".claude-plugin/plugin.json", json.dumps({"name": "groma", "version": "0.1.0"}))
    write(tmp_path / "package.json", json.dumps({"name": "groma", "version": "0.2.0"}))
    check.check_versions(tmp_path)
    assert any("package.json=0.2.0" in e for e in check.errors)


def test_openspec_docs_link_has_living_docs_rules():
    import yaml

    recipes = yaml.safe_load((check.ROOT / check.METHODOLOGIES).read_text(encoding="utf-8"))
    rules = yaml.safe_load(recipes["methodologies"]["openspec"]["docs_link"]["append"])["rules"]
    for key in ("proposal", "tasks", "design"):
        assert all(isinstance(r, str) for r in rules[key]), key
    assert any("## Docs impact" in r for r in rules["proposal"])
    assert any("Docs: <path> unchanged, because" in r for r in rules["tasks"])
    assert any("Alternatives" in r for r in rules["design"])


def good_code_style_table() -> str:
    return textwrap.dedent("""\
        # Tools

        | Stack | Tool | Role | Config patterns | Check | Fix | Install | Template | Default |
        |---|---|---|---|---|---|---|---|---|
        | all | EditorConfig | format | `.editorconfig` | | | | `editorconfig/.editorconfig` | yes |
        | Python | Ruff | format, lint | `ruff.toml`, `pyproject.toml#[tool.ruff]` | `ruff check .` | `ruff format .` | `uv add --dev ruff` | `ruff/ruff.toml` | yes |
        | Python | Black | format | `pyproject.toml#[tool.black]` | `black --check .` | `black .` | `uv add --dev black` | | no |

        ## Where checks run

        | Kind | Pattern | Command |
        |---|---|---|
        | package-scripts | `package.json` | `npm run {script}` |
        | targets | `Makefile` | `make {target}` |
        | file | `.github/workflows/*.yml` | `{line}` |

        ## Runner prefixes

        | Prefix |
        |---|
        | `npx` |
        """)


def write_code_style_templates(tmp_path: Path) -> Path:
    t = tmp_path / "templates"
    write(t / "editorconfig/.editorconfig", "root = true\n")
    write(t / "ruff/ruff.toml", "line-length = 100\n")
    return t


def test_valid_code_style_table_passes(tmp_path):
    check.validate_code_style_table(good_code_style_table(), "t", write_code_style_templates(tmp_path))
    assert check.errors == []


def test_code_style_table_needs_exact_columns(tmp_path):
    text = good_code_style_table().replace("| Install |", "| Installer |")
    check.validate_code_style_table(text, "t", write_code_style_templates(tmp_path))
    assert any("columns must be" in e for e in check.errors)


def test_code_style_two_defaults_per_stack_and_role(tmp_path):
    text = good_code_style_table().replace("`uv add --dev black` | | no |", "`uv add --dev black` | | yes |")
    check.validate_code_style_table(text, "t", write_code_style_templates(tmp_path))
    assert any("stack 'Python' role 'format' needs exactly one default" in e for e in check.errors)


def test_code_style_missing_default_for_stack_and_role(tmp_path):
    text = good_code_style_table().replace("`ruff/ruff.toml` | yes |", "`ruff/ruff.toml` | no |")
    check.validate_code_style_table(text, "t", write_code_style_templates(tmp_path))
    assert any("role 'lint' needs exactly one default, has none" in e for e in check.errors)


def test_code_style_template_must_exist(tmp_path):
    text = good_code_style_table().replace("`ruff/ruff.toml`", "`ruff/missing.toml`")
    check.validate_code_style_table(text, "t", write_code_style_templates(tmp_path))
    assert any("template 'ruff/missing.toml' not found" in e for e in check.errors)


def test_code_style_unknown_role(tmp_path):
    text = good_code_style_table().replace("| format, lint |", "| style |")
    check.validate_code_style_table(text, "t", write_code_style_templates(tmp_path))
    assert any("role must be one or more of" in e for e in check.errors)


def test_code_style_locations_table_required(tmp_path):
    text = good_code_style_table().split("## Where checks run")[0]
    check.validate_code_style_table(text, "t", write_code_style_templates(tmp_path))
    assert any("where checks run" in e for e in check.errors)
    assert any("runner prefixes" in e for e in check.errors)


def test_code_style_location_needs_known_kind_and_command(tmp_path):
    text = good_code_style_table().replace("| targets | `Makefile` | `make {target}` |", "| make | `Makefile` | |")
    check.validate_code_style_table(text, "t", write_code_style_templates(tmp_path))
    assert any("needs a kind in" in e for e in check.errors)


def test_code_style_runner_prefix_table_must_have_rows(tmp_path):
    text = good_code_style_table().replace("| `npx` |\n", "")
    check.validate_code_style_table(text, "t", write_code_style_templates(tmp_path))
    assert any("runner prefixes" in e for e in check.errors)


def test_shipped_hook_adapters():
    agents = check.yaml.safe_load((check.ROOT / "skills/groma/agents.yaml").read_text())["agents"]
    assert agents["claude"]["hook"]["status"] == "stable"
    assert agents["cursor"]["hook"] == {"status": "none"}  # no display-only channel


def shared_repo(tmp_path: Path, copy: str = "table\n") -> None:
    write(tmp_path / "skills/groma-a/references/t.md", "table\n")
    write(tmp_path / "skills/groma-b/references/t.md", copy)
    write(tmp_path / "scripts/shared-files.txt", "# c\nskills/groma-a/references/t.md -> skills/groma-b/references/t.md\n")


def test_shared_identical_copy_passes(tmp_path):
    shared_repo(tmp_path)
    check.check_shared(tmp_path)
    assert check.errors == []


def test_shared_drifted_copy_names_the_source(tmp_path):
    shared_repo(tmp_path, "edited\n")
    check.check_shared(tmp_path)
    assert any("differs from skills/groma-a/references/t.md" in e for e in check.errors)


def test_shared_missing_copy_and_bad_line(tmp_path):
    shared_repo(tmp_path)
    (tmp_path / "skills/groma-b/references/t.md").unlink()
    (tmp_path / "scripts/shared-files.txt").write_text(
        "skills/groma-a/references/t.md -> skills/groma-b/references/t.md\nonly-one-path\n")
    check.check_shared(tmp_path)
    assert any("vendored copy missing" in e for e in check.errors)
    assert any("expected '<source> -> <consumer>'" in e for e in check.errors)


def test_handoffs_unlisted_sibling_reference_fails(tmp_path):
    write(tmp_path / "skills/groma-a/SKILL.md", "Read `../groma-b/references/t.md` and follow `../groma-b/SKILL.md` "
          "(missing: `npx skills add Zeotyn/groma --skill groma-b`).\n")
    write(tmp_path / "scripts/handoffs.txt", "# c\nskills/groma-a/SKILL.md ../groma-b/SKILL.md\n")
    check.check_handoffs(tmp_path)
    assert len(check.errors) == 1
    assert "'../groma-b/references/t.md' points into a sibling skill" in check.errors[0]


def test_handoffs_stale_entry_fails(tmp_path):
    write(tmp_path / "skills/groma-a/SKILL.md", "Nothing here.\n")
    write(tmp_path / "scripts/handoffs.txt", "skills/groma-a/SKILL.md ../groma-b/SKILL.md\n")
    check.check_handoffs(tmp_path)
    assert any("listed but not found" in e for e in check.errors)


def test_handoffs_need_the_install_message(tmp_path):
    write(tmp_path / "skills/groma-a/SKILL.md", "Follow `../groma-b/SKILL.md`; else `npx skills add Zeotyn/groma --skill groma-c`.\n")
    write(tmp_path / "scripts/handoffs.txt", "skills/groma-a/SKILL.md ../groma-b/SKILL.md\n")
    check.check_handoffs(tmp_path)
    assert any("needs the message `npx skills add Zeotyn/groma --skill groma-b`" in e for e in check.errors)


def test_handoffs_generic_install_message_counts(tmp_path):
    write(tmp_path / "skills/groma-a/SKILL.md", "Follow `../groma-b/SKILL.md`; missing: `npx skills add Zeotyn/groma --skill <name>`.\n")
    write(tmp_path / "scripts/handoffs.txt", "skills/groma-a/SKILL.md ../groma-b/SKILL.md\n")
    check.check_handoffs(tmp_path)
    assert check.errors == []

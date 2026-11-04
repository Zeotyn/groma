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


def good_agents() -> dict:
    agent = {"skills_dir": ".claude/skills", "home_marker": "~/.claude", "npx_skills_id": "claude-code", "instructions": "CLAUDE.md"}
    return {
        "schema": 1,
        "agents": {a: dict(agent) for a in check.AGENT_IDS},
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

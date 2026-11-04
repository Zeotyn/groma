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

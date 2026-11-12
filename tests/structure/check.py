#!/usr/bin/env python3
"""Structure checks for the groma repository (test level 1).

Usage: uv run --with pyyaml python tests/structure/check.py [skills|links|published|catalog|agents|methodologies|manifests|versions|code-style|shared|handoffs|all]
Exit code 0 when all selected checks pass, 1 otherwise.
"""
from __future__ import annotations

import json
import re
import sys
from pathlib import Path

import yaml

ROOT = Path(__file__).resolve().parents[2]
NAME_RE = re.compile(r"^[a-z0-9]+(-[a-z0-9]+)*$")
SEMVER_RE = re.compile(r"^\d+\.\d+\.\d+(-[0-9A-Za-z.-]+)?$")
SOURCE_RE = re.compile(r"^[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+$")
KNOWN_CONDITIONS = {"has_ui", "greenfield", "brownfield"}
LINK_SCAN_DIRS = ["skills", "tests", "docs"]
LINK_SCAN_FILES = ["README.md", "CONTRIBUTING.md", "AGENTS.md", "CHANGELOG.md"]
CATALOG = "skills/groma-skills/catalog.yaml"
AGENTS = "skills/groma/agents.yaml"
METHODOLOGIES = "skills/groma-methodology/methodologies.yaml"
AGENT_IDS = ["claude", "copilot", "gemini", "cursor", "codex"]
AGENT_FIELDS = ["skills_dir", "home_marker", "npx_skills_id", "instructions"]
HOOK_STATUSES = ["stable", "experimental", "none"]
HOOK_FIELDS = ["event", "config", "format"]
AGENT_COMMANDS = ["npx_skills", "plugin_marketplace", "plugin_install"]
METHODOLOGY_IDS = ["openspec", "spec-kit", "bmad", "gsd", "none"]
MANIFESTS = [
    ".claude-plugin/plugin.json",
    ".codex-plugin/plugin.json",
    ".cursor-plugin/plugin.json",
    "gemini-extension.json",
]

errors: list[str] = []


def err(msg: str) -> None:
    errors.append(msg)


def frontmatter(path: Path) -> dict | None:
    text = path.read_text(encoding="utf-8")
    if not text.startswith("---\n"):
        return None
    end = text.find("\n---", 4)
    if end == -1:
        return None
    data = yaml.safe_load(text[4:end])
    return data if isinstance(data, dict) else None


def check_skills(root: Path = ROOT) -> None:
    skills_dir = root / "skills"
    if not skills_dir.is_dir():
        err("skills/: directory missing")
        return
    for skill in sorted(p for p in skills_dir.iterdir() if p.is_dir()):
        md = skill / "SKILL.md"
        rel = md.relative_to(root)
        if not md.is_file():
            err(f"{rel}: missing")
            continue
        fm = frontmatter(md)
        if fm is None:
            err(f"{rel}: no YAML frontmatter")
            continue
        name = fm.get("name")
        if name != skill.name:
            err(f"{rel}: name '{name}' does not match folder '{skill.name}'")
        if not isinstance(name, str) or not NAME_RE.match(name or "") or len(name) > 64:
            err(f"{rel}: name must be lowercase kebab-case, max 64 chars")
        if skill.name != "groma" and not skill.name.startswith("groma-"):
            err(f"{rel}: folder must be 'groma' or start with 'groma-'")
        desc = fm.get("description")
        if not isinstance(desc, str) or not desc.strip():
            err(f"{rel}: description missing")
        elif len(desc) > 1024:
            err(f"{rel}: description has {len(desc)} chars, max 1024")


LINK_RE = re.compile(r"\[[^\]]*\]\(([^)\s]+)(?:\s+\"[^\"]*\")?\)")


def iter_markdown(root: Path):
    for f in LINK_SCAN_FILES:
        p = root / f
        if p.is_file():
            yield p
    for d in LINK_SCAN_DIRS:
        base = root / d
        if base.is_dir():
            for p in base.rglob("*.md"):
                if ".work" not in p.parts:
                    yield p


def check_published_skills(root: Path = ROOT) -> None:
    """Only skills/ may ship SKILL.md files; others must be git-ignored."""
    import subprocess

    for md in root.rglob("SKILL.md"):
        rel = md.relative_to(root)
        if rel.parts[0] in ("skills", "tests") or ".git" in rel.parts:
            continue
        ignored = subprocess.run(
            ["git", "-C", str(root), "check-ignore", "-q", str(rel)], capture_output=True
        ).returncode == 0
        if not ignored:
            err(f"{rel}: SKILL.md outside skills/ would be offered by `npx skills add`; git-ignore it or move it")


def check_links(root: Path = ROOT) -> None:
    for md in iter_markdown(root):
        text = md.read_text(encoding="utf-8")
        # ignore fenced code blocks
        text = re.sub(r"```.*?```", "", text, flags=re.S)
        for target in LINK_RE.findall(text):
            if re.match(r"^[a-z]+:", target) or target.startswith("#"):
                continue
            if "{{" in target or "<" in target:
                continue  # template placeholder
            path = target.split("#", 1)[0]
            if not path:
                continue
            resolved = (md.parent / path).resolve()
            if not resolved.exists():
                err(f"{md.relative_to(root)}: broken link '{target}'")


def check_catalog(root: Path = ROOT) -> None:
    path = root / CATALOG
    if not path.is_file():
        err(f"{CATALOG}: missing")
        return
    data = yaml.safe_load(path.read_text(encoding="utf-8")) or {}
    validate_catalog(data, CATALOG)


def validate_catalog(data: dict, label: str) -> None:
    if data.get("schema") != 1:
        err(f"{label}: schema must be 1")
    skills = data.get("skills") or {}
    categories = data.get("categories") or {}
    if not isinstance(skills, dict) or not skills:
        err(f"{label}: 'skills' must be a non-empty mapping")
        skills = {}
    if not isinstance(categories, dict) or not categories:
        err(f"{label}: 'categories' must be a non-empty mapping")
        categories = {}
    for sid, s in skills.items():
        where = f"{label}: skills.{sid}"
        if sid == "none":
            err(f"{where}: 'none' is reserved")
        if not NAME_RE.match(str(sid)):
            err(f"{where}: id must be kebab-case")
        if not isinstance(s, dict):
            err(f"{where}: must be a mapping")
            continue
        for key in ("title", "description", "source", "ref"):
            if not s.get(key):
                err(f"{where}: '{key}' missing")
        if s.get("source") and not SOURCE_RE.match(str(s["source"])):
            err(f"{where}: source must be 'owner/repo'")
        if s.get("claude_plugin") and "@" not in str(s["claude_plugin"]):
            err(f"{where}: claude_plugin must be 'plugin@marketplace'")
        if s.get("claude_plugin") and not s.get("marketplace"):
            err(f"{where}: claude_plugin requires 'marketplace'")
        sk = s.get("skills", ["*"])
        if not isinstance(sk, list) or not sk:
            err(f"{where}: 'skills' must be a non-empty list")
    for cid, c in categories.items():
        where = f"{label}: categories.{cid}"
        if not isinstance(c, dict):
            err(f"{where}: must be a mapping")
            continue
        if c.get("select") not in ("single", "multi"):
            err(f"{where}: select must be 'single' or 'multi'")
        if not c.get("description"):
            err(f"{where}: description missing")
        cond = c.get("condition")
        if cond is not None and cond not in KNOWN_CONDITIONS:
            err(f"{where}: unknown condition '{cond}' (known: {sorted(KNOWN_CONDITIONS)})")
        options = c.get("options") or []
        if not isinstance(options, list) or len(options) < 2:
            err(f"{where}: needs at least two options")
            options = []
        if "none" not in options:
            err(f"{where}: options must include 'none'")
        for o in options:
            if o != "none" and o not in skills:
                err(f"{where}: option '{o}' is not defined in skills")
        rec = c.get("recommended")
        recs = rec if isinstance(rec, list) else [rec]
        if c.get("select") == "single" and isinstance(rec, list):
            err(f"{where}: single-select category needs one recommended value")
        for r in recs:
            if r not in options:
                err(f"{where}: recommended '{r}' is not an option")


def load_yaml(root: Path, rel: str) -> dict | None:
    path = root / rel
    if not path.is_file():
        err(f"{rel}: missing")
        return None
    return yaml.safe_load(path.read_text(encoding="utf-8")) or {}


def check_agents(root: Path = ROOT) -> None:
    data = load_yaml(root, AGENTS)
    if data is not None:
        validate_agents(data, AGENTS)


def validate_agents(data: dict, label: str) -> None:
    if data.get("schema") != 1:
        err(f"{label}: schema must be 1")
    agents = data.get("agents") or {}
    for a in AGENT_IDS:
        if a not in agents:
            err(f"{label}: agents.{a} missing")
    for a, entry in agents.items():
        if a not in AGENT_IDS:
            err(f"{label}: unknown agent '{a}' (known: {AGENT_IDS})")
            continue
        for f in AGENT_FIELDS:
            if not (entry or {}).get(f):
                err(f"{label}: agents.{a}: '{f}' missing")
        hook = (entry or {}).get("hook") or {}
        status = hook.get("status")
        if status not in HOOK_STATUSES:
            err(f"{label}: agents.{a}: hook.status must be one of {HOOK_STATUSES}, got '{status}'")
        elif status != "none":
            for f in HOOK_FIELDS:
                if not hook.get(f):
                    err(f"{label}: agents.{a}: hook.{f} missing")
    commands = data.get("commands") or {}
    for c in AGENT_COMMANDS:
        if not commands.get(c):
            err(f"{label}: commands.{c} missing")
    for k, paths in (data.get("touches") or {}).items():
        if not isinstance(paths, list):
            err(f"{label}: touches.{k} must be a list")


def check_methodologies(root: Path = ROOT) -> None:
    data = load_yaml(root, METHODOLOGIES)
    if data is not None:
        validate_methodologies(data, METHODOLOGIES)


def validate_methodologies(data: dict, label: str) -> None:
    if data.get("schema") != 1:
        err(f"{label}: schema must be 1")
    entries = data.get("methodologies") or {}
    for m in METHODOLOGY_IDS:
        if m not in entries:
            err(f"{label}: methodology '{m}' missing")
    for m, e in entries.items():
        where = f"{label}: methodologies.{m}"
        if m not in METHODOLOGY_IDS:
            err(f"{where}: unknown methodology (known: {METHODOLOGY_IDS})")
            continue
        if m == "none":
            continue
        e = e or {}
        for f in ("detect", "requires", "touches"):
            if not isinstance(e.get(f), list):
                err(f"{where}: '{f}' must be a list")
        if not e.get("init"):
            err(f"{where}: 'init' missing")
        if not isinstance(e.get("interactive"), bool):
            err(f"{where}: 'interactive' must be true or false")
        ids = e.get("agent_ids") or {}
        for a in ids:
            if a not in AGENT_IDS:
                err(f"{where}: unknown agent '{a}' in agent_ids")
        if ids and "{agents}" not in str(e.get("init", "")):
            err(f"{where}: init must contain {{agents}} when agent_ids is set")


REQUIRED_FIELDS = {
    ".claude-plugin/plugin.json": ["name", "version", "description"],
    ".codex-plugin/plugin.json": ["name", "version", "description"],
    ".cursor-plugin/plugin.json": ["name", "version", "description"],
    "gemini-extension.json": ["name", "version", "description"],
}


def check_manifests(root: Path = ROOT) -> None:
    """Required fields of every shipped manifest and the marketplace."""
    names = set()
    for rel, fields in REQUIRED_FIELDS.items():
        p = root / rel
        if not p.is_file():
            err(f"{rel}: missing")
            continue
        try:
            data = json.loads(p.read_text(encoding="utf-8"))
        except json.JSONDecodeError as e:
            err(f"{rel}: invalid JSON ({e})")
            continue
        for f in fields:
            if not isinstance(data.get(f), str) or not data[f].strip():
                err(f"{rel}: required field '{f}' missing or empty")
        if data.get("name"):
            names.add(data["name"])
    if len(names) > 1:
        err(f"manifests use different plugin names: {sorted(names)}")
    mp = root / ".claude-plugin" / "marketplace.json"
    if not mp.is_file():
        err(".claude-plugin/marketplace.json: missing")
        return
    try:
        data = json.loads(mp.read_text(encoding="utf-8"))
    except json.JSONDecodeError as e:
        err(f".claude-plugin/marketplace.json: invalid JSON ({e})")
        return
    if not data.get("name"):
        err(".claude-plugin/marketplace.json: required field 'name' missing")
    if not (data.get("owner") or {}).get("name"):
        err(".claude-plugin/marketplace.json: required field 'owner.name' missing")
    plugins = data.get("plugins") or []
    if not plugins:
        err(".claude-plugin/marketplace.json: 'plugins' must list at least one plugin")
    for i, entry in enumerate(plugins):
        for f in ("name", "source"):
            if not entry.get(f):
                err(f".claude-plugin/marketplace.json: plugins[{i}].{f} missing")
        if names and entry.get("name") and entry["name"] not in names:
            err(f".claude-plugin/marketplace.json: plugins[{i}].name '{entry['name']}' does not match plugin.json name")


CODE_STYLE_TABLE = "skills/groma-lay-out/references/code-style-tools.md"
CODE_STYLE_TEMPLATES = "skills/groma-lay-out/templates/code-style"
CODE_STYLE_COLUMNS = ["Stack", "Tool", "Role", "Config patterns", "Check", "Fix", "Install", "Template", "Default"]
CODE_STYLE_ROLES = {"format", "lint"}
CHECK_LOCATION_KINDS = {"file", "package-scripts", "targets"}
CHECK_LOCATION_COLUMNS = ["Kind", "Pattern", "Command"]


def markdown_tables(text: str) -> list[list[list[str]]]:
    """Every pipe table in `text` as rows of stripped cells (header first, separator dropped)."""
    tables: list[list[list[str]]] = []
    current: list[list[str]] = []
    for line in text.splitlines():
        if line.startswith("|"):
            cells = [c.strip() for c in line.strip().strip("|").split("|")]
            if all(re.fullmatch(r":?-+:?", c) for c in cells):
                continue
            current.append(cells)
        elif current:
            tables.append(current)
            current = []
    if current:
        tables.append(current)
    return tables


def check_code_style_table(root: Path = ROOT) -> None:
    """Reference table of style tools: columns, roles, one default per stack and role, templates exist."""
    path = root / CODE_STYLE_TABLE
    if not path.is_file():
        err(f"{CODE_STYLE_TABLE}: missing")
        return
    validate_code_style_table(path.read_text(encoding="utf-8"), CODE_STYLE_TABLE, root / CODE_STYLE_TEMPLATES)


def validate_code_style_table(text: str, label: str, templates: Path) -> None:
    tables = markdown_tables(text)
    tools = next((t for t in tables if t and t[0][:1] == ["Stack"]), None)
    if tools is None:
        err(f"{label}: no table with the columns {CODE_STYLE_COLUMNS}")
        return
    if tools[0] != CODE_STYLE_COLUMNS:
        err(f"{label}: columns must be {CODE_STYLE_COLUMNS}, got {tools[0]}")
        return
    defaults: dict[tuple[str, str], list[str]] = {}
    seen: set[str] = set()
    for row in tools[1:]:
        if len(row) != len(CODE_STYLE_COLUMNS):
            err(f"{label}: row {row[:2]} has {len(row)} cells, expected {len(CODE_STYLE_COLUMNS)}")
            continue
        stack, tool, role, patterns, _check, _fix, _install, template, default = row
        where = f"{label}: {tool}"
        if not tool:
            err(f"{label}: row without a tool name")
            continue
        if tool.lower() in seen:
            err(f"{where}: listed twice")
        seen.add(tool.lower())
        roles = [r.strip() for r in role.split(",") if r.strip()]
        if not roles or not set(roles) <= CODE_STYLE_ROLES:
            err(f"{where}: role must be one or more of {sorted(CODE_STYLE_ROLES)}, got '{role}'")
        if not patterns.strip("` "):
            err(f"{where}: config patterns missing")
        if default not in ("yes", "no"):
            err(f"{where}: default must be 'yes' or 'no', got '{default}'")
        for st in [x.strip() for x in stack.split(",") if x.strip()]:
            for r in roles:
                defaults.setdefault((st, r), [])
                if default == "yes":
                    defaults[(st, r)].append(tool)
        template = template.strip("`")
        if template and not (templates / template).is_file():
            err(f"{where}: template '{template}' not found under {templates.name}/")
    for (stack, r), names in sorted(defaults.items()):
        if len(names) != 1:
            err(f"{label}: stack '{stack}' role '{r}' needs exactly one default, has {names or 'none'}")
    locations = next((t for t in tables if t and t[0][:1] == ["Kind"]), None)
    if locations is None or locations[0] != CHECK_LOCATION_COLUMNS:
        err(f"{label}: no table with the columns {CHECK_LOCATION_COLUMNS} (where checks run)")
    else:
        for row in locations[1:]:
            if len(row) != 3 or row[0] not in CHECK_LOCATION_KINDS or not row[1].strip("` "):
                err(f"{label}: check location {row[:2]} needs a kind in {sorted(CHECK_LOCATION_KINDS)}, a pattern and a command")
    prefixes = next((t for t in tables if t and t[0] == ["Prefix"]), None)
    if prefixes is None or len(prefixes) < 2:
        err(f"{label}: no non-empty table with the column ['Prefix'] (runner prefixes)")
    else:
        for row in prefixes[1:]:
            if len(row) != 1 or not row[0].strip("` "):
                err(f"{label}: runner prefix row {row} must hold one command prefix")


def check_versions(root: Path = ROOT) -> None:
    versions: dict[str, str] = {}
    for m in MANIFESTS:
        p = root / m
        if p.is_file():
            try:
                v = json.loads(p.read_text(encoding="utf-8")).get("version")
            except json.JSONDecodeError as e:
                err(f"{m}: invalid JSON ({e})")
                continue
            if not isinstance(v, str) or not SEMVER_RE.match(v):
                err(f"{m}: version '{v}' is not SemVer")
            else:
                versions[m] = v
    mp = root / ".claude-plugin" / "marketplace.json"
    if mp.is_file():
        try:
            for entry in json.loads(mp.read_text(encoding="utf-8")).get("plugins", []):
                if "version" in entry:
                    versions[f"{mp.relative_to(root)}:{entry.get('name')}"] = entry["version"]
        except json.JSONDecodeError as e:
            err(f".claude-plugin/marketplace.json: invalid JSON ({e})")
    pkg = root / "package.json"
    if pkg.is_file():
        try:
            versions["package.json"] = json.loads(pkg.read_text(encoding="utf-8")).get("version")
        except json.JSONDecodeError as e:
            err(f"package.json: invalid JSON ({e})")
    vf = root / "skills" / "groma" / "VERSION"
    if vf.is_file():
        versions["skills/groma/VERSION"] = vf.read_text(encoding="utf-8").strip()
    distinct = set(versions.values())
    if len(distinct) > 1:
        err("manifest versions differ: " + ", ".join(f"{k}={v}" for k, v in sorted(versions.items())))
    changelog = root / "CHANGELOG.md"
    if changelog.is_file() and distinct:
        released = re.findall(r"^## \[(\d+\.\d+\.\d+[^\]]*)\]", changelog.read_text(encoding="utf-8"), re.M)
        version = next(iter(distinct))
        if released and released[0] != version:
            err(f"CHANGELOG.md: latest release {released[0]} != manifest version {version}")


SHARED_MANIFEST = "scripts/shared-files.txt"
HANDOFFS = "scripts/handoffs.txt"
INSTALL_HINT = "npx skills add Zeotyn/groma --skill "
SIBLING_REF_RE = re.compile(r"(?:\.\./)+groma[a-z-]*/[A-Za-z0-9_./-]*")


def shared_pairs(root: Path = ROOT) -> list[tuple[str, str]]:
    """`<source> -> <consumer>` lines of the shared-files manifest."""
    path = root / SHARED_MANIFEST
    if not path.is_file():
        err(f"{SHARED_MANIFEST}: missing")
        return []
    pairs: list[tuple[str, str]] = []
    for n, line in enumerate(path.read_text(encoding="utf-8").splitlines(), 1):
        line = line.strip()
        if not line or line.startswith("#"):
            continue
        parts = line.split()
        if len(parts) != 3 or parts[1] != "->":
            err(f"{SHARED_MANIFEST}:{n}: expected '<source> -> <consumer>', got '{line}'")
            continue
        pairs.append((parts[0], parts[2]))
    return pairs


def check_shared(root: Path = ROOT) -> None:
    """Every vendored copy is byte-identical to its source (ADR 0051)."""
    pairs = shared_pairs(root)
    consumers: set[str] = set()
    for source, consumer in pairs:
        for rel in (source, consumer):
            if not rel.startswith("skills/"):
                err(f"{SHARED_MANIFEST}: '{rel}' must live under skills/")
        if source.split("/")[:2] == consumer.split("/")[:2]:
            err(f"{SHARED_MANIFEST}: '{consumer}' is in the same skill as its source")
        if consumer in consumers:
            err(f"{SHARED_MANIFEST}: '{consumer}' listed twice")
        consumers.add(consumer)
        src, dst = root / source, root / consumer
        if not src.is_file():
            err(f"{source}: shared source missing")
            continue
        if not dst.is_file():
            err(f"{consumer}: vendored copy missing; run scripts/sync-shared.sh")
        elif src.read_bytes() != dst.read_bytes():
            err(f"{consumer}: differs from {source}; edit the source, then run scripts/sync-shared.sh")
    sources = {s for s, _ in pairs}
    for c in sorted(consumers & sources):
        err(f"{SHARED_MANIFEST}: '{c}' is both a source and a copy")


def check_handoffs(root: Path = ROOT) -> None:
    """No skill file points into a sibling skill folder except a listed procedure hand-off."""
    path = root / HANDOFFS
    if not path.is_file():
        err(f"{HANDOFFS}: missing")
        return
    allowed: set[tuple[str, str]] = set()
    for line in path.read_text(encoding="utf-8").splitlines():
        parts = line.split()
        if len(parts) == 2 and not line.startswith("#"):
            allowed.add((parts[0], parts[1]))
    seen: set[tuple[str, str]] = set()
    skills_dir = root / "skills"
    if not skills_dir.is_dir():
        return
    for f in sorted(p for p in skills_dir.rglob("*") if p.is_file()):
        try:
            text = f.read_text(encoding="utf-8")
        except UnicodeDecodeError:
            continue
        rel = f.relative_to(root).as_posix()
        for ref in SIBLING_REF_RE.findall(text):
            seen.add((rel, ref))
            if (rel, ref) not in allowed:
                err(f"{rel}: '{ref}' points into a sibling skill; vendor the file (scripts/shared-files.txt) or list a procedure hand-off in {HANDOFFS}")
    for rel, ref in sorted(allowed - seen):
        err(f"{HANDOFFS}: '{rel} {ref}' is listed but not found")
    for rel, ref in sorted(allowed & seen):
        sibling = re.match(r"(?:\.\./)+(groma[a-z-]*)/", ref).group(1)
        text = (root / rel).read_text(encoding="utf-8")
        if f"{INSTALL_HINT}{sibling}`" not in text and f"{INSTALL_HINT}<name>`" not in text:
            err(f"{rel}: hand-off to {sibling} needs the message `{INSTALL_HINT}{sibling}` for when it is missing")


CHECKS = {
    "skills": check_skills,
    "links": check_links,
    "published": check_published_skills,
    "catalog": check_catalog,
    "agents": check_agents,
    "methodologies": check_methodologies,
    "manifests": check_manifests,
    "versions": check_versions,
    "code-style": check_code_style_table,
    "shared": check_shared,
    "handoffs": check_handoffs,
}


def main(argv: list[str]) -> int:
    selected = argv[1:] or ["all"]
    names = list(CHECKS) if "all" in selected else selected
    for n in names:
        if n not in CHECKS:
            print(f"unknown check '{n}'", file=sys.stderr)
            return 2
        before = len(errors)
        CHECKS[n]()
        status = "ok" if len(errors) == before else f"{len(errors) - before} error(s)"
        print(f"[structure:{n}] {status}")
    for e in errors:
        print(f"  ✗ {e}")
    return 1 if errors else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))

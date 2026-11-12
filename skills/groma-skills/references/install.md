# Installing catalog skills

All installs are **project scope**: the skill is active in this project only. Pin every install to the catalog `ref`.

Command templates, agent ids and touched paths live in [../agents.yaml](../agents.yaml), a copy of the groma skill's `agents.yaml`, the data the `groma` CLI reads. The `groma` CLI (`npx groma-cli init`) produces the same commands from the same data.

## Building the commands

For each picked catalog entry, in this order:

1. **Custom `install`:** the entry's `install` command replaces everything below; run it once regardless of agents.
2. **Claude plugin:** when the entry has `claude_plugin` and `claude` is a configured agent (`plugins: true`): `commands.plugin_marketplace` (skip when `marketplace` is in `builtin_marketplaces`), then `commands.plugin_install`.
3. **npx skills:** one `commands.npx_skills` call for all remaining agents (claude only when step 2 did not apply). `{skills}` is `--skill '*'` when the entry lists `['*']`, otherwise one `--skill <name>` per listed skill; `{agents}` is one `-a <npx_skills_id>` per agent.

Entries with `post_install` (for example `/impeccable init`): tell the user to run it inside their agent once; it cannot be run from a shell.

## Asking first

Follow [install-consent.md](install-consent.md): ask before an installer touches an existing file or installs outside the project; on no, refusal or failure write `.groma/install.sh`.

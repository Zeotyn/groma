## ADDED Requirements

### Requirement: OpenSpec generations
groma SHALL support projects set up with OpenSpec 1.x and with OpenSpec 2.x. It SHALL tell them apart only from files in the project: an `opsx` command folder of any configured agent means 1.x; OpenSpec skills without such a folder mean 2.x. When both are present it SHALL use the 1.x form, because those commands still work. The marker paths and the command form of each generation SHALL live in the shared recipe data, and the files a 2.x install writes (`.agents/skills/openspec-*`) SHALL count as files the recipe touches.

#### Scenario: Project upgraded to OpenSpec 2.x
- **WHEN** a groma project ran `openspec update` with OpenSpec 2.x, which removed `.claude/commands/opsx/` and wrote `.agents/skills/openspec-*`
- **THEN** groma prints `/openspec-<step>` commands and treats `.agents/skills/openspec-*` as OpenSpec's files, not as unknown changes

#### Scenario: Half-finished upgrade
- **WHEN** a project has both `.claude/commands/opsx/` and `.agents/skills/openspec-*`
- **THEN** groma prints `/opsx:<step>` commands

#### Scenario: Agent-neutral wording
- **WHEN** groma writes the methodology hint into AGENTS.md or groma-loop names the propose step
- **THEN** the text names the OpenSpec workflow so that it is right for both generations, for example "the OpenSpec propose skill (`/openspec-propose`, or `/opsx:propose` with OpenSpec 1.x)"

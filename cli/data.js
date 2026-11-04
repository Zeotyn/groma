// Shared data: suite version, agent table, methodology recipes, skill catalog.
import { readFileSync } from 'node:fs';
import { join, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';
import { parse } from 'yaml';

export const PKG_ROOT = join(dirname(fileURLToPath(import.meta.url)), '..');
export const SKILLS_SRC = join(PKG_ROOT, 'skills');

const read = (rel) => readFileSync(join(SKILLS_SRC, rel), 'utf8');

export function version() {
  return read('groma/VERSION').trim();
}

export function loadData() {
  return {
    version: version(),
    agents: parse(read('groma/agents.yaml')),
    methodologies: parse(read('groma-methodology/methodologies.yaml')).methodologies,
    catalog: parse(read('groma-skills/catalog.yaml')),
    configTemplate: read('groma/templates/config.yaml'),
  };
}

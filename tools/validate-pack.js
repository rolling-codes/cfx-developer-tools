#!/usr/bin/env node
// validate-pack.js — static consistency checker for cfx-developer-tools
// Usage: node tools/validate-pack.js
// Exit 0 = all checks pass. Exit 1 = one or more failures listed.

const fs = require('fs');
const path = require('path');

const ROOT = path.resolve(__dirname, '..');
const SKILLS_DIR = path.join(ROOT, 'skills');
const PLUGIN_JSON = path.join(ROOT, '.claude-plugin', 'plugin.json');
const REQUIRED_FRONTMATTER = ['name', 'description', 'model', 'allowed-tools', 'last-verified', 'volatility'];
const VALID_VOLATILITY = new Set(['high', 'medium', 'low']);
const VALID_MODELS = new Set(['haiku', 'sonnet', 'opus']);
const MIN_SKILL_COUNT = 11;

const failures = [];

function fail(msg) {
  failures.push(msg);
}

// Parse YAML frontmatter between --- markers
function parseFrontmatter(content) {
  const match = content.match(/^---\r?\n([\s\S]*?)\r?\n---/);
  if (!match) return null;
  const fields = {};
  for (const line of match[1].split('\n')) {
    const m = line.match(/^([\w-]+)\s*:\s*(.+)/);
    if (m) fields[m[1].trim()] = m[2].trim().replace(/^['"]|['"]$/g, '');
  }
  return fields;
}

// 1. plugin.json is valid JSON with required fields
try {
  const plugin = JSON.parse(fs.readFileSync(PLUGIN_JSON, 'utf8'));
  if (!plugin.name) fail('plugin.json: missing "name" field');
  if (!plugin.version) fail('plugin.json: missing "version" field');
} catch (e) {
  fail(`plugin.json: failed to parse — ${e.message}`);
}

// 2. skills/ directory exists
if (!fs.existsSync(SKILLS_DIR)) {
  fail('skills/ directory not found at pack root');
  process.exit(1);
}

// 3. Enumerate skill directories
const skillDirs = fs.readdirSync(SKILLS_DIR).filter(d =>
  fs.statSync(path.join(SKILLS_DIR, d)).isDirectory()
);

// 4. Minimum skill count
if (skillDirs.length < MIN_SKILL_COUNT) {
  fail(`Expected at least ${MIN_SKILL_COUNT} skills, found ${skillDirs.length}`);
}

// 5. Per-skill checks
for (const dir of skillDirs) {
  const skillPath = path.join(SKILLS_DIR, dir, 'SKILL.md');

  // 5a. SKILL.md exists
  if (!fs.existsSync(skillPath)) {
    fail(`${dir}: missing SKILL.md`);
    continue;
  }

  const content = fs.readFileSync(skillPath, 'utf8');
  const fm = parseFrontmatter(content);

  if (!fm) {
    fail(`${dir}: no valid frontmatter block found`);
    continue;
  }

  // 5b. Required fields present
  for (const field of REQUIRED_FRONTMATTER) {
    if (!fm[field]) fail(`${dir}: missing frontmatter field "${field}"`);
  }

  // 5c. name matches directory
  if (fm.name && fm.name !== dir) {
    fail(`${dir}: frontmatter "name" (${fm.name}) does not match directory name`);
  }

  // 5d. volatility is valid
  if (fm.volatility && !VALID_VOLATILITY.has(fm.volatility)) {
    fail(`${dir}: invalid volatility "${fm.volatility}" — must be high, medium, or low`);
  }

  // 5e. last-verified is a valid ISO date (YYYY-MM-DD)
  if (fm['last-verified']) {
    const d = new Date(fm['last-verified']);
    if (isNaN(d.getTime()) || !/^\d{4}-\d{2}-\d{2}$/.test(fm['last-verified'])) {
      fail(`${dir}: last-verified "${fm['last-verified']}" is not a valid YYYY-MM-DD date`);
    }
  }

  // 5f. model is a known value
  if (fm.model && !VALID_MODELS.has(fm.model)) {
    fail(`${dir}: unknown model "${fm.model}" — expected haiku, sonnet, or opus`);
  }
}

// Report
if (failures.length === 0) {
  console.log(`✓ validate-pack: all checks passed (${skillDirs.length} skills)`);
  process.exit(0);
} else {
  console.error(`✗ validate-pack: ${failures.length} failure(s):`);
  for (const f of failures) console.error(`  - ${f}`);
  process.exit(1);
}

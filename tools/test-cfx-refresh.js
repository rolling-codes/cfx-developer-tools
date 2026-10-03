#!/usr/bin/env node
// test-cfx-refresh.js — behavioral tests for the cfx-refresh skill algorithm
// Implements the staleness detection logic from skills/cfx-refresh/SKILL.md
// and asserts correct behavior across 8 edge-case scenarios.
// Usage: node tools/test-cfx-refresh.js
// Exit 0 = all pass. Exit 1 = failures listed.

const THRESHOLDS = { high: 60, medium: 90, low: 180 };
const WATCH_BUFFER = 14;

// Parse YAML frontmatter — returns error object on any failure (never null/throw)
function parseFrontmatter(content) {
  const match = content.match(/^---\r?\n([\s\S]*?)\r?\n---/);
  if (!match) return { error: 'no frontmatter block found' };
  const fields = {};
  for (const line of match[1].split('\n')) {
    const m = line.match(/^([\w-]+)\s*:\s*(.+)/);
    if (m) fields[m[1].trim()] = m[2].trim().replace(/^['"]|['"]$/g, '');
  }
  if (!fields['last-verified']) return { error: 'missing last-verified field', fields };
  if (!fields.volatility) return { error: 'missing volatility field', fields };
  return fields;
}

function getDaysSince(dateStr, now) {
  const then = new Date(dateStr);
  if (isNaN(then.getTime())) return null;
  return Math.floor((now - then) / (1000 * 60 * 60 * 24));
}

// Core algorithm — mirrors the workflow in cfx-refresh/SKILL.md
// upstreamTag: { name: string, releasedAt: string } | null
// fetchFailed: true if the upstream HTTP request failed
function assessStaleness(lastVerified, volatility, upstreamTag, fetchFailed, now) {
  const threshold = THRESHOLDS[volatility];
  if (!threshold) return { status: 'ERROR', reason: `unknown volatility: ${volatility}` };

  const days = getDaysSince(lastVerified, now);
  if (days === null) return { status: 'ERROR', reason: `invalid date: ${lastVerified}` };

  // Fetch failure: upstream state is unknown — never collapse to OK
  if (fetchFailed) {
    const dateStatus = days > threshold ? 'STALE' : (days > threshold - WATCH_BUFFER ? 'WATCH' : 'OK');
    return {
      status: dateStatus === 'OK' ? 'WATCH' : dateStatus,
      days,
      upstream: 'UNABLE_TO_VERIFY',
      reason: 'upstream fetch failed — cannot confirm current; WATCH minimum applied'
    };
  }

  if (days > threshold) {
    return { status: 'STALE', days, reason: `${days}d exceeds ${threshold}d threshold for ${volatility}` };
  }
  if (days > threshold - WATCH_BUFFER) {
    return { status: 'WATCH', days, reason: `within ${WATCH_BUFFER}d of ${threshold}d threshold` };
  }
  if (upstreamTag && new Date(upstreamTag.releasedAt) > new Date(lastVerified)) {
    return { status: 'WATCH', days, reason: `upstream ${upstreamTag.name} released after last-verified` };
  }
  return { status: 'OK', days };
}

// ── Harness ───────────────────────────────────────────────────────────────────

let passed = 0;
let failed = 0;

const NOW = new Date('2026-10-03T12:00:00Z');

function daysAgo(n) {
  const d = new Date(NOW);
  d.setDate(d.getDate() - n);
  return d.toISOString().split('T')[0];
}

function assert(label, condition, detail) {
  if (condition) {
    console.log(`  ✓  ${label}`);
    passed++;
  } else {
    console.error(`  ✗  ${label}${detail ? `  →  ${detail}` : ''}`);
    failed++;
  }
}

// ── 1. Fresh skills → no warnings ────────────────────────────────────────────
console.log('\n1. Fresh skills → no unnecessary warnings');
for (const v of ['high', 'medium', 'low']) {
  const r = assessStaleness(daysAgo(1), v, null, false, NOW);
  assert(`1 day old, volatility=${v} → OK`, r.status === 'OK', `got ${r.status}`);
}

// ── 2. Old high-volatility → STALE, top priority ─────────────────────────────
console.log('\n2. Old high-volatility skill → highest-priority (STALE)');
{
  const r = assessStaleness(daysAgo(200), 'high', null, false, NOW);
  assert('200 days, high → STALE', r.status === 'STALE', `got ${r.status}`);
  assert('days field populated', typeof r.days === 'number' && r.days > 0, `got ${r.days}`);
}

// ── 3. Old low-volatility → lower priority than high ─────────────────────────
console.log('\n3. Old low-volatility → lower priority than high at same age');
{
  // 100 days: past high threshold (60) but within low threshold (180)
  const highR = assessStaleness(daysAgo(100), 'high', null, false, NOW);
  const lowR  = assessStaleness(daysAgo(100), 'low',  null, false, NOW);
  assert('100 days, high → STALE', highR.status === 'STALE', `got ${highR.status}`);
  assert('100 days, low  → not STALE (OK or WATCH)', lowR.status !== 'STALE', `got ${lowR.status}`);
}

// ── 4. Recent + new upstream release → WATCH ─────────────────────────────────
console.log('\n4. Recent verification + new upstream release → WATCH');
{
  const lastVerified = daysAgo(30);
  const tag = { name: 'v2.10.0', releasedAt: daysAgo(15) }; // released after last-verified
  const r = assessStaleness(lastVerified, 'high', tag, false, NOW);
  assert('30d old, upstream released 15d ago → WATCH', r.status === 'WATCH', `got ${r.status}`);
  assert('reason names the upstream release', r.reason.includes('v2.10.0'), `reason: ${r.reason}`);
}

// ── 5. Old + no upstream changes → age-stale, not confirmed break ─────────────
console.log('\n5. Old verification + no new upstream → STALE by age, reason cites threshold');
{
  const lastVerified = daysAgo(70); // past 60-day high threshold
  const oldTag = { name: 'v2.9.0', releasedAt: daysAgo(200) }; // released before last-verified
  const r = assessStaleness(lastVerified, 'high', oldTag, false, NOW);
  assert('70d, high, old upstream → STALE', r.status === 'STALE', `got ${r.status}`);
  assert('reason cites threshold, not upstream', r.reason.includes('threshold'), `reason: ${r.reason}`);
  assert('reason does NOT claim upstream changed', !r.reason.includes('upstream'), `reason: ${r.reason}`);
}

// ── 6. Malformed/missing frontmatter → error object, not silent skip ──────────
console.log('\n6. Malformed frontmatter → error object, never silent skip');
{
  const missingLV = `---\nname: test\nvolatility: high\n---\nbody`;
  const fm1 = parseFrontmatter(missingLV);
  assert('missing last-verified → { error: ... }', typeof fm1.error === 'string', JSON.stringify(fm1));

  const noBlock = `# Just a body\nNo YAML here at all.`;
  const fm2 = parseFrontmatter(noBlock);
  assert('no frontmatter block → { error: ... }', typeof fm2.error === 'string', JSON.stringify(fm2));

  const emptyBlock = `---\n---\nbody`;
  const fm3 = parseFrontmatter(emptyBlock);
  assert('empty frontmatter → { error: ... }', typeof fm3.error === 'string', JSON.stringify(fm3));
}

// ── 7. Upstream fetch failure → UNABLE_TO_VERIFY, never OK ───────────────────
console.log('\n7. Upstream fetch failure → UNABLE_TO_VERIFY, not OK');
{
  // Fresh skill: 5 days old, high → would normally be OK; fetch failure must not let it be OK
  const fresh = assessStaleness(daysAgo(5), 'high', null, true, NOW);
  assert('fresh + fetch fail → not OK', fresh.status !== 'OK', `got ${fresh.status}`);
  assert('upstream field = UNABLE_TO_VERIFY', fresh.upstream === 'UNABLE_TO_VERIFY', `got ${fresh.upstream}`);

  // Old skill: 200 days old, high → STALE + UNABLE_TO_VERIFY (must still show STALE)
  const old = assessStaleness(daysAgo(200), 'high', null, true, NOW);
  assert('old + fetch fail → STALE (not downgraded)', old.status === 'STALE', `got ${old.status}`);
  assert('upstream still UNABLE_TO_VERIFY on stale', old.upstream === 'UNABLE_TO_VERIFY', `got ${old.upstream}`);
}

// ── 8. Deterministic output ───────────────────────────────────────────────────
console.log('\n8. Deterministic output — two identical runs → identical results');
{
  const args = [daysAgo(45), 'high', { name: 'v2.9.0', releasedAt: daysAgo(200) }, false, NOW];
  const r1 = assessStaleness(...args);
  const r2 = assessStaleness(...args);
  assert('status identical across runs', r1.status === r2.status, `${r1.status} vs ${r2.status}`);
  assert('days identical across runs',   r1.days === r2.days,     `${r1.days} vs ${r2.days}`);
  assert('reason identical across runs', r1.reason === r2.reason, `"${r1.reason}" vs "${r2.reason}"`);
}

// ── Summary ───────────────────────────────────────────────────────────────────
const total = passed + failed;
console.log(`\n${total} assertions: ${passed} passed, ${failed} failed`);
process.exit(failed > 0 ? 1 : 0);

// Collects the numbers shown in the deck from the isa-research repo.
// Usage: node scripts/collect_facts.mjs <path-to-isa_research> [--at=<rev>]  ->  facts.json
// --at limits history and the file list to a commit (the deck uses the Oct 7, 2026 monthly
// refresh, 5c3469d); file contents are read from the working tree, so check out near that commit.
import { execFileSync } from "node:child_process";
import fs from "node:fs";
import path from "node:path";

const repo = path.resolve(process.argv.slice(2).find((a) => !a.startsWith("--")) ?? "../isa_research");
const rev = process.argv.find((a) => a.startsWith("--at="))?.slice(5) ?? "HEAD";
const git = (...args) => execFileSync("git", ["-C", repo, ...args], { encoding: "utf8", maxBuffer: 1 << 28 });
const readJson = (p) => JSON.parse(fs.readFileSync(path.join(repo, p), "utf8"));
const tracked = git("ls-tree", "-r", "--name-only", rev).split("\n").filter(Boolean);
// Lines counted the way git counts them: newline characters, plus a final unterminated line.
const countLines = (text) => (text.match(/\n/g)?.length ?? 0) + (text.length && !text.endsWith("\n") ? 1 : 0);

// Commits: totals, Claude co-authorship, and a per-day series split by who committed.
const SEP = "\u001e";
const log = git("log", rev, `--format=%H%x1f%an%x1f%ad%x1f%B${SEP}`, "--date=short")
  .split(SEP).map((s) => s.trim()).filter(Boolean)
  .map((s) => { const [hash, author, date, body] = s.split("\u001f"); return { hash, author, date, body }; });
const isBot = (a) => a === "github-actions[bot]" || a === "atlas-app";
const perDay = {};
for (const c of log) {
  const d = (perDay[c.date] ??= { date: c.date, human: 0, automation: 0 });
  isBot(c.author) ? d.automation++ : d.human++;
}
const human = log.filter((c) => !isBot(c.author));
const commits = {
  total: log.length,
  claudeCoAuthored: log.filter((c) => /Co-Authored-By: Claude/i.test(c.body)).length,
  byAuthor: Object.fromEntries(Object.entries(log.reduce((m, c) => ((m[c.author] = (m[c.author] ?? 0) + 1), m), {}))),
  firstHumanDate: human.map((c) => c.date).sort()[0],
  lastHumanDate: human.map((c) => c.date).sort().at(-1),
  humanActiveDays: new Set(human.map((c) => c.date)).size,
  perDay: Object.values(perDay).sort((a, b) => a.date.localeCompare(b.date)),
};

// Hand-written code: source files outside data, build output and the reference clone.
const CODE_EXT = new Set([".ts", ".tsx", ".mjs", ".js", ".py", ".css", ".scss", ".R"]);
const skip = (f) => /^(data|site|site-marketing|1kpapers|node_modules)\//.test(f) || f.includes("node_modules/") || f.endsWith(".d.ts");
const loc = {};
for (const f of tracked) {
  const ext = path.extname(f);
  if (!CODE_EXT.has(ext) || skip(f)) continue;
  const n = countLines(fs.readFileSync(path.join(repo, f), "utf8"));
  loc[ext] = (loc[ext] ?? 0) + n;
}
const testFiles = tracked.filter((f) => /\.test\.(ts|tsx|mjs|js)$/.test(f)).length;

// Net lines of code added per day (same file filter), for the cumulative line chart.
const locPerDay = {};
let day = null;
for (const line of git("log", rev, "--numstat", "--no-renames", "--format=@@%ad", "--date=short").split("\n")) {
  if (line.startsWith("@@")) { day = line.slice(2); continue; }
  const m = line.match(/^(\d+)\t(\d+)\t(.+)$/);
  if (!m || !CODE_EXT.has(path.extname(m[3])) || skip(m[3])) continue;
  locPerDay[day] = (locPerDay[day] ?? 0) + Number(m[1]) - Number(m[2]);
}
const docs = (dir) => tracked.filter((f) => f.startsWith(dir) && f.endsWith(".md")).map((f) => ({
  file: path.basename(f), lines: countLines(fs.readFileSync(path.join(repo, f), "utf8")),
}));

// Faculty, works and themes per department.
const units = fs.readdirSync(path.join(repo, "config/units"));
const perUnit = {};
const allWorks = new Set();
for (const u of units) {
  const faculty = readJson(`config/units/${u}/faculty.json`);
  const works = readJson(`data/units/${u}/works.json`);
  const themesPath = `data/units/${u}/themes.json`;
  const themes = fs.existsSync(path.join(repo, themesPath)) ? readJson(themesPath) : null;
  const themeList = Array.isArray(themes) ? themes : themes?.themes ?? [];
  works.works.forEach((w) => allWorks.add(w.id));
  perUnit[u] = {
    activeFaculty: faculty.filter((f) => (f.status ?? "active") === "active").length,
    works: works.works.length,
    fromDate: works.fromDate,
    themes: themeList.length,
  };
}
const school = readJson("data/school/atlas.json");

// Inference cost floor: every usage.costUsd recorded in tracked JSON under data/.
let costUsd = 0, costRecords = 0;
const costByDir = {};
const walk = (v, dir) => {
  if (!v || typeof v !== "object") return;
  if (Array.isArray(v)) return v.forEach((x) => walk(x, dir));
  if (typeof v.costUsd === "number") { costUsd += v.costUsd; costRecords++; costByDir[dir] = (costByDir[dir] ?? 0) + v.costUsd; }
  for (const k of Object.keys(v)) if (k !== "costUsd") walk(v[k], dir);
};
for (const f of tracked) {
  if (!f.startsWith("data/") || !f.endsWith(".json")) continue;
  const text = fs.readFileSync(path.join(repo, f), "utf8");
  if (!text.includes("costUsd")) continue;
  walk(JSON.parse(text), path.dirname(f).split("/").slice(0, 3).join("/"));
}

// Citation example: a journal article whose three sources disagree.
const examples = [];
for (const u of units) {
  for (const w of readJson(`data/units/${u}/works.json`).works) {
    const s = w.sources ?? {};
    const gs = s.scholar?.citedBy, s2 = s.s2?.citationCount, oa = s.openalex?.citedByCount;
    if ([gs, s2, oa].every((n) => typeof n === "number") && new Set([gs, s2, oa]).size === 3 && w.kind === "journal")
      examples.push({ unit: u, title: w.title, venue: w.venue, year: w.year, scholar: gs, s2, openalex: oa, shown: w.citations });
  }
}
examples.sort((a, b) => b.scholar - a.scholar);

const facts = {
  collectedAt: new Date().toISOString(),
  head: git("log", "-1", rev, "--format=%h %ad %s", "--date=short").trim(),
  commits,
  code: { linesByExt: loc, totalLines: Object.values(loc).reduce((a, b) => a + b, 0), testFiles, trackedFiles: tracked.length, locPerDay },
  specs: docs("docs/superpowers/specs/"),
  plans: docs("docs/superpowers/plans/"),
  units: perUnit,
  totals: {
    departments: units.length,
    activeFaculty: Object.values(perUnit).reduce((a, u) => a + u.activeFaculty, 0),
    distinctWorks: allWorks.size,
    unitThemes: Object.values(perUnit).reduce((a, u) => a + u.themes, 0),
  },
  school: { fromDate: school.fromDate, toDate: school.toDate, areas: school.themes.length, stats: school.stats },
  inference: { costUsdFloor: Math.round(costUsd * 100) / 100, records: costRecords, byDir: costByDir },
  citationExamples: examples.slice(0, 8),
};
fs.writeFileSync(new URL("../facts.json", import.meta.url), JSON.stringify(facts, null, 2));
console.log(JSON.stringify({ ...facts, commits: { ...commits, perDay: `${commits.perDay.length} days` } }, null, 2));

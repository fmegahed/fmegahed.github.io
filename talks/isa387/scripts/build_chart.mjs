// Builds the Development Timeline chart (inline SVG) from facts.json: cumulative commits
// (two series) above cumulative lines of code, sharing one time axis, with numbered milestones.
// Usage: node scripts/build_chart.mjs  ->  partials/_commits_chart.md
import fs from "node:fs";

const facts = JSON.parse(fs.readFileSync(new URL("../facts.json", import.meta.url), "utf8"));
const byDate = Object.fromEntries(facts.commits.perDay.map((d) => [d.date, d]));
const locByDate = facts.code.locPerDay;

const START = "2026-08-21", END = "2026-10-07";
const days = [];
let cumH = 0, cumA = 0, cumL = 0;
for (let t = Date.parse(START + "T12:00:00Z"); t <= Date.parse(END + "T12:00:00Z"); t += 86400000) {
  const date = new Date(t).toISOString().slice(0, 10);
  const h = byDate[date]?.human ?? 0, a = byDate[date]?.automation ?? 0, l = locByDate[date] ?? 0;
  cumH += h; cumA += a; cumL += l;
  days.push({ date, h, a, l, cumH, cumA, cumL });
}

const W = 820, H = 470, X0 = 56, X1 = 770;
const TOP = { y0: 276, y1: 76, max: 250 }, BOT = { y0: 430, y1: 340, max: 22000 };
const x = (i) => X0 + (i / (days.length - 1)) * (X1 - X0);
const yTop = (v) => TOP.y0 - (v / TOP.max) * (TOP.y0 - TOP.y1);
const yBot = (v) => BOT.y0 - (v / BOT.max) * (BOT.y0 - BOT.y1);
const RED = "#c3142d", BLUE = "#3b5fa3", TEAL = "#0d9a9a";
const fmt = (d) => new Date(d + "T12:00:00Z").toLocaleDateString("en-US", { month: "short", day: "numeric", timeZone: "UTC" });

// Seconds for each line to draw in, at constant speed, so a point's arrival time is
// proportional to its distance along the line.
const DRAW = 2.4;

// A polyline path, its length, and the running length at each point, so CSS can draw it in
// with stroke-dashoffset and milestones can appear when the line reaches them.
const line = (pts) => {
  const at = [0];
  for (let i = 1; i < pts.length; i++) at.push(at[i - 1] + Math.hypot(pts[i][0] - pts[i - 1][0], pts[i][1] - pts[i - 1][1]));
  return { d: "M" + pts.map((p) => p.map((n) => n.toFixed(1)).join(",")).join(" L"), len: Math.ceil(at.at(-1)), at };
};
const arrival = (ln, i) => ((DRAW * ln.at[i]) / ln.at.at(-1)).toFixed(2) + "s";

const parts = [];
// Grids and ticks
for (const v of [0, 100, 200]) {
  parts.push(`<line x1="${X0}" x2="${X1}" y1="${yTop(v)}" y2="${yTop(v)}" class="tl-grid${v ? "" : " tl-base"}"/>`);
  parts.push(`<text x="${X0 - 8}" y="${yTop(v) + 4}" text-anchor="end" class="tl-tick">${v}</text>`);
}
for (const v of [0, 10000, 20000]) {
  parts.push(`<line x1="${X0}" x2="${X1}" y1="${yBot(v)}" y2="${yBot(v)}" class="tl-grid${v ? "" : " tl-base"}"/>`);
  parts.push(`<text x="${X0 - 8}" y="${yBot(v) + 4}" text-anchor="end" class="tl-tick">${v ? v / 1000 + "K" : 0}</text>`);
}
days.forEach((d, i) => {
  if (i % 7 === 0) parts.push(`<text x="${x(i)}" y="${H - 14}" text-anchor="middle" class="tl-tick">${fmt(d.date)}</text>`);
});
parts.push(`<text x="${X0}" y="${TOP.y1 - 14}" class="tl-panel">Commits, cumulative</text>`);
parts.push(`<text x="${X0}" y="${BOT.y1 - 14}" class="tl-panel">Lines of code, cumulative</text>`);

// Area wash and lines
const human = line(days.map((d, i) => [x(i), yTop(d.cumH)]));
const auto = line(days.map((d, i) => [x(i), yTop(d.cumA)]));
const code = line(days.map((d, i) => [x(i), yBot(d.cumL)]));
parts.push(`<path d="${code.d} L${x(days.length - 1)},${BOT.y0} L${X0},${BOT.y0} Z" fill="${TEAL}" fill-opacity="0.12" class="tl-area"/>`);
parts.push(`<path d="${code.d}" class="tl-line" stroke="${TEAL}" style="--len:${code.len}"/>`);
parts.push(`<path d="${auto.d}" class="tl-line" stroke="${BLUE}" style="--len:${auto.len}"/>`);
parts.push(`<path d="${human.d}" class="tl-line" stroke="${RED}" style="--len:${human.len}"/>`);

// End values (text in ink, the line carries the color)
const last = days.at(-1), li = days.length - 1;
parts.push(`<text x="${x(li) + 8}" y="${yTop(last.cumH) + 5}" class="tl-end">${last.cumH}</text>`);
parts.push(`<text x="${x(li) + 8}" y="${yTop(last.cumA) + 5}" class="tl-end">${last.cumA}</text>`);
parts.push(`<text x="${x(li) + 8}" y="${yBot(last.cumL) + 5}" class="tl-end">~21K</text>`);

// Numbered milestones on the red line
const MILESTONES = [
  ["2026-08-21", "ISA pipeline and website"],
  ["2026-08-27", "Citations from three sources, monthly refresh, school website"],
  ["2026-08-28", "All seven departments, podcast"],
  ["2026-08-30", "AACSB and annual reporting"],
  ["2026-09-17", "Signed-in app: spec, plan, build, and launch in one day"],
  ["2026-09-25", "From here on, only automation commits"],
];
// Each milestone (marker and list entry) appears when its line reaches that day.
const delays = MILESTONES.map(([date], k) => {
  const i = days.findIndex((d) => d.date === date), d = days[i];
  const onAuto = k === MILESTONES.length - 1;
  const cy = onAuto ? yTop(d.cumA) - 16 : yTop(d.cumH);
  const delay = arrival(onAuto ? auto : human, i);
  parts.push(`<g class="tl-ms" style="--d:${delay}"><circle cx="${x(i)}" cy="${cy}" r="11" fill="${onAuto ? BLUE : RED}" stroke="#faf9f7" stroke-width="2"/>` +
    `<text x="${x(i)}" y="${cy + 4.5}" text-anchor="middle" class="tl-ms-n">${k + 1}</text></g>`);
  return delay;
});

// Hover targets: one column per day across both panels
days.forEach((d, i) => {
  const w = (X1 - X0) / (days.length - 1);
  const tip = `${fmt(d.date)}: ${d.h} commits by Fadel + Claude Code, ${d.a} by automation; ${d.l >= 0 ? "+" : ""}${d.l.toLocaleString("en-US")} lines`;
  parts.push(`<rect class="tl-hit" x="${x(i) - w / 2}" y="${TOP.y1 - 10}" width="${w}" height="${BOT.y0 - TOP.y1 + 10}" data-tip="${tip}"><title>${tip}</title></rect>`);
});

const legend = `<g transform="translate(${X0},14)">` +
  `<line x1="0" x2="22" y1="7" y2="7" stroke="${RED}" stroke-width="3"/><text x="30" y="12" class="tl-legend">Fadel Megahed with Claude Code</text>` +
  `<line x1="270" x2="292" y1="7" y2="7" stroke="${BLUE}" stroke-width="3"/><text x="300" y="12" class="tl-legend">Automation: GitHub Actions and app edits</text></g>`;

const list = MILESTONES.map(([date, text], k) => `<li style="--d:${delays[k]}"><span class="n${k === MILESTONES.length - 1 ? " blue" : ""}">${k + 1}</span><span><b>${fmt(date)}</b>${text}</span></li>`).join("");
const html = `<div class="tl-wrap"><div class="tl-chart"><svg class="tl-svg" viewBox="0 0 ${W} ${H}" role="img" aria-label="Cumulative commits and lines of code, Aug 21 to Oct 7, 2026">${legend}${parts.join("")}</svg><div class="tl-tip" hidden></div></div><ol class="tl-list">${list}</ol></div>`;

fs.mkdirSync(new URL("../partials/", import.meta.url), { recursive: true });
fs.writeFileSync(new URL("../partials/_commits_chart.md", import.meta.url), "```{=html}\n" + html + "\n```\n");
console.log(`chart: ${days.length} days; commits ${last.cumH} + ${last.cumA}; lines ${last.cumL}`);

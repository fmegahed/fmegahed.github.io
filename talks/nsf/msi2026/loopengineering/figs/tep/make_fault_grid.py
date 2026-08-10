"""Per-fault small-multiples grid for the TRIAGE deck (Slide: The Data and the Task).

One panel per fault (1..21): the fault's top SHAP-fingerprint process variable for a
representative run (batch 1), plotted over time with the t=10h onset marked. Panel borders
are colored by the fault's mechanistic type; a check mark tags faults whose designed cause
was recovered in the champion's SHAP top-3 (writeup Table 4).

Run:  conda run -n transplant python deck/figs/tep/make_fault_grid.py
"""
import json
import re
from pathlib import Path

import matplotlib

matplotlib.use("Agg")
import matplotlib.pyplot as plt
import pandas as pd

ROOT = Path(__file__).resolve().parents[3]
PARQUET = ROOT / "loop-tep" / "prepared" / "tep_mode1_long.parquet"
FINGERPRINTS = ROOT / "loop-tep" / "writeup" / "fault_fingerprints.json"
OUT = Path(__file__).with_name("fault_grid.png")

INK = "#1b1b1b"
MUTED = "#70685c"
NORMAL = "#1b7a3d"  # dark green: pre-onset normal operation
BG = "#faf9f7"

# fault -> (type, short designed cause) from writeup Table 4
META = {
    1: ("step", "A/C feed ratio"),
    2: ("step", "B composition"),
    3: ("step", "D feed temp"),
    4: ("step", "reactor CW inlet temp"),
    5: ("step", "condenser CW inlet temp"),
    6: ("step", "A feed loss"),
    7: ("step", "C header pressure"),
    8: ("random", "feed composition"),
    9: ("random", "D feed temp"),
    10: ("random", "C feed temp"),
    11: ("random", "reactor CW inlet temp"),
    12: ("random", "condenser CW inlet temp"),
    13: ("drift", "reaction kinetics"),
    14: ("stuck", "reactor CW valve"),
    15: ("stuck", "condenser CW valve"),
    16: ("undocumented", "not described in paper"),
    17: ("undocumented", "not described in paper"),
    18: ("undocumented", "not described in paper"),
    19: ("undocumented", "not described in paper"),
    20: ("undocumented", "not described in paper"),
    21: ("stuck", "stream-4 valve frozen"),
}
# designed variable recovered in SHAP top-3 (writeup Table 4 rank <= 3)
RECOVERED = {1, 2, 4, 5, 6, 7, 10, 11, 12, 14, 15}

TYPE_COLORS = {
    "step": "#1a66c9",
    "random": "#e08b18",
    "drift": "#7a4fb3",
    "stuck": "#c3142d",
    "undocumented": "#70685c",
}

fps = json.loads(FINGERPRINTS.read_text(encoding="utf-8"))
df = pd.read_parquet(PARQUET)
df["time_h"] = df["seq"] * (10 / 60.0)  # 10-min cadence

fig, axes = plt.subplots(3, 7, figsize=(16.4, 7.0), dpi=150)
fig.patch.set_facecolor(BG)

for i, fault in enumerate(range(1, 22)):
    ax = axes[i // 7][i % 7]
    ftype, cause = META[fault]
    color = TYPE_COLORS[ftype]

    top_var_raw = fps[str(fault)]["top"][0]["var"]
    var = re.match(r"(XMEAS-\d+|XMV-\d+)", top_var_raw).group(1)

    runs = sorted(df.loc[df["fault_number"] == fault, "run_id"].unique())
    sub = df[df["run_id"] == runs[0]].sort_values("seq")

    pre = sub[sub["time_h"] < 10]
    post = sub[sub["time_h"] >= 10]
    ax.plot(pre["time_h"], pre[var], color=NORMAL, lw=0.9)
    ax.plot(post["time_h"], post[var], color=color, lw=1.1)
    ax.axvline(10, color="#c3142d", lw=0.8, ls=(0, (3, 2)), alpha=0.8)

    check = "  ✓" if fault in RECOVERED else ""
    ax.set_title(
        f"F{fault} · {cause}{check}",
        fontsize=8.3,
        color=INK,
        pad=2.5,
        fontweight="bold" if fault in RECOVERED else "normal",
    )
    ax.text(
        0.985, 0.04, var, transform=ax.transAxes, ha="right", va="bottom",
        fontsize=6.6, color=MUTED, family="monospace",
    )
    ax.set_xticks([]); ax.set_yticks([])
    for s in ax.spines.values():
        s.set_color(color); s.set_linewidth(1.4)
    ax.set_facecolor("white")

handles = [plt.Line2D([0], [0], color=c, lw=3) for c in TYPE_COLORS.values()]
labels = [
    "step change", "random variation", "slow drift", "sticking valve",
    "real disturbance, but no description provided in the original paper",
]
fig.legend(
    handles, labels, loc="lower center", ncol=5, frameon=False,
    bbox_to_anchor=(0.5, 0.028), fontsize=9.0,
)
fig.text(
    0.5, 0.004,
    "✓ = the model's go-to sensor matches the physical cause described in the paper "
    "(11 of the 16 described faults; faults 16–20 were never described, so there is nothing to check against)",
    ha="center", fontsize=8.5, color=MUTED,
)
fig.tight_layout(rect=(0, 0.06, 1, 0.965))

# Caption with the normal-operation phrase in green (suptitle is single-color,
# so draw the segments sequentially and advance x by each segment's rendered width).
fig.canvas.draw()
renderer = fig.canvas.get_renderer()
segments = [
    ("Each panel: one real run of the sensor our trained model relies on most to "
     "recognize that fault (its name, bottom-right). ", INK),
    ("Dark green = normal operation before the t = 10 h injection (dashed line)", NORMAL),
    ("; line color after = the fault's mechanism (legend)", INK),
]
x = 0.012
for seg, color in segments:
    t = fig.text(x, 0.972, seg, fontsize=10.5, color=color, ha="left", va="bottom")
    bb = t.get_window_extent(renderer=renderer)
    x = fig.transFigure.inverted().transform((bb.x1, 0))[0]
fig.savefig(OUT, facecolor=BG, bbox_inches="tight")
print(f"saved {OUT}")

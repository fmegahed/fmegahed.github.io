"""Card-sized, legible mini version of the loop-tep improvement trajectory.

Values are the successful trials' validation macro-F1 from loop-tep/results.tsv;
the red step line is the running best. Designed to read at ~90 px card height:
one thick line, two endpoint labels, nothing else.

Run:  conda run -n transplant python deck/figs/evo/make_mini_trajectory.py
"""
from pathlib import Path

import matplotlib

matplotlib.use("Agg")
import matplotlib.pyplot as plt
import numpy as np

OUT = Path(__file__).with_name("evo_selfimproving.png")

vals = [0.702, 0.780, 0.780, 0.788, 0.836, 0.849, 0.864, 0.862]  # ok trials, in order
best = np.maximum.accumulate(vals)
x = np.arange(1, len(vals) + 1)

fig, ax = plt.subplots(figsize=(5.0, 2.1), dpi=160)
fig.patch.set_facecolor("white")
ax.plot(x, vals, "o", color="#9a9488", ms=7, zorder=2)
ax.step(x, best, where="post", color="#c3142d", lw=4, zorder=3)
ax.plot(x[-1], best[-1], "*", color="#c3142d", ms=22, zorder=4)

ax.text(x[0], vals[0] - 0.013, "0.702", fontsize=17, fontweight="bold",
        color="#1b1b1b", ha="left", va="top")
ax.text(x[-1] - 0.15, best[-1] + 0.012, "0.864", fontsize=17, fontweight="bold",
        color="#c3142d", ha="right", va="bottom")

ax.set_xlim(0.6, len(vals) + 0.4)
ax.set_ylim(0.675, 0.905)
ax.set_xticks([]); ax.set_yticks([])
for s in ax.spines.values():
    s.set_visible(False)
ax.spines["bottom"].set_visible(True)
ax.spines["bottom"].set_color("#ccc9b8")
ax.set_xlabel("experiments, run by the agent", fontsize=13, color="#70685c")

fig.tight_layout(pad=0.4)
fig.savefig(OUT, facecolor="white", bbox_inches="tight")
print(f"saved {OUT}")

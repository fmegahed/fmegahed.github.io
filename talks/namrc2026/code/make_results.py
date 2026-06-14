"""
Generate the results figures (accuracy, latency, cost) for the NAMRC 54 deck
directly from the experiment dataset, showing all 24 pipelines and highlighting
the two pipelines carried forward to expert (human) evaluation.

Reads:  deck/code/merged_output_finished.csv
Writes: deck/figs/accuracy.png, deck/figs/latency_cost.png

Run:  python deck/code/make_results.py
"""
import os, csv, statistics as st
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt

HERE = os.path.dirname(os.path.abspath(__file__))
DECK = os.path.join(HERE, "..")
CSV = os.path.join(HERE, "merged_output_finished.csv")
FIGS = os.path.join(DECK, "figs")

MIAMIRED = "#c3142d"
GRAY = "#c2bdb1"
DARKGRAY = "#6e675b"
DARK = "#1b1b1b"

plt.rcParams.update({
    "font.family": "DejaVu Sans", "font.size": 12,
    "axes.edgecolor": DARKGRAY, "text.color": DARK,
    "xtick.color": DARKGRAY, "ytick.color": DARK,
    "axes.spines.top": False, "axes.spines.right": False,
    "figure.facecolor": "white", "axes.facecolor": "white",
})

APPR = {"graph_eager": "Graph Eager", "graph_mmr": "Graph MMR",
        "openai_keyword": "OpenAI Keyword", "openai_semantic": "OpenAI Semantic",
        "lc_bm25": "BM25", "vanilla": "Vanilla"}

# Two pipelines carried to blind expert evaluation
SELECTED = {"Mini · OpenAI Keyword · k=7", "Mini · OpenAI Semantic · k=7"}
DEPLOYED = "Mini · OpenAI Keyword · k=7"


def load():
    rows = []
    with open(CSV, encoding="utf-8") as f:
        r = csv.reader(f); h = next(r); idx = {c: i for i, c in enumerate(h)}
        for row in r:
            rows.append(row)
    agg = {}
    for row in rows:
        model = row[idx["model"]]
        m = "Mini" if "mini" in model else "Nano"
        a = APPR[row[idx["approach"]]]
        tk = row[idx["top_k"]]
        cid = f"{m} · {a} · k={tk}"
        corr = 1.0 if row[idx["judge_answer_correctness_vs_ref"]].strip().upper() == "TRUE" else 0.0
        try:
            t = float(row[idx["total_elapsed_time"]].replace(" Seconds", ""))
        except Exception:
            t = None
        it = float(row[idx["meta_input_tokens"]] or 0)
        ot = float(row[idx["meta_output_tokens"]] or 0)
        cost = (it * 0.25e-6 + ot * 2e-6) if m == "Mini" else (it * 0.05e-6 + ot * 0.4e-6)
        d = agg.setdefault(cid, {"c": [], "t": [], "cost": []})
        d["c"].append(corr)
        if t is not None:
            d["t"].append(t)
        d["cost"].append(cost)
    return agg


def color_for(cid):
    return MIAMIRED if cid in SELECTED else GRAY


def accuracy_fig(agg):
    items = [(cid, sum(d["c"]) / len(d["c"])) for cid, d in agg.items()]
    items.sort(key=lambda x: x[1])  # ascending; best ends on top
    labels = [c for c, _ in items]
    vals = [v for _, v in items]
    fig, ax = plt.subplots(figsize=(11, 7.2))
    for i, (cid, v) in enumerate(items):
        c = color_for(cid)
        ax.hlines(i, 0, v, color=c, lw=2.4 if cid in SELECTED else 1.6, alpha=0.9)
        ax.plot(v, i, "o", color=c, ms=11 if cid in SELECTED else 7,
                zorder=3, markeredgecolor="white", markeredgewidth=1)
        ax.text(v + 0.012, i, f"{v*100:.1f}%", va="center", ha="left",
                fontsize=10.5, fontweight="bold" if cid in SELECTED else "normal",
                color=MIAMIRED if cid in SELECTED else DARKGRAY)
    ax.set_yticks(range(len(labels)))
    ax.set_yticklabels(labels, fontsize=9.5)
    for tick, cid in zip(ax.get_yticklabels(), labels):
        if cid in SELECTED:
            tick.set_color(MIAMIRED); tick.set_fontweight("bold")
    ax.set_xlim(0, 1.0)
    ax.set_xticks([0, .2, .4, .6, .8, 1.0])
    ax.set_xticklabels(["0%", "20%", "40%", "60%", "80%", "100%"])
    ax.set_xlabel("Share of answers judged correct vs. reference", fontweight="bold")
    ax.tick_params(length=0)
    fig.tight_layout()
    fig.savefig(os.path.join(FIGS, "accuracy.png"), dpi=200, bbox_inches="tight")
    plt.close(fig)


def _box_panel(ax, agg, key, sort_desc, title, xlabel, fmt):
    items = [(cid, d[key], st.median(d[key])) for cid, d in agg.items()]
    items.sort(key=lambda x: x[2], reverse=sort_desc)  # worst first so best ends on top
    labels = [c for c, _, _ in items]
    data = [vals for _, vals, _ in items]
    bp = ax.boxplot(data, vert=False, patch_artist=True, widths=0.62,
                    showfliers=False, medianprops=dict(color=DARK, lw=1.2))
    for i, (cid, _, med) in enumerate(items):
        c = color_for(cid)
        bp["boxes"][i].set(facecolor=c, alpha=0.55 if cid not in SELECTED else 0.9, edgecolor=c)
        for w in (bp["whiskers"][2*i], bp["whiskers"][2*i+1], bp["caps"][2*i], bp["caps"][2*i+1]):
            w.set(color=c)
    ax.set_yticks(range(1, len(labels) + 1))
    ax.set_yticklabels(labels, fontsize=8.6)
    for tick, cid in zip(ax.get_yticklabels(), labels):
        if cid in SELECTED:
            tick.set_color(MIAMIRED); tick.set_fontweight("bold")
    ax.set_title(title, fontweight="bold", loc="left", color=DARK)
    ax.set_xlabel(xlabel, fontweight="bold", fontsize=10.5)
    ax.tick_params(length=0)


def latency_cost_fig(agg):
    fig, (a1, a2) = plt.subplots(1, 2, figsize=(13.5, 7.0))
    _box_panel(a1, agg, "t", True, "End-to-end latency (all 24 pipelines)", "Seconds", None)
    _box_panel(a2, agg, "cost", True, "Cost per query (all 24 pipelines)", "USD", None)
    fig.tight_layout()
    fig.savefig(os.path.join(FIGS, "latency_cost.png"), dpi=200, bbox_inches="tight")
    plt.close(fig)


if __name__ == "__main__":
    agg = load()
    accuracy_fig(agg)
    latency_cost_fig(agg)
    print("Results figures written from", os.path.basename(CSV))

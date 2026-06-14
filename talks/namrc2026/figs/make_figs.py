"""
Generate the charts, QR codes (with center icons + captions), and placeholder
images for the NAMRC 54 deck. Recreates the paper's results figures from the
reported summary statistics and the future-work "token tax" chart as a relative
percent-improvement plot.

Run:  python deck/figs/make_figs.py
"""
import os
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
import numpy as np
from PIL import Image, ImageDraw, ImageFont

HERE = os.path.dirname(os.path.abspath(__file__))
DECK = os.path.join(HERE, "..")

MIAMIRED = "#c3142d"
GRAY = "#b9b4a7"
DARK = "#1b1b1b"
MUTED = "#70685c"

plt.rcParams.update({
    "font.family": "DejaVu Sans",
    "font.size": 13,
    "axes.edgecolor": MUTED,
    "axes.labelcolor": DARK,
    "text.color": DARK,
    "xtick.color": MUTED,
    "ytick.color": MUTED,
    "axes.spines.top": False,
    "axes.spines.right": False,
    "figure.facecolor": "white",
    "axes.facecolor": "white",
})

_FONT_TTF = os.path.join(matplotlib.get_data_path(), "fonts", "ttf", "DejaVuSans-Bold.ttf")


def _barh(ax, labels, values, highlight_idx, fmt, title, xlabel):
    colors = [MIAMIRED if i in highlight_idx else GRAY for i in range(len(values))]
    bars = ax.barh(labels, values, color=colors)
    ax.invert_yaxis()
    ax.set_title(title, fontweight="bold", loc="left", color=DARK)
    ax.set_xlabel(xlabel, fontsize=11)
    ax.tick_params(length=0)
    xmax = max(values)
    for b, v in zip(bars, values):
        ax.text(b.get_width() + xmax * 0.01, b.get_y() + b.get_height() / 2,
                fmt(v), va="center", ha="left", fontsize=11, fontweight="bold", color=DARK)
    ax.set_xlim(0, xmax * 1.18)


def accuracy_fig():
    labels = ["OpenAI Keyword", "OpenAI Semantic", "BM25", "Vanilla", "Graph MMR", "Graph Eager"]
    vals = [0.77, 0.77, 0.71, 0.68, 0.62, 0.50]
    fig, ax = plt.subplots(figsize=(9.2, 4.4))
    _barh(ax, labels, vals, {0, 1}, lambda v: f"{v*100:.0f}%",
          "Answer accuracy by retrieval method", "Share judged correct vs. reference")
    fig.text(0.62, 0.30,
             "Model also matters:\nmini 0.73  >  nano 0.62\n\nRetrieval depth does not:\ntop-k 3 ≈ top-k 7 (0.67 vs 0.68)",
             fontsize=11, color=MUTED, va="center",
             bbox=dict(boxstyle="round,pad=0.5", fc="#edece2", ec="#ccc9b8"))
    fig.tight_layout()
    fig.savefig(os.path.join(HERE, "accuracy.png"), dpi=200, bbox_inches="tight")
    plt.close(fig)


def latency_cost_fig():
    methods = ["BM25", "OpenAI Semantic", "OpenAI Keyword", "Vanilla", "Graph Eager", "Graph MMR"]
    lat = [6.11, 8.08, 8.56, 11.61, 14.97, 15.35]
    cost_map = {"OpenAI Keyword": 0.00247, "OpenAI Semantic": 0.00240, "BM25": 0.00185,
                "Vanilla": 0.00168, "Graph MMR": 0.00097, "Graph Eager": 0.00064}
    cost = [cost_map[m] for m in methods]
    fig, (a1, a2) = plt.subplots(1, 2, figsize=(11.5, 4.4))
    _barh(a1, methods, lat, {2}, lambda v: f"{v:.1f}s", "End-to-end latency", "Seconds")
    _barh(a2, methods, cost, {2}, lambda v: f"${v:.4f}", "Cost per query", "USD")
    fig.suptitle("Latency and cost: the deployed pipeline (OpenAI Keyword) trades speed and cost for accuracy",
                 fontsize=12, fontweight="bold", color=DARK, x=0.01, ha="left")
    fig.tight_layout(rect=[0, 0, 1, 0.94])
    fig.savefig(os.path.join(HERE, "latency_cost.png"), dpi=200, bbox_inches="tight")
    plt.close(fig)


def token_tax_fig():
    groups = ["gpt-5-mini", "gpt-5-nano"]
    vs_semantic = [12.8, 10.7]
    vs_keyword = [21.8, 18.7]
    x = np.arange(len(groups))
    w = 0.36
    fig, ax = plt.subplots(figsize=(9.0, 4.6))
    b1 = ax.bar(x - w/2, vs_semantic, w, label="vs. Semantic RAG", color=MIAMIRED)
    b2 = ax.bar(x + w/2, vs_keyword, w, label="vs. Keyword RAG", color=GRAY)
    for bars in (b1, b2):
        for b in bars:
            ax.text(b.get_x() + b.get_width()/2, b.get_height() + 0.4,
                    f"+{b.get_height():.1f}%", ha="center", va="bottom",
                    fontsize=12, fontweight="bold", color=DARK)
    ax.set_xticks(x)
    ax.set_xticklabels(groups)
    ax.set_ylabel("Relative improvement in correctness")
    ax.set_title("Long-context grounding is more correct than RAG",
                 fontweight="bold", loc="left", color=DARK)
    ax.set_ylim(0, max(vs_keyword) * 1.25)
    ax.tick_params(length=0)
    ax.legend(frameon=False, loc="upper right")
    fig.text(0.012, -0.02,
             "but at about 26x the per-query token cost. Across three machine benchmarks (972 Q&A pairs).",
             fontsize=10.5, color=MUTED)
    fig.tight_layout()
    fig.savefig(os.path.join(HERE, "token_tax.png"), dpi=200, bbox_inches="tight")
    plt.close(fig)


def human_eval_fig():
    labels = ["OpenAI Keyword", "Tie", "OpenAI Semantic"]
    vals = [45, 36, 29]
    pct = [41, 33, 26]
    colors = [MIAMIRED, GRAY, "#7a7164"]
    fig, ax = plt.subplots(figsize=(8.6, 2.4))
    left = 0
    for v, p, c, lab in zip(vals, pct, colors, labels):
        ax.barh(0, v, left=left, color=c)
        ax.text(left + v/2, 0, f"{lab}\n{p}%", ha="center", va="center",
                color="white", fontsize=11, fontweight="bold")
        left += v
    ax.set_xlim(0, sum(vals))
    ax.axis("off")
    ax.set_title("Blind expert preference: 110 comparisons (11 experts x 10 questions)",
                 fontweight="bold", loc="left", color=DARK, fontsize=12)
    fig.tight_layout()
    fig.savefig(os.path.join(HERE, "human_eval.png"), dpi=200, bbox_inches="tight")
    plt.close(fig)


def placeholder(path, title, sub):
    fig, ax = plt.subplots(figsize=(8.6, 4.8))
    ax.add_patch(plt.Rectangle((0, 0), 1, 1, fc="#edece2", ec=MIAMIRED, lw=2))
    ax.text(0.5, 0.58, title, ha="center", va="center", fontsize=18,
            fontweight="bold", color=MIAMIRED, wrap=True)
    ax.text(0.5, 0.38, sub, ha="center", va="center", fontsize=11, color=MUTED, wrap=True)
    ax.axis("off")
    fig.savefig(path, dpi=160, bbox_inches="tight")
    plt.close(fig)


def make_qr(url, out, icon_path=None, caption=None):
    """QR with an optional center icon (on a white pad) and an optional caption strip."""
    import qrcode
    from qrcode.constants import ERROR_CORRECT_H
    qr = qrcode.QRCode(error_correction=ERROR_CORRECT_H, box_size=12, border=2)
    qr.add_data(url)
    qr.make(fit=True)
    img = qr.make_image(fill_color="black", back_color="white").convert("RGBA")
    W, H = img.size

    if icon_path and os.path.exists(icon_path):
        icon = Image.open(icon_path).convert("RGBA")
        side = int(W * 0.24)
        icon.thumbnail((side, side), Image.LANCZOS)
        pad = int(side * 1.25)
        plate = Image.new("RGBA", (pad, pad), (255, 255, 255, 255))
        plate.alpha_composite(icon, ((pad - icon.width) // 2, (pad - icon.height) // 2))
        img.alpha_composite(plate, ((W - pad) // 2, (H - pad) // 2))

    if caption:
        strip = int(H * 0.16)
        canvas = Image.new("RGBA", (W, H + strip), (255, 255, 255, 255))
        canvas.alpha_composite(img, (0, 0))
        d = ImageDraw.Draw(canvas)
        try:
            font = ImageFont.truetype(_FONT_TTF, int(strip * 0.62))
        except Exception:
            font = ImageFont.load_default()
        tb = d.textbbox((0, 0), caption, font=font)
        d.text(((W - (tb[2] - tb[0])) // 2, H + (strip - (tb[3] - tb[1])) // 2 - tb[1]),
               caption, fill=(195, 20, 45, 255), font=font)
        img = canvas
    img.save(out)


if __name__ == "__main__":
    # accuracy + latency/cost are generated from real data by code/make_results.py
    token_tax_fig()
    human_eval_fig()
    placeholder(os.path.join(HERE, "chatbot.png"),
                "SIGHT chatbot screenshot",
                "Replace with a screenshot of sight.fsb.miamioh.edu")
    placeholder(os.path.join(HERE, "vr_platform.png"),
                "VR platform tour video",
                "Short platform tour (follow-up). Live at mou-virtual-demo.mkms.io")

    arxiv_icon = os.path.join(HERE, "logos", "arxiv_g.png")

    make_qr("http://fmegahed.github.io/talks/namrc2026/",
            os.path.join(DECK, "deck_qr.png"),
            icon_path=os.path.join(DECK, "beveled_m.png"), caption="Slides")
    make_qr("https://arxiv.org/pdf/2511.11847",
            os.path.join(DECK, "arxiv_qr.png"),
            icon_path=arxiv_icon if os.path.exists(arxiv_icon) else None, caption="Paper")
    make_qr("https://mou-virtual-demo.mkms.io/",
            os.path.join(DECK, "vr_qr.png"),
            icon_path=os.path.join(DECK, "beveled_m.png"), caption="Try it")
    print("Done: charts, placeholders, and QR codes generated.")

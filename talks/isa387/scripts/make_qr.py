# QR codes for the deck, adapted from sight_presentations/qr_code/qr_code_generator.py:
# high error correction with the Miami M icon in the center.
# Run from the deck folder: python scripts/make_qr.py
from pathlib import Path

import qrcode
from PIL import Image

DECK = Path(__file__).resolve().parent.parent
LOGO = DECK / "logos" / "mu_m_icon.png"

TARGETS = {
    "qr_repo": "https://github.com/fmegahed/fsb-research-atlas",
    "qr_site": "https://fsbresearch.vercel.app",
    "qr_video": "https://youtu.be/73JrWLZGCwE",
    "qr_expertise": "https://fsb-expertise.vercel.app",
}


def make(url: str, out: Path, color: str) -> None:
    qr = qrcode.QRCode(error_correction=qrcode.constants.ERROR_CORRECT_H, box_size=12, border=2)
    qr.add_data(url)
    qr.make(fit=True)
    img = qr.make_image(fill_color=color, back_color="white").convert("RGB")

    # The logo covers about a fifth of the code's width; ERROR_CORRECT_H tolerates that.
    logo = Image.open(LOGO).convert("RGBA")
    width = img.size[0] // 5
    logo = logo.resize((width, int(logo.size[1] * width / logo.size[0])), Image.Resampling.LANCZOS)
    pad = Image.new("RGBA", (logo.size[0] + 16, logo.size[1] + 16), "white")
    pad.paste(logo, (8, 8), logo)
    img.paste(pad, ((img.size[0] - pad.size[0]) // 2, (img.size[1] - pad.size[1]) // 2))
    img.save(out)


if __name__ == "__main__":
    (DECK / "qr").mkdir(exist_ok=True)
    for name, url in TARGETS.items():
        make(url, DECK / "qr" / f"{name}.png", "#3a3a3a")
        print(f"{name}: {url}")

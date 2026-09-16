from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter, ImageFont

ROOT = Path(__file__).resolve().parents[1]
OUT = Path(__file__).resolve().parent
W, H = 1024, 500


def load_font(paths, size):
    for p in paths:
        try:
            return ImageFont.truetype(p, size)
        except OSError:
            continue
    return ImageFont.load_default()


def resize_cover(im: Image.Image, tw: int, th: int) -> Image.Image:
    target_ratio = tw / th
    w, h = im.size
    if w / h > target_ratio:
        new_w = int(h * target_ratio)
        left = (w - new_w) // 2
        im = im.crop((left, 0, left + new_w, h))
    else:
        new_h = int(w / target_ratio)
        top = (h - new_h) // 2
        im = im.crop((0, top, w, top + new_h))
    return im.resize((tw, th), Image.Resampling.LANCZOS)


def main() -> None:
    OUT.mkdir(exist_ok=True)

    draft_path = Path(
        r"C:\Users\user\.cursor\projects\c-seve-flutter-HupWorks"
        r"\assets\hupworks_feature_graphic_draft.png"
    )
    if draft_path.exists():
        draft = resize_cover(Image.open(draft_path).convert("RGB"), W, H)
        draft.save(OUT / "play_feature_graphic_ai.png", "PNG", optimize=True)
        print("saved", OUT / "play_feature_graphic_ai.png", draft.size)

    canvas = Image.new("RGB", (W, H), (0, 0, 0))
    glow = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    gdraw = ImageDraw.Draw(glow)
    gdraw.ellipse((40, 60, 520, 460), fill=(255, 140, 50, 45))
    gdraw.ellipse((280, 80, 700, 440), fill=(64, 200, 200, 40))
    glow = glow.filter(ImageFilter.GaussianBlur(60))
    canvas = Image.alpha_composite(canvas.convert("RGBA"), glow)

    logo = Image.open(ROOT / "images" / "hupworks-logo-1.png").convert("RGBA")
    max_logo_h = 380
    scale = max_logo_h / logo.height
    logo = logo.resize(
        (int(logo.width * scale), int(logo.height * scale)),
        Image.Resampling.LANCZOS,
    )
    logo_x, logo_y = 36, (H - logo.height) // 2
    canvas.paste(logo, (logo_x, logo_y), logo)
    canvas = canvas.convert("RGB")
    draw = ImageDraw.Draw(canvas)

    title_font = load_font(
        [
            r"C:\Windows\Fonts\segoeuib.ttf",
            r"C:\Windows\Fonts\arialbd.ttf",
        ],
        54,
    )
    sub_font = load_font(
        [
            r"C:\Windows\Fonts\segoeui.ttf",
            r"C:\Windows\Fonts\arial.ttf",
        ],
        28,
    )

    text_x = 560
    draw.text((text_x, 175), "HupWorks", fill=(255, 255, 255), font=title_font)
    draw.rounded_rectangle(
        (text_x, 250, text_x + 220, 258), radius=3, fill=(255, 140, 50)
    )
    draw.rounded_rectangle(
        (text_x + 230, 250, text_x + 320, 258), radius=3, fill=(64, 200, 200)
    )
    draw.text(
        (text_x, 280), "Jobs & freelancers", fill=(200, 200, 200), font=sub_font
    )

    png = OUT / "play_feature_graphic.png"
    jpg = OUT / "play_feature_graphic.jpg"
    canvas.save(png, "PNG", optimize=True)
    canvas.save(jpg, "JPEG", quality=92, optimize=True)
    print("saved", png.resolve(), canvas.size)
    print("saved", jpg.resolve())


if __name__ == "__main__":
    main()

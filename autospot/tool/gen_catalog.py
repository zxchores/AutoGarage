#!/usr/bin/env python3
"""Append street-real car models and generate missing 800x500 cards."""
from __future__ import annotations

import re
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parents[1]
ASSETS = ROOT / "assets" / "cars"
DART = ROOT / "lib" / "domain" / "catalog_cars.dart"
MODELS_DIR = Path(__file__).resolve().parent
FONT = "/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf"

BODY_RU = {
    "sedan": "седан",
    "hatch": "хэтчбек",
    "suv": "кроссовер",
    "offroad": "внедорожник",
    "wagon": "универсал",
    "coupe": "купе",
    "liftback": "лифтбек",
    "pickup": "пикап",
    "mpv": "минивэн",
    "van": "фургон",
    "convertible": "кабриолет",
}

RARITY_COLOR = {
    "common": (139, 147, 167),
    "rare": (59, 130, 246),
    "epic": (168, 85, 247),
    "legendary": (234, 179, 8),
}


def existing_ids() -> set[str]:
    text = DART.read_text(encoding="utf-8")
    return set(re.findall(r"id: '([^']+)'", text))


def drive_for(body: str, hp: int, country: str) -> str:
    if body in {"offroad", "pickup"}:
        return "AWD"
    if body == "suv" and hp >= 180:
        return "AWD"
    if body in {"coupe", "convertible"} and hp >= 250:
        return "RWD"
    if country in {"US", "DE"} and hp >= 300:
        return "RWD" if body in {"coupe", "sedan", "convertible"} else "AWD"
    if hp >= 280:
        return "AWD"
    return "FWD"


def accel(hp: int) -> float:
    if hp >= 600:
        return 3.2
    if hp >= 400:
        return 4.2
    if hp >= 300:
        return 5.4
    if hp >= 200:
        return 7.2
    if hp >= 140:
        return 9.4
    return 11.6


def price_for(rarity: str, hp: int) -> int:
    base = {"common": 1_600_000, "rare": 3_800_000, "epic": 9_500_000, "legendary": 28_000_000}[rarity]
    return int(base + hp * 4200)


def year_to(year: int) -> int:
    return 2026 if year >= 2018 else min(year + 8, 2024)


def dart_escape(value: str) -> str:
    return value.replace("\\", "\\\\").replace("'", "\\'")


def card(path: Path, make: str, model: str, rarity: str) -> None:
    color = RARITY_COLOR[rarity]
    img = Image.new("RGB", (800, 500), (16, 18, 22))
    draw = ImageDraw.Draw(img)
    bold = ImageFont.truetype(FONT, 42)
    mid = ImageFont.truetype(FONT, 36)
    small = ImageFont.truetype(FONT, 22)
    draw.rectangle((0, 0, 18, 500), fill=color)
    draw.rectangle((0, 430, 800, 500), fill=color)
    draw.text((40, 28), make.upper(), font=bold, fill=(244, 241, 234))
    draw.text((40, 86), model, font=mid, fill=color)
    # simple car glyph
    draw.rounded_rectangle((250, 190, 550, 300), radius=28, outline=(244, 241, 234), width=4)
    draw.polygon([(310, 190), (360, 140), (440, 140), (490, 190)], outline=(200, 205, 214), fill=(40, 45, 54))
    draw.ellipse((290, 280, 360, 350), outline=color, width=5)
    draw.ellipse((440, 280, 510, 350), outline=color, width=5)
    draw.text((40, 450), rarity.upper(), font=small, fill=(11, 13, 16))
    path.parent.mkdir(parents=True, exist_ok=True)
    img.save(path, "PNG")


def load_models() -> list[tuple]:
    rows = []
    seen = set()
    for path in sorted(MODELS_DIR.glob("*.tsv")):
        for raw in path.read_text(encoding="utf-8").splitlines():
            line = raw.strip()
            if not line or line.startswith("#"):
                continue
            parts = line.split("|")
            if len(parts) != 9:
                raise ValueError(f"bad row in {path.name}: {line}")
            cid, make, model, gen, year, country, body, rarity, hp = parts
            if cid in seen:
                continue
            seen.add(cid)
            rows.append((cid, make, model, gen, int(year), country, body, rarity, int(hp)))
    return rows


def emit_spec(row: tuple) -> str:
    cid, make, model, gen, year, country, body, rarity, hp = row
    aliases = []
    low = f"{make} {model}".lower()
    if "mercedes" in low:
        aliases += ["mersedes", "mercedesbenz"]
    body_ru = BODY_RU[body]
    lines = [
        "  CarSpec(",
        f"    id: '{cid}',",
        f"    make: '{dart_escape(make)}',",
        f"    model: '{dart_escape(model)}',",
        f"    generation: '{dart_escape(gen)}',",
        f"    yearFrom: {year},",
        f"    yearTo: {year_to(year)},",
        f"    bodyType: '{body_ru}',",
        f"    horsepower: {hp},",
        f"    zeroToHundred: {accel(hp)},",
        f"    drivetrain: '{drive_for(body, hp, country)}',",
        f"    priceRub: {price_for(rarity, hp)},",
        f"    rarity: Rarity.{rarity},",
    ]
    if aliases:
        quoted = ", ".join(f"'{dart_escape(a)}'" for a in aliases)
        lines.append(f"    aliases: [{quoted}],")
    lines.append("  ),")
    return "\n".join(lines)


def main() -> None:
    have = existing_ids()
    added = []
    for row in load_models():
        if row[0] in have:
            continue
        have.add(row[0])
        added.append(row)
    if not added:
        print("no new cars")
        return
    text = DART.read_text(encoding="utf-8")
    if not text.rstrip().endswith("];"):
        raise SystemExit("catalog_cars.dart does not end with ];")
    block = "\n".join(emit_spec(row) for row in added)
    DART.write_text(text.rstrip()[:-2] + "\n" + block + "\n];\n", encoding="utf-8")
    for row in added:
        png = ASSETS / f"{row[0]}.png"
        if not png.exists():
            card(png, row[1], row[2], row[7])
    print(f"added {len(added)} cars, catalog now {len(have)}")


if __name__ == "__main__":
    main()

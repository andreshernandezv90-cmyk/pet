#!/usr/bin/env python3
"""Plano esquematico (vista cenital) del Mundo PET compacto (Fase C.1).

Uso: python3 tools/preview/layout_map.py docs/previews/mundo-pet-layout.png
Las medidas estan en studs y replican PetWorld.luau (largos, camino, arenas,
claros y retos); ver docs/MUNDO_PET_LAYOUT.md.
"""
import math
import random
import sys

from PIL import Image, ImageDraw, ImageFont

# Medidas (studs). X: oeste -> este. Z: norte (+) / sur (-).
CAMP = 140
ZONES = [  # nombre, largo, radio de mina, color de la region, especies (color de puntos)
    ("Zona 1 · Bosque de Lumi", 250, 45, (120, 200, 105), [(255, 240, 150)]),
    ("Zona 2 · Valle de los Engranajes", 260, 55, (185, 175, 110), [(140, 125, 110), (255, 220, 60)]),
    ("Zona 3 · Cavernas Olvidadas", 270, 65, (95, 120, 120), [(150, 105, 75), (70, 50, 120), (60, 210, 200)]),
    ("Zona 4 · Jardines Elementales", 280, 75, (110, 190, 155),
     [(100, 180, 80), (255, 120, 50), (255, 150, 200), (190, 220, 255)]),
    ("Zona 5 · Templo del Eclipse", 330, 110, (120, 100, 170),
     [(200, 255, 230), (240, 200, 255), (90, 70, 160), (40, 60, 140), (25, 20, 35)]),
]
HALF_W = 160
ARENAS = [("Arena del Sakura", 30), ("Coliseo Mecanico", 30), ("Circulo de las Esporas", 31),
          ("Arena del Cristal", 32), ("Altar del Eclipse", 36)]
RETOS = ["troncos y ramas", "engranajes", "hongos rebote", "cristal y hielo", "caminos temporales"]


def path_z(x):
    return math.sin(x / 105) * 30  # mitad del ancho transitable (norte-sur)
SCALE = 0.9  # px por stud
MARGIN = 60


def main(out):
    total = CAMP + sum(z[1] for z in ZONES)
    W = int(total * SCALE) + MARGIN * 2
    H = int((HALF_W * 2 + 260) * SCALE) + MARGIN * 2 + 40
    img = Image.new("RGB", (W, H), (34, 40, 36))
    d = ImageDraw.Draw(img, "RGBA")
    try:
        font = ImageFont.truetype("DejaVuSans-Bold.ttf", 15)
        small = ImageFont.truetype("DejaVuSans.ttf", 12)
    except OSError:
        font = small = ImageFont.load_default()

    north_extra = 220  # profundidad maxima de las minas hacia el norte

    def px(x, z):
        return MARGIN + x * SCALE, MARGIN + (north_extra + HALF_W - z) * SCALE

    rng = random.Random(4)
    # Montaña norte (donde se excavan las minas) y bosque sur
    d.rectangle([px(0, HALF_W + north_extra), px(total, HALF_W)], fill=(92, 88, 96))
    d.rectangle([px(0, HALF_W), px(total, -HALF_W)], fill=(70, 140, 70))
    d.rectangle([px(0, -HALF_W), px(total, -HALF_W - 30)], fill=(92, 88, 96))
    # Franja central (praderas y camino principal)
    x0 = 0
    regions = []
    for name, length, mine_r, col, pets in [("Campamento", CAMP, 0, (150, 200, 120), [])] + ZONES:
        d.rectangle([px(x0, HALF_W), px(x0 + length, -HALF_W)], fill=col + (255,))
        # bosque denso a ambos lados (bandas de arboles)
        for _ in range(int(length / 6)):
            tx = x0 + rng.uniform(4, length - 4)
            for band in ((HALF_W - 45, HALF_W - 4), (-HALF_W + 4, -HALF_W + 70)):
                tz = rng.uniform(*band)
                r = rng.uniform(5, 9) * SCALE
                cx, cy = px(tx, tz)
                d.ellipse([cx - r, cy - r, cx + r, cy + r], fill=(40, 105, 55, 230))
        regions.append((name, x0, length, mine_r, col, pets))
        x0 += length

    # Camino principal serpenteante
    pts = []
    for i in range(0, total + 1, 20):
        pts.append(px(i, path_z(i)))
    d.line(pts, fill=(214, 178, 125), width=int(16 * SCALE) + 4)
    # senderos secundarios hacia el bosque sur (retos y regalos)
    for name, xs, length, mine_r, col, pets in regions[1:]:
        cx = xs + length * 0.6
        d.line([px(cx, path_z(cx)), px(cx + 10, -70), px(cx + 4, -110)], fill=(200, 165, 115), width=6)

    # Minas (norte) con tunel de entrada
    for name, xs, length, mine_r, col, pets in regions[1:]:
        mx = xs + length * 0.45
        mz = HALF_W + 25 + mine_r
        d.line([px(mx, HALF_W - 20), px(mx, mz - mine_r * 0.6)], fill=(70, 62, 60), width=int(14 * SCALE) + 3)
        for k, f in enumerate((1.0, 0.7, 0.4)):
            r = mine_r * f * SCALE
            cx, cy = px(mx, mz)
            d.ellipse([cx - r, cy - r, cx + r, cy + r], outline=(255, 140, 40), width=3, fill=(60, 54, 58, 255) if k == 0 else None)
        ex, ey = px(mx, HALF_W - 4)
        d.polygon([(ex - 9, ey), (ex + 9, ey), (ex, ey - 12)], fill=(255, 140, 40))
        label = "Gran Mina de Zuar" if mine_r >= 100 else "Mina de Zuar"
        lx, ly = px(mx, mz + mine_r)
        d.text((lx - len(label) * 3.3, ly - 16), label, font=small, fill=(255, 200, 140))

    # PETs salvajes (praderas centrales) y regalos (bosques)
    for name, xs, length, mine_r, col, pets in regions[1:]:
        n = max(4, length // 50)
        cr = 24 if mine_r >= 100 else 22
        k = regions.index((name, xs, length, mine_r, col, pets))
        aname, ar = ARENAS[k - 1]
        ax = xs + length * 0.3
        az = path_z(ax) - (ar + 15)
        for i in range(1, n + 1):
            x = xs + 22 + (length - 44) * (i - 0.5) / n
            for side in ((1, -1) if i % 2 == 0 else (-1, 1)):
                cz = max(-52, min(52, path_z(x) + side * 30))
                if (x - ax) ** 2 + (cz - az) ** 2 > (ar + cr + 6) ** 2:
                    cx, cy = px(x, cz)
                    rr = cr * SCALE
                    d.ellipse([cx - rr, cy - rr, cx + rr, cy + rr], fill=(170, 220, 130, 120), outline=(230, 255, 200))
                    for j in range(3):
                        c = pets[(i + j) % len(pets)]
                        a = rng.uniform(0, 6.28)
                        q = rng.uniform(0, cr * 0.8)
                        qx, qy = px(x + math.cos(a) * q, cz + math.sin(a) * q)
                        d.ellipse([qx - 5, qy - 4, qx + 5, qy + 4], fill=c, outline=(0, 0, 0))
                    break
        # arena de incursion tematica de la zona
        cx, cy = px(ax, az)
        rr = ar * SCALE
        d.ellipse([cx - rr, cy - rr, cx + rr, cy + rr], fill=(90, 60, 80, 200), outline=(255, 120, 160), width=3)
        d.text((cx - len(aname) * 3.3, cy - 6), aname, font=small, fill=(255, 200, 220))
        for i in range(3):
            tx = xs + rng.uniform(40, length - 40)
            tz = rng.choice([rng.uniform(-150, -100), rng.uniform(100, 140)])
            cx, cy = px(tx, tz)
            d.rectangle([cx - 5, cy - 5, cx + 5, cy + 5], fill=(255, 205, 60), outline=(120, 60, 0))
        # faro de viaje rapido
        bx, by = px(xs + 22, path_z(xs + 22) + 20)
        d.polygon([(bx, by - 11), (bx - 7, by + 6), (bx + 7, by + 6)], fill=(110, 200, 255), outline=(20, 40, 80))
        # reto opcional (parkour) en el bosque sur
        rx0, ry0 = px(xs + length * 0.56, -100)
        rx1, ry1 = px(xs + length * 0.98, -156)
        d.rectangle([rx0, ry0, rx1, ry1], outline=(255, 255, 255), width=2)
        d.text((rx0 + 3, ry0 + 2), "reto opcional:", font=small, fill=(255, 255, 255))
        d.text((rx0 + 3, ry0 + 16), RETOS[k - 1], font=small, fill=(255, 255, 255))
        d.text((rx0 + 3, ry0 + 30), "+ cofre", font=small, fill=(255, 255, 255))

    # Barreras translucidas entre zonas
    x0 = CAMP
    for i, (name, length, mine_r, col, pets) in enumerate(ZONES):
        if i > 0:
            bx0, by0 = px(x0 - 4, HALF_W + north_extra)
            bx1, by1 = px(x0 + 4, -HALF_W - 30)
            d.rectangle([bx0, by0, bx1, by1], fill=(120, 220, 255, 140), outline=(200, 240, 255))
            gx, gy = px(x0, path_z(x0))
            d.rectangle([gx - 9, gy - 14, gx + 9, gy + 14], fill=(170, 120, 255), outline=(255, 255, 255))
        x0 += length

    # Campamento: portal de llegada, puestos de NPC y arena
    def box(x, z, w, h, text, fill):
        a, b = px(x - w / 2, z + h / 2), px(x + w / 2, z - h / 2)
        d.rectangle([a, b], fill=fill, outline=(0, 0, 0), width=2)
        d.text((a[0] + 3, a[1] + 3), text, font=small, fill=(0, 0, 0))
    cx, cy = px(12, 0)
    d.ellipse([cx - 12, cy - 18, cx + 12, cy + 18], fill=(160, 110, 255), outline=(255, 255, 255), width=2)
    d.text((cx - 4, cy - 36), "Portal", font=small, fill=(255, 255, 255))
    box(86, 66, 44, 22, "Comerciante", (250, 220, 150))
    box(60, -34, 30, 20, "Guia", (180, 230, 255))
    box(108, -58, 48, 22, "Premium", (255, 200, 230))
    fx, fy = px(30, -44)
    d.ellipse([fx - 5, fy - 5, fx + 5, fy + 5], fill=(255, 150, 40))
    bx, by = px(52, 32)
    d.polygon([(bx, by - 11), (bx - 7, by + 6), (bx + 7, by + 6)], fill=(110, 200, 255), outline=(20, 40, 80))

    # Etiquetas de zona
    for name, xs, length, mine_r, col, pets in regions:
        parts = name.split(" · ")
        tx, ty = px(xs + 6, HALF_W - 6)
        d.text((tx, ty), parts[0], font=font, fill=(255, 255, 255), stroke_width=2, stroke_fill=(0, 0, 0))
        if len(parts) > 1:
            d.text((tx, ty + 17), parts[1], font=small, fill=(255, 255, 255), stroke_width=2, stroke_fill=(0, 0, 0))

    # Leyenda
    ly = H - 34
    items = [((255, 240, 150), "PETs salvajes (privados)"), ((255, 205, 60), "Regalos (privados, raros)"),
             ((110, 200, 255), "Faro de viaje rapido"), ((120, 220, 255), "Barrera translucida + puerta"),
             ((255, 140, 40), "Mina de Zuar (sellada hasta Fase D)"), ((255, 120, 160), "Arena de incursion")]
    for i, (c, t) in enumerate(items):
        lx = MARGIN + (i % 3) * 330
        y = ly - 22 + (i // 3) * 22
        d.rectangle([lx, y, lx + 14, y + 14], fill=c)
        d.text((lx + 20, y), t, font=small, fill=(230, 230, 230))
    d.text((MARGIN, 18), "Mundo PET compacto (Fase C.1) — vista cenital, oeste → este. Ancho ≈ 320 studs, largo = "
           + str(total) + " studs", font=font, fill=(255, 255, 255))
    img.save(out)


if __name__ == "__main__":
    main(sys.argv[1] if len(sys.argv) > 1 else "mundo-pet-layout.png")

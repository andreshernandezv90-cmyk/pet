#!/usr/bin/env python3
"""Vista previa aproximada de la escena exportada por tools/preview/export.lua.

No reemplaza a Roblox Studio: sirve para revisar composicion, proporciones,
orientaciones y colores sin abrir Studio. Algoritmo del pintor con PIL.

Uso:
  python3 tools/preview/render.py scene.json salida.png --plot 1 --view front
  vistas: front, back, top, overview, house
"""
import argparse
import json
import math

import numpy as np
from PIL import Image, ImageDraw

SUN = np.array([-0.45, 0.8, -0.35])
SUN = SUN / np.linalg.norm(SUN)

MAT_COLORS = {
    "Grass": (104, 178, 76), "LeafyGrass": (82, 152, 66), "Ground": (150, 112, 76), "Mud": (116, 86, 62),
    "Rock": (126, 122, 132), "Slate": (110, 108, 118), "Sand": (226, 206, 160), "Cobblestone": (168, 160, 150),
    "Water": (70, 160, 200), "Pavement": (176, 170, 160), "Air": None,
}


def unit_sphere(nu=10, nv=7):
    verts, tris = [], []
    for j in range(nv + 1):
        v = math.pi * j / nv
        for i in range(nu):
            u = 2 * math.pi * i / nu
            verts.append((math.sin(v) * math.cos(u), math.cos(v), math.sin(v) * math.sin(u)))
    for j in range(nv):
        for i in range(nu):
            a = j * nu + i
            b = j * nu + (i + 1) % nu
            c = (j + 1) * nu + i
            d = (j + 1) * nu + (i + 1) % nu
            tris += [(a, c, b), (b, c, d)]
    return np.array(verts) * 0.5, tris


def unit_box():
    v = np.array([[x, y, z] for x in (-0.5, 0.5) for y in (-0.5, 0.5) for z in (-0.5, 0.5)])
    faces = [(0, 1, 3, 2), (4, 6, 7, 5), (0, 4, 5, 1), (2, 3, 7, 6), (0, 2, 6, 4), (1, 5, 7, 3)]
    tris = []
    for a, b, c, d in faces:
        tris += [(a, b, c), (a, c, d)]
    return v, tris


def unit_cyl(n=12):
    verts = []
    for side in (-0.5, 0.5):
        for i in range(n):
            a = 2 * math.pi * i / n
            verts.append((side, math.cos(a) * 0.5, math.sin(a) * 0.5))
    verts += [(-0.5, 0, 0), (0.5, 0, 0)]
    tris = []
    for i in range(n):
        j = (i + 1) % n
        tris += [(i, j, n + j), (i, n + j, n + i)]
        tris += [(2 * n, j, i), (2 * n + 1, n + i, n + j)]
    return np.array(verts), tris


def unit_wedge():
    # WedgePart: alto completo en +Z (atras), cero en -Z (frente)
    v = np.array([[-0.5, -0.5, -0.5], [0.5, -0.5, -0.5], [-0.5, -0.5, 0.5], [0.5, -0.5, 0.5], [-0.5, 0.5, 0.5], [0.5, 0.5, 0.5]])
    tris = [(0, 2, 3), (0, 3, 1), (2, 4, 5), (2, 5, 3), (0, 4, 2), (1, 3, 5), (0, 1, 5), (0, 5, 4)]
    return v, tris


SPHERE = unit_sphere()
BOX = unit_box()
CYL = unit_cyl()
WEDGE = unit_wedge()


def part_mesh(p):
    size = np.array(p["s"])
    shape = p["shape"]
    if p["mesh"] and "Sphere" in p["mesh"]:
        v, t = SPHERE
        return v * size, t
    if p["cls"] == "WedgePart":
        v, t = WEDGE
        return v * size, t
    if "Ball" in shape:
        v, t = SPHERE
        return v * min(size), t
    if "Cylinder" in shape:
        v, t = CYL
        d = min(size[1], size[2])
        return v * np.array([size[0], d, d]), t
    if max(size) > 3.5:
        return box_tiles(size)
    v, t = BOX
    return v * size, t


def box_tiles(size, tile=2.5):
    """Caja con caras subdivididas: mejora el orden del algoritmo del pintor."""
    verts, tris = [], []
    sx, sy, sz = size
    for axis in range(3):
        for sign in (-1, 1):
            u_ax, v_ax = [a for a in range(3) if a != axis]
            nu = max(1, int(math.ceil(size[u_ax] / tile)))
            nv = max(1, int(math.ceil(size[v_ax] / tile)))
            base = len(verts)
            for j in range(nv + 1):
                for i in range(nu + 1):
                    p = [0.0, 0.0, 0.0]
                    p[axis] = sign * size[axis] / 2
                    p[u_ax] = -size[u_ax] / 2 + size[u_ax] * i / nu
                    p[v_ax] = -size[v_ax] / 2 + size[v_ax] * j / nv
                    verts.append(p)
            for j in range(nv):
                for i in range(nu):
                    a = base + j * (nu + 1) + i
                    b, c, d = a + 1, a + nu + 1, a + nu + 2
                    tris += [(a, b, d), (a, d, c)]
    return np.array(verts), tris


def terrain_mesh(data, bounds, step):
    x0, x1, z0, z1 = bounds
    xs = np.arange(x0, x1 + step, step)
    zs = np.arange(z0, z1 + step, step)
    X, Z = np.meshgrid(xs, zs)
    Hh = np.full(X.shape, -1e9)
    Mm = np.full(X.shape, "", dtype=object)
    for o in data["terrain"]:
        mat = o["mat"].split(".")[-1]
        if o["op"] == "block":
            p = np.array(o["p"]); r = np.array(o["r"]).reshape(3, 3); s = np.array(o["s"])
            dx, dz = X - p[0], Z - p[2]
            lx = r[0, 0] * dx + r[2, 0] * dz
            lz = r[0, 2] * dx + r[2, 2] * dz
            inside = (np.abs(lx) <= s[0] / 2) & (np.abs(lz) <= s[2] / 2)
            top = p[1] + s[1] / 2
        elif o["op"] == "ball":
            p = np.array(o["p"]); rr = o["r"]
            d2 = (X - p[0]) ** 2 + (Z - p[2]) ** 2
            inside = d2 <= rr * rr
            top = p[1] + np.sqrt(np.maximum(rr * rr - d2, 0))
        else:
            p = np.array(o["p"]); rr = o["r"]
            inside = (X - p[0]) ** 2 + (Z - p[2]) ** 2 <= rr * rr
            top = p[1] + o["h"] / 2
        top = np.broadcast_to(top, X.shape)
        if mat == "Air":
            Hh = np.where(inside, np.minimum(Hh, top - 100), Hh)
            continue
        upd = inside & (top >= Hh - 0.6)
        Hh = np.where(upd, np.maximum(Hh, top), Hh)
        Mm = np.where(upd, mat, Mm)
    colors = {}
    for k, v in data.get("colors", {}).items():
        colors[k.split(".")[-1]] = tuple(int(c * 255) for c in v)
    tris = []
    ny, nx = X.shape
    for j in range(ny - 1):
        for i in range(nx - 1):
            if Hh[j, i] < -1e8:
                continue
            m = Mm[j, i]
            col = colors.get(m) or MAT_COLORS.get(m) or (100, 160, 80)
            a = (X[j, i], Hh[j, i], Z[j, i]); b = (X[j, i + 1], Hh[j, i + 1], Z[j, i + 1])
            c = (X[j + 1, i], Hh[j + 1, i], Z[j + 1, i]); d = (X[j + 1, i + 1], Hh[j + 1, i + 1], Z[j + 1, i + 1])
            if min(a[1], b[1], c[1], d[1]) < -1e8:
                continue
            tris.append((np.array([a, c, b]), col, False, 0))
            tris.append((np.array([b, c, d]), col, False, 0))
    return tris


def render(data, out, eye, target, fov=55, w=1280, h=800, bounds=None, step=2.0):
    eye, target = np.array(eye, float), np.array(target, float)
    fwd = target - eye; fwd /= np.linalg.norm(fwd)
    right = np.cross(fwd, [0, 1, 0]); right /= np.linalg.norm(right)
    up = np.cross(right, fwd)
    f = 1 / math.tan(math.radians(fov) / 2)
    tris = []
    for p in data["parts"]:
        pos = np.array(p["p"])
        if np.linalg.norm(pos - eye) > 700:
            continue
        v, t = part_mesh(p)
        r = np.array(p["r"]).reshape(3, 3)
        wv = v @ r.T + pos
        col = tuple(int(c * 255) for c in p["c"])
        neon = "Neon" in p["mat"]
        for a, b, c in t:
            tris.append((wv[[a, b, c]], col, neon, p["t"]))
    if bounds:
        tris += terrain_mesh(data, bounds, step)
    img = Image.new("RGB", (w, h))
    dr = ImageDraw.Draw(img)
    for yy in range(h):
        k = yy / h
        dr.line([(0, yy), (w, yy)], fill=(int(140 + 70 * k), int(185 + 45 * k), int(235 + 10 * k)))
    items = []
    for tri, col, neon, tr in tris:
        rel = tri - eye
        zc = rel @ fwd
        if np.any(zc < 0.5):
            continue
        xs = (rel @ right) / zc * f * (h / 2) + w / 2
        ys = -(rel @ up) / zc * f * (h / 2) + h / 2
        n = np.cross(tri[1] - tri[0], tri[2] - tri[0])
        nn = np.linalg.norm(n)
        if nn < 1e-9:
            continue
        n = n / nn
        if np.dot(n, tri[0] - eye) > 0:
            n = -n
        if neon:
            shade = 1.15
        else:
            shade = 0.5 + 0.62 * max(0.0, float(np.dot(n, SUN)))
        fog = min(0.8, max(0.0, (zc.mean() - 250) / 900))
        c = [min(255, int(col[i] * shade)) for i in range(3)]
        sky = (190, 215, 240)
        if tr > 0:
            c = [int(c[i] * (1 - tr * 0.6) + sky[i] * tr * 0.6) for i in range(3)]
        c = tuple(int(c[i] * (1 - fog) + sky[i] * fog) for i in range(3))
        items.append((zc.max() * 0.3 + zc.mean() * 0.7, list(zip(xs, ys)), c))
    items.sort(key=lambda it: -it[0])
    for _, poly, c in items:
        dr.polygon(poly, fill=c)
    img.save(out)
    return len(items)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("scene")
    ap.add_argument("out")
    ap.add_argument("--plot", type=int, default=1)
    ap.add_argument("--view", default="front")
    args = ap.parse_args()
    data = json.load(open(args.scene))
    pl = data["plots"][args.plot - 1]
    P = np.array(pl["p"]); R = np.array(pl["r"]).reshape(3, 3)

    def loc(x, y, z):
        return list(P + R @ np.array([x, y, z]))
    views = {
        "front": (loc(0, 30, -78), loc(0, 4, 14), None, 3.0),
        "spawn": (loc(0, 7, -24), loc(-2, 6, 30), None, 2.0),
        "house": (loc(14, 9, 14), loc(0, 6, 36), None, 2.0),
        "house2": (loc(-22, 12, 18), loc(0, 6, 36), None, 2.0),
        "back": (loc(-30, 38, 85), loc(0, 4, 5), None, 3.0),
        "top": (loc(0, 150, -1), loc(0, 0, 0), None, 3.0),
        "overview": ([0, 380, -560], [0, 0, 60], None, 6.0),
        "aerial": (loc(0, 95, -150), loc(0, 0, 10), None, 3.0),
        "plaza": ([0, 34, -110], [0, 10, 10], None, 2.5),
    }
    eye, target, _, step = views[args.view]
    if args.view == "aerial":
        c = P
        bounds = (c[0] - 200, c[0] + 200, c[2] - 200, c[2] + 200)
    elif args.view == "overview":
        bounds = (-460, 460, -460, 460)
    elif args.view == "plaza":
        bounds = (-140, 140, -150, 140)
    else:
        c = P
        bounds = (c[0] - 120, c[0] + 120, c[2] - 120, c[2] + 120)
    n = render(data, args.out, eye, target, bounds=bounds, step=step)
    print("triangulos dibujados:", n)


if __name__ == "__main__":
    main()

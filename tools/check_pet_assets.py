#!/usr/bin/env python3
"""Valida los modelos importados de assets/pets (.rbxm / .rbxmx) sin abrir Studio.

Uso:  python tools/check_pet_assets.py [--require Lumi,Lumi_rare,...] [--dir carpeta]

Los .rbxm se convierten a XML con Rojo en una carpeta temporal (el original no se
toca). Para cada modelo comprueba:
  - Model raiz con PrimaryPart que apunta a una MeshPart con los huesos dentro;
  - atributo Rig (texto) = "Lumi_v7" en los modelos de Lumi;
  - los 34 huesos esperados con su jerarquia;
  - SurfaceAppearance con mapa de color (y que cada variante tenga uno distinto);
  - AnimationController con Animator;
  - sin scripts y sin carpeta Animations (los ids viven en PetAssets.AnimationSets).
Sale con codigo 1 si hay errores. --require exige que existan esos modelos.
"""
import base64
import json
import os
import shutil
import struct
import subprocess
import sys
import tempfile
import xml.etree.ElementTree as ET

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
PETS = os.path.join(ROOT, "assets", "pets")

# Rig Lumi_v7 (Lumi_Comun_rig_v7.blend): hueso -> padre (None = la MeshPart)
LUMI_V7 = {
    "Root": None, "Hips": "Root", "Spine": "Hips", "Chest": "Spine", "Neck": "Chest", "Head": "Neck", "Jaw": "Head",
    "Ear_01.L": "Head", "Ear_02.L": "Ear_01.L", "Ear_03.L": "Ear_02.L", "Ear_01.R": "Head", "Ear_02.R": "Ear_01.R",
    "Ear_03.R": "Ear_02.R", "Shoulder.L": "Chest", "UpperArm.L": "Shoulder.L", "Forearm.L": "UpperArm.L",
    "FrontPaw.L": "Forearm.L", "Shoulder.R": "Chest", "UpperArm.R": "Shoulder.R", "Forearm.R": "UpperArm.R",
    "FrontPaw.R": "Forearm.R", "Tail_01": "Hips", "Tail_02": "Tail_01", "Tail_03": "Tail_02", "Tail_04": "Tail_03",
    "Tail_05": "Tail_04", "Thigh.L": "Hips", "Shin.L": "Thigh.L", "BackFoot.L": "Shin.L", "BackPaw.L": "BackFoot.L",
    "Thigh.R": "Hips", "Shin.R": "Thigh.R", "BackFoot.R": "Shin.R", "BackPaw.R": "BackFoot.R",
}
RIGS = {"Lumi": ("Lumi_v7", LUMI_V7)}  # prefijo de nombre -> (Rig esperado, huesos)


def to_xml(path, tmp):
    if path.endswith(".rbxmx"):
        return path
    rojo = shutil.which("rojo")
    if not rojo:
        raise RuntimeError("Rojo no esta instalado (hace falta para leer .rbxm)")
    stem = os.path.basename(path)[:-len(".rbxm")]
    project = os.path.join(tmp, stem + ".project.json")
    with open(project, "w", encoding="utf-8") as f:
        json.dump({"name": stem, "tree": {"$path": os.path.abspath(path).replace(os.sep, "/")}}, f)
    out = os.path.join(tmp, stem + ".rbxmx")
    res = subprocess.run([rojo, "build", project, "-o", out], capture_output=True, text=True)
    if res.returncode != 0:
        raise RuntimeError((res.stderr or res.stdout).strip())
    return out


def attributes(b64):
    """Decodifica AttributesSerialize (solo los tipos habituales)."""
    if not b64:
        return {}
    data = base64.b64decode(b64 + "=" * (-len(b64) % 4))
    n = struct.unpack("<I", data[:4])[0]
    i, out = 4, {}
    for _ in range(n):
        kl = struct.unpack("<I", data[i:i + 4])[0]; i += 4
        key = data[i:i + kl].decode("utf-8"); i += kl
        t = data[i]; i += 1
        if t == 0x02:  # string
            vl = struct.unpack("<I", data[i:i + 4])[0]; i += 4
            out[key] = data[i:i + vl].decode("utf-8"); i += vl
        elif t == 0x03:  # bool
            out[key] = bool(data[i]); i += 1
        elif t == 0x06:  # double
            out[key] = struct.unpack("<d", data[i:i + 8])[0]; i += 8
        else:  # tipo no soportado aqui: se deja de leer (los demas no se necesitan)
            out[key] = "<tipo %d>" % t
            break
    return out


def prop(item, name):
    props = item.find("Properties")
    for p in props:
        if p.get("name") == name:
            return p
    return None


def text(p):
    if p is None:
        return None
    if len(p):
        return " ".join((c.text or "").strip() for c in p if (c.text or "").strip()) or None
    return (p.text or "").strip() or None


def check_model(path, tmp):
    errors, info = [], {}
    root = ET.parse(to_xml(path, tmp)).getroot()
    items = root.findall("Item")
    if len(items) != 1 or items[0].get("class") != "Model":
        return ["la raiz debe ser un unico Model"], info
    model = items[0]
    name = os.path.splitext(os.path.basename(path))[0]  # Rojo nombra la instancia como el archivo
    refs, parent = {}, {}

    def walk(it, par):
        refs[it.get("referent")] = it
        parent[it.get("referent")] = par
        for c in it.findall("Item"):
            walk(c, it)
    walk(model, None)
    nm = lambda it: text(prop(it, "Name"))
    cls_count = {}
    for it in refs.values():
        cls_count[it.get("class")] = cls_count.get(it.get("class"), 0) + 1
    info["clases"] = cls_count
    pp = text(prop(model, "PrimaryPart"))
    primary = refs.get(pp) if pp and pp != "null" else None
    if primary is None:
        errors.append("sin PrimaryPart")
    elif primary.get("class") != "MeshPart":
        errors.append("PrimaryPart no es una MeshPart (%s)" % primary.get("class"))
    else:
        info["PrimaryPart"] = nm(primary)
        info["malla"] = text(prop(primary, "MeshContent")) or text(prop(primary, "MeshId"))
        size = prop(primary, "size")
        if size is None:
            size = prop(primary, "Size")
        info["tamano"] = [float(c.text) for c in size] if size is not None else None
    attrs = attributes(text(prop(model, "AttributesSerialize")))
    info["atributos"] = {k: v for k, v in attrs.items() if k != "RBX_ReimportId"}
    rig = next((v for k, v in RIGS.items() if name == k or name.startswith(k + "_")), None)
    if rig:
        if attrs.get("Rig") != rig[0]:
            errors.append('atributo Rig = %r (se espera "%s")' % (attrs.get("Rig"), rig[0]))
        bones = {}
        for it in refs.values():
            if it.get("class") == "Bone":
                par = parent[it.get("referent")]
                bones[nm(it)] = nm(par) if par is not None and par.get("class") == "Bone" else None
                if par is not None and par.get("class") != "Bone" and par is not primary:
                    errors.append("el hueso %s no cuelga de la PrimaryPart" % nm(it))
        if bones != rig[1]:
            missing = sorted(set(rig[1]) - set(bones))
            extra = sorted(set(bones) - set(rig[1]))
            moved = sorted(b for b in bones if b in rig[1] and bones[b] != rig[1][b])
            errors.append("huesos distintos del rig (faltan %s, sobran %s, padre distinto %s)" % (missing, extra, moved))
        info["huesos"] = len(bones)
    sa = [it for it in refs.values() if it.get("class") == "SurfaceAppearance"]
    color = None
    if not sa:
        errors.append("sin SurfaceAppearance")
    else:
        color = text(prop(sa[0], "ColorMapContent")) or text(prop(sa[0], "ColorMap"))
        if not color:
            errors.append("SurfaceAppearance sin mapa de color")
        info["textura"] = color
    ac = [it for it in refs.values() if it.get("class") == "AnimationController"]
    if not ac or not any(c.get("class") == "Animator" for c in ac[0].findall("Item")):
        errors.append("sin AnimationController con Animator")
    scripts = [nm(it) for it in refs.values() if it.get("class") in ("Script", "LocalScript", "ModuleScript")]
    if scripts:
        errors.append("contiene scripts: %s" % scripts)
    if any(it.get("class") == "Folder" and nm(it) == "Animations" for it in model.findall("Item")):
        errors.append("tiene carpeta Animations (los ids van en PetAssets.AnimationSets)")
    return errors, info


def main():
    global PETS
    if "--dir" in sys.argv:
        PETS = os.path.abspath(sys.argv[sys.argv.index("--dir") + 1])
    require = []
    if "--require" in sys.argv:
        require = sys.argv[sys.argv.index("--require") + 1].split(",")
    files = sorted(f for f in os.listdir(PETS) if f.endswith(".rbxm") or f.endswith(".rbxmx"))
    found = {os.path.splitext(f)[0] for f in files}
    failed = False
    textures = {}
    with tempfile.TemporaryDirectory() as tmp:
        for f in files:
            try:
                errors, info = check_model(os.path.join(PETS, f), tmp)
            except Exception as e:  # archivo ilegible
                errors, info = ["no se pudo leer: %s" % e], {}
            if info.get("textura"):
                textures.setdefault(info["textura"], []).append(f)
            print("%s %s" % ("OK  " if not errors else "FALLO", f))
            for k in ("PrimaryPart", "huesos", "atributos", "malla", "textura", "tamano"):
                if k in info:
                    print("      %-11s %s" % (k, info[k]))
            for e in errors:
                print("      ERROR: " + e)
            failed = failed or bool(errors)
    for tex, owners in textures.items():
        lumis = [o for o in owners if o.startswith("Lumi")]
        if len(lumis) > 1:
            print("FALLO textura repetida en %s (%s): cada rareza debe tener la suya" % (lumis, tex))
            failed = True
    for r in require:
        if r not in found:
            print("FALLO falta assets/pets/%s.rbxm" % r)
            failed = True
    print("RESULTADO:", "con errores" if failed else "todo correcto")
    sys.exit(1 if failed else 0)


if __name__ == "__main__":
    main()

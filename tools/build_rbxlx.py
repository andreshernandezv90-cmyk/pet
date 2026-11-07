#!/usr/bin/env python3
"""Genera PortalPets.rbxlx a partir de default.project.json sin necesitar Rojo.

Uso:  python3 tools/build_rbxlx.py [salida.rbxlx]

Sigue las mismas reglas de Rojo para carpetas y scripts:
  carpeta con init.server.luau -> Script, init.client.luau -> LocalScript,
  init.luau -> ModuleScript, si no -> Folder;
  *.server.luau -> Script, *.client.luau -> LocalScript, *.luau -> ModuleScript.
La forma recomendada sigue siendo `rojo build` o `rojo serve`; este script es
una alternativa para abrir el juego directamente en Roblox Studio.

Modelos importados (assets/pets): los archivos .rbxmx (XML) se incrustan tal cual
(con sus SharedStrings). Los .rbxm binarios se convierten primero a XML con Rojo
(`rojo build` de un proyecto temporal de un solo modelo, sin tocar el original);
si Rojo no esta instalado se avisa y el modelo no se incluye.
Los referentes de cada modelo incrustado se prefijan para que no choquen entre si.
"""
import json
import os
import shutil
import subprocess
import sys
import tempfile
import xml.etree.ElementTree as ET
from xml.sax.saxutils import escape

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ref_counter = [0]
shared_strings = []  # elementos <SharedString> de los .rbxmx incrustados
shared_keys = set()
model_counter = [0]


def ref():
    ref_counter[0] += 1
    return "RBX%08X" % ref_counter[0]


def cdata(src):
    return "<![CDATA[" + src.replace("]]>", "]]]]><![CDATA[>") + "]]>"


def item(cls, name, props_xml="", children=""):
    return ('<Item class="%s" referent="%s"><Properties><string name="Name">%s</string>%s</Properties>%s</Item>'
            % (cls, ref(), escape(name), props_xml, children))


def script_item(cls, name, path):
    with open(path, encoding="utf-8") as f:
        src = f.read()
    return cls, name, '<ProtectedString name="Source">%s</ProtectedString>' % cdata(src)


def rbxmx_items(path, stem=None):
    """Devuelve el XML de los <Item> raiz de un .rbxmx (y guarda sus SharedStrings)."""
    tree = ET.parse(path)
    root = tree.getroot()
    items = [c for c in root if c.tag == "Item"]
    # Referentes unicos por modelo: las propiedades Ref (PrimaryPart, Part0...) siguen
    # apuntando a su instancia aunque se incrusten varios modelos
    model_counter[0] += 1
    prefix = "M%d_" % model_counter[0]
    for it in root.iter("Item"):
        if it.get("referent"):
            it.set("referent", prefix + it.get("referent"))
    for ref in root.iter("Ref"):
        if ref.text and ref.text.strip() not in ("null", "nil", ""):
            ref.text = prefix + ref.text.strip()
    if len(items) == 1:
        # como Rojo: la instancia raiz toma el nombre del archivo
        stem = stem or os.path.basename(path)[:-len(".rbxmx")]
        props = items[0].find("Properties")
        if props is not None:
            for prop in props:
                if prop.get("name") == "Name":
                    prop.text = stem
    out = ""
    for child in root:
        if child.tag == "Item":
            out += ET.tostring(child, encoding="unicode")
        elif child.tag == "SharedStrings":
            for ss in child:
                key = ss.get("md5")
                if key not in shared_keys:
                    shared_keys.add(key)
                    shared_strings.append(ET.tostring(ss, encoding="unicode"))
    return out


def rbxm_items(path):
    """Convierte un .rbxm binario a XML con Rojo y lo incrusta como un .rbxmx."""
    stem = os.path.basename(path)[:-len(".rbxm")]
    rojo = shutil.which("rojo")
    if not rojo:
        print("AVISO: %s es binario (.rbxm) y Rojo no esta instalado; no se incluye. "
              "Instala Rojo (rokit install) o guarda el modelo como .rbxmx." % path)
        return ""
    with tempfile.TemporaryDirectory() as tmp:
        project = os.path.join(tmp, "model.project.json")
        with open(project, "w", encoding="utf-8") as f:
            json.dump({"name": stem, "tree": {"$path": os.path.abspath(path).replace(os.sep, "/")}}, f)
        out = os.path.join(tmp, stem + ".rbxmx")
        res = subprocess.run([rojo, "build", project, "-o", out], capture_output=True, text=True)
        if res.returncode != 0 or not os.path.isfile(out):
            print("AVISO: Rojo no pudo convertir %s; no se incluye." % path)
            print((res.stderr or res.stdout).strip())
            return ""
        print("Modelo binario convertido con Rojo:", os.path.relpath(path, ROOT))
        return rbxmx_items(out, stem)


def build_path(path, name):
    if os.path.isfile(path) and path.endswith(".rbxmx"):
        return rbxmx_items(path)
    if os.path.isfile(path) and path.endswith(".rbxm"):
        return rbxm_items(path)
    if os.path.isfile(path):
        base = os.path.basename(path)
        if base.endswith(".server.luau"):
            cls, n = "Script", base[:-len(".server.luau")]
        elif base.endswith(".client.luau"):
            cls, n = "LocalScript", base[:-len(".client.luau")]
        else:
            cls, n = "ModuleScript", base[:-len(".luau")]
        c, nm, props = script_item(cls, name or n, path)
        return item(c, nm, props)
    name = name or os.path.basename(path)
    entries = sorted(os.listdir(path))
    cls, props = "Folder", ""
    for init, c in (("init.server.luau", "Script"), ("init.client.luau", "LocalScript"), ("init.luau", "ModuleScript")):
        if init in entries:
            cls = c
            _, _, props = script_item(c, name, os.path.join(path, init))
            entries.remove(init)
            break
    children = ""
    for e in entries:
        full = os.path.join(path, e)
        if os.path.isdir(full) or e.endswith(".luau") or e.endswith(".rbxmx") or e.endswith(".rbxm"):
            children += build_path(full, None)
    return item(cls, name, props, children)


def prop_xml(key, value):
    if isinstance(value, bool):
        return '<bool name="%s">%s</bool>' % (key, "true" if value else "false")
    if isinstance(value, (int, float)):
        return '<float name="%s">%s</float>' % (key, value)
    if isinstance(value, list) and len(value) == 3:
        return '<Color3 name="%s"><R>%s</R><G>%s</G><B>%s</B></Color3>' % (key, value[0], value[1], value[2])
    if isinstance(value, str):
        return '<string name="%s">%s</string>' % (key, escape(value))
    return ""


def build_node(name, node, is_service):
    if "$path" in node:
        return build_path(os.path.join(ROOT, node["$path"]), name)
    cls = node.get("$className", name if is_service else "Folder")
    props = "".join(prop_xml(k, v) for k, v in node.get("$properties", {}).items())
    children = "".join(build_node(k, v, False) for k, v in node.items() if not k.startswith("$"))
    return item(cls, name, props, children)


def main():
    out = sys.argv[1] if len(sys.argv) > 1 else os.path.join(ROOT, "PortalPets.rbxlx")
    with open(os.path.join(ROOT, "default.project.json"), encoding="utf-8") as f:
        project = json.load(f)
    tree = project["tree"]
    body = ""
    for k, v in tree.items():
        if k.startswith("$") or k == "Workspace":
            continue
        body += build_node(k, v, True)
    xml = ('<roblox xmlns:xmime="http://www.w3.org/2005/05/xmlmime" '
           'xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" '
           'xsi:noNamespaceSchemaLocation="http://www.roblox.com/roblox.xsd" version="4">'
           '<External>null</External><External>nil</External>' + body
           + ('<SharedStrings>' + "".join(shared_strings) + '</SharedStrings>' if shared_strings else '')
           + '</roblox>')
    with open(out, "w", encoding="utf-8") as f:
        f.write(xml)
    print("Generado:", out)


if __name__ == "__main__":
    main()

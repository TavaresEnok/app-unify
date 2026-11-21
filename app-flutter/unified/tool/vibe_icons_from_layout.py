# Gera lib/core/vibe/vibe_icon_data.dart a partir de layout-app/vibe-5-definitivas.html.
# Uso (na pasta app-flutter/unified): python3 -I tool/vibe_icons_from_layout.py
import re, html, sys, json
import xml.etree.ElementTree as ET
src = open('../../layout-app/vibe-5-definitivas.html', encoding='utf-8').read()
m = re.search(r'<iframe id="x9"[^>]*?srcdoc="(.*?)"\s*(?:style|aria|title|tabindex|>)', src, re.S)
x9 = html.unescape(m.group(1))
main = src[:m.start()] + src[m.end():]

def num(v): return float(v)
def fmt(v):
    s = ('%.3f' % v).rstrip('0').rstrip('.')
    return '0' if s in ('-0', '') else s
def circle(cx, cy, r):
    return f"M{fmt(cx-r)} {fmt(cy)}a{fmt(r)} {fmt(r)} 0 1 0 {fmt(2*r)} 0a{fmt(r)} {fmt(r)} 0 1 0 {fmt(-2*r)} 0z"
def ellipse(cx, cy, rx, ry):
    return f"M{fmt(cx-rx)} {fmt(cy)}a{fmt(rx)} {fmt(ry)} 0 1 0 {fmt(2*rx)} 0a{fmt(rx)} {fmt(ry)} 0 1 0 {fmt(-2*rx)} 0z"
def rect(x, y, w, h, rx):
    if rx <= 0: return f"M{fmt(x)} {fmt(y)}h{fmt(w)}v{fmt(h)}h{fmt(-w)}z"
    rx = min(rx, w/2, h/2)
    return (f"M{fmt(x+rx)} {fmt(y)}h{fmt(w-2*rx)}a{fmt(rx)} {fmt(rx)} 0 0 1 {fmt(rx)} {fmt(rx)}"
            f"v{fmt(h-2*rx)}a{fmt(rx)} {fmt(rx)} 0 0 1 {fmt(-rx)} {fmt(rx)}h{fmt(-(w-2*rx))}"
            f"a{fmt(rx)} {fmt(rx)} 0 0 1 {fmt(-rx)} {fmt(-rx)}v{fmt(-(h-2*rx))}a{fmt(rx)} {fmt(rx)} 0 0 1 {fmt(rx)} {fmt(-rx)}z")

def parts(body, inherited=None):
    root = ET.fromstring('<svg xmlns="http://www.w3.org/2000/svg">' + body + '</svg>')
    out = []
    def walk(el, attrs):
        tag = el.tag.split('}')[-1]
        a = dict(attrs); a.update({k: v for k, v in el.attrib.items()})
        d = None
        if tag == 'path': d = a.get('d')
        elif tag == 'circle': d = circle(num(a['cx']), num(a['cy']), num(a['r']))
        elif tag == 'ellipse': d = ellipse(num(a['cx']), num(a['cy']), num(a['rx']), num(a['ry']))
        elif tag == 'rect': d = rect(num(a.get('x', 0)), num(a.get('y', 0)), num(a['width']), num(a['height']), num(a.get('rx', 0)))
        if d:
            fill = a.get('fill'); stroke = a.get('stroke')
            p = {'d': d.strip()}
            if fill and fill != 'none':
                p['fill'] = True
                if fill != 'currentColor': p['color'] = fill
            if ART[0]:
                if not stroke or stroke == 'none': p['stroke'] = False
                elif a.get('stroke-linecap') != 'round': p['butt'] = True
            elif stroke == 'none': p['stroke'] = False
            if stroke and stroke not in ('none', 'currentColor'): p['color'] = stroke
            if 'stroke-width' in a: p['sw'] = float(a['stroke-width'])
            if 'opacity' in a: p['op'] = float(a['opacity'])
            if 'stroke-opacity' in a: p['op'] = float(a['stroke-opacity'])
            out.append(p)
        for c in el: walk(c, {k: v for k, v in a.items() if k in ('fill', 'stroke', 'stroke-width', 'opacity', 'stroke-linecap')})
    for c in root: walk(c, inherited or {})
    return out

ART = [False]
icons = {}
for mm in re.finditer(r'<symbol id="([a-z0-9-]+)" viewBox="0 0 24 24">(.*?)</symbol>', main, re.S):
    icons[mm.group(1)] = parts(mm.group(2))
gm = re.search(r"const GICON=\{(.*?)\};|('g-x':.*?'g-help':'[^']*')", main, re.S)
for mm in re.finditer(r"'(g-[a-z]+)':'([^']*)'", main):
    icons[mm.group(1)] = parts(mm.group(2))
im = re.search(r"const iconShapes = \{(.*?)\n\};", x9, re.S)
for mm in re.finditer(r"([a-z]+):'([^']*)'", im.group(1)):
    icons['i-' + mm.group(1)] = parts(mm.group(2))
pri = re.search(r"const PRI=\{(.*?)\};\nconst PROMOS", main, re.S).group(1)
art = {}
ART[0] = True
for mm in re.finditer(r"(\w+):`<svg class=\"pri\" viewBox=\"0 0 120 120\" aria-hidden=\"true\">(.*?)</svg>`", pri, re.S):
    art['art-' + mm.group(1)] = parts(mm.group(2))
icons.pop('stat', None)

def dart_part(p):
    args = [repr(p['d']).replace('"', '\\"') if False else "'" + p['d'] + "'"]
    if p.get('fill'): args.append('fill: true')
    if p.get('stroke') is False: args.append('stroke: false')
    if 'sw' in p: args.append(f"strokeWidth: {p['sw']}")
    if 'op' in p: args.append(f"opacity: {p['op']}")
    if p.get('butt'): args.append('roundCap: false')
    if 'color' in p:
        c = p['color'].lstrip('#')
        if len(c) == 3: c = ''.join(ch * 2 for ch in c)
        if c.lower() == 'fff' or c.lower() == 'ffffff': args.append('color: Color(0xFFFFFFFF)')
        else: args.append(f'color: Color(0xFF{c.upper()})')
    return 'VibeIconPart(' + ', '.join(args) + ')'

lines = ['// GERADO a partir de layout-app/vibe-5-definitivas.html (sprites do protótipo).',
         '// Não editar à mão: os traços precisam ser idênticos aos do layout aprovado.',
         "import 'dart:ui' show Color;", '', "import 'vibe_icon_part.dart';", '',
         '/// Ícones de traço 24×24 do layout (sprite principal, g-* e i-* da tela Dock).',
         'const Map<String, List<VibeIconPart>> vibeIconData = {']
for k in sorted(icons):
    lines.append(f"  '{k}': [" + ', '.join(dart_part(p) for p in icons[k]) + '],')
lines.append('};'); lines.append('')
lines.append('/// Ilustrações 120×120 dos cartões de oferta (PRI no protótipo).')
lines.append('const Map<String, List<VibeIconPart>> vibeArtData = {')
for k in sorted(art):
    lines.append(f"  '{k[4:]}': [" + ', '.join(dart_part(p) for p in art[k]) + '],')
lines.append('};')
open(sys.argv[1] if len(sys.argv) > 1 else 'lib/core/vibe/vibe_icon_data.dart', 'w').write('\n'.join(lines) + '\n')
print(len(icons), 'icons', len(art), 'art', sorted(icons)[:80])

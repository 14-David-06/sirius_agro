# -*- coding: utf-8 -*-
"""Genera `assets/fuentes/IconosModulo.ttf`, la fuente de iconos del PDF.

    pip install fonttools
    python tool/iconos_modulo.py

Por que existe este archivo: el generador de PDF no entiende `IconData` de
Flutter, quiere una fuente y un numero de glifo. La tipografia de Material
entera pesa 1,6 MB y ademas viene con contornos CFF, que ese generador no sabe
leer; asi que hay que recortarla y convertirla. Hecho a mano, eso se olvida:
alguien agrega un modulo al mapa, en pantalla se ve bien, y el icono sale en
blanco SOLO en el papel, cuando el informe ya se archivo.

Por eso la lista de iconos NO se escribe aqui: se lee de
`lib/core/iconos_modulo.dart`, que es el unico sitio donde se decide que icono
lleva cada modulo. Este script solo empaqueta.

Hay un icono que Material no tiene —el senor aplicando insumos— y por eso va
dibujado a mano mas abajo, en la misma reticula de 24x24 que usan los de
Material para que pese lo mismo al lado de ellos.

Despues de correrlo, `flutter test test/iconos_modulo_test.dart` comprueba que
no falte ningun glifo.
"""
import math
import os
import re
import subprocess
import sys
import tempfile

from fontTools import subset
from fontTools.pens.cu2quPen import Cu2QuPen
from fontTools.pens.ttGlyphPen import TTGlyphPen
from fontTools.ttLib import TTFont
from fontTools.ttLib.tables._g_l_y_f import table__g_l_y_f
from fontTools.ttLib.tables._l_o_c_a import table__l_o_c_a

AQUI = os.path.dirname(os.path.abspath(__file__))
APP = os.path.dirname(AQUI)
MAPA = os.path.join(APP, 'lib', 'core', 'iconos_modulo.dart')
SALIDA = os.path.join(APP, 'assets', 'fuentes', 'IconosModulo.ttf')

UPEM = 512
REJILLA = 24.0  # la reticula de Material
ESCALA = UPEM / REJILLA

# El senor aplicando insumos. En la zona privada de Unicode porque no es un
# caracter de nadie: es nuestro. Tiene que coincidir con `iconoAplicacion` en
# `lib/core/iconos_modulo.dart`.
APLICACION = 0xE900


def material_regular():
    """La MaterialIcons-Regular.otf del SDK de Flutter instalado."""
    flutter = subprocess.run(
        ['flutter', '--version', '--machine'],
        capture_output=True, text=True, shell=(os.name == 'nt'),
    )
    raiz = None
    m = re.search(r'"flutterRoot"\s*:\s*"([^"]+)"', flutter.stdout)
    if m:
        raiz = m.group(1).replace('\\\\', '\\')
    if not raiz:
        sys.exit('No se encontro el SDK de Flutter: ¿esta `flutter` en el PATH?')
    ruta = os.path.join(raiz, 'bin', 'cache', 'artifacts', 'material_fonts',
                        'MaterialIcons-Regular.otf')
    if not os.path.exists(ruta):
        sys.exit('Falta %s. Corre `flutter precache` primero.' % ruta)
    return ruta


def codepoints_del_mapa(raiz_flutter):
    """Los iconos que nombra el mapa de Dart, con su numero de glifo."""
    dart = open(MAPA, encoding='utf-8').read()
    nombres = set(re.findall(r'Icons\.([a-z_0-9]+)', dart))
    tabla = {}
    ruta = os.path.join(raiz_flutter, 'bin', 'cache', 'artifacts',
                        'material_fonts', 'codepoints')
    for linea in open(ruta, encoding='utf-8'):
        partes = linea.split()
        if len(partes) == 2:
            tabla[partes[0]] = int(partes[1], 16)
    faltan = sorted(n for n in nombres if n not in tabla)
    if faltan:
        sys.exit('Iconos que Material no tiene: %s' % ', '.join(faltan))
    return sorted(tabla[n] for n in nombres), sorted(nombres)


def a_cff_en_truetype(origen, destino):
    """Convierte contornos CFF a TrueType, que es lo unico que lee el PDF."""
    f = TTFont(origen)
    upem = f['head'].unitsPerEm
    gs = f.getGlyphSet()
    glyf = table__g_l_y_f()
    glyf.glyphs = {}
    glyf.glyphOrder = f.getGlyphOrder()
    for nombre in glyf.glyphOrder:
        pen = TTGlyphPen(gs)
        gs[nombre].draw(Cu2QuPen(pen, upem / 1000.0, reverse_direction=True))
        glyf.glyphs[nombre] = pen.glyph()
    f['loca'] = table__l_o_c_a()
    f['glyf'] = glyf
    f['maxp'].numGlyphs = len(glyf.glyphs)
    glyf.compile(f)
    f['head'].indexToLocFormat = 0 if f['loca'].locations[-1] < 0x20000 else 1
    for tag in ('CFF ', 'CFF2', 'VORG'):
        if tag in f:
            del f[tag]
    f.sfntVersion = '\000\001\000\000'
    f.save(destino)


# --- El glifo dibujado a mano -------------------------------------------
#
# Coordenadas en la reticula de 24x24 y con y hacia abajo, como en cualquier
# editor de vectores. `_af` las lleva a unidades de fuente, donde y sube.

def _af(x, y):
    return (x * ESCALA, (REJILLA - y) * ESCALA)


def _poligono(pen, puntos):
    pen.moveTo(_af(*puntos[0]))
    for p in puntos[1:]:
        pen.lineTo(_af(*p))
    pen.closePath()


def _circulo(pen, cx, cy, r, lados=16):
    _poligono(pen, [(cx + r * math.cos(2 * math.pi * i / lados),
                     cy + r * math.sin(2 * math.pi * i / lados))
                    for i in range(lados)])


def _barra(pen, x1, y1, x2, y2, grosor):
    dx, dy = x2 - x1, y2 - y1
    largo = math.hypot(dx, dy)
    nx, ny = -dy / largo * grosor / 2, dx / largo * grosor / 2
    _poligono(pen, [(x1 + nx, y1 + ny), (x2 + nx, y2 + ny),
                    (x2 - nx, y2 - ny), (x1 - nx, y1 - ny)])


def dibujar_aplicacion(pen):
    """Silueta de un agricultor aplicando insumos, de perfil y caminando."""
    # El tanque a la espalda, primero: queda detras del cuerpo.
    _poligono(pen, [(5.6, 7.4), (9.4, 7.4), (9.4, 13.4), (5.6, 13.4)])
    _barra(pen, 9.0, 7.8, 12.4, 7.0, 1.0)  # la correa del hombro

    # Cabeza y sombrero. El ala ancha es lo que dice «campo» a 12 px.
    _circulo(pen, 12.0, 4.6, 2.1)
    _poligono(pen, [(8.6, 3.2), (15.4, 3.2), (15.4, 4.3), (8.6, 4.3)])
    _poligono(pen, [(10.4, 1.4), (13.6, 1.4), (13.6, 3.4), (10.4, 3.4)])

    _poligono(pen, [(9.8, 6.6), (13.8, 6.6), (14.2, 13.6), (10.4, 13.6)])

    # Las dos piernas en zancada: quieto no se lee como «esta aplicando».
    _barra(pen, 11.2, 13.0, 8.8, 19.6, 2.3)
    _poligono(pen, [(6.4, 19.2), (9.8, 19.2), (9.8, 21.2), (6.4, 21.2)])
    _barra(pen, 13.2, 13.0, 15.6, 19.6, 2.3)
    _poligono(pen, [(14.2, 19.2), (17.8, 19.2), (17.8, 21.2), (14.2, 21.2)])

    _barra(pen, 13.4, 7.6, 17.0, 11.0, 2.0)  # el brazo
    _barra(pen, 16.4, 10.4, 21.4, 14.6, 1.4)  # la lanza

    # El chorro. Sin las gotas es un senor con un palo, no un senor aplicando.
    _circulo(pen, 21.6, 17.0, 1.0, 12)
    _circulo(pen, 19.4, 18.6, 0.8, 12)
    _circulo(pen, 22.4, 20.4, 0.8, 12)


def agregar_dibujados(ruta):
    f = TTFont(ruta)
    nombre = 'uniE900'
    pen = TTGlyphPen(None)
    dibujar_aplicacion(pen)
    f['glyf'][nombre] = pen.glyph()
    f['hmtx'][nombre] = (UPEM, 0)
    orden = f.getGlyphOrder()
    if nombre not in orden:
        f.setGlyphOrder(list(orden) + [nombre])
        f['maxp'].numGlyphs = len(f.getGlyphOrder())
    for tabla in f['cmap'].tables:
        tabla.cmap[APLICACION] = nombre
    f.save(ruta)


def main():
    material = material_regular()
    raiz = os.path.dirname(os.path.dirname(os.path.dirname(
        os.path.dirname(os.path.dirname(material)))))
    cps, nombres = codepoints_del_mapa(raiz)

    with tempfile.TemporaryDirectory() as tmp:
        ttf = os.path.join(tmp, 'material.ttf')
        a_cff_en_truetype(material, ttf)
        subset.main([
            ttf,
            '--unicodes=' + ','.join('U+%X' % c for c in cps),
            '--no-hinting', '--desubroutinize',
            '--output-file=' + SALIDA,
        ])

    agregar_dibujados(SALIDA)

    g = TTFont(SALIDA)
    cmap = g.getBestCmap()
    faltan = [hex(c) for c in cps + [APLICACION] if c not in cmap]
    if faltan:
        sys.exit('Quedaron glifos fuera: %s' % ', '.join(faltan))
    print('%s  %d bytes  %d glifos' % (
        os.path.relpath(SALIDA, APP), os.path.getsize(SALIDA),
        g['maxp'].numGlyphs))
    print('de Material: %s' % ', '.join(nombres))
    print('dibujados:   aplicacion de insumos (U+%X)' % APLICACION)


if __name__ == '__main__':
    main()

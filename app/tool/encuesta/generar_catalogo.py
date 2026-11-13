"""Agrega al catalogo de campos de la app los temas de la encuesta de caracterizacion.

Uso (desde la raiz del repo; requiere `pip install openpyxl`):

    python -I app/tool/encuesta/generar_catalogo.py

Lee  docs/encuesta-caracterizacion/encuesta_caracterizacion_productores.xlsx
     app/assets/semilla/catalogo.json
Escribe app/assets/semilla/catalogo.json

Las preguntas de la encuesta NO son un cuestionario aparte: son temas que se
hablan en la visita. Por eso entran al mismo catalogo que alimenta la lista
«Cobertura de la conversacion» y la extraccion desde la grabacion.

Cuatro grupos, que entre los cuatro cubren las 116 preguntas (el script falla
si sobra o falta alguna):

  TEMAS        se agregan al catalogo, con el texto de la pregunta tal cual.
  REACTIVADOS  ya tenian un campo en el Catalogo de Campos de Airtable, pero
               apagado: se prende ese campo en vez de crear uno que diga lo
               mismo.
  REDUNDANTES  ya las cubre un campo activo del catalogo, o la visita misma:
               no se agregan, para no preguntar dos veces lo mismo.
  QUITADAS     se pidio dejarlas por fuera.

Los temas nuevos (TEMAS) solo existen en la app. No se crean en Airtable: al
subir una visita, el backend descarta los hallazgos cuya clave no esta en el
catalogo de Airtable y las reporta, sin tocar la base. Los reactivados si
estan en Airtable y llevan su record id.

Volver a correrlo es seguro: quita lo que el mismo agrego antes y lo vuelve a
generar. Los 55 campos originales no se tocan.
"""
import datetime
import json
import pathlib
import re
import sys

import openpyxl

RAIZ = pathlib.Path(__file__).resolve().parents[3]
EXCEL = RAIZ / "docs" / "encuesta-caracterizacion" / "encuesta_caracterizacion_productores.xlsx"
CATALOGO = RAIZ / "app" / "assets" / "semilla" / "catalogo.json"
INFORME = RAIZ / "docs" / "encuesta-caracterizacion" / "TEMAS_VISITA.md"

# Se pidio quitarlas: escala de alimentacion (41-44), trabajo colectivo (67),
# detalle de ganaderia (76-79) y certificaciones (87).
QUITADAS = {41, 42, 43, 44, 67, 76, 77, 78, 79, 87}

# Numero de pregunta -> que la cubre ya. Cuando es un campo del catalogo va su
# clave tecnica, y el script comprueba que exista.
REDUNDANTES = {
    1: "el permiso de uso de datos que la visita pide al empezar",
    2: "no es un tema de conversacion: los temas sensibles no se sugieren",
    3: "nombre_productor",
    4: "documento_identidad",
    5: "telefono",
    6: "municipio_vereda",
    7: "personas_hogar",
    8: "personas_hogar",
    9: "personas_hogar",
    10: "personas_hogar",
    11: "personas_hogar",
    21: "anios_en_territorio",
    25: "anios_experiencia",
    46: "otros_ingresos",
    47: "ingreso_mensual",
    51: "lleva_registros",
    57: "area_total_ha",
    58: "tenencia",
    62: "cultivos_principales",
    65: "trabajo_familiar",
    68: "cultivos_principales",
    69: "area_por_cultivo",
    70: "edad_cultivo",
    71: "rendimiento",
    75: "animales",
    80: "fertilizantes_usados",
    81: "usa_bioinsumos",
    82: "tiene_analisis_suelo",
    83: "plaguicidas_usados",
    86: "practicas_conservacion_suelo",
    91: "comprador",
    96: "organizacion",
    98: "fuente_agua",
    99: "escasez_agua",
    101: "eventos_climaticos",
    102: "problemas_suelo",
    106: "calidad_senal",
    110: "relevo_generacional",
    112: "riesgo_principal",
    116: "que_quiere_mejorar",
}

# Preguntas que ya tenian su campo en el Catalogo de Campos de Airtable, pero
# apagado (Activo sin marcar). No se crea un tema nuevo que diga lo mismo: se
# prende el que ya existe. Numero de pregunta -> claves tecnicas de Airtable.
REACTIVADOS = {
    40: ["apoyos_recibidos"],
    53: ["tiene_credito"],
    64: ["maquinaria", "infraestructura"],
    66: ["contrata_jornaleros"],
    94: ["acceso_vial"],
}

# Esos campos tal como estan en Airtable (leidos el 2026-11-13). Conservan su
# nombre, su modulo, su tipo y su pregunta guia: aca no se reescriben. Si
# alguien los cambia alla, hay que copiar el cambio aca.
CAMPOS_DE_AIRTABLE = {
    "apoyos_recibidos": {
        "remote_id": "receS8AwujzVn81Vp",
        "campo": "Apoyos institucionales recibidos",
        "modulo": "Creditos y apoyos",
        "tipo_dato": "Texto",
        "opciones": None,
        "pregunta_guia": "¿Lo ha visitado alguna entidad o programa?",
        "prioridad": "3 Deseable",
    },
    "tiene_credito": {
        "remote_id": "reckASEqlFC5VX0yP",
        "campo": "Tiene credito",
        "modulo": "Creditos y apoyos",
        "tipo_dato": "Si/No",
        "opciones": None,
        "pregunta_guia": "¿Tiene algun credito o deuda con banco?",
        "prioridad": "2 Importante",
    },
    "maquinaria": {
        "remote_id": "rec3BnpEVIoUPF5Lr",
        "campo": "Maquinaria y equipos",
        "modulo": "Maquinaria e infraestructura",
        "tipo_dato": "Texto",
        "opciones": None,
        "pregunta_guia": "¿Que herramientas o maquinas tiene?",
        "prioridad": "3 Deseable",
    },
    "infraestructura": {
        "remote_id": "recOq4q14ZULpRf46",
        "campo": "Infraestructura de la finca",
        "modulo": "Maquinaria e infraestructura",
        "tipo_dato": "Texto",
        "opciones": None,
        "pregunta_guia": "¿Que construcciones tiene: beneficiadero, bodega, corral?",
        "prioridad": "3 Deseable",
    },
    "contrata_jornaleros": {
        "remote_id": "rec1670VwycXMbEaL",
        "campo": "Contrata jornaleros",
        "modulo": "Mano de obra",
        "tipo_dato": "Si/No",
        "opciones": None,
        "pregunta_guia": "¿Contrata gente para las labores?",
        "prioridad": "2 Importante",
    },
    "acceso_vial": {
        "remote_id": "recrkl2P4PXcObtRW",
        "campo": "Acceso vial",
        "modulo": "Maquinaria e infraestructura",
        "tipo_dato": "Lista",
        "opciones": "Pavimentado\nDestapado en buen estado\nDestapado en mal estado\nCamino de herradura\nFluvial",
        "pregunta_guia": "Observacion del visitador al llegar.",
        "prioridad": "3 Deseable",
    },
}

FAMILIA = "Familia y social"
ECONOMIA = "Economia y comercializacion"
TIERRA = "Tierra y tenencia"
INSUMOS = "Insumos y manejo"
CONECTIVIDAD = "Conectividad"
ASPIRACIONES = "Aspiraciones y proyectos"

# Numero de pregunta -> (modulo del catalogo, nombre corto del tema). Se usan
# los modulos que ya existen para que la lista no cambie de forma.
TEMAS = {
    12: (FAMILIA, "Nivel de estudios de cada persona"),
    13: (FAMILIA, "Sabe leer y escribir"),
    14: (FAMILIA, "Estudia actualmente"),
    15: (FAMILIA, "Afiliacion a salud"),
    16: (FAMILIA, "Ocupacion de cada persona"),
    17: (FAMILIA, "Dificultades permanentes"),
    18: (FAMILIA, "Jefatura del hogar"),
    19: (FAMILIA, "Se considera campesino"),
    20: (FAMILIA, "Pertenencia etnica"),
    22: ("Historia y origen", "Afectacion por el conflicto"),
    23: (TIERRA, "Vive en la finca"),
    24: (TIERRA, "Dedicacion a la finca"),
    26: ("Historia y origen", "Formacion en temas del campo"),
    27: (FAMILIA, "Cotiza a pension"),
    28: (FAMILIA, "Cuidado de personas a cargo"),
    29: (FAMILIA, "Vivienda: tenencia"),
    30: (FAMILIA, "Vivienda: material de las paredes"),
    31: (FAMILIA, "Vivienda: material del piso"),
    32: (FAMILIA, "Vivienda: cuartos para dormir"),
    33: (FAMILIA, "Vivienda: energia electrica"),
    34: ("Agua y riego", "Agua para tomar y cocinar"),
    35: (FAMILIA, "Vivienda: servicio sanitario"),
    36: (FAMILIA, "Vivienda: con que cocinan"),
    37: (FAMILIA, "Vivienda: manejo de la basura"),
    38: (FAMILIA, "Tiempo al pueblo, a salud y a la escuela"),
    39: (FAMILIA, "Sisben"),
    45: (FAMILIA, "Alimentos para el consumo de la casa"),
    48: (ECONOMIA, "Parte del ingreso que viene de la finca"),
    49: (ECONOMIA, "Los ingresos alcanzan"),
    50: (ECONOMIA, "La finca deja ganancia"),
    52: (ECONOMIA, "Cuenta, billetera digital y seguros"),
    54: (ECONOMIA, "Credito: por que no lo pidio o se lo negaron"),
    55: (ECONOMIA, "Credito: quien le presto"),
    56: (ECONOMIA, "RUT, Camara de Comercio y factura"),
    59: (TIERRA, "Documento de la tierra"),
    60: (TIERRA, "Documento de la tierra: a nombre de quien"),
    61: (FAMILIA, "Quien decide en la finca"),
    63: (TIERRA, "Como esta repartida la tierra"),
    72: ("Cultivos", "Destino de la cosecha"),
    73: ("Cultivos", "Perdidas de la cosecha"),
    74: ("Cultivos", "Semilla o material de siembra"),
    84: (INSUMOS, "Proteccion al aplicar quimicos"),
    85: (INSUMOS, "Envases vacios de quimicos"),
    88: (INSUMOS, "Asistencia tecnica: recibio"),
    89: (INSUMOS, "Asistencia tecnica: quien se la dio"),
    90: (INSUMOS, "Asistencia tecnica: utilidad"),
    92: (ECONOMIA, "Acuerdo con el comprador"),
    93: (ECONOMIA, "Como saca los productos"),
    95: (ECONOMIA, "Dificultades para vender"),
    97: (FAMILIA, "Participacion en organizaciones"),
    100: ("Agua y riego", "Cuidado del agua"),
    103: ("Riesgos y clima", "Tumba de monte o bosque"),
    104: (CONECTIVIDAD, "Aparatos en el hogar"),
    105: (CONECTIVIDAD, "Internet en la casa o la finca"),
    107: (CONECTIVIDAD, "Frecuencia de uso de internet"),
    108: (CONECTIVIDAD, "Manejo del celular y el computador"),
    109: (CONECTIVIDAD, "Para que usa el celular o internet"),
    111: (ASPIRACIONES, "Planes con la finca"),
    113: (ASPIRACIONES, "Temas en que quiere capacitarse"),
    114: (ASPIRACIONES, "Como prefiere el acompanamiento"),
    115: (ASPIRACIONES, "Interes en asociarse"),
}

# De cada persona del hogar: la respuesta es de varias personas, no una opcion.
DE_CADA_PERSONA = range(8, 18)
# Se responden con si o no aunque el Excel las liste como opciones.
SI_O_NO = {103}
UNIDADES = {32: "cuartos"}
ORIGEN = "encuesta"
ORIGEN_REACTIVADO = "reactivado"


def leer_encuesta():
    preguntas = {}
    hoja = openpyxl.load_workbook(EXCEL, data_only=True)["Encuesta"]
    for fila in hoja.iter_rows(min_row=5, values_only=True):
        if not isinstance(fila[0], (int, float)):
            continue
        opciones = []
        for linea in str(fila[4] or "").splitlines():
            m = re.match(r"^\s*(\d+)\.\s+(.+?)\s*$", linea)
            # «No sabe» y «Prefiere no responder» no son valores de un tema:
            # si no se hablo, el tema simplemente queda sin resolver.
            if m and int(m.group(1)) not in (98, 99):
                opciones.append(re.sub(r"\s*\(¿[^)]*\)|,?\s*¿cuál\?.*$", "", m.group(2)).strip())
        preguntas[int(fila[0])] = {
            "texto": str(fila[3]).strip(), "opciones": opciones, "tipo": str(fila[5]).strip(),
            "esencial": fila[8] == "Esencial", "sensible": str(fila[9] or "").startswith("Sí"),
            "codigo": fila[10],
        }
    return preguntas


def tipo_de_dato(n, q):
    """El tipo del catalogo y sus opciones, a partir del tipo de la encuesta."""
    # Lo de cada persona del hogar va primero: un solo «si» o «no» no dice de
    # cual de las personas se esta hablando.
    if n in DE_CADA_PERSONA:
        return "Texto", None
    if n in UNIDADES or q["tipo"] == "Número":
        return "Numero", None
    if n in SI_O_NO or q["tipo"] == "Sí / No":
        return "Si/No", None
    de_una_opcion = q["tipo"] in ("Única", "Frecuencia", "Escala")
    if de_una_opcion and q["opciones"]:
        return "Lista", "\n".join(q["opciones"])
    # Las de varias respuestas y las compuestas: lo que se dijo, en texto.
    return "Texto", None


def informe(encuesta, originales, reactivados, nuevos):
    """La lista de que entro, que no y por que, para revisarla sin leer el JSON."""
    por_clave = {c["clave_tecnica"]: c for c in originales}

    def corta(texto):
        return texto.replace("|", "/").replace("\n", " ")

    s = [
        "# Temas de la encuesta en la visita\n\n",
        "> Archivo generado por `app/tool/encuesta/generar_catalogo.py`. Para cambiarlo, edite las tablas de ese\n",
        "> script (`TEMAS`, `REACTIVADOS`, `REDUNDANTES`, `QUITADAS`) y vuelva a generar.\n\n",
        "Las preguntas de la encuesta no son un cuestionario aparte: son temas que se hablan en la visita. Entran al\n",
        "catálogo de campos de la app, que es de donde sale la lista «Cobertura de la conversación» y lo que la IA busca\n",
        "en la grabación.\n\n",
        f"- **{len(nuevos)} temas nuevos**: {sum(not c['no_sugerir'] for c in nuevos)} aparecen en la lista y "
        f"{sum(c['no_sugerir'] for c in nuevos)} son sensibles (no se sugieren).\n",
        f"- **{len(REACTIVADOS)} preguntas usan {len(reactivados)} campos que ya existían en Airtable, apagados**: "
        "se prendieron en vez de crear temas repetidos.\n",
        f"- **{len(REDUNDANTES)} preguntas no se agregaron** porque el catálogo o la visita ya las cubren.\n",
        f"- **{len(QUITADAS)} preguntas se quitaron** a pedido: {', '.join(map(str, sorted(QUITADAS)))}.\n\n",
        "## 1. Temas nuevos\n",
    ]
    modulo = None
    for c in sorted(nuevos, key=lambda c: (c["modulo"], c["pregunta_encuesta"])):
        if c["modulo"] != modulo:
            modulo = c["modulo"]
            s.append(f"\n### {modulo}\n\n| P | Tema | Pregunta | Tipo | En la lista |\n|---:|---|---|---|---|\n")
        s.append(f"| {c['pregunta_encuesta']} | {c['campo']} | {corta(c['pregunta_guia'])} | {c['tipo_dato']} | "
                 f"{'No: tema sensible' if c['no_sugerir'] else 'Sí'} |\n")
    s.append("\n## 2. Preguntas que usan un campo que ya existía en Airtable\n\n"
             "Estos campos estaban en el «Catalogo de Campos» con «Activo» sin marcar. Conservan su nombre, su módulo,\n"
             "su tipo y su pregunta guía, tal como están en Airtable. Aparecen en la lista en su propio módulo.\n\n"
             "| P | Pregunta de la encuesta | Campo de Airtable | Módulo | Pregunta guía | Tipo |\n"
             "|---:|---|---|---|---|---|\n")
    for c in reactivados:
        n = c["pregunta_encuesta"]
        s.append(f"| {n} | {corta(encuesta[n]['texto'])} | `{c['clave_tecnica']}`: {c['campo']} | {c['modulo']} | "
                 f"{corta(c['pregunta_guia'])} | {c['tipo_dato']} |\n")
    s.append("\n## 3. Preguntas que no se agregaron por repetidas\n\n"
             "| P | Pregunta de la encuesta | Ya la cubre |\n|---:|---|---|\n")
    for n, cubre in sorted(REDUNDANTES.items()):
        campo = por_clave.get(cubre)
        ya = f"`{cubre}`: {campo['pregunta_guia']}" if campo else cubre.capitalize()
        s.append(f"| {n} | {corta(encuesta[n]['texto'])} | {corta(ya)} |\n")
    s.append("\n## 4. Preguntas quitadas a pedido\n\n| P | Pregunta de la encuesta |\n|---:|---|\n")
    for n in sorted(QUITADAS):
        s.append(f"| {n} | {corta(encuesta[n]['texto'])} |\n")
    return "".join(s)


def main():
    encuesta = leer_encuesta()
    catalogo = json.loads(CATALOGO.read_text(encoding="utf-8"))
    originales = [c for c in catalogo["campos"] if c.get("origen") not in (ORIGEN, ORIGEN_REACTIVADO)]
    claves = {c["clave_tecnica"] for c in originales}

    errores = []
    grupos = [set(TEMAS), set(REACTIVADOS), set(REDUNDANTES), QUITADAS]
    if set().union(*grupos) != set(encuesta) or sum(map(len, grupos)) != len(encuesta):
        errores.append("TEMAS, REACTIVADOS, REDUNDANTES y QUITADAS no cubren las preguntas una sola vez cada una")
    for n, cubre in REDUNDANTES.items():
        if re.fullmatch(r"[a-z_]+", cubre) and cubre not in claves:
            errores.append(f"P{n}: el campo «{cubre}» no esta en el catalogo")
    claves_reactivadas = [clave for de_airtable in REACTIVADOS.values() for clave in de_airtable]
    if len(set(claves_reactivadas)) != len(claves_reactivadas):
        errores.append("REACTIVADOS repite un campo de Airtable en dos preguntas")
    for n, de_airtable in REACTIVADOS.items():
        for clave in de_airtable:
            if clave not in CAMPOS_DE_AIRTABLE:
                errores.append(f"P{n}: falta copiar «{clave}» de Airtable en CAMPOS_DE_AIRTABLE")
            if clave in claves:
                errores.append(f"P{n}: «{clave}» ya esta activo en el catalogo: va en REDUNDANTES")
    modulos = {c["modulo"] for c in originales}
    for n, (modulo, _) in TEMAS.items():
        if modulo not in modulos:
            errores.append(f"P{n}: el modulo «{modulo}» no existe en el catalogo")
        if encuesta[n]["codigo"] in claves or encuesta[n]["codigo"] in claves_reactivadas:
            errores.append(f"P{n}: la clave «{encuesta[n]['codigo']}» ya existe en el catalogo")
    if errores:
        raise SystemExit("No se genero nada:\n  - " + "\n  - ".join(errores))

    reactivados = []
    for n, de_airtable in sorted(REACTIVADOS.items()):
        for clave in de_airtable:
            a = CAMPOS_DE_AIRTABLE[clave]
            reactivados.append({
                "clave_tecnica": clave,
                "campo": a["campo"],
                "modulo": a["modulo"],
                "tipo_dato": a["tipo_dato"],
                "unidad": None,
                "opciones": a["opciones"],
                "pregunta_guia": a["pregunta_guia"],
                # En Airtable «Obligatorio MVP» esta sin marcar. Aca va en
                # verdadero porque es lo que pone el tema en la lista de la
                # visita, que es para lo que se prendio.
                "obligatorio_mvp": True,
                "prioridad": a["prioridad"],
                "activo": True,
                "no_sugerir": False,
                "remote_id": a["remote_id"],
                "origen": ORIGEN_REACTIVADO,
                "pregunta_encuesta": n,
            })

    nuevos = []
    for n, (modulo, nombre) in sorted(TEMAS.items()):
        q = encuesta[n]
        tipo, opciones = tipo_de_dato(n, q)
        nuevos.append({
            "clave_tecnica": q["codigo"],
            "campo": nombre,
            "modulo": modulo,
            "tipo_dato": tipo,
            "unidad": UNIDADES.get(n),
            "opciones": opciones,
            "pregunta_guia": q["texto"],
            # Un tema sensible no se le sugiere al visitador ni cuenta para la
            # cobertura: se registra solo si el productor lo cuenta.
            "obligatorio_mvp": not q["sensible"],
            "prioridad": "2 Importante" if q["esencial"] else "3 Deseable",
            "activo": True,
            "no_sugerir": q["sensible"],
            "remote_id": None,
            "origen": ORIGEN,
            "pregunta_encuesta": n,
        })

    campos = originales + reactivados + nuevos
    catalogo["campos"] = campos
    catalogo["activos"] = sum(c.get("activo", True) for c in campos)
    catalogo["obligatorios"] = sum(bool(c.get("obligatorio_mvp")) and c.get("activo", True) for c in campos)
    # La app vuelve a sembrar el catalogo cuando cambia esta fecha o cambia la
    # cantidad de campos activos.
    catalogo["generado"] = datetime.date.today().isoformat()
    catalogo["_nota_encuesta"] = (
        f"{len(nuevos)} campos con origen=encuesta: temas de la encuesta de caracterizacion, agregados por "
        "tool/encuesta/generar_catalogo.py. Solo existen en la app; no estan en el Catalogo de Campos de Airtable. "
        f"{len(reactivados)} campos con origen=reactivado: ya existian en el Catalogo de Campos de Airtable, "
        "inactivos, y cubren preguntas de la encuesta; llevan su record id."
    )
    CATALOGO.write_text(json.dumps(catalogo, ensure_ascii=False, indent=2) + "\n", encoding="utf-8", newline="\n")

    INFORME.write_text(informe(encuesta, originales, reactivados, nuevos), encoding="utf-8", newline="\n")

    sugeribles = sum(c["obligatorio_mvp"] and not c["no_sugerir"] for c in nuevos)
    print(f"escrito {CATALOGO.relative_to(RAIZ)}: {len(originales)} originales + {len(reactivados)} reactivados "
          f"+ {len(nuevos)} de la encuesta = {catalogo['activos']} activos, {catalogo['obligatorios']} obligatorios")
    print(f"temas nuevos en la lista: {sugeribles} | sensibles (no se sugieren): {len(nuevos) - sugeribles} | "
          f"reactivados: {len(reactivados)} | redundantes: {len(REDUNDANTES)} | quitadas: {len(QUITADAS)}")


if __name__ == "__main__":
    sys.exit(main())

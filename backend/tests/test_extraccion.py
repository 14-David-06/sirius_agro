"""Pruebas de la extraccion, sin red ni credenciales.

`construir_resultado` esta separado del POST para poder verificar lo que el
resto del sistema da por cierto: que ninguna clave inventada entre a la base,
y que el mapeo de hablante no adivine cuando no se sabe.
"""

import pytest

from app.schemas import CampoCatalogo
from app.services import extraccion as ex

CAMPOS = [
    CampoCatalogo(
        clave_tecnica="area_total_ha",
        campo="Area total de la finca",
        modulo="Tierra y tenencia",
        tipo_dato="Numero",
        unidad="ha",
    ),
    CampoCatalogo(
        clave_tecnica="tenencia",
        campo="Tipo de tenencia",
        modulo="Tierra y tenencia",
        tipo_dato="Lista",
        opciones="Propia con titulo\nArriendo\nSucesion",
    ),
    CampoCatalogo(
        clave_tecnica="area_por_cultivo",
        campo="Area por cultivo",
        modulo="Cultivos",
        unidad="ha",
    ),
]
CLAVES = {c.clave_tecnica for c in CAMPOS}


def _hallazgo(**extra):
    base = {
        "clave": "area_total_ha",
        "entidad_destino": "Finca",
        "valor_numerico": 12,
        "unidad": "ha",
        "certeza": "Estimado",
        "hablante": 2,
        "cita": "seran unas doce hectareas",
        "segundo": 30,
    }
    base.update(extra)
    return base


class TestEsquema:
    def test_la_clave_es_un_enum_cerrado(self):
        """Una clave inventada tiene que ser un error del proveedor, no un
        hallazgo que entra apuntando a un campo que no existe."""
        esquema = ex.esquema(sorted(CLAVES))
        clave = esquema["properties"]["hallazgos"]["items"]["properties"]["clave"]

        assert clave["enum"] == sorted(CLAVES)

    def test_cita_y_segundo_son_obligatorios(self):
        # Sin cita no hay procedencia; sin segundo no se puede volver al audio.
        requeridos = ex.esquema(["x"])["properties"]["hallazgos"]["items"]["required"]

        assert "cita" in requeridos
        assert "segundo" in requeridos
        assert "hablante" in requeridos

    def test_no_legible_y_pendiente_no_son_opciones_del_modelo(self):
        """El modelo declara lo que observo; los estados que salen de una regla
        los pone el codigo, no el modelo."""
        certeza = ex.esquema(["x"])["properties"]["hallazgos"]["items"]["properties"][
            "certeza"
        ]

        assert certeza["enum"] == ["Confirmado", "Estimado", "Inferido"]

    def test_el_valor_admite_null(self):
        props = ex.esquema(["x"])["properties"]["hallazgos"]["items"]["properties"]

        assert "null" in props["valor_texto"]["type"]
        assert "null" in props["valor_numerico"]["type"]
        assert "null" in props["razonamiento"]["type"]


class TestListaDeCampos:
    def test_incluye_tipo_unidad_y_valores_permitidos(self):
        texto = ex._lista_de_campos(CAMPOS)

        assert "area_total_ha (Tierra y tenencia)" in texto
        assert "unidad esperada: ha" in texto
        assert "Propia con titulo | Arriendo | Sucesion" in texto

    def test_un_tipo_desconocido_no_rompe_la_lista(self):
        texto = ex._lista_de_campos(
            [CampoCatalogo(clave_tecnica="raro", tipo_dato="Inventado")]
        )
        assert "raro" in texto


class TestPrompt:
    def test_la_prohibicion_esta_literal(self):
        # Es la instruccion que sostiene todo el modelo de datos.
        assert "no inventes nada" in ex.SYSTEM.lower()

    def test_explica_el_formato_de_la_transcripcion(self):
        # Si el formato cambia en transcription.py, hay que cambiarlo aqui.
        assert "[mm:ss] Hablante N:" in ex.SYSTEM

    def test_exige_copiar_la_cita_tal_cual(self):
        assert "TAL CUAL" in ex.SYSTEM

    def test_cubre_los_casos_del_ejemplo_canonico(self):
        s = ex.SYSTEM.lower()
        # Cultivo abandonado, producto sin nombre, y el aproximado.
        assert "abandono" in s
        assert "sin nombre" in s
        assert "unos veinte anios" in s
        # Y que los cultivos no se mezclen.
        assert "entidad_local_id" in s


class TestConstruirResultado:
    def test_pasa_los_hallazgos_con_su_procedencia(self):
        r = ex.construir_resultado(
            {"hallazgos": [_hallazgo()], "resumen": "Visita corta.", "temas_pendientes": []},
            hablante_visitador=1,
            claves_validas=CLAVES,
        )

        assert len(r.hallazgos) == 1
        h = r.hallazgos[0]
        assert h["clave"] == "area_total_ha"
        assert h["certeza"] == "Estimado"
        assert h["cita"] == "seran unas doce hectareas"
        assert h["segundo"] == 30
        assert h["fuente"] == "Audio"
        assert r.resumen == "Visita corta."

    def test_descarta_una_clave_que_no_existe_y_lo_dice(self):
        r = ex.construir_resultado(
            {
                "hallazgos": [_hallazgo(clave="area_de_riego_inventada")],
                "temas_pendientes": [],
            },
            claves_validas=CLAVES,
        )

        assert r.hallazgos == []
        # No se pierde en silencio: queda como tema pendiente visible.
        assert any("Clave desconocida" in t for t in r.temas_pendientes)

    def test_tres_cultivos_conservan_su_entidad(self):
        crudo = {
            "hallazgos": [
                _hallazgo(
                    clave="area_por_cultivo",
                    entidad_destino="Cultivo",
                    entidad_local_id=f"cultivo_{i}",
                    valor_numerico=area,
                    valor_texto=nombre,
                )
                for i, (nombre, area) in enumerate(
                    [("platano", 4), ("yuca", 2.5), ("maiz", 1)], start=1
                )
            ],
            "temas_pendientes": [],
        }
        r = ex.construir_resultado(crudo, claves_validas=CLAVES)

        assert [h["entidad_local_id"] for h in r.hallazgos] == [
            "cultivo_1",
            "cultivo_2",
            "cultivo_3",
        ]
        assert [h["valor_numerico"] for h in r.hallazgos] == [4, 2.5, 1]


class TestMapeoDeHablante:
    @pytest.mark.parametrize(
        "numero,visitador,esperado",
        [
            (1, 1, "visitador"),
            (2, 1, "agricultor"),
            (1, 2, "agricultor"),
            # Sin confirmacion NO se adivina: equivocarse aca invierte la regla
            # dura y avala el dato del visitador.
            (2, None, "no identificado"),
            (None, 1, "no identificado"),
            (None, None, "no identificado"),
        ],
    )
    def test_solo_traduce_cuando_se_sabe(self, numero, visitador, esperado):
        assert ex._hablante_a_texto(numero, visitador) == esperado

    def test_el_dato_del_visitador_llega_marcado_como_tal(self):
        # Lo que hace verificable la regla: la app baja esto a Estimado.
        r = ex.construir_resultado(
            {
                "hallazgos": [
                    _hallazgo(certeza="Confirmado", hablante=1, cita="usted usa DAP, cierto?")
                ],
                "temas_pendientes": [],
            },
            hablante_visitador=1,
            claves_validas=CLAVES,
        )

        assert r.hallazgos[0]["hablante"] == "visitador"
        assert r.hallazgos[0]["certeza"] == "Confirmado"

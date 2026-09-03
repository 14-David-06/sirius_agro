"""Pruebas de la transcripcion diarizada, sin red ni credenciales.

`construir_resultado` esta separado del POST justamente para esto: se puede
probar contra una respuesta guardada de ElevenLabs y verificar lo unico que le
importa al resto del sistema — que los turnos queden con su segundo y su
hablante, porque de ahi salen las citas que sostienen cada hallazgo.
"""

import pytest

from app.config import Settings
from app.services import transcription as tr
from app.services import vocabulario
from app.schemas import HablanteStats, Turno


def _palabras(hablante, inicio, fin, texto):
    """Reparte `texto` en palabras entre `inicio` y `fin`.

    ElevenLabs no devuelve turnos ya cerrados como Deepgram: manda las palabras
    sueltas, cada una con su hablante y su segundo. Agruparlas es trabajo del
    backend, y es lo que estas pruebas verifican.
    """
    partes = texto.split()
    paso = (fin - inicio) / len(partes)
    return [
        {
            "text": palabra,
            "type": "word",
            "start": round(inicio + i * paso, 2),
            "end": fin if i == len(partes) - 1 else round(inicio + (i + 1) * paso, 2),
            "speaker_id": f"speaker_{hablante}",
        }
        for i, palabra in enumerate(partes)
    ]


# Una visita corta con las cosas que el Dia 5 tiene que poder distinguir:
# el visitador sugiriendo un dato, un aproximado, y tres cultivos.
#
# El salto de 12.4 a 30.1 es a proposito: la misma voz vuelve a hablar tras un
# silencio largo, y eso tiene que abrir un turno nuevo o la cita apunta al
# segundo equivocado.
RESPUESTA = {
    "language_code": "es",
    "language_probability": 0.97,
    "text": (
        "Buenos dias don Pedro, yo trabajo con Sirius. "
        "Buenos dias, mucho gusto, Pedro Rodriguez. "
        "La finca sera de unas doce hectareas. "
        "Tengo platano, yuca y un poquito de maiz. "
        "Usted usa DAP, cierto? "
        "Si senor, eso es lo que le echo."
    ),
    "words": [
        *_palabras(0, 0.5, 6.2, "Buenos dias don Pedro, yo trabajo con Sirius."),
        *_palabras(1, 6.8, 12.4, "Buenos dias, mucho gusto, Pedro Rodriguez."),
        *_palabras(1, 30.1, 38.9, "La finca sera de unas doce hectareas."),
        *_palabras(1, 41.5, 52.5, "Tengo platano, yuca y un poquito de maiz."),
        *_palabras(0, 60.0, 63.1, "Usted usa DAP, cierto?"),
        *_palabras(1, 64.0, 70.2, "Si senor, eso es lo que le echo."),
    ],
}


class TestTurnos:
    def test_cada_turno_trae_hablante_y_segundo(self):
        r = tr.construir_resultado(RESPUESTA, "scribe_v2")

        assert len(r.turnos) == 6
        assert r.turnos[0] == Turno(
            hablante=0,
            inicio=0.5,
            fin=6.2,
            texto="Buenos dias don Pedro, yo trabajo con Sirius.",
        )
        assert r.turnos[2].inicio == 30.1
        assert r.turnos[2].hablante == 1

    def test_agrupa_palabras_consecutivas_de_la_misma_voz(self):
        """Perder los turnos deja todos los hallazgos en Pendiente."""
        data = {
            "text": "Hola que tal. Bien, gracias.",
            "words": [
                {"text": "Hola", "type": "word", "start": 0.0, "end": 0.4, "speaker_id": "speaker_0"},
                {"text": "que", "type": "word", "start": 0.5, "end": 0.7, "speaker_id": "speaker_0"},
                {"text": "tal.", "type": "word", "start": 0.8, "end": 1.0, "speaker_id": "speaker_0"},
                {"text": "Bien,", "type": "word", "start": 1.5, "end": 1.9, "speaker_id": "speaker_1"},
                {"text": "gracias.", "type": "word", "start": 2.0, "end": 2.6, "speaker_id": "speaker_1"},
            ],
        }
        turnos = tr.construir_resultado(data, "scribe_v2").turnos

        assert len(turnos) == 2
        assert turnos[0].texto == "Hola que tal."
        assert turnos[0].hablante == 0
        assert turnos[1].texto == "Bien, gracias."
        assert turnos[1].inicio == 1.5
        assert turnos[1].fin == 2.6

    def test_una_pausa_larga_abre_turno_nuevo_aunque_sea_la_misma_voz(self):
        """Sin esto la respuesta de las 30:01 quedaria citada en el segundo 6."""
        turnos = tr.construir_resultado(RESPUESTA, "scribe_v2").turnos

        assert turnos[1].fin == 12.4
        assert turnos[2].inicio == 30.1
        assert turnos[1].hablante == turnos[2].hablante == 1

    def test_ignora_espacios_y_eventos_de_audio(self):
        """`spacing` y `audio_event` no son habla de nadie."""
        data = {
            "text": "Hola",
            "words": [
                {"text": "Hola", "type": "word", "start": 0.0, "end": 0.4, "speaker_id": "speaker_0"},
                {"text": " ", "type": "spacing", "start": 0.4, "end": 0.5, "speaker_id": "speaker_0"},
                {"text": "(risas)", "type": "audio_event", "start": 0.5, "end": 1.0, "speaker_id": "speaker_0"},
            ],
        }
        turnos = tr.construir_resultado(data, "scribe_v2").turnos

        assert len(turnos) == 1
        assert turnos[0].texto == "Hola"

    def test_traduce_el_hablante_a_entero_por_orden_de_aparicion(self):
        """El proveedor no siempre nombra las voces `speaker_N`."""
        data = {
            "text": "uno dos",
            "words": [
                {"text": "uno", "type": "word", "start": 0.0, "end": 0.4, "speaker_id": "customer"},
                {"text": "dos", "type": "word", "start": 1.0, "end": 1.4, "speaker_id": "agent"},
            ],
        }
        turnos = tr.construir_resultado(data, "scribe_v2").turnos

        assert [t.hablante for t in turnos] == [0, 1]

    def test_descarta_turnos_vacios(self):
        data = {
            "text": "hola",
            "words": [
                {"text": "   ", "type": "word", "start": 1.0, "end": 2.0, "speaker_id": "speaker_0"},
                {"text": "hola", "type": "word", "start": 3.0, "end": 4.0, "speaker_id": "speaker_1"},
            ],
        }
        assert len(tr.construir_resultado(data, "scribe_v2").turnos) == 1

    def test_sin_diarizacion_no_hay_turnos_ni_marcas(self):
        """No se fabrica un turno unico: seria aparentar una marca que nadie midio."""
        data = {
            "text": "texto plano",
            "words": [
                {"text": "texto", "type": "word", "start": 0.0, "end": 0.5},
                {"text": "plano", "type": "word", "start": 0.6, "end": 1.0},
            ],
        }
        r = tr.construir_resultado(data, "scribe_v2")

        assert r.turnos == []
        assert r.text_with_timestamps == ""
        assert r.text == "texto plano"


class TestFormato:
    def test_el_formato_lleva_minuto_segundo_y_hablante(self):
        r = tr.construir_resultado(RESPUESTA, "scribe_v2")
        lineas = r.text_with_timestamps.split("\n")

        assert lineas[0] == "[00:00] Hablante 1: Buenos dias don Pedro, yo trabajo con Sirius."
        assert lineas[2] == "[00:30] Hablante 2: La finca sera de unas doce hectareas."
        assert len(lineas) == 6

    def test_los_hablantes_se_numeran_desde_uno_para_el_humano(self):
        """El backend cuenta desde 0; a una persona se le habla de Hablante 1."""
        assert "Hablante 1" in tr.formatear_con_marcas([Turno(hablante=0, inicio=0, fin=1, texto="x")])

    def test_pasado_el_minuto_sigue_bien(self):
        turnos = [Turno(hablante=0, inicio=754.0, fin=760.0, texto="tarde")]
        assert tr.formatear_con_marcas(turnos).startswith("[12:34]")


class TestEstadisticas:
    def test_suma_tiempo_y_turnos_por_voz(self):
        r = tr.construir_resultado(RESPUESTA, "scribe_v2")

        assert r.hablantes == [
            # 5.7 + 3.1
            HablanteStats(hablante=0, segundos=8.8, turnos=2),
            # 5.6 + 8.8 + 11.0 + 6.2
            HablanteStats(hablante=1, segundos=31.6, turnos=4),
        ]


class TestSugerenciaDeVisitador:
    def test_propone_al_que_hablo_menos(self):
        r = tr.construir_resultado(RESPUESTA, "scribe_v2")

        assert r.hablante_visitador_sugerido == 0
        assert "22%" in r.razon_sugerencia
        assert "agricultor habla mas" in r.razon_sugerencia

    def test_con_una_sola_voz_no_propone_nada(self):
        stats = [HablanteStats(hablante=0, segundos=100.0, turnos=5)]
        sugerido, razon = tr.sugerir_visitador(stats)

        assert sugerido is None
        assert "una voz" in razon

    def test_si_hablaron_parecido_no_adivina(self):
        """Fingir precision aca invierte la regla dura y avala el dato equivocado."""
        stats = [
            HablanteStats(hablante=0, segundos=100.0, turnos=10),
            HablanteStats(hablante=1, segundos=105.0, turnos=11),
        ]
        sugerido, razon = tr.sugerir_visitador(stats)

        assert sugerido is None
        assert "a mano" in razon

    def test_sin_turnos_no_propone_nada(self):
        assert tr.sugerir_visitador([]) == (
            None,
            "Solo se detecto una voz: no se puede distinguir al visitador del agricultor.",
        )


class TestMetadata:
    def test_pasa_duracion_y_motor(self):
        r = tr.construir_resultado(RESPUESTA, "scribe_v2")

        # ElevenLabs no manda la duracion del audio: sale de la ultima palabra.
        assert r.duration_seconds == 70.2
        assert r.motor == "scribe_v2"
        assert r.language == "es"


class TestParametrosDeLaPeticion:
    def _form(self, diarizar=True, terminos=("Guaicaramo",), **extra):
        s = Settings(elevenlabs_model="scribe_v2", elevenlabs_language="es", **extra)
        return tr._form(s, list(terminos), diarizar)

    def test_diarizacion_pide_marcas_por_palabra(self):
        form = self._form()

        assert form["diarize"] == "true"
        # Sin marcas por palabra no hay con que reconstruir los turnos.
        assert form["timestamps_granularity"] == "word"
        assert form["language_code"] == "es"
        assert form["model_id"] == "scribe_v2"

    def test_sin_diarizar_lo_dice_explicito(self):
        assert self._form(diarizar=False)["diarize"] == "false"

    def test_los_eventos_de_audio_no_se_piden(self):
        """"(risas)" no trae hablante y ensucia las citas."""
        assert self._form()["tag_audio_events"] == "false"

    def test_el_vocabulario_va_como_keyterms(self):
        form = self._form(terminos=["Guaicaramo", "gallinaza"])
        assert form["keyterms"] == ["Guaicaramo", "gallinaza"]

    def test_sin_terminos_no_manda_el_campo(self):
        assert "keyterms" not in self._form(terminos=[])

    def test_descarta_terminos_mas_largos_que_el_tope(self):
        largo = "x" * 60
        assert self._form(terminos=["Guaicaramo", largo])["keyterms"] == ["Guaicaramo"]

    def test_no_fija_el_numero_de_voces_por_defecto(self):
        """Fijar 2 fusionaria las voces si en la visita habla un tercero."""
        assert "num_speakers" not in self._form()
        assert self._form(elevenlabs_num_speakers=3)["num_speakers"] == "3"


class TestVocabulario:
    def test_las_siete_veredas_estan(self):
        terminos = {t.casefold() for t in vocabulario.construir()}
        for v in ["carutal", "el algarrobo", "el hijoa", "guaicaramo",
                  "las moras", "los pavitos", "san ignacio"]:
            assert v in terminos

    def test_lo_de_la_visita_va_primero(self):
        """Si hay que recortar por el limite, lo generico es lo que sobra."""
        terminos = vocabulario.construir(["Pedro Estupinan"], limite=3)

        assert terminos[0] == "Pedro Estupinan"
        assert len(terminos) == 3

    def test_no_repite_lo_que_ya_estaba(self):
        terminos = vocabulario.construir(["Guaicaramo", "guaicaramo", "GUAICARAMO"])
        assert sum(1 for t in terminos if t.casefold() == "guaicaramo") == 1

    def test_descarta_vacios(self):
        assert "" not in vocabulario.construir(["", "   "])

    @pytest.mark.parametrize(
        "nombre,esperado",
        [
            ("Pedro Rodriguez", ["Pedro Rodriguez", "Pedro", "Rodriguez"]),
            # "de" y "la" no aportan y gastan cupo.
            ("Maria de la Cruz Nino", ["Maria Cruz Nino", "Maria", "Cruz", "Nino"]),
            ("Pedro", ["Pedro"]),
            ("", []),
        ],
    )
    def test_parte_el_nombre_en_terminos_utiles(self, nombre, esperado):
        assert vocabulario.desde_nombre(nombre) == esperado

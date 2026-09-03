"""Pruebas del bucket, sin red ni credenciales.

Lo que se verifica es la URL: si sale mal, Airtable no puede ir a buscar el
archivo y el adjunto queda vacio sin que nadie se entere hasta meses despues,
cuando alguien quiera volver a escuchar la cita que respalda un dato.
"""

import pytest
from fastapi import HTTPException

from app.config import Settings
from app.services import almacenamiento as alm


def _s(**kwargs) -> Settings:
    base = {
        "bucket_name": "sirius-agro-campo",
        "bucket_access_key": "AKIA-test",
        "bucket_secret_key": "secreto",
        "bucket_region": "us-east-1",
    }
    base.update(kwargs)
    return Settings(**base)


class TestConfigurado:
    def test_en_aws_el_endpoint_no_hace_falta(self):
        """AWS lo deduce de la region; exigirlo dejaria fuera al mas comun."""
        assert alm.configurado(_s()) is True

    def test_sin_llaves_no_esta_configurado(self):
        assert alm.configurado(_s(bucket_secret_key="")) is False

    def test_sin_nombre_no_esta_configurado(self):
        assert alm.configurado(_s(bucket_name="")) is False


class TestUrlPublica:
    def test_en_aws_usa_el_dominio_del_bucket(self):
        url = alm.url_publica(_s(), "visitas/abc/audio/tramo-1.m4a")
        assert url == (
            "https://sirius-agro-campo.s3.us-east-1.amazonaws.com/"
            "visitas/abc/audio/tramo-1.m4a"
        )

    def test_el_dominio_publico_manda_sobre_todo(self):
        """Es lo que se pone cuando hay CDN o el endpoint no es alcanzable."""
        url = alm.url_publica(
            _s(bucket_public_url="https://media.sirius.co/"), "visitas/a/f.jpg"
        )
        assert url == "https://media.sirius.co/visitas/a/f.jpg"

    def test_con_endpoint_propio_usa_estilo_path(self):
        """R2, B2 y MinIO no siempre resuelven el virtual-host."""
        url = alm.url_publica(
            _s(bucket_endpoint="https://x.r2.cloudflarestorage.com"),
            "visitas/a/f.jpg",
        )
        assert url == (
            "https://x.r2.cloudflarestorage.com/sirius-agro-campo/visitas/a/f.jpg"
        )


class TestClave:
    def test_agrupa_por_visita(self):
        """Borrar una visita revocada tiene que ser borrar un prefijo."""
        assert (
            alm.clave_de("uuid-1", "audio", "tramo-1.m4a")
            == "visitas/uuid-1/audio/tramo-1.m4a"
        )

    @pytest.mark.parametrize("nombre", ["../../etc/passwd", "a/b/c.m4a", "a\\b.m4a"])
    def test_un_nombre_con_rutas_no_se_escapa_del_prefijo(self, nombre):
        """El nombre lo manda el cliente: no puede sacar el archivo de su visita."""
        clave = alm.clave_de("uuid-1", "audio", nombre)
        assert clave.startswith("visitas/uuid-1/audio/")
        assert clave.count("visitas/") == 1

    def test_un_nombre_vacio_no_deja_la_clave_colgando(self):
        assert alm.clave_de("uuid-1", "fotos", "   ") == "visitas/uuid-1/fotos/archivo"


class TestSubidaSinConfigurar:
    def test_dice_que_falta_configurar_en_vez_de_reventar(self):
        # Los campos van en blanco explicitamente: `Settings()` a secas lee el
        # .env de quien corre las pruebas, asi que el test pasaria o fallaria
        # segun la maquina.
        sin_bucket = _s(bucket_name="", bucket_access_key="", bucket_secret_key="")

        with pytest.raises(HTTPException) as exc:
            alm.subir(
                sin_bucket,
                b"x",
                codigo_visita="v1",
                categoria="audio",
                nombre="a.m4a",
            )

        assert exc.value.status_code == 500
        assert "BUCKET_NAME" in exc.value.detail

    def test_un_archivo_vacio_es_error_del_cliente_no_del_bucket(self):
        with pytest.raises(HTTPException) as exc:
            alm.subir(_s(), b"", codigo_visita="v1", categoria="audio", nombre="a.m4a")

        assert exc.value.status_code == 400


class TestTipoDeContenido:
    @pytest.mark.parametrize(
        "nombre,esperado",
        [
            ("tramo-1.m4a", "audio/mp4"),
            ("foto.jpg", "image/jpeg"),
            ("foto.PNG", "image/png"),
        ],
    )
    def test_el_tipo_sale_de_la_extension_no_del_cliente(self, nombre, esperado):
        """De esto depende que el navegador reproduzca el audio."""
        assert alm._tipo(nombre) == esperado


class TestNombreOrdenado:
    """El bucket lo va a abrir alguien a los seis meses buscando la etiqueta
    de un insumo. `foto-1788370464996.jpg` no le dice nada."""

    def test_renombra_la_foto_a_su_posicion(self):
        assert alm.nombre_ordenado("fotos", "foto-1788370464996.jpg", 3) == "foto-03.jpg"

    def test_renombra_el_tramo_a_su_posicion(self):
        assert alm.nombre_ordenado("audio", "grabacion.m4a", 2) == "tramo-02.m4a"

    def test_rellena_con_cero_para_que_ordene_como_texto(self):
        """S3 ordena alfabeticamente: sin el cero, foto-10 va antes que foto-2."""
        nombres = sorted(
            alm.nombre_ordenado("fotos", "x.jpg", i) for i in (2, 10, 1)
        )
        assert nombres == ["foto-01.jpg", "foto-02.jpg", "foto-10.jpg"]

    def test_de_dos_digitos_para_arriba_no_recorta(self):
        assert alm.nombre_ordenado("fotos", "x.jpg", 120) == "foto-120.jpg"

    def test_conserva_la_extension_en_minuscula(self):
        assert alm.nombre_ordenado("fotos", "FOTO.JPEG", 1) == "foto-01.jpeg"

    def test_sin_orden_conserva_el_nombre(self):
        """Mejor un nombre feo que inventar una posicion que no se sabe."""
        original = "foto-1788370464996.jpg"
        assert alm.nombre_ordenado("fotos", original, None) == original

    def test_un_archivo_sin_extension_no_rompe(self):
        assert alm.nombre_ordenado("fotos", "sinpunto", 1) == "foto-01.bin"

    def test_la_clave_completa_queda_ordenada(self):
        assert (
            alm.clave_de("uuid-1", "fotos", "foto-1788370464996.jpg", 3)
            == "visitas/uuid-1/fotos/foto-03.jpg"
        )

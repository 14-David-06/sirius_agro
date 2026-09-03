"""El login contra nomina.

Lo que se protege aca no es "que entre quien debe", sino los tres modos de
fallar mal: filtrar quien trabaja en la empresa, aceptar un registro sin
hashear, y dejar entrar a alguien que ya no esta activo.
"""

import bcrypt
import httpx
import pytest

from app.config import get_settings
from app.services import nomina

PASSWORD = "Contrasena-de-prueba-1"
# Como la teclearia el visitador: sin puntos. En nomina esta con puntos.
CEDULA = "1234567890"
HASH = bcrypt.hashpw(PASSWORD.encode(), bcrypt.gensalt(rounds=4)).decode()


def _registro(**cambios):
    campos = {
        nomina.CAMPO_ID_EMPLEADO: "SIRIUS-PER-0007",
        nomina.CAMPO_DOCUMENTO: "1.234.567.890",
        nomina.CAMPO_NOMBRE: "Persona De Prueba",
        nomina.CAMPO_EMAIL: "persona@siriusregenerative.com",
        nomina.CAMPO_PASSWORD: HASH,
        nomina.CAMPO_ESTADO: "Activo",
        nomina.CAMPO_NIVEL: ["Usuario"],
        nomina.CAMPO_ORDEN_NIVEL: [3],
        nomina.CAMPO_ROL: ["Operario"],
    }
    campos.update(cambios)
    return {"id": "recTEST", "fields": campos}


@pytest.fixture
def nomina_responde(monkeypatch):
    """Reemplaza la llamada HTTP a Airtable por lo que devuelva `registros`."""

    def instalar(registros):
        capturado = {}

        class _Cliente:
            def __init__(self, *a, **k):
                pass

            async def __aenter__(self):
                return self

            async def __aexit__(self, *a):
                return False

            async def get(self, url, headers=None, params=None):
                capturado["url"] = url
                capturado["params"] = params or {}
                return httpx.Response(200, json={"records": registros})

        monkeypatch.setattr(nomina.httpx, "AsyncClient", _Cliente)
        return capturado

    return instalar


def test_login_correcto_devuelve_el_empleado_y_el_hash(client, auth, nomina_responde):
    nomina_responde([_registro()])

    r = client.post(
        "/v1/auth/login",
        headers=auth,
        json={"cedula": CEDULA, "password": PASSWORD},
    )

    assert r.status_code == 200, r.text
    cuerpo = r.json()
    assert cuerpo["id_empleado"] == "SIRIUS-PER-0007"
    assert cuerpo["rol_app"] == "Visitador"
    # El hash viaja solo aca, y solo porque la contrasena ya se verifico.
    assert cuerpo["hash_offline"] == HASH
    assert cuerpo["dias_max_offline"] == get_settings().dias_max_offline


def test_el_nivel_de_nomina_decide_el_rol_en_la_app(client, auth, nomina_responde):
    nomina_responde([_registro(**{nomina.CAMPO_ORDEN_NIVEL: [1]})])

    r = client.post(
        "/v1/auth/login",
        headers=auth,
        json={"cedula": CEDULA, "password": PASSWORD},
    )

    assert r.json()["rol_app"] == "Coordinador"


def test_sin_nivel_se_cae_al_rol_menos_privilegiado(client, auth, nomina_responde):
    # Un lookup vacio no puede ascender a nadie.
    nomina_responde([_registro(**{nomina.CAMPO_ORDEN_NIVEL: []})])

    r = client.post(
        "/v1/auth/login",
        headers=auth,
        json={"cedula": CEDULA, "password": PASSWORD},
    )

    assert r.json()["rol_app"] == "Visitador"
    assert r.json()["orden_nivel"] == 99


@pytest.mark.parametrize(
    "tecleada", ["1234567890", "1.234.567.890", "1 234 567 890", " 1234567890 "]
)
def test_da_igual_como_se_teclee_la_cedula(client, auth, nomina_responde, tecleada):
    """En nomina el documento es texto libre y hay registros con puntos. Poder
    entrar no puede depender de como lo cargo quien lleno la nomina."""
    capturado = nomina_responde([_registro()])

    r = client.post(
        "/v1/auth/login",
        headers=auth,
        json={"cedula": tecleada, "password": PASSWORD},
    )

    assert r.status_code == 200, r.text
    assert r.json()["cedula"] == CEDULA
    # Y del otro lado tambien: la formula le quita puntos, guiones y espacios
    # al valor guardado antes de comparar.
    formula = capturado["params"]["filterByFormula"]
    assert nomina.CAMPO_DOCUMENTO in formula
    assert "SUBSTITUTE" in formula
    assert f"'{CEDULA}'" in formula


def test_contrasena_mala_y_usuario_inexistente_dan_EL_MISMO_error(
    client, auth, nomina_responde
):
    """Si los mensajes se distinguen, el login se vuelve un directorio de la
    empresa: cualquiera podria averiguar quien trabaja aca probando cedulas."""
    nomina_responde([_registro()])
    mala = client.post(
        "/v1/auth/login",
        headers=auth,
        json={"cedula": CEDULA, "password": "otra"},
    )

    nomina_responde([])
    inexistente = client.post(
        "/v1/auth/login",
        headers=auth,
        json={"cedula": "9999999999", "password": PASSWORD},
    )

    assert mala.status_code == inexistente.status_code == 401
    assert mala.json()["detail"] == inexistente.json()["detail"]


def test_un_password_en_texto_plano_no_se_compara_nunca(client, auth, nomina_responde):
    nomina_responde([_registro(**{nomina.CAMPO_PASSWORD: PASSWORD})])

    r = client.post(
        "/v1/auth/login",
        headers=auth,
        json={"cedula": CEDULA, "password": PASSWORD},
    )

    # La contrasena es LA correcta en texto plano y aun asi no entra.
    assert r.status_code == 500
    assert "bcrypt" in r.json()["detail"]


def test_sin_contrasena_en_nomina_se_dice_que_hay_que_asignarla(
    client, auth, nomina_responde
):
    nomina_responde([_registro(**{nomina.CAMPO_PASSWORD: ""})])

    r = client.post(
        "/v1/auth/login",
        headers=auth,
        json={"cedula": CEDULA, "password": PASSWORD},
    )

    assert r.status_code == 403
    assert "nomina" in r.json()["detail"].lower()


@pytest.mark.parametrize("estado", ["De baja", "Suspendido", ""])
def test_quien_no_esta_activo_no_entra(client, auth, nomina_responde, estado):
    nomina_responde([_registro(**{nomina.CAMPO_ESTADO: estado})])

    r = client.post(
        "/v1/auth/login",
        headers=auth,
        json={"cedula": CEDULA, "password": PASSWORD},
    )

    assert r.status_code == 403


def test_el_estado_se_revisa_despues_de_la_contrasena(client, auth, nomina_responde):
    """Con la contrasena mala, alguien de baja tiene que dar 401 igual que
    cualquiera: el 403 confirmaria que la persona existe en la nomina."""
    nomina_responde([_registro(**{nomina.CAMPO_ESTADO: "De baja"})])

    r = client.post(
        "/v1/auth/login",
        headers=auth,
        json={"cedula": CEDULA, "password": "otra"},
    )

    assert r.status_code == 401


def test_el_login_exige_la_api_key_como_el_resto(client, nomina_responde):
    nomina_responde([_registro()])

    r = client.post(
        "/v1/auth/login",
        json={"cedula": CEDULA, "password": PASSWORD},
    )

    assert r.status_code == 401


def test_no_se_puede_inyectar_en_la_formula_de_airtable(client, auth, nomina_responde):
    """La cedula se reduce a digitos antes de tocar la formula, asi que no hay
    nada que escapar: las comillas y los parentesis nunca llegan."""
    capturado = nomina_responde([])

    client.post(
        "/v1/auth/login",
        headers=auth,
        json={"cedula": "1234',OR(1,1))'", "password": PASSWORD},
    )

    formula = capturado["params"]["filterByFormula"]
    assert formula.endswith("='123411'")
    assert "OR(" not in formula


def test_una_cedula_sin_un_solo_digito_ni_se_consulta(client, auth, nomina_responde):
    capturado = nomina_responde([_registro()])

    r = client.post(
        "/v1/auth/login",
        headers=auth,
        json={"cedula": "no-es-una-cedula", "password": PASSWORD},
    )

    assert r.status_code == 400
    # Ni siquiera se le pregunto a Airtable.
    assert capturado == {}

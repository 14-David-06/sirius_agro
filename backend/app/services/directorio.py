"""Lee de Airtable los agricultores ya registrados.

El unico servicio que lee y no escribe. Existe porque el nombre del productor
se teclea al crear la visita, y sin una lista contra la cual reconocerlo cada
visita crea una persona nueva: «Pedro Gomez», «pedro gomez» y «don Pedro» son
tres productores en Airtable, con tres fincas y ninguna historia.

La regla de oro esta en el llamador, no aca: esto es una ayuda. Si Airtable no
contesta, si no hay senal o si el APK se compilo sin servidor, el visitador
tiene que poder escribir el nombre y seguir. Por eso el servicio no cachea ni
reintenta — falla rapido y la app sigue con lo que ya tiene en el telefono.
"""

import httpx
from fastapi import HTTPException

from ..config import Settings
from ..schemas_directorio import DirectorioProductores, ProductorDirectorio
from .sincronizacion import TBL_PRODUCTORES, Airtable, _escapar

# Tope de seguridad. El piloto tiene decenas de productores; si algun dia son
# miles, el telefono no deberia bajarlos todos por una red de vereda para
# ayudar a completar un nombre. Se recorta y se avisa que se recorto.
LIMITE_POR_DEFECTO = 500


def _texto(valor: object) -> str | None:
    """Airtable devuelve el campo ausente, no vacio. Los dos son lo mismo."""
    if valor is None:
        return None
    limpio = str(valor).strip()
    return limpio or None


def _foto(valor: object) -> str | None:
    """La primera miniatura del adjunto `Foto`, si la hay.

    Se prefiere la miniatura grande a la original: es la cara de alguien en un
    listado, no un archivo que haya que guardar, y la original puede pesar
    varios megas en una red que apenas alcanza para sincronizar la visita.
    """
    if not isinstance(valor, list) or not valor:
        return None
    primero = valor[0]
    if not isinstance(primero, dict):
        return None
    miniaturas = primero.get("thumbnails") or {}
    grande = miniaturas.get("large") or miniaturas.get("full") or {}
    return _texto(grande.get("url")) or _texto(primero.get("url"))


def _entero(valor: object) -> int | None:
    if valor is None or isinstance(valor, bool):
        return None
    try:
        return int(valor)
    except (TypeError, ValueError):
        # Un campo de Airtable que alguien convirtio en texto ("mas de 20") no
        # puede tumbar el directorio entero: se ignora ese campo y ya.
        return None


def _a_productor(registro: dict) -> ProductorDirectorio | None:
    f = registro.get("fields", {})
    nombre = _texto(f.get("Nombre completo"))
    if not nombre:
        # Una fila sin nombre no se puede ofrecer: en el listado seria una
        # linea en blanco que al tocarla adopta una identidad invisible.
        return None

    return ProductorDirectorio(
        id=registro["id"],
        nombre_completo=nombre,
        codigo_productor=_texto(f.get("Codigo productor")),
        documento=_texto(f.get("Documento")),
        tipo_documento=_texto(f.get("Tipo de documento")),
        telefono=_texto(f.get("Telefono")),
        telefono_alterno=_texto(f.get("Telefono alterno")),
        genero=_texto(f.get("Genero")),
        fecha_nacimiento=_texto(f.get("Fecha de nacimiento")),
        nivel_educativo=_texto(f.get("Nivel educativo")),
        anios_experiencia=_entero(f.get("Anios de experiencia")),
        personas_hogar=_entero(f.get("Personas en el hogar")),
        organizacion=_texto(f.get("Organizacion o asociacion")),
        consentimiento_datos=bool(f.get("Consentimiento de datos")),
        foto_url=_foto(f.get("Foto")),
    )


def _formula(buscar: str | None) -> str:
    """Filtro por nombre, documento o codigo.

    Sin `buscar` trae todo: el caso normal es que la app se traiga el
    directorio completo cuando tiene senal y despues busque sin red. La
    busqueda con formula es para el dia en que el directorio no quepa.
    """
    termino = (buscar or "").strip()
    if not termino:
        return "TRUE()"

    aguja = _escapar(termino.lower())
    campos = "{Nombre completo} & ' ' & {Documento} & ' ' & {Codigo productor}"
    return f"SEARCH('{aguja}', LOWER({campos})) > 0"


async def listar_productores(
    settings: Settings,
    buscar: str | None = None,
    limite: int = LIMITE_POR_DEFECTO,
) -> DirectorioProductores:
    if not settings.airtable_token or not settings.airtable_base_id:
        raise HTTPException(status_code=500, detail="Falta configuracion de Airtable.")

    # Timeout corto a proposito, y mas corto que el de sincronizar: esto es una
    # comodidad. Un directorio que tarda medio minuto ya no ayuda a nadie que
    # esta parado frente al agricultor, y la app tiene que caer a lo local.
    async with httpx.AsyncClient(timeout=20) as cliente:
        registros = await Airtable(settings, cliente).listar(
            TBL_PRODUCTORES, _formula(buscar)
        )

    productores = [p for p in map(_a_productor, registros) if p is not None]
    # Alfabetico y sin distinguir mayusculas: es una lista para leer con el
    # pulgar, no un resultado de relevancia.
    productores.sort(key=lambda p: p.nombre_completo.lower())

    return DirectorioProductores(
        productores=productores[:limite],
        truncado=len(productores) > limite,
    )

"""Trae de Airtable las visitas ya registradas de un agricultor.

El segundo servicio que lee y no escribe, despues del directorio. Responde a
algo que hasta ahora la app no podia hacer: llegar a una finca sabiendo que se
hablo la vez pasada. La sincronizacion era de una sola via —el telefono
empujaba y nunca bajaba— asi que un visitador que cubria la finca de un
companero llegaba en blanco.

Tres decisiones de fondo, todas por la misma razon (que traer el historial no
pueda costar trabajo de campo):

1. **Se pide por agricultor, no "todo".** El historial se baja cuando alguien
   lo pide para una persona concreta. Bajar el equipo entero a un telefono de
   campo es mover datos personales de productores a dispositivos que no los
   registraron, y ademas no cabe.

2. **Las visitas se identifican por `Codigo de visita`**, que es el UUID que
   genero el telefono que la registro. Con eso la app sabe cual visita ya es
   suya —y no la toca— y cual puede espejar.

3. **Falla rapido y no reintenta.** Como el directorio: es una ayuda. Si
   Airtable no contesta, el visitador sigue con lo que tiene en el telefono.
"""

import httpx
from fastapi import HTTPException

from ..config import Settings
from ..schemas_historial import (
    EvidenciaRemota,
    GrabacionRemota,
    HallazgoRemoto,
    HistorialProductor,
    InformeRemoto,
    VisitaRemota,
)
from .sincronizacion import (
    TBL_CATALOGO,
    TBL_EVIDENCIAS,
    TBL_FINCAS,
    TBL_GRABACIONES,
    TBL_HALLAZGOS,
    TBL_INFORMES,
    TBL_PRODUCTORES,
    TBL_VEREDAS,
    TBL_VISITADORES,
    TBL_VISITAS,
    Airtable,
    _escapar,
)

# Tope de visitas por agricultor. Un productor del piloto tiene unas pocas; el
# tope existe para que una ficha con dos anios de historia no le baje treinta
# visitas con su audio a un telefono en una vereda. Se recorta por las mas
# viejas y se avisa que se recorto.
LIMITE_POR_DEFECTO = 30

# Airtable topa la URL de la peticion, y `filterByFormula` viaja en la query.
# Con muchos ids, un OR() de una sola linea la revienta y la respuesta es un
# 422 que no dice que paso. Se parte en tandas.
_POR_TANDA = 40


def _texto(valor: object) -> str | None:
    if valor is None:
        return None
    limpio = str(valor).strip()
    return limpio or None


def _numero(valor: object) -> float | None:
    if valor is None or isinstance(valor, bool):
        return None
    try:
        return float(valor)
    except (TypeError, ValueError):
        return None


def _entero(valor: object) -> int | None:
    n = _numero(valor)
    return None if n is None else int(n)


def _adjunto(valor: object) -> str | None:
    """La URL del primer adjunto.

    Airtable la rota cada pocas horas: sirve para descargar el archivo ahora,
    no para guardarla. Quien la reciba tiene que bajarse el archivo en el
    momento o quedarse sin el.
    """
    if not isinstance(valor, list) or not valor:
        return None
    primero = valor[0]
    return _texto(primero.get("url")) if isinstance(primero, dict) else None


def _ids(valor: object) -> list[str]:
    """Los record ids de un campo de enlace. Airtable los devuelve como lista."""
    if not isinstance(valor, list):
        return []
    return [x for x in valor if isinstance(x, str)]


def _primer_id(valor: object) -> str | None:
    ids = _ids(valor)
    return ids[0] if ids else None


def _tandas(valores: list[str]) -> list[list[str]]:
    return [
        valores[i : i + _POR_TANDA] for i in range(0, len(valores), _POR_TANDA)
    ]


def _or_de_ids(ids: list[str]) -> str:
    condiciones = ",".join(f"RECORD_ID()='{_escapar(x)}'" for x in ids)
    return f"OR({condiciones})"


def _or_de_visitas(codigos: list[str]) -> str:
    """Filtro de hijos por su visita.

    El campo de enlace resuelve al campo primario de `Visitas`, que es el
    `Codigo de visita`. Es el mismo filtro que usa la escritura para casar los
    hijos, y por eso se sabe que funciona contra la base real.
    """
    condiciones = ",".join(
        f"{{Visita}}='{_escapar(c)}'" for c in codigos
    )
    return f"OR({condiciones})"


async def _nombres(
    at: Airtable, tabla: str, ids: list[str]
) -> dict[str, dict]:
    """Los registros de una tabla por record id, en una sola pasada.

    Las visitas traen sus enlaces como record ids, no como nombres. Resolverlos
    de a uno serian cuatro peticiones por visita; asi son dos o tres en total.
    """
    unicos = sorted({x for x in ids if x})
    if not unicos:
        return {}

    registros: list[dict] = []
    for tanda in _tandas(unicos):
        registros.extend(await at.listar(tabla, _or_de_ids(tanda)))

    return {r["id"]: r.get("fields", {}) for r in registros}


def _a_hallazgo(registro: dict, catalogo: dict[str, dict]) -> HallazgoRemoto:
    """Un hallazgo, con su clave tecnica resuelta desde el catalogo.

    Viaja la CLAVE y no el nombre legible del campo ni su modulo: esos dos los
    resuelve la app contra su propio `Catalogo de Campos`, que ya tiene sembrado.
    Leerlos aca obligaria a adivinar como se llaman esas dos columnas en
    Airtable —el backend no las toca en ningun otro lado— y una columna
    adivinada no falla: devuelve vacio, que es la forma mas cara de
    equivocarse.
    """
    f = registro.get("fields", {})
    campo = catalogo.get(_primer_id(f.get("Campo")) or "", {})

    return HallazgoRemoto(
        clave_tecnica=_texto(campo.get("Clave tecnica")),
        valor_texto=_texto(f.get("Valor texto")),
        valor_numerico=_numero(f.get("Valor numerico")),
        unidad=_texto(f.get("Unidad")),
        certeza=_texto(f.get("Certeza")),
        fuente=_texto(f.get("Fuente")),
        estado=_texto(f.get("Estado")),
        entidad_destino=_texto(f.get("Entidad destino")),
        entidad_local_id=_texto(f.get("Entidad local id")),
        cita_textual=_texto(f.get("Cita textual")),
        segundo_audio=_entero(f.get("Segundo del audio")),
        hablante=_texto(f.get("Hablante")),
        razonamiento=_texto(f.get("Razonamiento")),
        confianza=_numero(f.get("Confianza")),
        valor_corregido=_texto(f.get("Valor corregido")),
    )


def _a_evidencia(registro: dict) -> EvidenciaRemota:
    f = registro.get("fields", {})
    return EvidenciaRemota(
        titulo=_texto(f.get("Titulo")),
        tipo=_texto(f.get("Tipo")),
        tomada_en=f.get("Tomada en"),
        latitud=_numero(f.get("Latitud")),
        longitud=_numero(f.get("Longitud")),
        descripcion_visitador=_texto(f.get("Descripcion del visitador")),
        descripcion_ia=_texto(f.get("Descripcion IA")),
        texto_ocr=_texto(f.get("Texto OCR")),
        estado_validacion=_texto(f.get("Estado de validacion")),
        url=_adjunto(f.get("Archivo")),
    )


def _a_grabacion(registro: dict) -> GrabacionRemota:
    f = registro.get("fields", {})
    return GrabacionRemota(
        orden=_entero(f.get("Orden")),
        archivo=_texto(f.get("Archivo")),
        inicio=f.get("Inicio"),
        duracion_min=_numero(f.get("Duracion (min)")),
        tamano_mb=_numero(f.get("Tamano (MB)")),
        estado=_texto(f.get("Estado")),
        transcripcion=_texto(f.get("Transcripcion")),
        transcripcion_marcas=_texto(f.get("Transcripcion con marcas de tiempo")),
        motor_transcripcion=_texto(f.get("Motor de transcripcion")),
        idioma=_texto(f.get("Idioma")),
        url=_texto(f.get("Enlace de audio")),
    )


def _a_informe(registro: dict) -> InformeRemoto:
    f = registro.get("fields", {})
    return InformeRemoto(
        titulo=_texto(f.get("Nombre")),
        tipo=_texto(f.get("Tipo")),
        contenido=_texto(f.get("Contenido")),
        version=_entero(f.get("Version")),
        generado_en=f.get("Generado en"),
        entregado=bool(f.get("Entregado")),
        medio_entrega=_texto(f.get("Medio de entrega")),
        enlace_pdf=_texto(f.get("Enlace")),
    )


def _a_visita(
    registro: dict,
    visitadores: dict[str, dict],
    fincas: dict[str, dict],
    veredas: dict[str, dict],
    productor: str | None,
) -> VisitaRemota | None:
    f = registro.get("fields", {})
    codigo = _texto(f.get("Codigo de visita"))
    if not codigo:
        # Sin codigo no hay identidad: la app no podria decidir si esta visita
        # ya es suya, y espejarla arriesgaria duplicar la que tiene.
        return None

    vereda = veredas.get(_primer_id(f.get("Vereda")) or "", {})

    return VisitaRemota(
        codigo_visita=codigo,
        inicio=f.get("Inicio"),
        fin=f.get("Fin"),
        estado=_texto(f.get("Estado")),
        tipo_visita=_texto(f.get("Tipo de visita")),
        # Airtable guarda el percent como fraccion: 0.55 se muestra 55%.
        completitud_pct=round((_numero(f.get("Completitud (%)")) or 0) * 100),
        latitud=_numero(f.get("Latitud")),
        longitud=_numero(f.get("Longitud")),
        productor=productor,
        # «Nombre de la finca», que es como se llama la columna de verdad: la
        # escritura la usa en `_upsert_finca`.
        finca=_texto(
            fincas.get(_primer_id(f.get("Finca")) or "", {}).get(
                "Nombre de la finca"
            )
        ),
        vereda=_texto(vereda.get("Vereda")),
        visitador=_texto(
            visitadores.get(_primer_id(f.get("Visitador")) or "", {}).get("Nombre")
        ),
        objetivo=_texto(f.get("Objetivo de la visita")),
        observaciones=_texto(f.get("Observaciones del visitador")),
        resumen=_texto(f.get("Resumen de la conversacion")),
        temas_pendientes=_texto(f.get("Temas pendientes")),
        consiente_audio=bool(f.get("Consiente audio")),
        consiente_fotos=bool(f.get("Consiente fotos")),
        consiente_uso_datos=bool(f.get("Consiente uso de datos")),
        segundo_consentimiento=_entero(f.get("Segundo del consentimiento")),
        marcada_para_eliminacion=bool(f.get("Marcada para eliminacion")),
    )


def _orden(visita: VisitaRemota) -> str:
    """La mas reciente primero. Sin fecha, al final: una visita sin `Inicio`
    esta rota y no puede encabezar el historial."""
    return visita.inicio.isoformat() if visita.inicio else ""


async def historial_de_productor(
    settings: Settings,
    productor_id: str,
    limite: int = LIMITE_POR_DEFECTO,
) -> HistorialProductor:
    if not settings.airtable_token or not settings.airtable_base_id:
        raise HTTPException(status_code=500, detail="Falta configuracion de Airtable.")

    # Mas largo que el del directorio (20 s) porque son varias tablas, y mas
    # corto que el de sincronizar: esto se pide con el agricultor enfrente.
    async with httpx.AsyncClient(timeout=40) as cliente:
        at = Airtable(settings, cliente)

        ficha = await at.buscar(
            TBL_PRODUCTORES, f"RECORD_ID() = '{_escapar(productor_id)}'"
        )
        if ficha is None:
            raise HTTPException(
                status_code=404,
                detail="Ese agricultor no esta en Airtable.",
            )

        campos_productor = ficha.get("fields", {})
        nombre = _texto(campos_productor.get("Nombre completo"))

        # Se parte del enlace `Visitas` de la ficha y NO de una formula por
        # nombre: dos homonimos en la misma vereda terminarian con el historial
        # mezclado, que es exactamente lo que el modelo de datos existe para
        # impedir.
        ids_visitas = _ids(campos_productor.get("Visitas"))
        if not ids_visitas:
            return HistorialProductor(
                productor_id=productor_id,
                productor=nombre,
                codigo_productor=_texto(campos_productor.get("Codigo productor")),
                documento=_texto(campos_productor.get("Documento")),
            )

        registros: list[dict] = []
        for tanda in _tandas(ids_visitas):
            registros.extend(await at.listar(TBL_VISITAS, _or_de_ids(tanda)))

        def enlazados(campo: str) -> list[str]:
            return [
                _primer_id(r.get("fields", {}).get(campo)) or "" for r in registros
            ]

        visitadores = await _nombres(at, TBL_VISITADORES, enlazados("Visitador"))
        fincas = await _nombres(at, TBL_FINCAS, enlazados("Finca"))
        veredas = await _nombres(at, TBL_VEREDAS, enlazados("Vereda"))

        # La visita se queda con su record id al lado: los hijos enlazan a ella
        # por ese id, no por el codigo, y sin este mapa cada hallazgo y cada
        # foto se caerian del historial sin error ninguno — llegarian visitas
        # vacias que parecen visitas sin datos.
        por_record: dict[str, VisitaRemota] = {}
        for r in registros:
            visita = _a_visita(r, visitadores, fincas, veredas, nombre)
            if visita is not None:
                por_record[r["id"]] = visita

        # Se ordena y se recorta sobre los pares (record id, visita) para no
        # perder el id por el camino.
        ordenadas = sorted(
            por_record.items(), key=lambda par: _orden(par[1]), reverse=True
        )
        truncado = len(ordenadas) > limite
        ordenadas = ordenadas[:limite]
        visitas = [v for _, v in ordenadas]

        if ordenadas:
            # Solo las que sobrevivieron al recorte: bajarle los hijos a una
            # visita que no se va a devolver es gastar la ventana de red de una
            # vereda en algo que nadie va a ver.
            await _colgar_hijos(at, dict(ordenadas))

    return HistorialProductor(
        productor_id=productor_id,
        productor=nombre,
        codigo_productor=_texto(campos_productor.get("Codigo productor")),
        documento=_texto(campos_productor.get("Documento")),
        visitas=visitas,
        truncado=truncado,
    )


async def _colgar_hijos(
    at: Airtable, por_record: dict[str, VisitaRemota]
) -> None:
    """Trae hallazgos, evidencias, grabaciones e informes de todas las visitas.

    Una consulta por tabla y no una por visita: diez visitas serian cuarenta
    peticiones contra Airtable, con su limite de cinco por segundo, y el
    visitador esperando parado en la finca.

    El indice va por RECORD ID de la visita y no por su codigo, porque asi es
    como enlaza Airtable: el campo `Visita` de un hijo es una lista de record
    ids. Casar por codigo devolveria visitas sin un solo hallazgo y sin un solo
    error — que es la peor forma de fallar, porque se parece a una visita en la
    que no se registro nada.
    """
    visitas = list(por_record.values())
    codigos = [v.codigo_visita for v in visitas]

    hallazgos: list[dict] = []
    evidencias: list[dict] = []
    grabaciones: list[dict] = []
    informes: list[dict] = []

    for tanda in _tandas(codigos):
        formula = _or_de_visitas(tanda)
        hallazgos.extend(await at.listar(TBL_HALLAZGOS, formula))
        evidencias.extend(await at.listar(TBL_EVIDENCIAS, formula))
        grabaciones.extend(await at.listar(TBL_GRABACIONES, formula))
        informes.extend(await at.listar(TBL_INFORMES, formula))

    # El catalogo, para que el hallazgo llegue con el nombre legible del campo
    # y su modulo. Sin esto la app mostraria `area_total_ha` en el historial.
    catalogo = await _nombres(
        at,
        TBL_CATALOGO,
        [_primer_id(r.get("fields", {}).get("Campo")) or "" for r in hallazgos],
    )

    for registro in hallazgos:
        visita = _visita_de(registro, por_record)
        if visita is not None:
            visita.hallazgos.append(_a_hallazgo(registro, catalogo))

    for registro in evidencias:
        visita = _visita_de(registro, por_record)
        if visita is not None:
            visita.evidencias.append(_a_evidencia(registro))

    for registro in grabaciones:
        visita = _visita_de(registro, por_record)
        if visita is not None:
            visita.grabaciones.append(_a_grabacion(registro))

    for registro in informes:
        visita = _visita_de(registro, por_record)
        if visita is not None:
            visita.informes.append(_a_informe(registro))

    for visita in visitas:
        visita.grabaciones.sort(key=lambda g: g.orden or 0)
        visita.evidencias.sort(key=lambda e: e.titulo or "")
        visita.informes.sort(key=lambda i: i.version or 0)


def _visita_de(
    registro: dict, por_record: dict[str, VisitaRemota]
) -> VisitaRemota | None:
    """A que visita pertenece un hijo, por el record id de su enlace."""
    for rid in _ids(registro.get("fields", {}).get("Visita")):
        visita = por_record.get(rid)
        if visita is not None:
            return visita
    return None


# ------------------------------------------------ el indice de todas las visitas

# Cuantas visitas trae el indice. Es una lista para mirar, no un archivo: mas
# alla de esto nadie baja con el pulgar, y cada fila cuesta resolver sus
# enlaces.
INDICE_POR_DEFECTO = 200


async def indice_de_visitas(
    settings: Settings, limite: int = INDICE_POR_DEFECTO
) -> list[VisitaRemota]:
    """Todas las visitas de Airtable, SIN sus hijos.

    Es lo que permite que la app muestre las visitas del equipo sin que nadie
    toque un boton: la lista se refresca sola cuando hay senal.

    Lo que NO trae es lo que pesa —hallazgos, fotos, audio, informes—, y esa es
    justamente la razon por la que puede ser automatico. Doscientas visitas con
    su ficha son unos pocos KB; las mismas con sus fotos son cientos de megas y
    ningun telefono de campo las quiere.

    El detalle de una visita se pide aparte, cuando alguien la abre.
    """
    if not settings.airtable_token or not settings.airtable_base_id:
        raise HTTPException(status_code=500, detail="Falta configuracion de Airtable.")

    async with httpx.AsyncClient(timeout=40) as cliente:
        at = Airtable(settings, cliente)
        registros = await at.listar(TBL_VISITAS, "TRUE()")
        return await _fichas(at, registros, limite)


async def visita_por_codigo(
    settings: Settings, codigo_visita: str
) -> VisitaRemota:
    """Una visita con todo lo suyo, para cuando alguien la abre.

    Separado del indice a proposito: asi lo pesado se baja cuando alguien lo va
    a mirar, y no doscientas veces por si acaso.
    """
    if not settings.airtable_token or not settings.airtable_base_id:
        raise HTTPException(status_code=500, detail="Falta configuracion de Airtable.")

    async with httpx.AsyncClient(timeout=40) as cliente:
        at = Airtable(settings, cliente)
        registro = await at.buscar(
            TBL_VISITAS,
            f"{{Codigo de visita}} = '{_escapar(codigo_visita)}'",
        )
        if registro is None:
            raise HTTPException(
                status_code=404, detail="Esa visita no esta en Airtable."
            )

        fichas = await _fichas(at, [registro], 1)
        if not fichas:
            raise HTTPException(
                status_code=404, detail="Esa visita no esta en Airtable."
            )

        await _colgar_hijos(at, {registro["id"]: fichas[0]})
        return fichas[0]


async def _fichas(
    at: Airtable, registros: list[dict], limite: int
) -> list[VisitaRemota]:
    """Convierte registros de `Visitas` en fichas, con sus enlaces resueltos.

    Los enlaces llegan como record id. Resolverlos de a uno serian cuatro
    peticiones por visita; asi son cuatro en total para todo el indice.
    """

    def enlazados(campo: str) -> list[str]:
        return [_primer_id(r.get("fields", {}).get(campo)) or "" for r in registros]

    productores = await _nombres(at, TBL_PRODUCTORES, enlazados("Productor"))
    visitadores = await _nombres(at, TBL_VISITADORES, enlazados("Visitador"))
    fincas = await _nombres(at, TBL_FINCAS, enlazados("Finca"))
    veredas = await _nombres(at, TBL_VEREDAS, enlazados("Vereda"))

    fichas: list[VisitaRemota] = []
    for r in registros:
        productor = _texto(
            productores.get(
                _primer_id(r.get("fields", {}).get("Productor")) or "", {}
            ).get("Nombre completo")
        )
        ficha = _a_visita(r, visitadores, fincas, veredas, productor)
        if ficha is not None:
            fichas.append(ficha)

    fichas.sort(key=_orden, reverse=True)
    return fichas[:limite]

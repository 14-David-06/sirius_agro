"""Vocabulario de refuerzo para la transcripcion.

Un motor generico transcribe "Guaicaramo" como "guai caramo", "gallinaza" como
"gallina asa" y "Estupinan" como "es tu pinan". Cada uno de esos errores rompe
algo concreto: el nombre de la vereda no empareja con el listado, el insumo no
se reconoce, y el nombre del productor queda mal en el informe que se le
entrega firmado.

Esta lista NO pretende ser completa. Lo que la vuelve util de verdad es lo que
se le suma en tiempo de ejecucion: el nombre del productor de ESTA visita, su
vereda y los insumos que ya se le registraron antes. Un termino generico ayuda
poco; el apellido de la persona que esta hablando ayuda mucho.
"""

# Veredas de Barranca de Upia (Meta). Espejo de la tabla Veredas.
# Si se agrega una vereda en Airtable, hay que agregarla aqui tambien: el
# motor no puede reconocer un nombre propio que nunca vio.
VEREDAS = [
    "Barranca de Upia",
    "Carutal",
    "El Algarrobo",
    "El Hijoa",
    "Guaicaramo",
    "Las Moras",
    "Los Pavitos",
    "San Ignacio",
]

# Cultivos del piedemonte llanero.
CULTIVOS = [
    "platano",
    "yuca",
    "arroz",
    "maiz",
    "palma",
    "palma de aceite",
    "maracuya",
    "citricos",
    "naranja",
    "mandarina",
    "papaya",
    "cacao",
    "caucho",
    "maranon",
    "brachiaria",
    "pasto de corte",
    "guayaba",
    "aguacate",
]

# Insumos que aparecen en la conversacion y en las etiquetas. Se transcriben
# mal casi siempre porque son marcas y siglas, no palabras del idioma.
INSUMOS = [
    "DAP",
    "urea",
    "KCl",
    "cloruro de potasio",
    "triple quince",
    "sulfato de amonio",
    "fosforo",
    "cal dolomita",
    "gallinaza",
    "porquinaza",
    "compost",
    "lombriabono",
    "melaza",
    "glifosato",
    "Roundup",
    "paraquat",
    "cipermetrina",
    "clorpirifos",
    "Lorsban",
    "Furadan",
    "mancozeb",
    "Amistar",
    "carbofuran",
    "Trichoderma",
    "Beauveria",
    "Metarhizium",
    "Bacillus",
    "bioinsumo",
    "biofertilizante",
    "microorganismos",
]

# Unidades con las que el agricultor habla de cantidades. Que se transcriban
# bien es la condicion para poder convertirlas con la tabla Unidades.
UNIDADES = [
    "bulto",
    "bultos",
    "arroba",
    "arrobas",
    "carga",
    "cargas",
    "quintal",
    "hectarea",
    "hectareas",
    "fanegada",
    "jornal",
    "jornales",
    "canastilla",
]

# Apellidos frecuentes en el Llano. Lista corta y deliberadamente conservadora:
# lo que de verdad hay que reforzar son los apellidos de los productores del
# piloto, y esos se pasan en tiempo de ejecucion. Un apellido inventado aqui
# solo agrega ruido.
APELLIDOS = [
    "Estupinan",
    "Barragan",
    "Parales",
    "Torrealba",
    "Riano",
    "Chaparro",
    "Pabon",
    "Nino",
    "Salcedo",
    "Baquero",
]

# Terminos del oficio que se confunden con palabras comunes.
OFICIO = [
    "vereda",
    "finca",
    "lote",
    "potrero",
    "rastrojo",
    "nacimiento",
    "quebrada",
    "reservorio",
    "aspersion",
    "goteo",
    "encalar",
    "compactado",
    "erosion",
    "aparceria",
    "comodato",
    "sucesion",
    "ICA",
    "UMATA",
    "Finagro",
    "Banco Agrario",
]

BASE: list[str] = [
    *VEREDAS,
    *CULTIVOS,
    *INSUMOS,
    *UNIDADES,
    *APELLIDOS,
    *OFICIO,
]


def construir(extra: list[str] | None = None, limite: int = 500) -> list[str]:
    """Devuelve la lista de terminos a reforzar, sin repetidos.

    `extra` es lo especifico de la visita: el nombre del productor, su vereda,
    los insumos de la visita anterior. Va primero a proposito — si hay que
    recortar por el limite del proveedor, lo generico es lo que sobra.

    El proveedor admite hasta 1000 terminos, pero la precision se degrada
    mucho antes: el limite existe para proteger la transcripcion de si misma.
    """
    vistos: set[str] = set()
    salida: list[str] = []

    for termino in [*(extra or []), *BASE]:
        limpio = termino.strip()
        if not limpio:
            continue
        clave = limpio.casefold()
        if clave in vistos:
            continue
        vistos.add(clave)
        salida.append(limpio)
        if len(salida) >= limite:
            break

    return salida


def desde_nombre(nombre: str) -> list[str]:
    """Parte un nombre completo en terminos utiles para reforzar.

    Se refuerza el nombre completo y cada palabra por separado: el agricultor
    va a decir "Pedro" a secas y el visitador "don Pedro Rodriguez". Las
    palabras de una o dos letras se descartan porque no aportan y sí gastan
    cupo ("de", "la", "y").
    """
    partes = [p for p in nombre.split() if len(p) > 2]
    if not partes:
        return []
    completo = " ".join(partes)
    return [completo, *partes] if len(partes) > 1 else partes

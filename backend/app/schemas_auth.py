from pydantic import BaseModel, Field


class LoginRequest(BaseModel):
    """La cedula es lo que la persona se sabe de memoria.

    Se acepta como venga —con puntos, espacios o sin nada— y el backend la
    normaliza a digitos antes de buscarla.
    """

    cedula: str = Field(min_length=1)
    password: str = Field(min_length=1)


class LoginResult(BaseModel):
    id_empleado: str
    cedula: str
    nombre: str
    email: str
    rol_nomina: str
    nivel_acceso: str
    orden_nivel: int

    # Papel dentro de ESTA app, derivado del nivel de nomina.
    rol_app: str

    # El hash bcrypt de la persona, para que el telefono pueda validar la
    # contrasena en una vereda sin senal.
    #
    # Sale del backend UNICAMENTE dentro de esta respuesta, o sea solo despues
    # de que alguien ya demostro conocer la contrasena. Nunca hay un endpoint
    # que devuelva hashes sin esa prueba, y nunca se manda el de otra persona:
    # el telefono termina con los hashes de quienes entraron en ese equipo, no
    # con la nomina entera.
    hash_offline: str
    dias_max_offline: int

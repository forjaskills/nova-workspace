# nova-__nombre__

**Seguridad** de **Nova Retail** (proyecto de ejemplo del canal Forja Skills): usuarios, roles y
login. Emite el JWT que validan el gateway y todos los servicios.
Creada con la skill `arquetipo` (tipo `seguridad`): hexagonal por fuera, DDD por dentro.

## Endpoints

| Método | Ruta | Para qué |
|---|---|---|
| POST | `/api/v1/sesion` | login → JWT (RS256, 60 min). Máximo 5 intentos por minuto |
| GET | `/.well-known/openid-configuration` | quién emite los tokens |
| GET | `/.well-known/jwks.json` | llave **pública** para validar los tokens |
| GET | `/api/v1/quien-soy` | quién eres según tu token |
| GET | `/salud` | la API está arriba y llega a su base |

## Capas

| Carpeta | Qué va |
|---|---|
| `src/01. Business Rules Model` | `Usuario` (raíz de agregado), `Rol`, `NombreUsuario` y `Scope` (value objects), `IRepositorioUsuarios` |
| `src/02. Application Rules Model` | caso de uso `IniciarSesion` y sus puertos (`IEmisorToken`, `IVerificadorClave`) |
| `src/03. Interface Adapter` | controladores, presentador de errores, gateways: EF Core, firma RS256, hash de claves |
| `src/04. Framework and Driver` | arranque: JWT, políticas, límites, errores, OpenAPI |
| `tests/` | unitarias · integración · **arquitectura** |

## Correr en local

```
dotnet run --project tools/Migrador -- --ambiente DEV
dotnet run --project "src/04. Framework and Driver/Nova.__Nombre__.Api" --launch-profile DEV
```

| Ambiente | Puerto | Base |
|---|---|---|
| DEV | __PUERTO_DEV__ | `__BASE___DEV` |
| QA | __PUERTO_QA__ | `__BASE___QA` |
| PROD | __PUERTO_PROD__ | `__BASE___PROD` |

Usuarios **de demo** (`bd/0002-datos-semilla.sql`): `cliente.demo`, `operador.demo` y `admin.demo`,
todos con la clave `NovaDemo#1`. Es un proyecto de ejemplo: en una empresa, producción no lleva
usuarios demo.

## Llaves y secretos

La llave privada **no está en el repositorio**: se crea al primer arranque en
`%LOCALAPPDATA%\nova\llaves\` (una por ambiente). Los demás servicios solo usan la pública.
La base usa la autenticación de Windows (`Integrated Security=true`): sin contraseñas.

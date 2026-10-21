# nova-__nombre__

API de negocio de **Nova Retail** (proyecto de ejemplo del canal Forja Skills).
Creada con la skill `arquetipo` (tipo `servicio`): hexagonal por fuera, DDD por dentro.

## Capas

| Carpeta | Qué va | Depende de |
|---|---|---|
| `src/01. Business Rules Model` | entidades, value objects, reglas, puertos de infraestructura | nada |
| `src/02. Application Rules Model` | casos de uso, DTOs, puertos de entrada y salida | Dominio |
| `src/03. Interface Adapter` | controladores, presentadores, gateways (EF Core + SQL Server) | Aplicación |
| `src/04. Framework and Driver` | arranque: JWT, políticas, límites, errores, OpenAPI | todo (une las capas) |
| `tests/` | unitarias · integración · **arquitectura** (fallan si alguien rompe las capas) | — |

## Correr en local

```
dotnet run --project tools/Migrador -- --ambiente DEV       # crea o actualiza las tablas
dotnet run --project "src/04. Framework and Driver/Nova.__Nombre__.Api" --launch-profile DEV
```

| Ambiente | Puerto | Base |
|---|---|---|
| DEV | __PUERTO_DEV__ | `__BASE___DEV` |
| QA | __PUERTO_QA__ | `__BASE___QA` |
| PROD | __PUERTO_PROD__ | `__BASE___PROD` |

- Documentación y pruebas de la API: `http://localhost:__PUERTO_DEV__/scalar`
- Salud: `GET /salud` · Quién soy: `GET /api/v1/quien-soy` (con el token de nova-seguridad)

## Seguridad

Acepta solo tokens de **nova-seguridad** (RS256): descarga su llave pública, así que este repo
no guarda ningún secreto. Scopes: `__nombre__.leer`, `__nombre__.escribir`.
La base usa la autenticación de Windows (`Integrated Security=true`): sin contraseñas.

## Requisitos

.NET 10 · SQL Server Express (`.\SQLEXPRESS`) con las bases ya creadas · nova-seguridad corriendo.

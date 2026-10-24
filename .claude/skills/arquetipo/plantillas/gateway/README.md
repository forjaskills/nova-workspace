# nova-__nombre__

**API pública** de **Nova Retail** (proyecto de ejemplo del canal Forja Skills): la única puerta de entrada.
Creada con la skill `arquetipo` (tipo `gateway`). No tiene dominio ni base de datos: enruta con
[YARP](https://github.com/dotnet/yarp), valida el token y protege el borde.

## Qué hace

| | |
|---|---|
| **Enruta** | `/seguridad/api/v1/sesion` y `/seguridad/.well-known/jwks.json` → nova-seguridad (abiertos)__TABLA_RUTAS__ |
| **Valida el JWT** | de nova-seguridad (RS256, su llave pública). Sin token válido → 401 y el pedido no llega al servicio. El servicio lo vuelve a validar. |
| **Limita** | 100 pedidos/min por usuario (o IP) · login: 5 intentos/min por IP → 429 |
| **CORS** | solo nova-web de cada ambiente; ningún otro sitio puede llamar desde el navegador |
| **Salud** | `GET /salud` pregunta a cada servicio: `Healthy` si todos responden, `Degraded` si falta alguno |

Lo que no está en una ruta (Scalar, `/salud` de cada servicio…) **no se publica**: responde 404.

## Correr en local

```
dotnet run --project src/Nova.__Nombre__.Api --launch-profile DEV
```

| Ambiente | Puerto | Web permitida |
|---|---|---|
| DEV | __PUERTO_DEV__ | `http://localhost:__WEB_PUERTO_DEV__` |
| QA | __PUERTO_QA__ | `http://localhost:__WEB_PUERTO_QA__` |
| PROD | __PUERTO_PROD__ | `http://localhost:__WEB_PUERTO_PROD__` |

Rutas: `src/Nova.__Nombre__.Api/appsettings.json` (`ReverseProxy:Routes`). A dónde apunta cada ambiente:
`appsettings.{Ambiente}.json` (`ReverseProxy:Clusters`).

## Requisitos

.NET 10 · nova-seguridad y los servicios corriendo en el mismo ambiente.

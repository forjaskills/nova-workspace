# nova-__nombre__

**Frontend** de **Nova Retail** (proyecto de ejemplo del canal Forja Skills), con Next.js (App Router) y TypeScript.
Creado con la skill `arquetipo` (tipo `web`). Solo habla con **nova-gateway**: nunca llama directo a un servicio.

## Cómo está ordenado

| Carpeta | Qué va |
|---|---|
| `app/` | rutas: `login/` (abierta) y `(privado)/` (exige sesión: sin cookie, al login) |
| `features/` | una carpeta por funcionalidad: `sesion/` (login, cierre, token) · `__SERVICIO__/` (lo que viene de nova-__SERVICIO__) |
| `lib/api/cliente.ts` | el **cliente HTTP único**: dirección del gateway, token y errores `ProblemDetails` |
| `tests/unit/` · `tests/e2e/` | Vitest · Playwright (un navegador de verdad, de punta a punta) |

## Sesión

El login va a nova-seguridad **a través del gateway**. El token queda en una cookie `httpOnly` y `SameSite=Strict`
que pone el servidor de Next: ningún script del navegador puede leerlo. Las llamadas a la API salen del servidor de
Next con ese token; el gateway lo valida y el servicio lo vuelve a validar.

Usuarios demo (solo DEV y QA): `cliente.demo`, `operador.demo`, `admin.demo` · clave `NovaDemo#1`.

## Correr en local

```
npm ci
npm run dev                         # DEV en http://localhost:__PUERTO_DEV__
npm run build && npm run start:qa   # QA en  http://localhost:__PUERTO_QA__
npm run build && npm start          # PROD en http://localhost:__PUERTO_PROD__
npm test                            # unitarias
npm run e2e                         # de punta a punta (con todo encendido)
```

| Ambiente | Puerto | Gateway (`NOVA_GATEWAY_URL`) |
|---|---|---|
| DEV | __PUERTO_DEV__ | `http://localhost:__GW_PUERTO_DEV__` (`.env.development`) |
| QA | __PUERTO_QA__ | `http://localhost:__GW_PUERTO_QA__` (`.env.qa`) |
| PROD | __PUERTO_PROD__ | `http://localhost:__GW_PUERTO_PROD__` (`.env.production`) |

Los `.env` solo tienen la dirección del gateway: no hay secretos en este repo.

## Requisitos

Node 22 LTS · nova-gateway, nova-seguridad y nova-__SERVICIO__ corriendo en el mismo ambiente.

---
name: arquetipo
description: Crea un proyecto nuevo de Nova Retail desde el arquetipo — tipo `seguridad` (usuarios, login, emite el JWT), `servicio` (API de negocio que acepta ese JWT; 5 capas, hexagonal por fuera y DDD por dentro, EF Core con SQL Server), `gateway` (API pública con YARP: enruta, valida el JWT, CORS y límites) o `web` (frontend Next.js con App Router y TypeScript que inicia sesión y llega a los servicios a través del gateway) — y su repo en GitHub con main/develop/qa. Lo verifica antes de darlo por terminado (compila, pruebas en verde, arranca y prueba de verdad lo que promete cada tipo). Usar cuando se pida crear, generar o arrancar un proyecto, servicio, API, microservicio, gateway, frontend o web nuevo («créame el servicio de inventario», «necesito el proyecto de seguridad», «crea el gateway», «arma la web en Next.js»).
---

# arquetipo

Crea un proyecto **idéntico cada vez**: el código sale de `plantillas/` con un script; tú pones el
criterio (validar, verificar, explicar qué falló). No escribas a mano lo que ya está en las plantillas.

## Parámetros

| Parámetro | Valores | Ejemplo |
|---|---|---|
| tipo | `seguridad` · `servicio` · `gateway` · `web` | `servicio` |
| nombre | minúsculas y números, 3–30, empieza con letra | `pedidos` → `proyectos/nova-pedidos` |

Si falta alguno, pregúntalo. Si el nombre trae guiones, mayúsculas o espacios, propón la versión válida.
Para `seguridad`, `gateway` y `web` el nombre habitual es el mismo tipo (`seguridad`, `gateway`, `web`): hay uno por
espacio de trabajo.

**Orden**: cada tipo necesita los anteriores, porque los usa de verdad.

```
seguridad  →  servicio (uno o más)  →  gateway  →  web
emite el JWT  lo acepta              enruta y lo valida   inicia sesión y llega al servicio por el gateway
```

## Pasos

1. **Antes de generar**: lee `proyectos.json` (raíz del espacio de trabajo).
   - Lo que necesita cada tipo: `servicio` → un `seguridad`; `gateway` → un `seguridad` y al menos un `servicio`;
     `web` → un `gateway`. Si falta, dilo y ofrece crearlo primero.
   - Si el nombre ya existe, detente: nunca sobrescribas un proyecto.
2. **Generar**:
   `powershell -ExecutionPolicy Bypass -File .claude/skills/arquetipo/scripts/generar.ps1 -Tipo <tipo> -Nombre <nombre>`
   Asigna puertos (un bloque de 100 por proyecto), bases y lo registra en `proyectos.json`. El gateway toma de ahí
   sus rutas (una por servicio) y la web, la dirección del gateway.
3. **Verificar** (obligatorio, no te lo saltes aunque el usuario tenga apuro):
   `powershell -ExecutionPolicy Bypass -File .claude/skills/arquetipo/scripts/verificar.ps1 -Nombre <nombre>`
   Enciende lo que el proyecto necesita detrás (seguridad, servicios, gateway) y cierra solo lo que encendió.
   Muestra la tabla al usuario tal como sale.
4. **Si algo está en rojo**: lee el detalle (y el log que indica), explica la causa en una frase y
   propone el arreglo. Corrige **la plantilla** si el error viene de ahí (para que no se repita en el
   próximo proyecto), regenera y vuelve a verificar. El proyecto no está terminado con una fila en rojo.
5. **Repo en GitHub** (con el OK del usuario, porque publica):
   `powershell -ExecutionPolicy Bypass -File .claude/skills/arquetipo/scripts/crear-repo.ps1 -Nombre <nombre>`
   Primero revisa que el correo de git sea el `noreply` de GitHub y que no haya secretos, rutas de
   usuario ni IPs; si encuentra algo, se detiene. Luego crea `main`, `develop` (por defecto) y `qa`, y
   protege `main`, `develop` y `qa` (solo por PR; las `feature/` se borran solas al unirse). Corre otra vez `verificar.ps1` para ver la fila del repo en verde.
6. **Cerrar**: resume en 3 líneas qué se creó (carpeta, puertos DEV/QA/PROD, repo) y cómo probarlo:
   backend `http://localhost:<puerto DEV>/scalar` · gateway `http://localhost:5201/salud` · web `http://localhost:3001`.

## Qué genera cada tipo

| Tipo | Puertos DEV · QA · PROD | Qué genera |
|---|---|---|
| `seguridad` | 5101 · 5102 · 5100 | 5 capas + `Usuario` y `Rol` (DDD), login `POST /api/v1/sesion` → JWT RS256, `/.well-known/jwks.json`, usuarios demo (`cliente.demo`, `operador.demo`, `admin.demo` · clave `NovaDemo#1`) |
| `servicio` | 5001… (el bloque libre que sigue) | 5 capas, API vacía que acepta el JWT de seguridad (`GET /api/v1/quien-soy`); los módulos llegan con `nuevo-modulo` |
| `gateway` | 5201 · 5202 · 5200 | API delgada con YARP, sin dominio ni base: `/seguridad/…` (login y llaves, abiertos) y `/<servicio>/api/…` (con token), valida el JWT, CORS solo para la web, límites (login 5/min), `/salud` que pregunta a cada servicio |
| `web` | 3001 · 3002 · 3000 | Next.js (App Router + TypeScript): `app/` (login y zona privada), `features/` por funcionalidad, cliente HTTP único en `lib/api/`; el token en cookie `httpOnly`; Vitest + Playwright |

Qué va en cada capa y qué vigilan las pruebas de arquitectura: `referencias/capas.md`.
Gateway y web por dentro: `referencias/gateway.md` y `referencias/web.md`.

## Qué comprueba `verificar.ps1`

| Tipo | Filas |
|---|---|
| `seguridad` | compila · pruebas · base (Migrador, idempotente) · arranca · login (200 / clave mala 401 / 6.º intento 429) · repo |
| `servicio` | compila · pruebas · base · arranca · acepta el JWT (sin token 401 / con token 200 / alterado 401) · repo |
| `gateway` | compila · pruebas · arranca (`Healthy`: ve a todos) · login a través del gateway · protege el servicio (401 / 200 / 401) · CORS (la web sí, otro sitio no) y 429 · repo |
| `web` | dependencias (`npm ci`, audit de producción sin altas) · compila (build + TypeScript + lint) · Vitest · arranca · Playwright en un navegador real (login → servicio por el gateway, clave mala, sin sesión, cerrar sesión) · repo |

## Reglas

- **Nada de secretos en el repo**: la base usa autenticación de Windows; la llave que firma los tokens
  vive en `%LOCALAPPDATA%\nova\llaves`; los servicios y el gateway solo usan la llave pública; los `.env` de la web
  solo tienen la dirección del gateway.
- **La web solo habla con el gateway**, nunca directo con un servicio; y el token nunca llega al JavaScript del
  navegador.
- **No crees bases de datos**: las crea el DBA. Si `/salud` falla porque la base no existe, dilo así.
- El esquema cambia **solo con scripts en `bd/`** (los aplica el Migrador), nunca con migraciones de EF.
- No abras PR ni subas a `main`/`develop` directo: eso es de `gitflow`.
- Cierra solo los procesos que levantaste (verificar.ps1 ya lo hace).

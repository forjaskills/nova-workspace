---
name: arquetipo
description: Crea un proyecto backend nuevo de Nova Retail desde el arquetipo — tipo `seguridad` (usuarios, login, emite el JWT) o `servicio` (API de negocio que acepta ese JWT) — con las 5 capas (hexagonal por fuera, DDD por dentro), EF Core con SQL Server y autenticación de Windows, pruebas de arquitectura, y su repo en GitHub con main/develop/qa. Lo verifica antes de darlo por terminado (compila, pruebas en verde, base al día, arranca, login y token). Usar cuando se pida crear, generar o arrancar un proyecto, servicio, API o microservicio nuevo («créame el servicio de inventario», «necesito el proyecto de seguridad»).
---

# arquetipo

Crea un proyecto **idéntico cada vez**: el código sale de `plantillas/` con un script; tú pones el
criterio (validar, verificar, explicar qué falló). No escribas a mano lo que ya está en las plantillas.

## Parámetros

| Parámetro | Valores | Ejemplo |
|---|---|---|
| tipo | `seguridad` · `servicio` | `servicio` |
| nombre | minúsculas y números, 3–30, empieza con letra | `pedidos` → `proyectos/nova-pedidos` |

Si falta alguno, pregúntalo. Si el nombre trae guiones, mayúsculas o espacios, propón la versión válida.

## Pasos

1. **Antes de generar**: lee `proyectos.json` (raíz del espacio de trabajo).
   - `servicio` necesita un proyecto `seguridad` registrado. Si no hay, dilo y ofrece crearlo primero.
   - Si el nombre ya existe, detente: nunca sobrescribas un proyecto.
2. **Generar**:
   `powershell -ExecutionPolicy Bypass -File .claude/skills/arquetipo/scripts/generar.ps1 -Tipo <tipo> -Nombre <nombre>`
   Asigna puertos (un bloque de 100 por proyecto), bases y lo registra en `proyectos.json`.
3. **Verificar** (obligatorio, no te lo saltes aunque el usuario tenga apuro):
   `powershell -ExecutionPolicy Bypass -File .claude/skills/arquetipo/scripts/verificar.ps1 -Nombre <nombre>`
   Muestra la tabla al usuario tal como sale.
4. **Si algo está en rojo**: lee el detalle (y el log que indica), explica la causa en una frase y
   propone el arreglo. Corrige **la plantilla** si el error viene de ahí (para que no se repita en el
   próximo proyecto), regenera y vuelve a verificar. El proyecto no está terminado con una fila en rojo.
5. **Repo en GitHub** (con el OK del usuario, porque publica):
   `powershell -ExecutionPolicy Bypass -File .claude/skills/arquetipo/scripts/crear-repo.ps1 -Nombre <nombre>`
   Primero revisa que el correo de git sea el `noreply` de GitHub y que no haya secretos, rutas de
   usuario ni IPs; si encuentra algo, se detiene. Luego crea `main`, `develop` (por defecto) y `qa`, y
   protege `main` y `develop`. Corre otra vez `verificar.ps1` para ver la fila 7 en verde.
6. **Cerrar**: resume en 3 líneas qué se creó (carpeta, puertos DEV/QA/PROD, repo) y cómo probarlo:
   `http://localhost:<puerto DEV>/scalar`.

## Qué genera cada tipo

| Tipo | Además de las 5 capas, pruebas y Migrador |
|---|---|
| `seguridad` | `Usuario` y `Rol` (DDD), login `POST /api/v1/sesion` → JWT RS256, `/.well-known/jwks.json`, usuarios demo (`cliente.demo`, `operador.demo`, `admin.demo` · clave `NovaDemo#1`) |
| `servicio` | API vacía que acepta el JWT de seguridad (`GET /api/v1/quien-soy`); los módulos llegan con `nuevo-modulo` |

Qué va en cada capa y qué vigilan las pruebas de arquitectura: `referencias/capas.md`.

## Reglas

- **Nada de secretos en el repo**: la base usa autenticación de Windows; la llave que firma los tokens
  vive en `%LOCALAPPDATA%\nova\llaves`; los servicios solo usan la llave pública.
- **No crees bases de datos**: las crea el DBA. Si `/salud` falla porque la base no existe, dilo así.
- El esquema cambia **solo con scripts en `bd/`** (los aplica el Migrador), nunca con migraciones de EF.
- No abras PR ni subas a `main`/`develop` directo: eso es de `gitflow`.
- Cierra solo los procesos que levantaste (verificar.ps1 ya lo hace).

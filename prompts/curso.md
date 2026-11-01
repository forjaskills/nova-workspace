# Prompts del curso · Claude Code para programadores

Todos los prompts que se escriben en los módulos nuevos del curso (M1–M5 y M10–M12), palabra por palabra, con por qué
están escritos así. Los de M6–M9 están en `video-01a.md`, `video-02a.md`, `video-02b.md` y `video-03.md`.
Comandos confirmados contra la documentación oficial y **grabados con Claude Code 2.1.314** (octubre de 2026): las notas
dicen lo que pasó de verdad en la grabación. Claude Code cambia seguido: si algo no coincide, revisa la documentación.

## M1 · Qué es Claude Code

### P1.1 · Que explique el proyecto (en `nova-workspace`)
```
¿Qué hace este proyecto? Explícamelo en cinco líneas y dime cómo se corren las pruebas de nova-pedidos.
```
- **No le pego nada**: tiene que leer el repo solo. Es la diferencia con un chat.
- **«En cinco líneas»**: le pongo un formato para que la respuesta se pueda revisar de un vistazo.
- La segunda pregunta prepara la P1.2: si dice bien el comando, leyó de verdad.
- En la grabación, en modo manual, **pidió permiso dos veces solo para listar carpetas** (comandos de PowerShell);
  las búsquedas dentro de los archivos no piden permiso.

### P1.2 · Que actúe
```
Corre las pruebas de nova-pedidos y dime cuántas pasan y cuántas fallan.
```
- Le pido **un hecho comprobable** (cuántas pasan), no una opinión.
- Pide permiso para ejecutar `dotnet test`; como el comando entra a otra carpeta (`cd`), **solo ofrece sí o no**.
  Se responde «sí, esta vez» (los permisos se ven en M3). Grabación: pasan las 59, ninguna falla.

## M2 · Instalar (terminal de PowerShell, fuera de Claude Code)
```
irm https://claude.ai/install.ps1 | iex     # confirmado en la documentación oficial (30-oct)
claude --version
claude doctor
```
- `claude doctor` revisa la instalación y dice qué falta. Es lo primero que se corre si algo no anda.
- **Si `claude` «no se reconoce como comando»** (en la grabación pasó de verdad: el instalador avisa en «Setup notes»
  que `.local\bin` no está en el PATH), agregar la carpeta al PATH **de tu usuario** y abrir **una terminal nueva**:
```
[Environment]::SetEnvironmentVariable("Path", [Environment]::GetEnvironmentVariable("Path", "User") + ";$env:USERPROFILE\.local\bin", "User")
```
- Primer inicio: tema → método de inicio de sesión (suscripción · consola · otra nube) → «¿Confías en esta carpeta?»
  (la opción marcada es «No, exit»: confiar es una decisión). En VS Code, la extensión **verificada de Anthropic**; hay
  copias de terceros con nombres parecidos.

## M3 · Permisos, modo plan y deshacer

### P3.0 · Rama de prueba (terminal en `proyectos/nova-pedidos`, antes de abrir Claude Code)
```
git switch -c prueba/filtro-producto
```
(Parte de `feature/modulo-pedidos`: el módulo de pedidos todavía no está unido a `develop`.)
- Todo lo que se prueba va en una rama aparte: el deshacer de Claude Code no deshace comandos.

### P3.1 · En modo plan (Shift+Tab: Manual → aceptar ediciones → plan; confirmado en la documentación)
```
En nova-pedidos quiero que el listado de pedidos se pueda filtrar por producto: solo los pedidos que llevan un producto dado, por ejemplo para avisar a quienes compraron algo que se agotó.
Respeta la arquitectura del proyecto y agrega una prueba. Antes de tocar nada, muéstrame el plan: qué archivos
cambias y cómo lo vas a comprobar.
```
- **«Solo los pedidos que llevan un producto dado»** y **un para qué** (avisar si algo se agotó): un caso concreto evita
  que adivine el alcance.
- **«Respeta la arquitectura»** y **«agrega una prueba»**: lo que un dev pediría en una revisión.
- **«Muéstrame el plan»**: en modo plan no edita; igual lo pido explícito para que el plan diga cómo comprueba.
- Grabación: **antes del plan hizo dos preguntas** con su recomendación (nombre exacto o que contenga el texto · solo el
  servicio o también la web) → exacto y solo el servicio. El plan incluía migrar la base DEV (ver P3.1b).

### P3.1b · Cuando pide migrar DEV (grabación 30-oct: se le dijo «No» al permiso del Migrador)
```
No toques DEV. Deja el cambio así y dime qué hiciste y cuántas pruebas pasan.
```
- El plan incluía la prueba en DEV; **el permiso es la barrera**: se responde «No» y se le dice qué hacer en su lugar.

### P3.2 · Regla de prohibir (en `/permissions`, pestaña de prohibir)
```
Bash(git push:*)
```
- Se agrega en **Deny**: en el curso, subir algo siempre lo decide una persona. Ojo (documentación): no cubre
  variantes como `git -C . push`; es una barrera, no una garantía. La garantía es el hook de M11 y la rama protegida.

### P3.3 · Deshacer
```
/rewind
```
- Se elige el punto anterior al cambio y **«Restore code»** (deja la conversación; las opciones son «Restore code and
  conversation», «Restore conversation» y «Restore code»). Grabación: limpio, también el script nuevo; **lo que hicieron
  los comandos (el índice en la base de pruebas) no se deshace**. Después, en la terminal: `git status` (limpio) y
  `git switch feature/modulo-pedidos` + `git branch -D prueba/filtro-producto`.

## M4 · CLAUDE.md

### P4.1 · La pregunta de todos los días (antes y después de CLAUDE.md)
```
¿Cómo corro las pruebas de pedidos?
```
- Corta a propósito: así la diferencia entre «explora carpetas» y «responde directo» se nota.

### P4.2 · Generar el borrador
```
/init
```
- **Antes, `/clear`**: en la grabación, lanzado en la misma sesión de P4.1, se puso a explorar `nova-pedidos`.
  Salió en inglés y con 105 líneas (con la clave demo): se reemplazó por la versión corta (`CLAUDE.md` del repo).
- El borrador **se revisa entero**: se queda lo que un dev nuevo necesita (comandos, carpetas, reglas del equipo) y
  se va lo que Claude deduce solo o lo que es un procedimiento (eso va a una skill).

### P4.3 · Importar el AGENTS.md de la web (una línea en `CLAUDE.md`)
```
@proyectos/nova-web/AGENTS.md
```
- No se copia: se importa. Si el archivo cambia, `CLAUDE.md` no queda viejo.

## M5 · Contexto y tokens

### P5.1 · Llenar el contexto a propósito
```
Lee todas las pruebas de nova-web y dime qué parte de las pantallas no tiene ninguna prueba.
```
- Una tarea real que obliga a leer mucho: sirve para ver subir el número en `/context`.

### P5.2 · Compactar con foco
```
/compact quédate con la lista de pantallas sin pruebas y olvida el detalle de cada archivo
```
- Con foco, el resumen guarda lo que importa para seguir. Sin foco, decide Claude.

## M10 · Subagentes

### P10.1 · Búsqueda pesada con un subagente
```
Usa un subagente para buscar en los cuatro proyectos dónde se valida el estado de un pedido. Devuélveme solo la
lista de archivos y líneas, sin el código.
```
- **«Usa un subagente»**: lo pido explícito para ver la diferencia en `/context`.
- **«Solo la lista, sin el código»**: lo que vuelve a la sesión principal tiene que ser poco.

### P10.1b · La misma pregunta sin subagente (para comparar)
```
Busca en los cuatro proyectos dónde se valida el estado de un pedido. Devuélveme solo la lista de archivos y líneas, sin el código.
```
- Grabación: con subagente, 130 → 16,2k tokens en 1 min 49 s; sin subagente, 18,2k en 22 s. **Para una búsqueda corta
  el ahorro es chico**; rinde cuando hay que leer mucho (P10.3: ~37k tokens por revisor quedaron fuera de la sesión).

### P10.0 · Crear el subagente `revisor-arquitectura` (archivo `.claude/agents/revisor-arquitectura.md`)
```
Crea un subagente de proyecto en .claude/agents/revisor-arquitectura.md, con tools: Read, Grep, Glob y model: inherit.
Usa exactamente esta descripción y esta instrucción.
```
(Desde la v2.1.198, `/agents` ya no abre un asistente: el subagente es un archivo con `name`, `description`, `tools`, `model`.)
Descripción (cuándo usarlo):
```
Revisa cambios de código de Nova Retail contra las reglas de arquitectura (capas hexagonales y dominio DDD). Usar
después de cambiar código en nova-pedidos o nova-seguridad, o cuando se pida revisar la arquitectura de una rama.
No corrige: reporta.
```
Instrucción (lo que sabe):
```
Eres un revisor de arquitectura. Solo lees: nunca editas ni ejecutas comandos que cambien algo.
Reglas que revisas:
1. El dominio no depende de infraestructura, ni de la web, ni de paquetes externos.
2. Los controladores viven en los adaptadores de entrada, nunca en la capa Api (la Api solo arranca).
3. Los casos de uso no conocen la base de datos: usan puertos.
4. Las reglas de negocio están en las entidades, no en los controladores.
Para cada regla rota, devuelve: archivo, línea, regla y cómo se arregla, en una tabla. Si no hay ninguna, dilo en
una línea. No repitas el código.
```
- **Solo lectura** (`tools: Read, Grep, Glob`): un revisor que edita deja de ser revisor.
- **«No repitas el código»**: lo que vuelve tiene que ser corto.

### P10.2 · Probar el revisor (en una rama con el error de M6)
```
Revisa los cambios de esta rama con el revisor de arquitectura.
```

### P10.3 · Dos revisores en paralelo
```
Lanza dos revisores de arquitectura en paralelo: uno para nova-pedidos y otro para nova-seguridad, y júntame los
dos resultados en una sola tabla.
```

## M11 · Hooks

### P11.1 · Intentar un commit en main (con el hook ya puesto)
```
En nova-web, haz un commit en main con el cambio del README.
```
(En la grabación, `nova-workspace` no era un repo de git: el `main` es el de `nova-web`, que antes queda en `main` con
una línea nueva en el README. El hook mira la carpeta del comando — `git -C`, `cd … &&`, `Set-Location` — y no solo la
de la sesión.)
- Lo pido mal a propósito: es lo que el hook tiene que frenar aunque yo lo pida.

### P11.1b · Si se niega por el CLAUDE.md (grabación 30-oct: se negó y ofreció una rama)
```
Sí, es un hotfix acordado: haz el commit directo en main.
```
- Ahí sí intenta el commit y **el hook lo bloquea** (exit 2). Lo bueno: se ven las dos capas, la regla escrita y la
  garantía.

### P11.2 · Una edición chica de C# (con el hook de formato puesto)
```
En nova-pedidos, en la entidad del pedido, agrega una propiedad EstaPendiente que diga si el pedido sigue pendiente.
No cambies nada más.
```
- **«No cambies nada más»**: así, lo único distinto además de la propiedad es lo que hace el hook.
- Antes de empezar, el archivo tiene la sangría desordenada (como cuando alguien edita sin `.editorconfig`). El hook corre `dotnet format whitespace` sobre ese archivo después de la edición: solo espacios,
  sangría y saltos de línea, sin compilar (tarda un segundo).
- ⚠ En Windows (documentación de hooks): **sin Git para Windows, el código 1 también bloquea**. Con Git Bash instalado,
  el código 1 solo avisa y el 2 bloquea, como se ve en el curso.

Los hooks quedan en `.claude/settings.json` de `nova-workspace` (formato confirmado en la documentación el 30-oct):
```
"hooks": {
  "PreToolUse":  [ { "matcher": "Bash|PowerShell", "hooks": [ { "type": "command", "command": "powershell.exe",
                    "args": ["-NoProfile", "-ExecutionPolicy", "Bypass", "-File", "${CLAUDE_PROJECT_DIR}/.claude/hooks/bloquear-main.ps1"] } ] } ],
  "PostToolUse": [ { "matcher": "Edit|Write", "hooks": [ { "type": "command", "command": "powershell.exe",
                    "args": ["-NoProfile", "-ExecutionPolicy", "Bypass", "-File", "${CLAUDE_PROJECT_DIR}/.claude/hooks/formato-cs.ps1"] } ] } ]
}
```
El script lee la acción con `[Console]::In.ReadToEnd() | ConvertFrom-Json` (`tool_input.command` o `tool_input.file_path`).
- **Antes de un comando** (`PreToolUse`, herramientas Bash y PowerShell: sin Git para Windows, Claude Code usa PowerShell): `.claude/hooks/bloquear-main.ps1` lee la acción, y si es
  `git commit` o `git push` con la rama `main` activa, sale con código 2 y el mensaje «En main no se hace commit:
  crea una rama feature». Código 2 = bloquea; código 1 = solo avisa.
- **Después de editar** (`PostToolUse`, herramientas de edición): si el archivo es `.cs`, `dotnet format` sobre ese
  archivo.

## M12 · Plugins
```
/plugin
```
- Pestaña **Discover** (grabación: 3695 plugins, del *Anthropic Directory* y de `claude-plugins-official`). Se busca
  `commit-commands`: la ficha dice el repositorio, **el commit exacto** que instala y el autor, pero no sus componentes
  («not available for remote plugin»): trae `/commit-commands:commit`, `:clean_gone` y `:commit-push-pr`; se instala
  **para tu usuario** (user scope). `:commit-push-pr` hace push y abre un PR: no se ejecuta sin decidirlo. Después se muestra qué trajo
  (skills, subagentes, hooks o servidores MCP). Un plugin corre código con tus permisos: se revisa antes.

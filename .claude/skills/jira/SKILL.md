---
name: jira
description: Trabaja con los tickets del espacio NOVA de Jira (proyecto Nova Retail) a través del MCP de Atlassian — lee un ticket, deja un comentario con la plantilla del equipo (Inicio, Avance, Revisión, Bloqueo, Pase a QA) y mueve el ticket al siguiente estado del tablero (Por hacer → En curso → En revisión → En QA), siempre de a un paso, con confirmación del dev y sin pasarlo nunca a Listo. Usar siempre que se hable de un ticket NOVA-… o de Jira, aunque sea una frase corta, como «empiezo NOVA-1», «¿qué pide NOVA-1?», «toma NOVA-3», «comenta en el ticket que…», «pásalo a revisión», «mándalo a QA» o «estoy bloqueado con NOVA-…». No usar para preguntas generales sobre qué es Jira o cómo funciona.
---

# jira

Tres cosas, nada más: **leer** un ticket, **comentar** con la plantilla y **mover** al siguiente estado. La skill no
crea tickets, no edita campos y no borra nada.

## El sitio y el tablero

| Dato | Valor |
|---|---|
| Sitio | `https://forjaskills.atlassian.net` |
| cloudId | el que devuelve `getAccessibleAtlassianResources` para tu sitio (pásalo en cada llamada) |
| Proyecto | `NOVA` — Nova Retail |
| Tablero | `SCRUM board` (id `1`) |

Estados del tablero, en orden (leídos con `getJiraBoardConfig` el 2026-10-29):

| # | Estado | id | Comentario que lo acompaña |
|---|---|---|---|
| 1 | Por hacer | 10000 | — |
| 2 | En curso | 10001 | `[Inicio]` |
| 3 | En revisión | 10002 | `[Revisión]` |
| 4 | En QA | 10004 | `[Pase a QA]` |
| 5 | Listo | 10003 | **nunca lo mueve la IA** |

**Ojo:** el flujo de NOVA permite ir de cualquier estado a cualquier otro (incluido Listo). Jira no te va a frenar;
las reglas de abajo las haces cumplir tú.

## Reglas

1. **Nunca saltarse un estado.** Solo se mueve al estado siguiente de la tabla. Si piden «pásalo a QA» y está en
   «En curso», explica que primero va a «En revisión» y ofrece ese paso.
2. **Nunca pasar a Listo.** Desde «En QA» no se mueve: Listo lo decide una persona después de probar. Tampoco se
   mueve hacia atrás; eso se hace a mano en Jira.
3. **Nunca borrar nada.** Ni tickets, ni comentarios, ni campos, ni enlaces. No uses `executeDestructive` ni
   `editJiraIssue`, y llama a `addOrEditJiraIssueComment` **sin** `commentId` (editar reemplaza el comentario).
4. **Confirmación antes de mover.** Muestra el ticket, `estado actual → estado siguiente` y el comentario tal como
   se va a publicar, y espera un sí explícito. Sin sí, no se mueve ni se comenta.
5. **No inventar campos.** Muestra solo lo que viene en la respuesta del MCP. Si un campo no viene o está vacío
   (asignado, prioridad, story points, etiquetas…), dilo así («sin asignar», «no tiene story points»); no lo
   rellenes ni lo deduzcas. Si los criterios están dentro de la descripción, cítalos como parte de la descripción.

## Leer un ticket

1. `getJiraIssue` con `issueIdOrKey: NOVA-N` y `view: "evidence"` (trae sprint, story points y enlaces si existen).
2. Si `comment.total > 0`, `listJiraIssueComments` para ver los comentarios.
3. Resume: clave, título, tipo, estado, asignado, sprint, descripción y los últimos comentarios. Solo campos
   presentes (regla 5). Si la clave no es de NOVA o no existe, dilo y para.

## Comentar

Plantilla: `referencias/comentario.md`. Elige el tipo según lo que pasó:

| Tipo | Cuándo | Mueve |
|---|---|---|
| Inicio | al tomar el ticket | Por hacer → En curso |
| Avance | hay algo que contar | no |
| Revisión | se abrió el pull request | En curso → En revisión |
| Bloqueo | falta algo; qué y de quién depende | no |
| Pase a QA | qué probar y dónde | En revisión → En QA |

- El tipo tiene que cuadrar con el estado: `[Inicio]` solo desde «Por hacer», `[Revisión]` solo desde «En curso»,
  `[Pase a QA]` solo desde «En revisión». Si no cuadra, dilo y pregunta qué pasó de verdad.
- Rellena cada línea con lo que el dev te contó o lo que hiciste en esta sesión. Si no sabes «Qué sigue» o la rama,
  pregúntalo. La rama es `feature/NOVA-N-slug` o «todavía no».
- Publica el texto sin el bloque de código, en markdown, con **una línea en blanco entre cada línea** (si no, Jira
  las junta en un solo párrafo):

  ```
  [Inicio] Tomo la historia de cancelar un pedido.

  Qué se hizo: Leí la historia y sus dos reglas.

  Qué sigue: Armar la ficha del módulo con el dev.

  Rama: todavía no
  ```

- Avance y Bloqueo no mueven el ticket, pero igual muestra el texto antes de publicarlo.

## Mover al siguiente estado

1. Vuelve a leer el estado actual con `getJiraIssue` (puede haber cambiado desde que lo leíste).
2. Calcula el siguiente con la tabla. Si está en «En QA» o «Listo», no hay paso posible: dilo y para (regla 2).
3. `executeRead` → `listJiraIssueTransitions` y toma la transición cuyo **`to.name`** es el estado siguiente. Usa
   su `id`; no adivines nombres de transición. Si no aparece, para y avisa: el tablero cambió.
4. Pide confirmación (regla 4) con el movimiento y el comentario juntos.
5. Con el sí: `transitionJiraIssue` con ese `transitionId`, y después `addOrEditJiraIssueComment` con el comentario.
   Si la transición falla, no publiques el comentario (diría algo que no pasó). Si falla solo el comentario,
   reintenta solo el comentario.

## Comprobar (siempre, al final)

Vuelve a leer el ticket antes de darlo por terminado:

1. `getJiraIssue` → el estado es el esperado (el siguiente, o el mismo si solo comentaste).
2. `listJiraIssueComments` → el último comentario es el tuyo, con el tipo correcto y en líneas separadas.
3. Cuéntaselo al dev en una o dos líneas: `NOVA-N: <antes> → <ahora>, comentario [Tipo] publicado`. Si algo no
   cuadra, dilo tal cual; no lo des por hecho.

# Prompts del video · Claude Code + Jira con MCP

Todos los prompts que se escriben en el video, tal cual, para que los copies. Cada uno con:
**qué le pido**, **por qué está escrito así**, **qué hace Claude Code** y **cómo reviso la respuesta**.

> Se usan dentro de `nova-workspace`. Necesitas un sitio de Jira Cloud (el plan gratis sirve) con un proyecto de
> clave `NOVA`, un tablero con los estados **Por hacer → En curso → En revisión → En QA → Listo** y una historia
> NOVA-1. La plantilla de comentario ya está en `.claude/skills/jira/referencias/comentario.md`.

---

## P1 · Conectar el MCP de Atlassian al proyecto (en la terminal, fuera de Claude Code)

```
claude mcp add --transport http --scope project atlassian https://mcp.atlassian.com/v2/mcp
```

- **Qué le pido**: que agregue el servidor MCP oficial de Atlassian (la empresa de Jira) a este proyecto.
- **Por qué está escrito así**: con `--scope project` la conexión queda en `.mcp.json`, dentro del repo: quien lo
  clone tiene la misma conexión. **No se pega ninguna clave**: Jira se autoriza en el navegador, con tu cuenta.
- **Qué hace Claude Code**: crea `.mcp.json` (nombre, tipo `http` y la dirección). Al abrir `claude` avisa
  «New MCP server found in this project» y pregunta si lo usas: elige «Use this MCP server».
- **Cómo lo reviso**: `/mcp` → `atlassian` conectado, con sus herramientas. La primera vez te pide entrar con tu
  cuenta de Atlassian en el navegador y aprobar.

## P2 · Primera prueba de la conexión

```
¿Qué tickets hay en el espacio NOVA de Jira?
```

- **Qué le pido**: una lectura, nada más.
- **Por qué está escrito así**: pregunta abierta, sin skill todavía: comprueba que el MCP responde.
- **Qué hace Claude Code**: pide permiso para ver tus sitios de Atlassian y otro para buscar los tickets (JQL), y
  responde con la tabla: NOVA-1, Historia, «Cancelar un pedido», Por hacer, sin asignar.
- **Cómo lo reviso**: lo que dice tiene que estar en Jira. Cada herramienta pide permiso antes de usarse.

## P3 · El prompt suelto (sin skill, para comparar)

```
Empiezo a trabajar NOVA-1: muévelo y déjale un comentario.
```

- **Qué le pido**: lo de todos los días, sin preparación.
- **Por qué está escrito así**: **no dice** a qué estado, con qué formato ni qué tiene que comprobar.
- **Qué hace Claude Code**: en el video, buscó por su cuenta cómo mover un ticket, eligió «En curso» y escribió un
  comentario libre. Seis permisos seguidos y ninguna pregunta antes de mover. Funciona, pero otra corrida (u otro
  dev) escribiría otra cosa.
- **Cómo lo reviso**: abre el ticket en Jira. ¿El comentario dice qué sigue y en qué rama? Después déjalo como
  estaba: borra el comentario y vuelve NOVA-1 a «Por hacer».

## P4 · Crear la skill `jira`

```
Crea la skill jira en .claude/skills/jira. Debe saber tres cosas del espacio NOVA de Jira, usando el MCP de Atlassian: leer un ticket, comentar con la plantilla de referencias/comentario.md y mover el ticket al siguiente estado del tablero. Antes de escribir nada, lee el tablero NOVA con el MCP y usa los nombres reales de sus estados. Reglas: nunca saltarse un estado, nunca pasar un ticket a Listo, nunca borrar nada, pedir confirmación antes de mover, y no inventar campos que el ticket no tiene. Al final, comprueba volviendo a leer el ticket.
```

- **Qué le pido**: la skill, con las tres cosas que hace y las reglas del equipo.
- **Por qué está escrito así**: le doy los datos (el espacio, la plantilla, el MCP) para que no adivine. «Lee el
  tablero antes de escribir»: los estados salen de Jira, no de la imaginación. Lo que **no** debe hacer va escrito.
- **Qué hace Claude Code**: lee Jira (tableros de NOVA, configuración del tablero, transiciones de NOVA-1), avisa que
  el flujo de NOVA **no restringe transiciones** (Jira te deja saltar a Listo), así que la skill tiene que imponer las
  reglas, y te muestra el `SKILL.md` antes de crearlo. No mueve ningún ticket para probarse.
- **Cómo lo reviso**: recorre el `SKILL.md`: la tabla de estados en orden (Listo: «nunca lo mueve la IA»), las cinco
  reglas, cómo lee, comenta, mueve y comprueba. Ojo: en el tuyo, el sitio y el cloudId serán los de tu Jira.

## P4b · Ajustar la descripción (en el editor)

Se reemplaza el «Usar cuando…» que escribió Claude por las frases reales del equipo:

```
Usar siempre que se hable de un ticket NOVA-… o de Jira, aunque sea una frase corta, como «empiezo NOVA-1», «¿qué pide NOVA-1?», «toma NOVA-3», «comenta en el ticket que…», «pásalo a revisión», «mándalo a QA» o «estoy bloqueado con NOVA-…». No usar para preguntas generales sobre qué es Jira o cómo funciona.
```

- **Por qué**: Claude no lee todas las skills enteras; lee su **descripción** y con eso decide si la usa. Si no dice
  las palabras de tu equipo, la skill no se activa.
- **Trampa**: escribe «, como» y no «:» antes de los ejemplos. Un «: » dentro de la `description:` sin comillas
  rompe el YAML y la skill no carga.
- **Cómo lo reviso**: con las tres frases de abajo, cada una en una conversación nueva.

## Pruebas de la descripción (una conversación nueva cada una)

```
¿Qué pide NOVA-1?
```
```
Comenta en NOVA-1 que voy por la mitad.
```
```
¿Qué es Jira?
```

- Las dos primeras tienen que mostrar **Skill(jira) · Successfully loaded skill**; la tercera responde normal, sin la
  skill y sin tocar Jira.
- En el video, la segunda **frenó**: NOVA-1 seguía en Por hacer y un comentario de avance no cuadraba con eso.
  Propuso dos caminos y no escribió nada hasta saber qué se hizo, qué sigue y la rama.

## P5 · NOVA-1 de punta a punta (con la skill)

```
Empiezo NOVA-1.
```

- **Por qué está escrito así**: la frase más corta posible. Si la skill se activa con esto, se activa con todo.
- **Qué hace Claude Code**: carga la skill, lee la plantilla, el ticket y sus transiciones, y **antes de tocar nada**
  te muestra el comentario `[Inicio]` y pregunta «¿Lo muevo y publico el comentario así?». Con tu sí, mueve NOVA-1 a
  En curso, publica el comentario y vuelve a leer el ticket para comprobarlo.
- **Cómo lo reviso**: en Jira, NOVA-1 en En curso y el comentario línea por línea, igual que la plantilla.

## Tu reto

Pídele que comente un **bloqueo** en NOVA-1 y prueba si la skill se activa con:

```
estoy trabado con NOVA-1
```

Si no se activa, mejora la descripción y vuelve a probar.

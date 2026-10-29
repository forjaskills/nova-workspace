# Prompts del video · El proyecto crece con skills: las pantallas de Pedidos (web)

Todos los prompts que se escriben en el video, tal cual, para que los copies. Cada uno con:
**qué le pido**, **por qué está escrito así**, **qué hace Claude Code** y **cómo reviso la respuesta**.

> Se usan dentro de `nova-workspace`, con la skill `nuevo-modulo` en `.claude/skills/nuevo-modulo/` y el módulo
> Pedidos del video anterior ya hecho: `nova-pedidos` y `nova-seguridad` en la rama `feature/modulo-pedidos`, y
> `nova-web` como quedó en el video 1b. Si empiezas desde cero, primero los prompts de los videos anteriores.
> Necesitas .NET 10, SQL Server Express y Node 22 LTS.

---

## P1 · El prompt suelto (para comparar)

```
Hazle a esta web las pantallas de pedidos: el listado, el detalle y un formulario para crear un pedido.
```

- **Qué le pido**: las pantallas de un módulo, sin darle ningún procedimiento.
- **Por qué está escrito así**: es el prompt que escribiría cualquiera con el repo de la web abierto. A propósito **no
  dice** qué devuelve la API, quién puede qué ni qué calcula el servidor.
- **Qué hace Claude Code**: lo que mejor le parece **esa vez**. Córrelo en una copia de `nova-web` **sin** la carpeta
  `.claude/skills` (y sin el código de la API al lado, como cuando abres solo el repo de la web). En el video la copia
  estaba junto al workspace: Claude **buscó el servicio en la carpeta vecina** y leyó el contrato real. Funcionó, pero
  por suerte; y aun así borró la franja de permisos, cambió una prueba del video 1b y no probó nada en un navegador.
- **Cómo lo reviso**: ¿de dónde sacó los campos de un pedido (los preguntó o los supuso)? ¿Llama a la API desde el
  navegador? ¿Manda el total? ¿Usó el cliente de `lib/api/cliente.ts`? ¿Escribió pruebas? Y lo más directo: enciende
  la web y abre la página con los pedidos de verdad.

## P2 · ¿Claude entiende lo nuevo de la skill?

```
¿Qué hace ahora la skill nuevo-modulo con la web y en qué orden trabaja?
```

- **Qué le pido**: que me diga qué entendió de las partes nuevas del `SKILL.md`.
- **Por qué está escrito así**: compruebo el manual **antes** de usarlo; digo «ahora» porque la skill ya existía.
- **Qué hace Claude Code**: lee el `SKILL.md`.
- **Cómo lo reviso**: tiene que decir que, si el módulo ya existe, **lee la ficha y el `Dtos.cs`** y propone qué va en
  cada pantalla antes de escribir; que el esqueleto agrega solo las pantallas; y que la verificación prueba la web en
  un navegador.

## P3 · Las pantallas del módulo

```
Agrega las pantallas del módulo Pedidos a nova-web: el listado con filtro por estado, el detalle y el formulario de nuevo pedido.
```

- **Qué le pido**: las tres pantallas de un módulo que ya tiene su API.
- **Por qué está escrito así**: «agrega las pantallas del módulo» activa la skill; digo **en qué web** y **qué
  pantallas** (y que el listado se filtra por estado). **No** le digo campos, tipos ni componentes: eso sale del
  contrato de la API.
- **Qué hace Claude Code**: lee el `SKILL.md`, la ficha del módulo (`docs/modulos/pedidos.md`) y el `Dtos.cs` de
  `nova-pedidos`, y **antes de escribir** te propone cada pantalla: columnas y filtros, datos del detalle, campos del
  formulario y qué calcula el servidor. Te pregunta lo que no sabe.
- **Cómo lo reviso**: ¿todo sale del contrato real? ¿El total del formulario es solo «estimado»? ¿Propuso algo que el
  cliente no puede hacer (avanzar el estado)?

## P4 · Aprobar las pantallas

```
Está bien así. Sin botón de avanzar estado: eso es del operador y llega después. Sigue.
```

- **Qué le pido**: el OK que la skill espera y una decisión de alcance.
- **Por qué está escrito así**: la skill no escribe sin el OK. Digo **qué queda fuera** para que no lo agregue «por si
  acaso». Si te pregunta otras cosas, respóndelas una por una antes del «Sigue».
- **Qué hace Claude Code**: corre `esqueleto.ps1` (no toca `nova-pedidos`: agrega las pantallas en `nova-web`, en la
  rama `feature/modulo-pedidos`), escribe de la API hacia la pantalla y lo verifica con `verificar.ps1`.
- **Cómo lo reviso**: la tabla con las filas 1 a 6 en verde; en la 6, lint, Vitest, build y Playwright (las pruebas
  nuevas y las de sesión del video 1b). La fila 7 queda en rojo («archivos sin commit») hasta que subes: subir es el
  paso siguiente y espera tu OK.

## P5 · Revisar el contrato

```
Dime de dónde sacaste cada tipo de la web y qué calcula el navegador.
```

- **Qué le pido**: una revisión, no código nuevo.
- **Por qué está escrito así**: así compruebo que cada tipo apunta a un DTO real de `nova-pedidos` y que el navegador
  solo **estima** (el total que vale lo calcula el pedido en el servidor).
- **Cómo lo reviso**: cada tipo, con su `record` de `Dtos.cs`; el total estimado, sin mandarse a la API.

## P5b · Lo que ninguna prueba ve

```
El formulario de nuevo pedido se sale de su tarjeta: los botones y el total quedan fuera del borde. Arréglalo y vuelve a verificar. Todavía no subas nada.
```

- **Qué le pido**: un arreglo visual que encontré al usar la web a mano.
- **Por qué está escrito así**: digo **qué** veo (qué se sale y de dónde), no cómo arreglarlo; «vuelve a verificar»
  para que la tabla confirme que no rompió nada; «todavía no subas nada» porque subir es otro paso.
- **Cómo lo reviso**: abro la pantalla otra vez. TypeScript, lint, Vitest y Playwright estaban en verde **con** el
  defecto: ninguno mira cómo se ve. La verificación no reemplaza mirar.

## P6 · Subir y abrir el pull request

```
Sube las pantallas y abre el pull request a develop.
```

- **Qué le pido**: publicar la rama del módulo en `nova-web`.
- **Por qué está escrito así**: corto, porque la skill sabe el resto; como subir es **publicar**, la skill me pide
  confirmación antes.
- **Qué hace Claude Code**: commit en `feature/modulo-pedidos` de `nova-web`, push y `gh pr create --base develop`.
- **Cómo lo reviso**: en GitHub, el PR contra `develop`. Con los del video anterior, son tres: seguridad, pedidos y la
  web. El merge, después de revisarlos.

## P7 · Tu reto

```
Agrega las pantallas del módulo Productos a nova-web: el listado, el detalle y el formulario de nuevo producto.
```

- **Qué le pido**: las pantallas del módulo del reto anterior (Productos), en tu PC, con la misma skill.
- **Por qué está escrito así**: igual que P3: qué pantallas, sin campos ni componentes.
- **Cómo lo reviso**: la propuesta antes del código y las filas 1 a 6 en verde (la 7, al subir). Cuéntame en los comentarios qué te
  propuso.

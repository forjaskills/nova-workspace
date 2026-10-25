# Prompts del video · El proyecto crece con skills: el módulo Pedidos (backend)

Todos los prompts que se escriben en el video, tal cual, para que los copies. Cada uno con:
**qué le pido**, **por qué está escrito así**, **qué hace Claude Code** y **cómo reviso la respuesta**.

> Se usan dentro de `nova-workspace`, con la skill `nuevo-modulo` en `.claude/skills/nuevo-modulo/` y los cuatro
> proyectos de los videos anteriores ya creados (`nova-seguridad`, `nova-pedidos`, `nova-gateway` y `nova-web`, tag
> `video-01b`). Si empiezas desde cero, primero los cuatro prompts del reto del video anterior.
> Necesitas .NET 10, SQL Server Express y Node 22 LTS.

---

## P1 · El prompt suelto (para comparar)

```
Agrega a este proyecto un módulo de pedidos con su API. El cliente ve y crea sus pedidos.
```

- **Qué le pido**: un módulo de negocio completo, sin darle ningún procedimiento.
- **Por qué está escrito así**: es el prompt que escribiría cualquiera. A propósito **no dice** qué reglas tiene un
  pedido, quién puede qué, cómo se crean las tablas ni qué tiene que probar.
- **Qué hace Claude Code**: lo que mejor le parece **esa vez**. Córrelo en una copia de `nova-pedidos` **sin** la
  carpeta `.claude/skills`: el proyecto ya trae sus pruebas de arquitectura.
- **Cómo lo reviso**: ¿inventó reglas sin preguntar? ¿Dónde quedaron (entidad, controlador, caso de uso)? ¿El total
  viene en el cuerpo del POST? ¿Creó las tablas con migraciones de EF? ¿El cliente ve solo los suyos? ¿Corrió las
  pruebas?

## P1b · ¿Qué dicen las pruebas? (solo si no las corrió; en el video no hizo falta)

```
Corre todas las pruebas de la solución, incluidas las de arquitectura.
```

- **Qué le pido**: que el proyecto juzgue lo que escribió.
- **Por qué está escrito así**: nombro las de arquitectura porque son las que miran **dónde** quedó cada cosa.
- **Cómo lo reviso**: `CapasPruebas` en verde o en rojo, y qué clase nombra si falla.

## P2 · ¿Claude entiende la skill?

```
¿Qué hace la skill nuevo-modulo y en qué orden trabaja?
```

- **Qué le pido**: que me diga qué entendió del `SKILL.md` que acabo de escribir.
- **Por qué está escrito así**: compruebo el manual **antes** de usarlo.
- **Qué hace Claude Code**: lee el `SKILL.md`.
- **Cómo lo reviso**: tiene que decir que **la ficha va primero** y espera mi OK, y después esqueleto → capa por capa
  de adentro hacia afuera → verificar → subir con permiso. Si no la reconoce, revisa la `description` del encabezado.

## P3 · Agregar el módulo

```
Agrega el módulo Pedidos a nova-pedidos. Un pedido es lo que compra un cliente: una o más líneas con producto, cantidad y precio unitario. Pasa por Registrado, Pagado, Enviado y Entregado. El cliente ve y crea los suyos; el operador ve todos y avanza el estado.
```

- **Qué le pido**: el módulo de negocio, descrito como lo diría un analista.
- **Por qué está escrito así**: «agrega el módulo» activa la skill; digo **en qué servicio** para que no adivine;
  describo el negocio (las líneas, los estados, quién puede qué) y **no** le digo carpetas, tablas ni rutas: eso lo
  sabe la skill.
- **Qué hace Claude Code**: lee el `SKILL.md` y `referencias/ficha-modulo.md`, y **antes de escribir código** te
  devuelve la ficha del módulo (campos, estados, reglas con su código de error, quién puede qué, la API) y te pregunta
  lo que no sabe.
- **Cómo lo reviso**: ¿inventó alguna regla? ¿Cada regla tiene su código (`pedido.sin-lineas`…)? ¿El total lo
  calcula el pedido? ¿El cliente ve solo los suyos (uno ajeno responde 404)?

## P4 · Aprobar la ficha

```
La ficha está bien. Cancelar todavía no: llega con su propio ticket. Admin, igual que el operador; los límites, así; PED-000123 en las rutas; y sí, los 3 pedidos demo. Sigue.
```

- **Qué le pido**: el OK que la skill espera, una decisión de alcance y las respuestas a lo que preguntó.
- **Por qué está escrito así**: la skill no escribe código sin el OK. Digo **qué queda fuera** para que no lo agregue
  «por si acaso». En el video Claude preguntó 5 cosas (cancelar, admin, límites, el número en las rutas, datos
  demo): se responden todas, en el mismo orden. Si a ti te pregunta otras, respóndelas igual, una por una.
- **Qué hace Claude Code**: corre `esqueleto.ps1` (rama `feature/modulo-pedidos`, un archivo por capa, el script de
  permisos en `nova-seguridad`), escribe el módulo de adentro hacia afuera y lo verifica con `verificar.ps1`.
- **Cómo lo reviso**: el resumen por capas del esqueleto y, al final, la tabla: compila sin advertencias · pruebas
  **con las de arquitectura** · la base (2.ª pasada: 0) · `pedidos.leer` y `pedidos.escribir` en el token · la API por
  el gateway (401 · 200 · 201 · 200) · la rama lista para el PR. La fila de la web dice que llega en el próximo video.

## P5 · Revisar dónde quedó cada regla

```
Dime dónde quedó cada regla de la ficha y qué prueba la comprueba.
```

- **Qué le pido**: una revisión, no código nuevo.
- **Por qué está escrito así**: así compruebo que cada regla tiene **un lugar** (la entidad) **y una prueba**. Si
  alguna no tiene prueba, es lo primero que le pido.
- **Cómo lo reviso**: cada regla apunta a `Pedido.cs` (o a `LineaPedido.cs`) y a una prueba unitaria; las de quién
  puede qué, a una prueba de integración.

## P5b · La prueba que faltaba

```
Sí: agrega la prueba que compara el dueño con el sub del token y vuelve a verificar. Todavía no subas nada.
```

- **Qué le pido**: lo que la revisión encontró. En el video, Claude avisó solo que el dueño del pedido sale del token
  pero ninguna prueba lo comparaba directamente.
- **Por qué está escrito así**: «sí» responde a su oferta; nombro qué prueba quiero; «vuelve a verificar» para ver la
  tabla otra vez; y «todavía no subas nada» porque subir es otro paso, con su propio permiso.
- **Cómo lo reviso**: el nombre de la prueba nueva, la tabla en verde y que diga que no subió nada.

## P6 · Subir y abrir los pull requests

```
Sube el módulo y abre los pull requests a develop.
```

- **Qué le pido**: publicar la rama del módulo en los dos repos que cambiaron.
- **Por qué está escrito así**: corto, porque la skill sabe el resto. Y como subir es **publicar**, la skill me pide
  confirmación antes.
- **Qué hace Claude Code**: commit en `feature/modulo-pedidos` de `nova-pedidos` y de `nova-seguridad`, push, y
  `gh pr create --base develop` con la ficha como descripción.
- **Cómo lo reviso**: en GitHub, los dos PR contra `develop`, con la ficha. El merge, después de revisarlos.

## P7 · Tu reto

```
Agrega el módulo Productos a nova-pedidos. Un producto tiene nombre, precio y stock; el stock nunca es negativo. El cliente solo los ve; el operador los crea y los edita.
```

- **Qué le pido**: un segundo módulo, en tu PC, con la misma skill.
- **Por qué está escrito así**: igual que P3: el negocio en pocas frases, sin carpetas ni tablas.
- **Cómo lo reviso**: la ficha antes del código y la tabla en verde. Cuéntame en los comentarios qué te preguntó.

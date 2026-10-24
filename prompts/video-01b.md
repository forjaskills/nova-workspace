# Prompts del video · La skill crece: el gateway y la web en Next.js

Todos los prompts que se escriben en el video, tal cual, para que los copies. Cada uno con:
**qué le pido**, **por qué está escrito así**, **qué hace Claude Code** y **cómo reviso la respuesta**.

> Se usan dentro de `nova-workspace`, con la skill `arquetipo` en `.claude/skills/arquetipo/` y los proyectos del video
> anterior ya creados (`nova-seguridad` y `nova-pedidos`). Si empiezas desde cero, primero:
> «Crea el proyecto de seguridad de Nova Retail.» y «Ahora crea el servicio de pedidos. Tiene que aceptar los tokens
> de seguridad.»
> Necesitas .NET 10, SQL Server Express y **Node 22 LTS**.

---

## P1 · El prompt suelto (para comparar)

```
Créame un frontend en Next.js con login contra mi API de seguridad.
```

- **Qué le pido**: una web con inicio de sesión, sin darle ningún procedimiento.
- **Por qué está escrito así**: es el prompt que escribiría cualquiera. A propósito **no dice** dónde guardar el
  token, cómo probar que funciona ni qué versiones usar.
- **Qué hace Claude Code**: lo que mejor le parece **esa vez**. Córrelo en una carpeta vacía, sin skills.
- **Cómo lo reviso**: ¿dónde quedó el token? (busca `localStorage` o `sessionStorage`: cualquier script de la página
  lo puede leer). ¿Hay pruebas? ¿Probó algo antes de decir «listo»? ¿`npm audit` está limpio?

## P2 · ¿Claude ve los tipos nuevos?

```
¿Qué tipos de proyecto puede crear la skill arquetipo y en qué orden?
```

- **Qué le pido**: que me diga qué entendió del `SKILL.md` que acabo de actualizar.
- **Por qué está escrito así**: compruebo el manual **antes** de usarlo. Pregunto también el orden porque cada tipo
  necesita al anterior.
- **Qué hace Claude Code**: lee el `SKILL.md` de la skill.
- **Cómo lo reviso**: tiene que nombrar los cuatro (`seguridad`, `servicio`, `gateway`, `web`) y el orden
  seguridad → servicio → gateway → web. Si no aparecen `gateway` o `web`, revisa la `description` del encabezado.

## P3 · Crear el gateway

```
Crea el gateway de Nova Retail.
```

- **Qué le pido**: la puerta de entrada única: enruta, valida el token, CORS y límites.
- **Por qué está escrito así**: «crea» y «gateway» calzan con la descripción de la skill. No le digo rutas ni
  puertos: la skill los lee de `proyectos.json`. Lo mismo, de forma explícita: `/arquetipo gateway gateway`.
- **Qué hace Claude Code**: revisa que existan seguridad y al menos un servicio, corre `scripts/generar.ps1` y después
  `scripts/verificar.ps1`, que enciende seguridad y pedidos para probar de verdad.
- **Cómo lo reviso**: la tabla, fila por fila. Healthy (ve a todos) · login a través del gateway → 200 ·
  `/pedidos` sin token → 401, con token → 200, alterado → 401 · CORS: la web sí, otro sitio no · 6.º intento → 429.

## P4 · Crear la web

```
Ahora crea la web en Next.js. Tiene que iniciar sesión y llegar a pedidos a través del gateway.
```

- **Qué le pido**: el frontend.
- **Por qué está escrito así**: la segunda frase dice **qué espero**; así sé qué fila mirar (la 5, de punta a punta).
- **Qué hace Claude Code**: genera `nova-web`, instala las dependencias exactas (`npm ci`), compila, corre las pruebas,
  enciende seguridad, pedidos y gateway, y prueba la web en un navegador real con Playwright.
- **Cómo lo reviso**: fila 1, `npm audit` de lo que va a producción sin altas (lo de desarrollo aparece con su nombre:
  léelo) · fila 2, build + TypeScript + lint sin advertencias · fila 3, pruebas unitarias · fila 5, las 4 pruebas en el
  navegador: login → Pedidos por el gateway, clave mala, sin sesión, cerrar sesión.

## P5 · Levantar todo para probarlo en el navegador

```
Levanta todo en DEV para probar la web en el navegador.
```

- **Qué le pido**: que deje corriendo los cuatro (la verificación los apaga al terminar).
- **Por qué está escrito así**: digo el **ambiente** (DEV) para que use los puertos correctos. «Todo» alcanza: la skill
  sabe qué necesita la web detrás.
- **Qué hace Claude Code**: arranca seguridad, pedidos, gateway y web, y me da la dirección `http://localhost:3001`.
- **Cómo lo reviso**: login con `cliente.demo` / `NovaDemo#1` → «Conectado a nova-pedidos a través del gateway».
  Herramientas del navegador → Aplicación → Cookies: `nova_sesion` con **HttpOnly**. En la consola, `document.cookie`
  no la muestra. En Red, el navegador solo habla con `localhost:3001`.

## P6 · Apagar lo que levantó

```
Apaga todo lo que levantaste.
```

- **Qué le pido**: dejar el equipo como estaba.
- **Por qué está escrito así**: «lo que levantaste», no «todo lo que esté corriendo»: que no cierre procesos ajenos.
- **Cómo lo reviso**: los puertos 5001, 5101, 5201 y 3001, libres.

## P7 · Subir a GitHub

```
Sube nova-gateway y nova-web a GitHub.
```

- **Qué le pido**: crear los repositorios con sus ramas.
- **Por qué está escrito así**: corto, porque la skill sabe el resto. Y como subir es **publicar**, la skill me pide
  confirmación antes.
- **Qué hace Claude Code**: revisa que tu correo de git sea el `noreply` de GitHub y que no haya secretos (sin entrar a
  `node_modules`), crea los repos con `gh`, las ramas `main`, `develop` y `qa`, y protege `main` y `develop`.
- **Cómo lo reviso**: en GitHub, las tres ramas y la protección; en la verificación, la fila del repo en verde.

## P8 · Tu reto

```
Crea el proyecto de seguridad de Nova Retail.
Ahora crea el servicio de pedidos. Tiene que aceptar los tokens de seguridad.
Crea el gateway de Nova Retail.
Ahora crea la web en Next.js. Tiene que iniciar sesión y llegar a pedidos a través del gateway.
```

- **Qué le pido**: los cuatro proyectos desde cero, en tu PC, uno por mensaje.
- **Por qué está escrito así**: en el orden en que se necesitan. Si la skill está bien escrita, no hace falta nada más.
- **Cómo lo reviso**: cuatro tablas en verde. Cuéntame en los comentarios cómo te fue.

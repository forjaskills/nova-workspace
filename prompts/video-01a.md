# Prompts del video · Tu primera skill crea los proyectos

Todos los prompts que se escriben en el video, tal cual, para que los copies. Cada uno con:
**qué le pido**, **por qué está escrito así**, **qué hace Claude Code** y **cómo reviso la respuesta**.

> Se usan dentro de `nova-workspace`, con la skill `arquetipo` en `.claude/skills/arquetipo/`.
> Si tu espacio de trabajo se llama distinto, los prompts funcionan igual: la skill se activa por lo que pides,
> no por la carpeta.

---

## P1 · El prompt suelto (para comparar)

```
Créame un proyecto .NET con arquitectura hexagonal para seguridad, con login y JWT.
```

- **Qué le pido**: un proyecto completo, sin darle ningún procedimiento.
- **Por qué está escrito así**: es el prompt que escribiría cualquiera. A propósito **no dice** qué capas, dónde va
  cada cosa, dónde se guarda la llave que firma los tokens ni cómo comprobar que funciona.
- **Qué hace Claude Code**: lo que mejor le parece **esa vez**. Córrelo dos veces en dos carpetas vacías y compara.
- **Cómo lo reviso**: ¿la estructura es la misma las dos veces? ¿Tiene pruebas? ¿Dónde quedó la clave de firma?
  ¿Cómo sé que funciona? Si no puedes responder, le falta un procedimiento: una skill.

## P2 · ¿Claude ve la skill?

```
¿Qué skills tienes disponibles y cuándo usarías arquetipo?
```

- **Qué le pido**: que me diga qué skills encontró y cuándo usaría la nuestra.
- **Por qué está escrito así**: compruebo que la skill está bien cargada **antes** de usarla.
- **Qué hace Claude Code**: lista las skills y responde con la `description` del `SKILL.md`.
- **Cómo lo reviso**: si repite lo que escribí en la descripción, está bien. Si no aparece, revisa la ruta
  (`.claude/skills/arquetipo/SKILL.md`) y el encabezado `---` del archivo.

## P3 · Crear el proyecto de seguridad

```
Crea el proyecto de seguridad de Nova Retail.
```

- **Qué le pido**: el proyecto que emite los tokens (usuarios, roles, login).
- **Por qué está escrito así**: en lenguaje normal y sin explicar la estructura. Las palabras «crea», «proyecto» y
  «seguridad» calzan con la descripción de la skill, y la skill pone el resto. Lo mismo, de forma explícita:
  `/arquetipo seguridad seguridad`.
- **Qué hace Claude Code**: lee el `SKILL.md`, revisa `proyectos.json`, corre `scripts/generar.ps1` y después
  `scripts/verificar.ps1`.
- **Cómo lo reviso**: la tabla final, fila por fila. Compila sin advertencias · pruebas en verde · base al día (la
  segunda pasada aplica 0 scripts) · arranca · login 200, clave mala 401 y sexto intento 429.

## P4 · Crear el servicio de pedidos

```
Ahora crea el servicio de pedidos. Tiene que aceptar los tokens de seguridad.
```

- **Qué le pido**: una API de negocio que confíe en los tokens del proyecto anterior.
- **Por qué está escrito así**: la segunda frase dice **qué espero**; así sé qué fila de la verificación mirar.
- **Qué hace Claude Code**: genera `nova-pedidos` con los puertos que siguen, enciende seguridad si está apagado,
  pide un token real y lo prueba contra Pedidos.
- **Cómo lo reviso**: la fila 6. Sin token, 401 · con el token de seguridad, 200 · con el token alterado, 401.

## P5 · Levantar los dos para probarlos en el navegador

```
Levanta nova-seguridad y nova-pedidos en DEV para probarlos en el navegador.
```

- **Qué le pido**: que los deje corriendo (la verificación los apaga al terminar).
- **Por qué está escrito así**: digo el **ambiente** (DEV) para que use los puertos y la base correctos.
- **Qué hace Claude Code**: los arranca en segundo plano y me da las direcciones de Scalar
  (`http://localhost:5101/scalar` y `http://localhost:5001/scalar`).
- **Cómo lo reviso**: en Scalar, login con `cliente.demo` / `NovaDemo#1` → copio `tokenAcceso` → `quien-soy` en
  Pedidos con ese token → 200 con mi usuario. Sin token → 401. Al terminar: «Apaga los dos servicios».

## P6 · Ver qué hay dentro del token

```
Decodifica este token y explícame cada parte. No lo pegues en ninguna página web.
<pega aquí el token>
```

- **Qué le pido**: entender qué viaja dentro del JWT.
- **Por qué está escrito así**: un token es una **credencial**. Mientras no vence, sirve para entrar. Por eso le
  pido que lo decodifique aquí y no en un sitio de terceros.
- **Qué hace Claude Code**: separa las tres partes (encabezado · datos · firma) y explica `iss`, `aud`, `sub`,
  `name`, `role`, `scope` y `exp`.
- **Cómo lo reviso**: `iss` es `nova-seguridad`, `aud` es `nova-api` y `alg` es `RS256`, y la firma no se puede
  leer: solo se comprueba con la llave pública.

## P7 · Romper la arquitectura a propósito

```
En nova-pedidos, crea en la capa Api un controlador ControladorPing que responda "pong", y corre las pruebas.
```

- **Qué le pido**: un error que haría alguien apurado: un controlador en la capa equivocada.
- **Por qué está escrito así**: le digo exactamente **dónde** ponerlo, para ver si las pruebas lo atrapan.
- **Qué hace Claude Code**: crea el archivo, compila (C# no lo impide) y corre las pruebas.
- **Cómo lo reviso**: la prueba `Los_controladores_viven_en_adaptadores` en rojo, con el nombre de la clase que
  rompe la regla.

## P8 · Entender antes de arreglar

```
¿Por qué falló esa prueba? Explícamelo y después déjalo como estaba.
```

- **Qué le pido**: primero la explicación y después el arreglo.
- **Por qué está escrito así**: así aprendo **qué protege** la regla y no solo cómo apagar el rojo. Y le pido
  volver al estado anterior, no «hacer que pase».
- **Qué hace Claude Code**: explica la regla de capas, borra el controlador y vuelve a correr las pruebas.
- **Cómo lo reviso**: todo en verde y el archivo ya no existe.

## P9 · Subir a GitHub

```
Sube nova-seguridad y nova-pedidos a GitHub.
```

- **Qué le pido**: crear los repositorios con sus ramas.
- **Por qué está escrito así**: es corto porque la skill sabe el resto. Y como subir es **publicar**, la skill me
  pide confirmación antes.
- **Qué hace Claude Code**: revisa que tu correo de git sea el `noreply` de GitHub y que no haya secretos, crea el
  repo con `gh`, las ramas `main`, `develop` y `qa`, y protege `main` y `develop`.
- **Cómo lo reviso**: en GitHub, las tres ramas y la protección; en la verificación, la fila 7 en verde.
  (En GitHub Free, la protección de ramas solo funciona en repos públicos.)

## P10 · Tu reto

```
Crea el servicio de inventario.
```

- **Qué le pido**: un servicio nuevo, con el mismo prompt que usamos para pedidos.
- **Por qué está escrito así**: si la skill está bien escrita, no hace falta explicar nada más.
- **Cómo lo reviso**: la tabla en verde en tu PC. Cuéntame en los comentarios cómo te fue.

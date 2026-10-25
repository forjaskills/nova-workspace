---
name: nuevo-modulo
description: Agrega un módulo de negocio (Pedidos, Productos, Clientes…) a un servicio de Nova Retail creado con `arquetipo`, respetando la arquitectura — cada archivo en su capa (dominio con sus reglas, casos de uso, controlador, EF Core, script SQL, pruebas), los permisos del servicio en nova-seguridad, en una rama feature/ — y lo verifica de verdad (compila, pruebas con las de arquitectura, base, permisos en el token y la API a través del gateway). Usar cuando se pida agregar, crear o construir un módulo, una funcionalidad de negocio, un CRUD, una entidad o un recurso de la API en un servicio existente («agrega el módulo de pedidos», «necesito productos en nova-catalogo», «crea la API de clientes»). Para crear un proyecto o servicio nuevo, usa `arquetipo`.
---

# nuevo-modulo

Un módulo no es un proyecto: cada uno tiene **reglas de negocio distintas**. Por eso esta skill reparte el trabajo:
el **script** pone cada archivo en su capa (siempre igual), **tú** escribes las reglas a partir de una ficha que el
dev aprueba, y **`verificar.ps1`** comprueba que todo funciona y que nadie rompió las capas.

## Parámetros

| Parámetro | Qué es | Ejemplo |
|---|---|---|
| servicio | un proyecto tipo `servicio` de `proyectos.json` | `pedidos` (→ `proyectos/nova-pedidos`) |
| módulo | PascalCase, plural: la ruta y la carpeta | `Pedidos` (→ `/api/v1/pedidos`) |
| entidad | PascalCase, singular: la raíz del agregado | `Pedido` |

Si falta alguno, pregúntalo. Si el servicio no existe, ofrece crearlo con `arquetipo`.

## Pasos

1. **La ficha primero.** Antes de una línea de código, arma con el dev la ficha del módulo (qué es, campos, estados,
   reglas con su código de error, quién puede qué, la API). Plantilla y ejemplo: `referencias/ficha-modulo.md`.
   **Pregunta lo que no sepas; no inventes reglas.** Muéstrale la ficha y espera su OK.
2. **Esqueleto**:
   `powershell -ExecutionPolicy Bypass -File .claude/skills/nuevo-modulo/scripts/esqueleto.ps1 -Servicio <servicio> -Modulo <Modulo> -Entidad <Entidad>`
   Crea la rama `feature/modulo-<modulo>` (desde `develop`), un archivo por capa con marcas `TODO(nuevo-modulo)`,
   el registro del repositorio, el script SQL como `.sql.borrador`, la ficha en `docs/modulos/` y, si es el primer
   módulo del servicio, el script de permisos en nova-seguridad. Muestra al dev el resumen por capas tal como sale.
3. **Escribe el módulo, capa por capa, de adentro hacia afuera** (dónde va cada cosa: `referencias/ubicacion.md`):
   1. **Dominio**: la entidad con sus reglas (fábrica que valida, métodos para cada acción, nada de setters
      públicos), objetos valor (`record`), enums de estado, el puerto `IRepositorio<Modulo>`.
   2. **Aplicación**: DTOs (nunca se devuelve la entidad), un puerto de entrada por caso de uso, los casos de uso
      (orquestan; una `ExcepcionDominio` se vuelve `Error`) y su registro en `RegistroAplicacion.cs`.
   3. **Adaptadores**: el controlador (solo traduce HTTP; `Politicas.Lectura` / `Politicas.Escritura`), la
      configuración de EF Core y el repositorio.
   4. **Base**: completa el script y **recién entonces** quítale `.borrador` (un `.sql` aplicado no se vuelve a
      aplicar nunca). Si ayuda a probar, un segundo script con datos demo (DEV y QA).
   5. **Pruebas**: unitarias (una por regla de la ficha, sin base) e integración (HTTP + SQL Server `_PRUEBAS`:
      401, 403, 201, lo ajeno → 404, cada error → 400 con su código). Y `docs/modulos/<modulo>.ejemplo.json`: el
      cuerpo para crear uno, que usa la verificación.
   Al terminar no queda ningún `TODO(nuevo-modulo)` (búscalo).
4. **Verificar** (obligatorio, aunque haya apuro):
   `powershell -ExecutionPolicy Bypass -File .claude/skills/nuevo-modulo/scripts/verificar.ps1 -Servicio <servicio> -Modulo <modulo>`
   Enciende seguridad, el servicio y el gateway si hace falta, y cierra solo lo que encendió. Muestra la tabla tal
   como sale. Una fila en rojo: lee el detalle, explica la causa en una frase y corrige.
   **Si falla una prueba de arquitectura, se mueve el código a su capa: la regla nunca se relaja.**
5. **Subir** (con el OK del dev, porque publica): commit en `feature/modulo-<modulo>` de cada repo tocado (el
   servicio y, si cambió, nova-seguridad), push y un PR a `develop` con la ficha como descripción
   (`gh pr create --base develop`). `release/` y `hotfix/` no se tocan aquí: nacen al preparar una versión o
   corregir producción.
6. **Cerrar**: en 3 líneas, qué se agregó (rutas de la API, tablas, permisos), la tabla de verificación y los PR.

## Qué NO hacer

- Reglas de negocio en el controlador, en el caso de uso o solo en la base: van en la entidad (la base además las
  protege con `CHECK`).
- EF Core, `HttpContext` o SQL fuera de `Adaptadores.Gateways` / `Adaptadores.Controladores`.
- Cambiar tablas con EF (migraciones de EF): las tablas las crean los scripts de `bd/` y el Migrador.
- Editar un `.sql` que ya se aplicó en algún ambiente: se escribe uno nuevo.
- Aceptar del cliente lo que el dominio calcula (totales, estados, dueños): el dueño sale del token (`sub`).
- Relajar o borrar una prueba para que pase.

## Lo que deja (ejemplo: Pedidos en nova-pedidos)

```
src/01. Business Rules Model/…Dominio/Pedidos/        Pedido · LineaPedido · NumeroPedido · EstadoPedido · IRepositorioPedidos
src/02. Application Rules Model/…Aplicacion/Pedidos/  Dtos · Puertos · CasosDeUso (Listar, Obtener, Crear, Avanzar)
src/03. Interface Adapter/…Adaptadores/               Controladores/ControladorPedidos · Gateways/Pedidos/ (EF Core)
bd/0001-modulo-pedidos.sql · bd/0002-pedidos-demo.sql
tests/…Unitarias/Pedidos/ · tests/…Integracion/PedidosPruebas.cs
docs/modulos/pedidos.md (la ficha) · pedidos.ejemplo.json
nova-seguridad: bd/0003-scopes-pedidos.sql (pedidos.leer, pedidos.escribir)
```

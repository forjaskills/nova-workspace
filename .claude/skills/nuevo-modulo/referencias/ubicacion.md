# ¿Dónde va esto?

Las capas son las de `arquetipo/referencias/capas.md`; las vigilan las pruebas de arquitectura (`CapasPruebas.cs`).
Para un módulo `<Modulo>` con raíz `<Entidad>`:

| Si escribes… | Va en | Ejemplo (Pedidos) |
|---|---|---|
| una regla del negocio («al menos una línea», «solo avanza en orden») | la entidad, `Dominio/<Modulo>/` | `Pedido.Registrar`, `Pedido.Avanzar` |
| un valor con forma propia (número, monto, correo) | objeto valor `record` en `Dominio/<Modulo>/` | `NumeroPedido` |
| un estado | `enum` en `Dominio/<Modulo>/` | `EstadoPedido` |
| lo que el dominio necesita guardar o leer | interfaz `IRepositorio<Modulo>` en `Dominio/<Modulo>/` | `IRepositorioPedidos` |
| lo que entra y sale de la API | `record` en `Aplicacion/<Modulo>/Dtos.cs` | `CrearPedidoSolicitud`, `PedidoDto` |
| lo que se le puede pedir al módulo | interfaz en `Aplicacion/<Modulo>/Puertos.cs` | `ICrearPedido` |
| leer → llamar al dominio → guardar | caso de uso en `Aplicacion/<Modulo>/CasosDeUso.cs` | `CrearPedido` |
| la hora actual | `TimeProvider` inyectado (nunca `DateTime.Now`) | `CrearPedido(…, TimeProvider reloj)` |
| una ruta HTTP | acción en `Adaptadores/Controladores/Controlador<Modulo>.cs` | `ControladorPedidos.Crear` |
| quién es el usuario | el controlador lo saca del token (`sub`, `role`) y lo pasa como `Solicitante` | `Solicitante()` |
| cómo se mapea a tablas | `Adaptadores/Gateways/<Modulo>/Configuracion<Entidad>.cs` | `OwnsMany` para las líneas |
| una consulta SQL / EF Core | `Adaptadores/Gateways/<Modulo>/Repositorio<Modulo>.cs` | `RepositorioPedidos.Listar` |
| una tabla, índice o secuencia | script numerado en `bd/` (nunca migraciones de EF) | `0001-modulo-pedidos.sql` |
| un permiso nuevo | script en `nova-seguridad/bd/` | `0003-scopes-pedidos.sql` |

## En la web (`nova-web`)

| Si escribes… | Va en | Ejemplo (Pedidos) |
|---|---|---|
| hablar con el gateway (dirección, token, errores) | `lib/api/cliente.ts`, **ya existe**: no se toca ni se copia | `llamarApi` |
| las llamadas del módulo y sus tipos (los DTOs del servicio, campo por campo, de su `Dtos.cs` **real**) | `features/<modulo>/api.ts` | `listarPedidos`, `type Pedido` |
| cómo se muestra (moneda, fecha, un total «estimado» mientras se escribe) | `features/<modulo>/formato.ts` | `formatoMoneda`, `totalEstimado` |
| leer el formulario y el mensaje de cada error | `features/<modulo>/formulario.ts` (puro: lo prueba Vitest) | `leerLineas`, `mensajeDeError` |
| guardar (llama a la API con el token) | Server Action en `features/<modulo>/acciones.ts` (`'use server'`) | `crearPedidoAccion` |
| un componente con estado (agregar y quitar filas) | `features/<modulo>/Formulario<Entidad>.tsx` (`'use client'`) | `FormularioPedido` |
| una página | `app/(privado)/<modulo>/…` (solo arma: lee el token, llama a `api.ts`, pinta componentes) | `[id]/page.tsx` |
| estilos del módulo | `features/<modulo>/<modulo>.module.css` (los de `globals.css` son de toda la web) | `.tabla`, `.franja` |

Nunca en la web: llamar a la API desde el navegador (`fetch` en un componente `'use client'`), guardar el token
fuera de la cookie httpOnly, ni mandar a la API lo que calcula el dominio (totales, estado, dueño).

## Errores esperados → HTTP (lo hace el presentador)

| `TipoError` | HTTP | Cuándo |
|---|---|---|
| `Validacion` | 400 | una regla del dominio rota (`ExcepcionDominio`) o un filtro inválido |
| `NoEncontrado` | 404 | no existe **o es de otro** (no se revela que existe) |
| `Conflicto` | 409 | la acción no se puede en el estado actual (avanzar un pedido entregado) |
| (sin scope o sin rol) | 403 | lo decide la política del controlador, no el caso de uso |

## Trampas que ya pasaron

- `SqlQueryRaw(...).SingleAsync()` con `NEXT VALUE FOR`: EF lo envuelve en una subconsulta y SQL Server lo rechaza.
  Usa `ToListAsync()` y `.Single()` (está en `RepositorioPedidos.SiguienteSecuencia`).
- Un token emitido antes del script de permisos no trae los scopes nuevos: hay que volver a iniciar sesión.
- Los tipos de la web se copian del `Dtos.cs` del servicio que se tiene delante, no de memoria ni de otro proyecto:
  en un `nova-pedidos` el listado devolvía el `PedidoDto` completo (con `lineas` como lista) y la web, escrita para un
  resumen con `lineas` como número, se cayó al pintar la tabla («Objects are not valid as a React child»).
- El orden de los scopes en el token no está garantizado: una prueba busca cada permiso por separado.
- Playwright: el gateway deja 5 logins por minuto. Las pruebas del módulo inician sesión **una vez** (`beforeAll`) y
  comparten la página; `verificar.ps1` espera lo que falte del minuto antes de abrir el navegador.

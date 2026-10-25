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

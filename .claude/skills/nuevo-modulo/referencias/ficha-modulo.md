# La ficha del módulo

Se arma con el dev **antes** del código y queda en `docs/modulos/<modulo>.md` del servicio. Es el contrato: el código
la cumple, las pruebas la comprueban y el PR la lleva como descripción. Lo que no esté claro se pregunta.

| Fila | Qué se escribe | Cómo se usa |
|---|---|---|
| Qué es | una frase | encabezado del PR |
| Agregado | la raíz y sus hijos (los hijos no tienen repositorio propio) | clases del dominio |
| Campos | nombre · tipo · obligatorio · límites | entidad, `CHECK` de la base, validaciones |
| Estados | si tiene, y por dónde pasa | enum + método que cambia el estado |
| Reglas | una por línea, cada una con su **código de error** (`entidad.algo`) | `ExcepcionDominio(codigo, …)` + una prueba unitaria |
| Quién | qué hace cada rol (`cliente`, `operador`, `admin`) | `Solicitante` + políticas del controlador |
| API | método, ruta y qué devuelve | controlador + pruebas de integración |
| Base | scripts de `bd/` | Migrador |
| Permisos | `<servicio>.leer` · `<servicio>.escribir` | script en nova-seguridad |

## Ejemplo: Pedidos (nova-pedidos)

| | |
|---|---|
| Qué es | Lo que un cliente compra en Nova Retail: uno o más productos, con su total y su estado de entrega. |
| Agregado | `Pedido` (raíz) con sus `LineaPedido` · número legible `PED-000123` (objeto valor `NumeroPedido`) |
| Campos | `Numero` (secuencia de la base, único) · `ClienteId` (el `sub` del token) · `Fecha` · `Estado` · líneas: `Producto` (1–100) · `Cantidad` (> 0) · `PrecioUnitario` (≥ 0, 2 decimales) |
| Estados | `Registrado → Pagado → Enviado → Entregado` · `Cancelado` (cancelar llega con su propio ticket) |
| Reglas | al menos una línea (`pedido.sin-lineas`) · producto obligatorio, hasta 100 (`pedido.producto-invalido`) · cantidad > 0 (`pedido.cantidad-invalida`) · precio ≥ 0 (`pedido.precio-invalido`) · el total lo calcula el pedido, nunca viene de afuera · el estado solo avanza en orden; desde Entregado o Cancelado ya no (`pedido.no-avanza`) |
| Quién | `cliente`: ve y crea **sus** pedidos (uno ajeno responde 404, como si no existiera) · `operador` y `admin`: ven todos y avanzan el estado |
| API | `GET /api/v1/pedidos?estado=&pagina=&tamano=` (máx. 50) · `GET /api/v1/pedidos/{numero}` · `POST /api/v1/pedidos` → 201 · `POST /api/v1/pedidos/{numero}/avanzar` (operador, admin) |
| Base | `0001-modulo-pedidos.sql` (secuencia, `Pedidos`, `LineasPedido` con `CHECK`) · `0002-pedidos-demo.sql` (3 de `cliente.demo`) |
| Permisos | `pedidos.leer` y `pedidos.escribir` para cliente, operador y admin (`nova-seguridad/bd/0003-scopes-pedidos.sql`) |

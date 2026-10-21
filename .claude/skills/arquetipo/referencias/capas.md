# Capas del arquetipo: qué va en cada una

Hexagonal por fuera (capas y dependencias que apuntan hacia adentro), DDD por dentro (el dominio
se ordena en agregados, entidades y value objects).

```
04. Framework and Driver  ─►  03. Interface Adapter  ─►  02. Application Rules Model  ─►  01. Business Rules Model
   (arranque)                   (HTTP, EF Core)             (casos de uso)                    (reglas del negocio)
```

| Capa | Proyecto | Va | No va |
|---|---|---|---|
| 01. Business Rules Model | `Nova.X.Dominio` | entidades y raíces de agregado con sus reglas, value objects (`record`), `ExcepcionDominio`, **puertos de infraestructura** (`IRepositorio...`) | EF Core, ASP.NET, DTOs, nada de otras capas |
| 02. Application Rules Model | `Nova.X.Aplicacion` | casos de uso, DTOs, **puertos de entrada** (`IIniciarSesion`) y **de salida** (`IEmisorToken`), `Resultado<T>` | `HttpContext`, `DbContext`, SQL |
| 03. Interface Adapter | `Nova.X.Adaptadores` | `Controladores/` (HTTP → caso de uso), `Presentadores/` (resultado → HTTP/ProblemDetails), `Gateways/` (EF Core, repositorios, firma de tokens, hash de claves) | `Program.cs`, configuración de la app |
| 04. Framework and Driver | `Nova.X.Api` | `Program.cs` y `Configuracion/`: JWT, políticas, rate limiting, cabeceras, OpenAPI, `/salud` | controladores, reglas de negocio |
| 05. Tests | `tests/` | unitarias (dominio y casos de uso con dobles), integración (`WebApplicationFactory` + base `_PRUEBAS`), arquitectura | — |

## Pruebas de arquitectura (`CapasPruebas.cs`)

1. El dominio no depende de nada del proyecto ni de EF Core / ASP.NET Core.
2. La aplicación solo conoce el dominio (ni EF Core, ni ASP.NET, ni SqlClient).
3. Los adaptadores no conocen la Api.
4. Los controladores viven solo en `Adaptadores.Controladores`.
5. EF Core solo se usa en `Adaptadores.Gateways`.

Si una falla, el mensaje dice qué tipo rompe la regla. **No se relaja la regla para que pase**: se
mueve el código a su capa.

## Convenciones

- Errores esperados → `Resultado<T>` con `Error(codigo, mensaje, tipo)`; el presentador los vuelve
  `ProblemDetails` con `codigo`. Las excepciones son para lo inesperado.
- Puertos por ambiente: PROD = bloque×100, DEV +1, QA +2 (pedidos 5000/5001/5002, seguridad 5100/5101/5102).
- Bases: `Nova<Nombre>_DEV|QA|PROD|PRUEBAS`, autenticación de Windows.
- Scopes: `<servicio>.leer`, `<servicio>.escribir`; políticas `lectura` y `escritura`.

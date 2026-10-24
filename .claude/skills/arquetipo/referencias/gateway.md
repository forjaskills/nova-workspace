# Gateway (`nova-gateway`) por dentro

La única puerta de entrada. **No tiene dominio ni base**: si una regla de negocio aparece aquí, está en el lugar
equivocado (va al servicio).

```
src/Nova.Gateway.Api/
  Program.cs                    orden del pipeline: errores → cabeceras → CORS → autenticación → autorización → límites → YARP
  Configuracion/
    Autenticacion.cs            JWT de nova-seguridad (JWKS) + política «autenticado»
    Origenes.cs                 CORS: solo los orígenes de Cors:Origenes (nunca «*»)
    Endurecimiento.cs           límites (general 100/min, login 5/min por IP) y cabeceras de seguridad
    Salud.cs                    /salud pregunta /salud a cada destino → Healthy o Degraded
    Politicas.cs                nombres que usan las rutas
  appsettings.json              ReverseProxy:Routes (qué se publica) — igual en todos los ambientes
  appsettings.{Ambiente}.json   ReverseProxy:Clusters (a dónde va), Tokens:Autoridad, Cors:Origenes
tests/Nova.Gateway.Pruebas/     el gateway en memoria contra dos servicios falsos (Kestrel en un puerto libre)
```

## Rutas

| Ruta pública | Va a | Política |
|---|---|---|
| `POST /seguridad/api/v1/sesion` | nova-seguridad `/api/v1/sesion` | anónima + límite estricto |
| `GET /seguridad/.well-known/jwks.json` | nova-seguridad | anónima |
| `/<servicio>/api/{**resto}` | nova-<servicio> `/api/…` | `autenticado` |

Lo que no está en una ruta **no se publica** (Scalar, `/salud` de cada servicio): 404.

## Decisiones

- **El servicio vuelve a validar el token** (defensa en profundidad). El gateway reenvía el `Authorization` tal cual.
- **CORS vive solo aquí**: los servicios no lo necesitan porque ningún navegador les habla directo.
- **Agregar un servicio** después de generar el gateway: una ruta en `appsettings.json` y su destino en cada
  `appsettings.{Ambiente}.json` (con el mismo nombre de cluster que el servicio).

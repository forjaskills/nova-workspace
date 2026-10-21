# bd/ — esquema y datos de la base

Cada cambio de la base es un script SQL numerado (`0001-...sql`, `0002-...sql`). El **Migrador**
(`tools/Migrador`) los aplica en orden y anota cada uno en la tabla `dbo.VersionesBd`: un script
nunca se aplica dos veces.

```
dotnet run --project tools/Migrador -- --ambiente DEV
```

- En **DEV** lo corre el dev. En **QA y PROD** lo ejecuta otra persona (DBA o pipeline): por eso
  cada script es idempotente, atómico y dice qué hace en cada paso (`PRINT`).
- Nada de `USE <base>`: el ambiente lo elige quien ejecuta.
- EF Core **no** crea ni cambia tablas: solo lee y escribe datos.

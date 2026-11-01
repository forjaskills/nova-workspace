# Nova Retail · espacio de trabajo

Nova Retail es una empresa ficticia. Cuatro proyectos en `proyectos/`, cada uno con su repo:

| Proyecto | Qué es | Puerto DEV |
|---|---|---|
| nova-seguridad | Login; emite el JWT (RS256). .NET 10 | 5101 |
| nova-pedidos | API de negocio. .NET 10, 5 capas: hexagonal por fuera, DDD por dentro | 5001 |
| nova-gateway | YARP: la única puerta de entrada de la web | 5201 |
| nova-web | Next.js (App Router) | 3001 |

## Comandos
- Pruebas de un servicio .NET, **desde su carpeta**: `dotnet test Nova.Pedidos.slnx` (o `Nova.Seguridad.slnx`).
  Unitarias, arquitectura e integración contra la base `*_PRUEBAS` en `.\SQLEXPRESS`.
- Web, desde `proyectos/nova-web`: `npm run lint`, `npm test` y `npm run e2e` (Playwright).
- Scripts de base: `bd/NNNN-*.sql`; los aplica `dotnet run --project tools/Migrador -- --ambiente DEV`.

## Reglas del equipo
- En español: nombres del dominio, mensajes, commits y documentación.
- Ramas `feature/...` desde `develop`. `main`, `develop` y `qa` solo por pull request: nunca commit ni push directo.
- Cada archivo en su capa: lo vigilan las pruebas de arquitectura.
- Las bases `*_DEV` no se tocan sin pedirlo: para probar está `*_PRUEBAS`.
- Lo que es un procedimiento (crear un proyecto, un módulo, mover un ticket) vive en `.claude/skills/`.

@proyectos/nova-web/AGENTS.md

# Nova Retail · espacio de trabajo

Espacio de trabajo de la serie **«Tu flujo de dev con skills»** del canal Forja Skills: un equipo de desarrollo
ficticio, Nova Retail, que construye su sistema con Claude Code y skills, un video a la vez.

Aquí viven las **skills del proyecto** (`.claude/skills/`). Los proyectos que crean quedan en `proyectos/` y cada uno
se sube a su propio repositorio.

| Skill | Qué hace | Video |
|---|---|---|
| `arquetipo` | Crea un proyecto de Nova Retail y lo **verifica** antes de decir «listo»: seguridad (JWT/RS256) o un servicio de negocio en .NET con 5 capas (1a); el gateway con YARP y la web en Next.js que inicia sesión y llega al servicio a través del gateway (1b) | 1a · 1b |
| `nuevo-modulo` | Agrega un **módulo de negocio** a un servicio **respetando la arquitectura**: primero la ficha del módulo (las reglas, que aprueba el dev), después un archivo en cada capa, los permisos en seguridad y una rama `feature/`; lo verifica con las pruebas de arquitectura como guardián y la API por el gateway (2a: Pedidos). Después crece hacia la **web**: lee el contrato del servicio (`Dtos.cs`), propone qué va en cada pantalla, agrega el listado, el detalle y el formulario en `nova-web` con el token siempre en el servidor, y los prueba en un navegador real con Playwright (2b) | 2a · 2b |

## Para empezar

Requisitos: Windows, .NET 10 SDK, SQL Server Express (`.\SQLEXPRESS`, autenticación de Windows), git, GitHub CLI,
Claude Code y, para la web (1b), Node 22 LTS.

```
git clone https://github.com/forjaskills/nova-workspace
cd nova-workspace
claude
```

Y en Claude Code: `Crea el proyecto de seguridad de Nova Retail.`

Los prompts de cada video, explicados uno por uno, están en `prompts/`. Cada video deja un tag (`video-01a`,
`video-01b`, `video-02a`, `video-02b`, …) para retomar desde ese punto.

Y para el módulo de pedidos (2a), con los cuatro proyectos ya creados: `Agrega el módulo Pedidos a nova-pedidos. …`
(el prompt completo, en `prompts/video-02a.md`). Y sus pantallas (2b): `Agrega las pantallas del módulo Pedidos a
nova-web: el listado con filtro por estado, el detalle y el formulario de nuevo pedido.` (en `prompts/video-02b.md`).

## Si algo falla

- **«Filename too long» al clonar**: las plantillas tienen rutas largas. Clona en una carpeta corta o activa
  `git config --global core.longpaths true`.
- **El primer login tarda más de 10 s y la prueba de la web sale en rojo**: en SQL Server Express las bases nuevas
  tienen `AUTO_CLOSE` activado y la primera consulta paga la reapertura (lo vemos en el video 1b). La verificación lo
  avisa como «base fría»; quien administra la base puede apagarlo con `ALTER DATABASE … SET AUTO_CLOSE OFF`.

*Nova Retail es una empresa ficticia, creada para enseñar.*

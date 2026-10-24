# Nova Retail · espacio de trabajo

Espacio de trabajo de la serie **«Tu flujo de dev con skills»** del canal Forja Skills: un equipo de desarrollo
ficticio, Nova Retail, que construye su sistema con Claude Code y skills, un video a la vez.

Aquí viven las **skills del proyecto** (`.claude/skills/`). Los proyectos que crean quedan en `proyectos/` y cada uno
se sube a su propio repositorio.

| Skill | Qué hace | Video |
|---|---|---|
| `arquetipo` | Crea un proyecto de Nova Retail y lo **verifica** antes de decir «listo»: seguridad (JWT/RS256) o un servicio de negocio en .NET con 5 capas (1a); el gateway con YARP y la web en Next.js que inicia sesión y llega al servicio a través del gateway (1b) | 1a · 1b |

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
`video-01b`, …) para retomar desde ese punto.

## Si algo falla

- **«Filename too long» al clonar**: las plantillas tienen rutas largas. Clona en una carpeta corta o activa
  `git config --global core.longpaths true`.
- **El primer login tarda más de 10 s y la prueba de la web sale en rojo**: en SQL Server Express las bases nuevas
  tienen `AUTO_CLOSE` activado y la primera consulta paga la reapertura (lo vemos en el video 1b). La verificación lo
  avisa como «base fría»; quien administra la base puede apagarlo con `ALTER DATABASE … SET AUTO_CLOSE OFF`.

*Nova Retail es una empresa ficticia, creada para enseñar.*

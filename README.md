# Nova Retail · espacio de trabajo

Espacio de trabajo de la serie **«Tu flujo de dev con skills»** del canal Forja Skills: un equipo de desarrollo
ficticio, Nova Retail, que construye su sistema con Claude Code y skills, un video a la vez.

Aquí viven las **skills del proyecto** (`.claude/skills/`). Los proyectos que crean quedan en `proyectos/` y cada uno
se sube a su propio repositorio.

| Skill | Qué hace | Video |
|---|---|---|
| `arquetipo` | Crea un proyecto .NET con 5 capas (seguridad con JWT/RS256 o un servicio de negocio) y lo **verifica** antes de decir «listo» | 1a |

## Para empezar

Requisitos: Windows, .NET 10 SDK, SQL Server Express (`.\SQLEXPRESS`, autenticación de Windows), git, GitHub CLI y
Claude Code.

```
git clone https://github.com/forjaskills/nova-workspace
cd nova-workspace
claude
```

Y en Claude Code: `Crea el proyecto de seguridad de Nova Retail.`

Los prompts de cada video, explicados uno por uno, están en `prompts/`. Cada video deja un tag (`video-01a`, …) para
retomar desde ese punto.

*Nova Retail es una empresa ficticia, creada para enseñar.*

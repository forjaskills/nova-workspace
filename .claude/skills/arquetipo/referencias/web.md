# Web (`nova-web`) por dentro

Next.js (App Router) + TypeScript. Ordenada **por funcionalidad**: todo lo de una funcionalidad vive junto en
`features/<funcionalidad>/`; `app/` solo arma las rutas con esas piezas.

```
app/
  layout.tsx                 html, título, estilos
  page.tsx                   / → al primer servicio
  login/page.tsx             abierta
  (privado)/layout.tsx       exige sesión: sin cookie válida, al login; barra con usuario y «Cerrar sesión»
  (privado)/<servicio>/      la página que llega al servicio por el gateway
features/
  sesion/                    acciones.ts (iniciar y cerrar, «use server») · FormularioLogin.tsx · sesion.ts (cookie) · token.ts (leer para mostrar)
  <servicio>/                las llamadas a ese servicio (hoy: quien-soy; con nuevo-modulo, sus pantallas)
lib/api/
  cliente.ts                 el cliente HTTP ÚNICO: NOVA_GATEWAY_URL + token + errores → ErrorApi
  problemas.ts               lee ProblemDetails (title/detail) del gateway y los servicios
tests/unit/                  Vitest (cliente, token)
tests/e2e/                   Playwright contra la web encendida y todo lo de detrás
```

## Reglas

- **Nadie llama a `fetch` fuera de `lib/api/cliente.ts`.** Una funcionalidad nueva usa `llamarApi`.
- **El token vive en la cookie `nova_sesion`** (`httpOnly`, `SameSite=Strict`, `Secure` en producción), que pone
  el servidor de Next. El JavaScript del navegador nunca lo ve; las llamadas a la API salen del servidor de Next.
- **Solo el gateway**: la web no conoce las direcciones de los servicios.
- `token.ts` lee el token para mostrar el nombre y los roles; **no lo valida** (eso es del gateway y del servicio).
- Ambientes: `.env.development` (`npm run dev`), `.env.qa` (`npm run start:qa`), `.env.production` (`npm start`).
  Solo llevan `NOVA_GATEWAY_URL`: nada secreto.
- Versiones exactas en `package.json` y `package-lock.json` en el repo: `npm ci` instala lo mismo siempre.

## Dependencias de desarrollo con avisos

`verificar.ps1` frena si `npm audit` encuentra algo alto o crítico en lo que va a **producción**. Lo de desarrollo
(lint, pruebas) se informa con nombre en la misma fila: no se despliega, pero se vigila y se actualiza apenas haya
parche (octubre 2026: `braces`, que trae `eslint-config-next`, todavía sin versión corregida).

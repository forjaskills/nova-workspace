export type DatosToken = { usuario: string; roles: string[]; expira: Date };

/**
 * Lee lo que dice el token para mostrarlo (nombre, roles, vencimiento).
 * No lo valida: eso lo hacen el gateway y cada servicio con la llave pública de nova-seguridad.
 */
export function leerDatos(token: string): DatosToken | null {
  const partes = token.split('.');
  if (partes.length !== 3) return null;
  try {
    const contenido = JSON.parse(Buffer.from(partes[1], 'base64url').toString('utf8')) as {
      name?: string;
      role?: string | string[];
      exp?: number;
    };
    if (!contenido.name || !contenido.exp) return null;
    const roles = Array.isArray(contenido.role) ? contenido.role : contenido.role ? [contenido.role] : [];
    return { usuario: contenido.name, roles, expira: new Date(contenido.exp * 1000) };
  } catch {
    return null;
  }
}

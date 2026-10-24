import { redirect } from 'next/navigation';
import { ErrorApi, llamarApi } from '@/lib/api/cliente';

export type Conexion = { usuario: string; id: string; roles: string[]; scopes: string[] };

/**
 * Pregunta a nova-__SERVICIO__ quién eres, a través del gateway. Prueba la cadena completa:
 * web → gateway (valida el token) → servicio (lo vuelve a validar).
 * Cuando llegue el primer módulo (nuevo-modulo), aquí van sus llamadas.
 */
export async function obtenerConexion(token: string): Promise<Conexion> {
  try {
    return await llamarApi<Conexion>('/__SERVICIO__/api/v1/quien-soy', { token });
  } catch (error) {
    // Token vencido o rechazado: de vuelta al login.
    if (error instanceof ErrorApi && error.estado === 401) redirect('/login?vencida=1');
    throw error;
  }
}

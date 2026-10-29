import { redirect } from 'next/navigation';
import { ErrorApi, llamarApi } from '@/lib/api/cliente';

// Los tipos son los DTOs que devuelve nova-__servicio__ (Aplicacion/__Modulo__/Dtos.cs), en camelCase.
// TODO(nuevo-modulo): copia los campos de los DTOs. Fechas como string (ISO), decimales como number.
export type __Entidad__Resumen = { id: string };
export type __Entidad__ = { id: string };
export type Pagina<T> = { elementos: T[]; total: number; pagina: number; tamano: number };
/** Lo que se manda para crear. TODO(nuevo-modulo): solo lo que escribe el usuario; nunca lo que calcula el dominio (totales, estados, dueño). */
export type Nuevo__Entidad__ = Record<string, unknown>;

const RUTA = '/__servicio__/api/v1/__modulo__';

/** Token vencido o rechazado (401): de vuelta al login. El resto de errores sube a quien llama. */
async function conSesion<T>(llamada: () => Promise<T>): Promise<T> {
  try {
    return await llamada();
  } catch (error) {
    if (error instanceof ErrorApi && error.estado === 401) redirect('/login?vencida=1');
    throw error;
  }
}

// TODO(nuevo-modulo): los filtros que tenga la API (p. ej. estado) van como parámetros de la consulta.
export function listar__Modulo__(token: string, { pagina = 1 }: { pagina?: number } = {}): Promise<Pagina<__Entidad__Resumen>> {
  const consulta = new URLSearchParams({ pagina: String(pagina), tamano: '20' });
  return conSesion(() => llamarApi<Pagina<__Entidad__Resumen>>(`${RUTA}?${consulta}`, { token }));
}

/** El registro, o null si no existe o no es tuyo (la API responde 404 en los dos casos, a propósito). */
export async function obtener__Entidad__(token: string, id: string): Promise<__Entidad__ | null> {
  try {
    return await conSesion(() => llamarApi<__Entidad__>(`${RUTA}/${encodeURIComponent(id)}`, { token }));
  } catch (error) {
    if (error instanceof ErrorApi && error.estado === 404) return null;
    throw error;
  }
}

export function crear__Entidad__(token: string, nuevo: Nuevo__Entidad__): Promise<__Entidad__> {
  return conSesion(() => llamarApi<__Entidad__>(RUTA, { metodo: 'POST', cuerpo: nuevo, token }));
}

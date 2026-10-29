import { ErrorApi } from '@/lib/api/cliente';
import type { Nuevo__Entidad__ } from './api';

/** Lo que devuelve la acción de crear al formulario (si todo sale bien, redirige y no devuelve nada). */
export type EstadoFormulario = { error: string | null };

/**
 * Lee el formulario y arma lo que se manda a la API. Las reglas las valida el dominio en el servidor;
 * aquí solo se convierten los tipos (texto → número) y se descartan las filas vacías.
 */
export function leerFormulario(datos: FormData): Nuevo__Entidad__ {
  // TODO(nuevo-modulo): un campo por cada dato de Nuevo__Entidad__ (datos.get / datos.getAll si se repite).
  return Object.fromEntries(datos.entries());
}

/** El mensaje para el usuario: el del dominio si es una regla (400), uno claro para los permisos. */
export function mensajeDeError(error: ErrorApi): string {
  if (error.estado === 400) return error.titulo; // el mensaje de la regla, tal como lo dice el dominio
  if (error.estado === 403)
    return 'Tu sesión no tiene permiso para crear (__servicio__.escribir). Si te lo acaban de dar, cierra sesión y vuelve a entrar.';
  if (error.estado === 0) return error.detalle ?? error.titulo;
  return 'No pudimos guardar. Intenta de nuevo en un momento.';
}

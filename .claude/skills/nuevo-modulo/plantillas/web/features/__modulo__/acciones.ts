'use server';

import { redirect } from 'next/navigation';
import { ErrorApi } from '@/lib/api/cliente';
import { leerToken } from '@/features/sesion/sesion';
import { crear__Entidad__ } from './api';
import { leerFormulario, mensajeDeError, type EstadoFormulario } from './formulario';

/** Crea en nova-__servicio__ (a través del gateway) y lleva al detalle. Corre en el servidor: el token no sale de aquí. */
export async function crear__Entidad__Accion(_previo: EstadoFormulario, datos: FormData): Promise<EstadoFormulario> {
  const token = await leerToken();
  if (!token) redirect('/login');

  let id: string;
  try {
    id = (await crear__Entidad__(token, leerFormulario(datos))).id; // TODO(nuevo-modulo): la clave legible (numero, codigo…)
  } catch (error) {
    if (error instanceof ErrorApi) return { error: mensajeDeError(error) };
    throw error;
  }
  redirect(`/__modulo__/${id}`);
}

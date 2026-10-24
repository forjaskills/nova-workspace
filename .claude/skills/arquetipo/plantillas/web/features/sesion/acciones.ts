'use server';

import { cookies } from 'next/headers';
import { redirect } from 'next/navigation';
import { ErrorApi, llamarApi } from '@/lib/api/cliente';
import { COOKIE_SESION } from './sesion';

export type EstadoLogin = { error: string | null };

type TokenEmitido = { tokenAcceso: string; tipo: string; expiraEnSegundos: number };

/** Inicia sesión contra nova-seguridad (a través del gateway) y guarda el token en una cookie httpOnly. */
export async function iniciarSesion(_previo: EstadoLogin, datos: FormData): Promise<EstadoLogin> {
  const usuario = String(datos.get('usuario') ?? '').trim();
  const clave = String(datos.get('clave') ?? '');
  if (!usuario || !clave) return { error: 'Escribe tu usuario y tu clave.' };

  try {
    const token = await llamarApi<TokenEmitido>('/seguridad/api/v1/sesion', {
      metodo: 'POST',
      cuerpo: { usuario, clave },
    });
    (await cookies()).set(COOKIE_SESION, token.tokenAcceso, {
      httpOnly: true,
      sameSite: 'strict',
      secure: process.env.NODE_ENV === 'production',
      path: '/',
      maxAge: token.expiraEnSegundos,
    });
  } catch (error) {
    if (error instanceof ErrorApi) return { error: mensajeDeLogin(error) };
    throw error;
  }
  redirect('/__SERVICIO__');
}

export async function cerrarSesion(): Promise<void> {
  (await cookies()).delete(COOKIE_SESION);
  redirect('/login');
}

function mensajeDeLogin(error: ErrorApi): string {
  if (error.estado === 401) return error.titulo; // «Usuario o clave incorrectos.», tal como lo dice nova-seguridad
  if (error.estado === 429) return 'Demasiados intentos. Espera un minuto y vuelve a probar.';
  if (error.estado === 0) return error.detalle ?? error.titulo;
  return 'No pudimos iniciar tu sesión. Intenta de nuevo en un momento.';
}

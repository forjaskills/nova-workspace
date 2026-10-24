import { cookies } from 'next/headers';

/** La cookie donde vive el token: httpOnly, así ningún script del navegador puede leerlo. */
export const COOKIE_SESION = 'nova_sesion';

export async function leerToken(): Promise<string | null> {
  return (await cookies()).get(COOKIE_SESION)?.value ?? null;
}

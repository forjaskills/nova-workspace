import { ErrorApi, leerProblema } from './problemas';

export { ErrorApi } from './problemas';

type Opciones = {
  metodo?: 'GET' | 'POST' | 'PUT' | 'PATCH' | 'DELETE';
  cuerpo?: unknown;
  token?: string | null;
};

/**
 * El único lugar de la web que habla con la API. Pone la dirección del gateway y el token, y convierte
 * cualquier error en ErrorApi. Corre solo en el servidor de Next: el token nunca llega al navegador.
 */
export async function llamarApi<T>(ruta: string, { metodo = 'GET', cuerpo, token }: Opciones = {}): Promise<T> {
  const gateway = process.env.NOVA_GATEWAY_URL;
  if (!gateway) {
    throw new Error('Falta NOVA_GATEWAY_URL (está en .env.development, .env.qa y .env.production).');
  }

  const cabeceras: Record<string, string> = { Accept: 'application/json' };
  if (cuerpo !== undefined) cabeceras['Content-Type'] = 'application/json';
  if (token) cabeceras.Authorization = `Bearer ${token}`;

  let respuesta: Response;
  try {
    respuesta = await fetch(new URL(ruta, gateway), {
      method: metodo,
      headers: cabeceras,
      body: cuerpo === undefined ? undefined : JSON.stringify(cuerpo),
      cache: 'no-store',
    });
  } catch {
    throw new ErrorApi(0, 'Sin conexión', 'No pudimos conectar con Nova. Intenta de nuevo en un momento.');
  }

  if (!respuesta.ok) throw await leerProblema(respuesta);
  return (await respuesta.json()) as T;
}

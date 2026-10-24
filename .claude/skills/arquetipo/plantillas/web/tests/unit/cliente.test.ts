import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest';
import { ErrorApi, llamarApi } from '@/lib/api/cliente';

describe('llamarApi', () => {
  beforeEach(() => {
    vi.stubEnv('NOVA_GATEWAY_URL', 'http://gateway.prueba');
  });

  afterEach(() => {
    vi.unstubAllEnvs();
    vi.unstubAllGlobals();
  });

  it('llama al gateway con el token', async () => {
    const fetchFalso = vi.fn().mockResolvedValue(Response.json({ usuario: 'cliente.demo' }));
    vi.stubGlobal('fetch', fetchFalso);

    const respuesta = await llamarApi<{ usuario: string }>('/__SERVICIO__/api/v1/quien-soy', { token: 'abc' });

    expect(respuesta.usuario).toBe('cliente.demo');
    const [url, opciones] = fetchFalso.mock.calls[0];
    expect(String(url)).toBe('http://gateway.prueba/__SERVICIO__/api/v1/quien-soy');
    expect(opciones.headers.Authorization).toBe('Bearer abc');
  });

  it('sin token no manda la cabecera Authorization', async () => {
    const fetchFalso = vi.fn().mockResolvedValue(Response.json({}));
    vi.stubGlobal('fetch', fetchFalso);

    await llamarApi('/seguridad/api/v1/sesion', { metodo: 'POST', cuerpo: { usuario: 'x', clave: 'y' } });

    const [, opciones] = fetchFalso.mock.calls[0];
    expect(opciones.headers.Authorization).toBeUndefined();
    expect(opciones.body).toBe('{"usuario":"x","clave":"y"}');
  });

  it('convierte un ProblemDetails en ErrorApi con su mensaje', async () => {
    const problema = new Response(JSON.stringify({ title: 'Usuario o clave incorrectos.', status: 401 }), {
      status: 401,
      headers: { 'content-type': 'application/problem+json' },
    });
    vi.stubGlobal('fetch', vi.fn().mockResolvedValue(problema));

    const llamada = llamarApi('/seguridad/api/v1/sesion', { metodo: 'POST', cuerpo: {} });

    await expect(llamada).rejects.toBeInstanceOf(ErrorApi);
    await expect(llamada).rejects.toMatchObject({ estado: 401, titulo: 'Usuario o clave incorrectos.' });
  });

  it('si el gateway no responde, avisa sin conexión', async () => {
    vi.stubGlobal('fetch', vi.fn().mockRejectedValue(new TypeError('fetch failed')));

    const llamada = llamarApi('/__SERVICIO__/api/v1/quien-soy');

    await expect(llamada).rejects.toBeInstanceOf(ErrorApi);
    await expect(llamada).rejects.toMatchObject({ estado: 0 });
  });
});

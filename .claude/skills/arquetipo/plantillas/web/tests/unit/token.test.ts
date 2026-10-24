import { describe, expect, it } from 'vitest';
import { leerDatos } from '@/features/sesion/token';

function tokenCon(contenido: object): string {
  const parte = (o: object) => Buffer.from(JSON.stringify(o)).toString('base64url');
  return `${parte({ alg: 'RS256', typ: 'JWT' })}.${parte(contenido)}.firma`;
}

describe('leerDatos', () => {
  it('lee el usuario, los roles y el vencimiento', () => {
    const datos = leerDatos(tokenCon({ name: 'cliente.demo', role: ['cliente'], exp: 2_000_000_000 }));

    expect(datos).toEqual({ usuario: 'cliente.demo', roles: ['cliente'], expira: new Date(2_000_000_000_000) });
  });

  it('acepta un solo rol como texto', () => {
    expect(leerDatos(tokenCon({ name: 'admin.demo', role: 'admin', exp: 1 }))?.roles).toEqual(['admin']);
  });

  it('devuelve null si no es un token', () => {
    expect(leerDatos('no-es-un-token')).toBeNull();
    expect(leerDatos('a.b.c')).toBeNull();
  });
});

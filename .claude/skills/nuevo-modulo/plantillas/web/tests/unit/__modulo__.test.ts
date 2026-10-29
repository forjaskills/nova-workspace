import { describe, expect, it } from 'vitest';
import { leerFormulario, mensajeDeError } from '@/features/__modulo__/formulario';
import { ErrorApi } from '@/lib/api/cliente';

// TODO(nuevo-modulo): una prueba por cada conversión de leerFormulario (texto → número, filas vacías) y por
// cada cálculo «estimado» de formato.ts. Las reglas del negocio se prueban en nova-__servicio__, no aquí.
describe('leerFormulario', () => {
  it('arma lo que se manda a la API', () => {
    const datos = new FormData();
    datos.append('nombre', 'Ejemplo');

    expect(leerFormulario(datos)).toEqual({ nombre: 'Ejemplo' });
  });
});

describe('mensajeDeError', () => {
  it('una regla del dominio (400) se muestra tal como la dice el servidor', () => {
    expect(mensajeDeError(new ErrorApi(400, 'Mensaje de la regla.'))).toBe('Mensaje de la regla.');
  });

  it('sin permiso (403) explica qué permiso falta', () => {
    expect(mensajeDeError(new ErrorApi(403, 'Forbidden'))).toContain('__servicio__.escribir');
  });
});

'use client';

import Link from 'next/link';
import { useActionState } from 'react';
import { crear__Entidad__Accion } from './acciones';
import type { EstadoFormulario } from './formulario';
import estilos from './__modulo__.module.css';

const inicial: EstadoFormulario = { error: null };

export function Formulario__Entidad__() {
  const [estado, enviar, enviando] = useActionState(crear__Entidad__Accion, inicial);

  return (
    <form action={enviar} className="tarjeta formulario">
      {/* TODO(nuevo-modulo): un <label> con su <input> por campo de Nuevo__Entidad__ (con required, min, maxLength
          según la ficha: ayudan al usuario, pero la regla la sigue validando el dominio). Si un campo se repite
          (líneas), un componente con estado para agregar y quitar filas. */}
      <label>
        Nombre
        <input name="nombre" required />
      </label>

      {estado.error && (
        <p role="alert" className="error">
          {estado.error}
        </p>
      )}

      <div className={estilos.acciones}>
        <button type="submit" disabled={enviando}>
          {enviando ? 'Guardando…' : 'Guardar'}
        </button>
        <Link href="/__modulo__" className={estilos.enlace}>
          Cancelar
        </Link>
      </div>
    </form>
  );
}

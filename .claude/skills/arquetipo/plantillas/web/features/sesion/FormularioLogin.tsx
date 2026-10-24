'use client';

import { useActionState } from 'react';
import { iniciarSesion, type EstadoLogin } from './acciones';

const inicial: EstadoLogin = { error: null };

export function FormularioLogin({ aviso }: { aviso?: string }) {
  const [estado, enviar, enviando] = useActionState(iniciarSesion, inicial);

  return (
    <form action={enviar} className="tarjeta formulario">
      <h1>Iniciar sesión</h1>
      {aviso && !estado.error && <p className="aviso">{aviso}</p>}
      <label>
        Usuario
        <input name="usuario" autoComplete="username" required />
      </label>
      <label>
        Clave
        <input name="clave" type="password" autoComplete="current-password" required />
      </label>
      {estado.error && (
        <p role="alert" className="error">
          {estado.error}
        </p>
      )}
      <button type="submit" disabled={enviando}>
        {enviando ? 'Entrando…' : 'Iniciar sesión'}
      </button>
    </form>
  );
}

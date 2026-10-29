import { obtenerConexion } from '@/features/__servicio__/conexion';
import estilos from './__modulo__.module.css';

/** Quién eres, con qué rol y qué permisos trae tu token: arriba de cada pantalla de __Modulo__. */
export async function Franja({ token }: { token: string }) {
  const conexion = await obtenerConexion(token);

  return (
    <p className={estilos.franja} data-testid="conexion">
      <span>
        Conectado a través del gateway como <strong>{conexion.usuario}</strong>
      </span>
      <span>Rol: {conexion.roles.join(', ') || 'ninguno'}</span>
      <span>Permisos: {conexion.scopes.join(' ') || 'ninguno todavía'}</span>
    </p>
  );
}

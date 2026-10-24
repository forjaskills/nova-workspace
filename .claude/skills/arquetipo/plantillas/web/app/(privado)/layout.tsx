import { redirect } from 'next/navigation';
import { cerrarSesion } from '@/features/sesion/acciones';
import { leerToken } from '@/features/sesion/sesion';
import { leerDatos } from '@/features/sesion/token';

/** Todo lo que está en (privado) exige sesión: sin la cookie, al login. */
export default async function LayoutPrivado({ children }: Readonly<{ children: React.ReactNode }>) {
  const token = await leerToken();
  const datos = token ? leerDatos(token) : null;
  if (!datos) redirect('/login');

  return (
    <>
      <header className="barra">
        <span className="marca">Nova Retail</span>
        <form action={cerrarSesion} className="usuario">
          <span>{datos.usuario}</span>
          <button type="submit" className="secundario">
            Cerrar sesión
          </button>
        </form>
      </header>
      <main className="contenido">{children}</main>
    </>
  );
}

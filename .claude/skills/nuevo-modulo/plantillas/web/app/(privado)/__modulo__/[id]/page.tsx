import Link from 'next/link';
import { notFound, redirect } from 'next/navigation';
import { obtener__Entidad__ } from '@/features/__modulo__/api';
import estilos from '@/features/__modulo__/__modulo__.module.css';
import { leerToken } from '@/features/sesion/sesion';

export default async function Pagina__Entidad__({ params }: { params: Promise<{ id: string }> }) {
  const token = await leerToken();
  if (!token) redirect('/login');
  const { id } = await params;
  const registro = await obtener__Entidad__(token, id);
  if (!registro) notFound();

  return (
    <section>
      <div className={estilos.encabezado}>
        <h1>{registro.id}</h1>
        <Link href="/__modulo__" className={estilos.enlace}>← Volver</Link>
      </div>
      {/* TODO(nuevo-modulo): los datos del detalle (un <dl className="tarjeta">) y, si tiene partes (líneas),
          su tabla con el total que calculó el dominio. */}
    </section>
  );
}

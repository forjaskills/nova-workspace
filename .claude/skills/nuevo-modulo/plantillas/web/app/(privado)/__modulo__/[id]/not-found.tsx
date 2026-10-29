import Link from 'next/link';
import estilos from '@/features/__modulo__/__modulo__.module.css';

export default function __Entidad__NoEncontrado() {
  return (
    <section className="tarjeta">
      {/* TODO(nuevo-modulo): «No encontramos ese pedido», con el nombre de la entidad */}
      <h1>No lo encontramos</h1>
      <p className="nota">Puede que la dirección esté mal o que no sea tuyo.</p>
      <Link href="/__modulo__" className={estilos.enlace}>← Volver</Link>
    </section>
  );
}

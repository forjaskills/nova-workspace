import { Formulario__Entidad__ } from '@/features/__modulo__/Formulario__Entidad__';
import estilos from '@/features/__modulo__/__modulo__.module.css';

export default function PaginaNuevo__Entidad__() {
  return (
    <section>
      <div className={estilos.encabezado}>
        {/* TODO(nuevo-modulo): «Nuevo pedido», con el nombre de la entidad */}
        <h1>Nuevo</h1>
      </div>
      <Formulario__Entidad__ />
    </section>
  );
}

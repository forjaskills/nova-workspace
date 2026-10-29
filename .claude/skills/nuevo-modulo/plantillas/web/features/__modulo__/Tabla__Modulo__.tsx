import Link from 'next/link';
import type { __Entidad__Resumen } from './api';
import estilos from './__modulo__.module.css';

export function Tabla__Modulo__({ elementos }: { elementos: __Entidad__Resumen[] }) {
  return (
    <div className={estilos.envoltura}>
      <table className={estilos.tabla}>
        <thead>
          <tr>
            {/* TODO(nuevo-modulo): una columna por campo del resumen; números y montos con className={estilos.numero} */}
            <th scope="col">Id</th>
          </tr>
        </thead>
        <tbody>
          {elementos.map((e) => (
            <tr key={e.id}>
              <td>
                <Link href={`/__modulo__/${e.id}`}>{e.id}</Link>
              </td>
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
}

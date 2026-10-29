import Link from 'next/link';
import { redirect } from 'next/navigation';
import { listar__Modulo__ } from '@/features/__modulo__/api';
import estilos from '@/features/__modulo__/__modulo__.module.css';
import { Tabla__Modulo__ } from '@/features/__modulo__/Tabla__Modulo__';
import { leerToken } from '@/features/sesion/sesion';
import { ErrorApi } from '@/lib/api/cliente';

// TODO(nuevo-modulo): si la API tiene filtros (estado…), agrégalos aquí y como enlaces sobre la tabla.
type Parametros = { pagina?: string };

export default async function Pagina__Modulo__({ searchParams }: { searchParams: Promise<Parametros> }) {
  const token = await leerToken();
  if (!token) redirect('/login');
  const parametros = await searchParams;
  const pagina = Math.max(1, Number.parseInt(parametros.pagina ?? '1', 10) || 1);

  let resultado;
  try {
    resultado = await listar__Modulo__(token, { pagina });
  } catch (error) {
    // Un token de antes de que existieran los permisos de __Modulo__: la API responde 403.
    if (error instanceof ErrorApi && error.estado === 403) {
      return (
        <section className="tarjeta">
          <h1>__Modulo__</h1>
          <p role="alert" className="error">
            Tu sesión no tiene permiso para ver esto (__servicio__.leer). Si te lo acaban de dar, cierra sesión y vuelve
            a entrar.
          </p>
        </section>
      );
    }
    throw error;
  }

  const paginas = Math.max(1, Math.ceil(resultado.total / resultado.tamano));
  const enlace = (n: number) => (n > 1 ? `/__modulo__?pagina=${n}` : '/__modulo__');

  return (
    <section>
      <div className={estilos.encabezado}>
        <h1>__Modulo__</h1>
        <Link href="/__modulo__/nuevo" className={estilos.boton}>
          Nuevo
        </Link>
      </div>

      {resultado.elementos.length === 0 ? (
        <p className="tarjeta nota">Aún no hay nada aquí.</p>
      ) : (
        <Tabla__Modulo__ elementos={resultado.elementos} />
      )}

      <div className={estilos.paginas}>
        <span>
          {resultado.total} en total · página {resultado.pagina} de {paginas}
        </span>
        <span>
          {pagina > 1 && <Link href={enlace(pagina - 1)}>← Anterior</Link>}{' '}
          {pagina < paginas && <Link href={enlace(pagina + 1)}>Siguiente →</Link>}
        </span>
      </div>
    </section>
  );
}

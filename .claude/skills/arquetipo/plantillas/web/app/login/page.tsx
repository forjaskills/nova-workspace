import { redirect } from 'next/navigation';
import { FormularioLogin } from '@/features/sesion/FormularioLogin';
import { leerToken } from '@/features/sesion/sesion';

export default async function PaginaLogin({ searchParams }: { searchParams: Promise<{ vencida?: string }> }) {
  const { vencida } = await searchParams;
  if (!vencida && (await leerToken())) redirect('/__SERVICIO__');

  return (
    <main className="centrado">
      <p className="marca">Nova Retail</p>
      <FormularioLogin aviso={vencida ? 'Tu sesión venció. Vuelve a iniciarla.' : undefined} />
    </main>
  );
}

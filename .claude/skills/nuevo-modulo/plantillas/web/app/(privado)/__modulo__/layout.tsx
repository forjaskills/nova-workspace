import { redirect } from 'next/navigation';
import { Franja } from '@/features/__modulo__/Franja';
import { leerToken } from '@/features/sesion/sesion';

/** Todas las pantallas de __Modulo__ llevan arriba la franja «usuario · rol · permisos». */
export default async function Layout__Modulo__({ children }: Readonly<{ children: React.ReactNode }>) {
  const token = await leerToken();
  if (!token) redirect('/login');

  return (
    <>
      <Franja token={token} />
      {children}
    </>
  );
}

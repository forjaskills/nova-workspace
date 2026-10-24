import type { Metadata } from 'next';
import './globals.css';

export const metadata: Metadata = {
  title: 'Nova Retail',
  description: 'Nova Retail: proyecto de ejemplo del canal Forja Skills.',
};

export default function Raiz({ children }: Readonly<{ children: React.ReactNode }>) {
  return (
    <html lang="es">
      <body>{children}</body>
    </html>
  );
}

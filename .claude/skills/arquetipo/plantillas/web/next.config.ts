import type { NextConfig } from 'next';

const configuracion: NextConfig = {
  // No anunciar con qué está hecha la web.
  poweredByHeader: false,
  // Las mismas cabeceras de seguridad que el gateway y los servicios.
  async headers() {
    return [
      {
        source: '/:ruta*',
        headers: [
          { key: 'X-Content-Type-Options', value: 'nosniff' },
          { key: 'X-Frame-Options', value: 'DENY' },
          { key: 'Referrer-Policy', value: 'no-referrer' },
        ],
      },
    ];
  },
};

export default configuracion;

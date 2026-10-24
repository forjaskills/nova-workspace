/** Un error de la API, ya leído del ProblemDetails (RFC 9457) que devuelven el gateway y los servicios. */
export class ErrorApi extends Error {
  readonly estado: number;
  readonly titulo: string;
  readonly detalle?: string;

  constructor(estado: number, titulo: string, detalle?: string) {
    super(detalle ?? titulo);
    this.name = 'ErrorApi';
    this.estado = estado;
    this.titulo = titulo;
    this.detalle = detalle;
  }
}

type ProblemDetails = { title?: string; detail?: string };

/** Convierte una respuesta con error en ErrorApi, con el mensaje del servidor si lo trae. */
export async function leerProblema(respuesta: Response): Promise<ErrorApi> {
  const tipo = respuesta.headers.get('content-type') ?? '';
  if (tipo.includes('json')) {
    try {
      const problema = (await respuesta.json()) as ProblemDetails;
      return new ErrorApi(respuesta.status, problema.title ?? respuesta.statusText, problema.detail);
    } catch {
      // Cuerpo que no es JSON válido: se queda con el estado.
    }
  }
  return new ErrorApi(respuesta.status, respuesta.statusText || `Error ${respuesta.status}`);
}

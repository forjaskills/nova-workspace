// Cómo se muestran los datos de __Modulo__. Un solo lugar: la moneda y la zona horaria no se repiten por la web.
const moneda = new Intl.NumberFormat('es-PE', { style: 'currency', currency: 'PEN' });
const fecha = new Intl.DateTimeFormat('es-PE', { dateStyle: 'medium', timeZone: 'America/Lima' });

export function formatoMoneda(valor: number): string {
  return moneda.format(valor);
}

export function formatoFecha(iso: string): string {
  return fecha.format(new Date(iso));
}

// TODO(nuevo-modulo): si el formulario muestra un cálculo mientras se escribe (un total), va aquí, rotulado
// «estimado»: el valor que vale lo calcula el dominio en el servidor y nunca se manda a la API.

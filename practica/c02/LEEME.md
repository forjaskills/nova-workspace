# Archivo de práctica · Dashboards con IA usando Claude

Todo es **ficticio**: Nova Retail es una tienda inventada para el curso. Ninguna cifra es real.

## Qué hay

| Archivo | Para qué capítulo |
|---|---|
| `ventas-nova-retail-2026.xlsx` | Todos: el dashboard gratis (cap. 2), el dashboard Pro (cap. 3), revisar los números (cap. 4) |

## Qué trae el Excel

Una sola hoja, **Ventas**, con **5,033 ventas** del **1 de enero al 31 de octubre de 2026**. Cada fila es una venta.

| Columna | Qué dice | Ejemplo |
|---|---|---|
| `fecha` | el día de la venta | 01/01/2026 |
| `region` | la ciudad: Lima, Arequipa, Piura, Cusco o Trujillo | Arequipa |
| `canal` | dónde compró: Tienda, Web o WhatsApp | WhatsApp |
| `categoria` | Electrónica, Hogar, Moda, Deportes o Belleza | Electrónica |
| `producto` | qué compró (20 productos) | Parlante bluetooth |
| `cantidad` | cuántas unidades | 1 |
| `precio_unitario` | precio de una unidad, en soles | S/ 199.00 |
| `total_soles` | cantidad × precio (la calcula Excel) | S/ 199.00 |

**Ojo:** el archivo no tiene un número de venta, y hay **126 filas iguales** a otra (misma fecha, ciudad, canal,
producto y cantidad). Son ventas distintas que coinciden, no errores. Si Claude te pregunta si son duplicados,
esa es la respuesta (y es una buena pregunta: en tus datos reales, revísalo).

## Cómo usarlo

1. Descárgalo con el enlace de la descripción del video. Queda en tu carpeta **Descargas**.
2. No hace falta abrirlo para usarlo con Claude: lo subes tal cual con el botón **+** del chat.
3. Si lo abres en Excel y cambias algo, guárdalo como **.xlsx** (no como .csv) antes de subirlo.

## Cifras para comprobar (capítulo 4)

Si tu dashboard muestra otra cosa, pídele a Claude que te diga **qué columna sumó** y compara.

| Qué | Cifra correcta |
|---|---|
| Ventas totales (suma de `total_soles`) | **S/ 841,863.60** |
| Número de ventas (filas) | 5,033 |
| Unidades vendidas (suma de `cantidad`) | 7,287 |
| Mes con más ventas | **julio**: S/ 104,749.90 |
| Mes con menos ventas | febrero: S/ 56,046.00 |
| Región que más vende | **Lima**: S/ 342,141.20 |
| Ventas por canal | Tienda S/ 330,478.50 · Web S/ 283,771.40 · WhatsApp S/ 227,613.70 |
| Producto que más vende **en soles** | **Freidora de aire 4 L**: S/ 106,925.00 |
| Producto que más vende **en unidades** | **Polo básico algodón**: 663 unidades (luego Crema hidratante 519, Protector solar 505, Tomatodo 484, Cargador USB-C 467) |
| Solo Piura | S/ 133,421.00 · 801 ventas · 1,158 unidades |

**Cómo sumarlo tú mismo en Excel:** haz clic en la letra **H** (arriba de la columna `total_soles`) y mira abajo a la
derecha de la ventana: dice **Suma**. Para una sola región: botón de flecha en `region` → deja marcada solo esa
ciudad → la suma de abajo cambia.

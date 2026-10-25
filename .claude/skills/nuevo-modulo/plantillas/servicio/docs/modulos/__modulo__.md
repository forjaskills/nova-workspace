# Módulo __Modulo__ (nova-__servicio__)

Ficha del módulo: la llena el dev con Claude **antes** de escribir código. Es lo que el código tiene que cumplir y lo
que revisan las pruebas. Ejemplo completo: `referencias/ficha-modulo.md` de la skill `nuevo-modulo`.

| | |
|---|---|
| Qué es | TODO: una frase |
| Agregado | `__Entidad__` (raíz) · TODO: hijos, si tiene |
| Campos | TODO: nombre · tipo · obligatorio · límites |
| Estados | TODO: si tiene, y por dónde pasa |
| Reglas | TODO: una por línea; cada una con su código de error (`__entidad__.…`) |
| Quién | TODO: qué hace cada rol (cliente · operador · admin) |
| API | TODO: `GET /api/v1/__modulo__` … |
| Base | `bd/__NNNN__-modulo-__modulo__.sql` (+ datos demo, si hacen falta) |
| Permisos | `__servicio__.leer` · `__servicio__.escribir` (nova-seguridad) |

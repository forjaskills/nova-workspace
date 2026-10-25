using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Nova.__Servicio__.Adaptadores.Presentadores;
using Nova.__Servicio__.Aplicacion.Comun;

namespace Nova.__Servicio__.Adaptadores.Controladores;

/// <summary>
/// HTTP → casos de uso del módulo __Modulo__. Aquí no hay reglas de negocio: solo se traduce la petición,
/// se arma el <see cref="Solicitante"/> con el token y se presenta el resultado (this.Presentar / this.Problema).
/// </summary>
[ApiController]
[Route("api/v1/__modulo__")]
[Authorize(Policy = Politicas.Lectura)]
public sealed class Controlador__Modulo__ : ControllerBase
{
    // TODO(nuevo-modulo): una acción por caso de uso, recibido con [FromServices] (I…). Lo que escribe lleva
    // [Authorize(Policy = Politicas.Escritura)]; crear responde CreatedAtAction(…).

    private Solicitante Solicitante() =>
        new(Guid.TryParse(User.FindFirst("sub")?.Value, out var id) ? id : Guid.Empty, GestionaTodos());

    private bool GestionaTodos() => User.HasClaim("role", "operador") || User.HasClaim("role", "admin");
}

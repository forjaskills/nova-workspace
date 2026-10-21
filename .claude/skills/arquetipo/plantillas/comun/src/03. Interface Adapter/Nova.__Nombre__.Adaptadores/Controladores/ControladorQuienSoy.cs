using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Nova.__Nombre__.Adaptadores.Controladores;

/// <summary>Devuelve quién eres según tu token: prueba que este servicio acepta el JWT de nova-seguridad.</summary>
[ApiController]
[Route("api/v1/quien-soy")]
[Authorize]
public sealed class ControladorQuienSoy : ControllerBase
{
    [HttpGet]
    public ActionResult<QuienSoyRespuesta> Obtener() => new QuienSoyRespuesta(
        Usuario: User.FindFirst("name")?.Value ?? "",
        Id: User.FindFirst("sub")?.Value ?? "",
        Roles: [.. User.FindAll("role").Select(c => c.Value)],
        Scopes: User.FindFirst("scope")?.Value.Split(' ', StringSplitOptions.RemoveEmptyEntries) ?? []);
}

public sealed record QuienSoyRespuesta(string Usuario, string Id, IReadOnlyList<string> Roles, IReadOnlyList<string> Scopes);

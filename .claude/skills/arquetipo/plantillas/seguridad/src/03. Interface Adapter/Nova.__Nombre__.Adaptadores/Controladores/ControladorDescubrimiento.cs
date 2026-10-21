using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Options;
using Nova.__Nombre__.Adaptadores.Gateways.Tokens;

namespace Nova.__Nombre__.Adaptadores.Controladores;

/// <summary>
/// Publica quién emite los tokens y su llave pública (estándar OpenID Connect).
/// Con esto, cualquier servicio valida los tokens sin compartir ningún secreto.
/// </summary>
[ApiController]
[Route(".well-known")]
[AllowAnonymous]
public sealed class ControladorDescubrimiento(LlavesFirma llaves, IOptions<OpcionesTokens> opciones) : ControllerBase
{
    [HttpGet("openid-configuration")]
    public IActionResult Configuracion() => Ok(new Dictionary<string, object>
    {
        ["issuer"] = opciones.Value.Emisor,
        ["jwks_uri"] = $"{Request.Scheme}://{Request.Host}/.well-known/jwks.json",
        ["id_token_signing_alg_values_supported"] = new[] { "RS256" },
    });

    [HttpGet("jwks.json")]
    public IActionResult Llaves() => Ok(new { keys = new[] { llaves.LlavePublicaJwk() } });
}

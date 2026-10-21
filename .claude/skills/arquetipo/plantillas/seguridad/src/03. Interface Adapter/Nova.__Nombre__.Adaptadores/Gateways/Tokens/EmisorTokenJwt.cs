using Microsoft.Extensions.Options;
using Microsoft.IdentityModel.JsonWebTokens;
using Microsoft.IdentityModel.Tokens;
using Nova.__Nombre__.Aplicacion.Sesion;
using Nova.__Nombre__.Dominio.Usuarios;

namespace Nova.__Nombre__.Adaptadores.Gateways.Tokens;

/// <summary>Firma el JWT con RS256: quién eres (sub, name), tus roles y tus scopes.</summary>
public sealed class EmisorTokenJwt(LlavesFirma llaves, IOptions<OpcionesTokens> opciones, TimeProvider reloj) : IEmisorToken
{
    private readonly JsonWebTokenHandler _manejador = new();

    public TokenEmitido Emitir(Usuario usuario)
    {
        var config = opciones.Value;
        var vigencia = TimeSpan.FromMinutes(config.MinutosVigencia);
        var token = _manejador.CreateToken(new SecurityTokenDescriptor
        {
            Issuer = config.Emisor,
            Audience = config.Audiencia,
            IssuedAt = reloj.GetUtcNow().UtcDateTime,
            Expires = reloj.GetUtcNow().Add(vigencia).UtcDateTime,
            SigningCredentials = new SigningCredentials(llaves.LlavePrivada, SecurityAlgorithms.RsaSha256),
            Claims = new Dictionary<string, object>
            {
                ["sub"] = usuario.Id.ToString(),
                ["name"] = usuario.NombreUsuario.Valor,
                ["role"] = usuario.Roles.Select(r => r.Nombre).ToArray(),
                ["scope"] = string.Join(' ', usuario.Scopes()),
            },
        });
        return new TokenEmitido(token, "Bearer", (int)vigencia.TotalSeconds);
    }
}

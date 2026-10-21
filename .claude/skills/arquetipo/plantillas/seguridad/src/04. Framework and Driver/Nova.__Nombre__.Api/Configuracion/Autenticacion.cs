using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.Extensions.Options;
using Microsoft.IdentityModel.Tokens;
using Nova.__Nombre__.Adaptadores.Gateways.Tokens;

namespace Nova.__Nombre__.Api.Configuracion;

public static class Autenticacion
{
    public static IServiceCollection AgregarAutenticacion(this IServiceCollection servicios, IConfiguration configuracion)
    {
        servicios.AddAuthentication(JwtBearerDefaults.AuthenticationScheme).AddJwtBearer();

        // Seguridad valida sus propios tokens con su llave pública; los demás servicios la descargan de /.well-known.
        servicios.AddOptions<JwtBearerOptions>(JwtBearerDefaults.AuthenticationScheme)
            .Configure<LlavesFirma, IOptions<OpcionesTokens>>((opciones, llaves, tokens) =>
            {
                opciones.MapInboundClaims = false;
                opciones.TokenValidationParameters = new TokenValidationParameters
                {
                    ValidIssuer = tokens.Value.Emisor,
                    ValidAudience = tokens.Value.Audiencia,
                    IssuerSigningKey = llaves.LlavePublica,
                    NameClaimType = "name",
                    RoleClaimType = "role",
                };
            });
        return servicios;
    }
}

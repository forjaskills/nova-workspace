using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.IdentityModel.Tokens;

namespace Nova.__Nombre__.Api.Configuracion;

public static class Autenticacion
{
    public static IServiceCollection AgregarAutenticacion(this IServiceCollection servicios, IConfiguration configuracion)
    {
        servicios.AddAuthentication(JwtBearerDefaults.AuthenticationScheme)
            .AddJwtBearer(opciones =>
            {
                var tokens = configuracion.GetSection("Tokens");

                // nova-seguridad publica su llave pública (/.well-known/jwks.json):
                // aquí no se guarda ningún secreto.
                opciones.Authority = tokens["Autoridad"];
                // Solo en local: en tu empresa el TLS lo pone el balanceador o el gateway.
                opciones.RequireHttpsMetadata = false;
                opciones.MapInboundClaims = false;
                opciones.TokenValidationParameters = new TokenValidationParameters
                {
                    ValidIssuer = tokens["Emisor"],
                    ValidAudience = tokens["Audiencia"],
                    NameClaimType = "name",
                    RoleClaimType = "role",
                };
            });
        return servicios;
    }
}

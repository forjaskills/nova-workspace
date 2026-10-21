using System.Security.Cryptography;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.Mvc.Testing;
using Microsoft.AspNetCore.TestHost;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.IdentityModel.JsonWebTokens;
using Microsoft.IdentityModel.Protocols.OpenIdConnect;
using Microsoft.IdentityModel.Tokens;
using Nova.__Nombre__.Migrador;

namespace Nova.__Nombre__.Pruebas.Integracion;

/// <summary>
/// Levanta la API en memoria contra la base de pruebas. En vez de pedir el token a nova-seguridad,
/// las pruebas firman los suyos con una llave propia: así no dependen de otro servicio encendido.
/// </summary>
public sealed class FabricaApi : WebApplicationFactory<Program>
{
    public const string CadenaPruebas =
        @"Server=.\SQLEXPRESS;Database=__BASE___PRUEBAS;Integrated Security=true;Encrypt=true;TrustServerCertificate=true";

    private readonly RsaSecurityKey _llave = new(RSA.Create(2048)) { KeyId = "pruebas" };

    public FabricaApi() => MigradorBd.Aplicar(CadenaPruebas, _ => { });

    /// <summary>Un token como los de nova-seguridad, firmado con la llave de pruebas (u otra, para probar el rechazo).</summary>
    public string CrearToken(string usuario, string[] roles, string[] scopes, SecurityKey? otraLlave = null) =>
        new JsonWebTokenHandler().CreateToken(new SecurityTokenDescriptor
        {
            Issuer = "nova-seguridad",
            Audience = "nova-api",
            Expires = DateTime.UtcNow.AddMinutes(5),
            SigningCredentials = new SigningCredentials(otraLlave ?? _llave, SecurityAlgorithms.RsaSha256),
            Claims = new Dictionary<string, object>
            {
                ["sub"] = Guid.NewGuid().ToString(),
                ["name"] = usuario,
                ["role"] = roles,
                ["scope"] = string.Join(' ', scopes),
            },
        });

    protected override void ConfigureWebHost(IWebHostBuilder builder)
    {
        builder.UseEnvironment("Development");
        builder.UseSetting("ConnectionStrings:Principal", CadenaPruebas);
        builder.ConfigureTestServices(servicios =>
            servicios.Configure<JwtBearerOptions>(JwtBearerDefaults.AuthenticationScheme, opciones =>
            {
                // Sin Autoridad: la llave pública se entrega directo, sin ir a /.well-known.
                opciones.Authority = null;
                opciones.Configuration = new OpenIdConnectConfiguration { Issuer = "nova-seguridad" };
                opciones.TokenValidationParameters.IssuerSigningKey = _llave;
            }));
    }
}

using System.Security.Cryptography;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.Mvc.Testing;
using Microsoft.AspNetCore.TestHost;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.IdentityModel.JsonWebTokens;
using Microsoft.IdentityModel.Protocols.OpenIdConnect;
using Microsoft.IdentityModel.Tokens;

// Un solo gateway en memoria (y un solo par de servicios falsos) para todas las pruebas.
[assembly: AssemblyFixture(typeof(Nova.__Nombre__.Pruebas.FabricaGateway))]

namespace Nova.__Nombre__.Pruebas;

/// <summary>
/// Levanta el gateway en memoria apuntando a servicios falsos. Los tokens se firman con una llave
/// de pruebas, como los de nova-seguridad, sin depender de que esté encendido.
/// </summary>
public sealed class FabricaGateway : WebApplicationFactory<Program>, IAsyncLifetime
{
    /// <summary>El origen de nova-web en DEV: el único que CORS deja pasar.</summary>
    public const string OrigenWeb = "http://localhost:__WEB_PUERTO_DEV__";

    private readonly RsaSecurityKey _llave = new(RSA.Create(2048)) { KeyId = "pruebas" };

    public ServicioFalso Seguridad { get; private set; } = null!;

    public ServicioFalso Servicio { get; private set; } = null!;

    public async ValueTask InitializeAsync()
    {
        Seguridad = await ServicioFalso.IniciarAsync();
        Servicio = await ServicioFalso.IniciarAsync();
    }

    /// <summary>Un token como los de nova-seguridad, firmado con la llave de pruebas (u otra, para probar el rechazo).</summary>
    public string CrearToken(string usuario, SecurityKey? otraLlave = null) =>
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
                ["role"] = new[] { "cliente" },
            },
        });

    protected override void ConfigureWebHost(IWebHostBuilder builder)
    {
        builder.UseEnvironment("Development");
        builder.UseSetting("ReverseProxy:Clusters:seguridad:Destinations:principal:Address", Seguridad.Direccion);
        builder.UseSetting("ReverseProxy:Clusters:__SERVICIO__:Destinations:principal:Address", Servicio.Direccion);
        builder.ConfigureTestServices(servicios =>
            servicios.Configure<JwtBearerOptions>(JwtBearerDefaults.AuthenticationScheme, opciones =>
            {
                // Sin Autoridad: la llave pública se entrega directo, sin ir a /.well-known.
                opciones.Authority = null;
                opciones.Configuration = new OpenIdConnectConfiguration { Issuer = "nova-seguridad" };
                opciones.TokenValidationParameters.IssuerSigningKey = _llave;
            }));
    }

    public override async ValueTask DisposeAsync()
    {
        await base.DisposeAsync();
        await Seguridad.DisposeAsync();
        await Servicio.DisposeAsync();
    }
}

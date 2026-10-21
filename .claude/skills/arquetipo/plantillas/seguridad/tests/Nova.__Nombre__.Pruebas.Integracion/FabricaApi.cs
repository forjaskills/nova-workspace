using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.Mvc.Testing;
using Nova.__Nombre__.Migrador;

namespace Nova.__Nombre__.Pruebas.Integracion;

/// <summary>Levanta la API en memoria contra la base de pruebas, con una llave de firma temporal.</summary>
public sealed class FabricaApi : WebApplicationFactory<Program>
{
    public const string CadenaPruebas =
        @"Server=.\SQLEXPRESS;Database=__BASE___PRUEBAS;Integrated Security=true;Encrypt=true;TrustServerCertificate=true";

    private readonly string _carpetaLlaves = Path.Combine(Path.GetTempPath(), $"nova-llaves-{Guid.NewGuid():N}");

    public FabricaApi() => MigradorBd.Aplicar(CadenaPruebas, _ => { });

    protected override void ConfigureWebHost(IWebHostBuilder builder)
    {
        builder.UseEnvironment("Development");
        builder.UseSetting("ConnectionStrings:Principal", CadenaPruebas);
        builder.UseSetting("Tokens:CarpetaLlaves", _carpetaLlaves);
    }

    public override async ValueTask DisposeAsync()
    {
        await base.DisposeAsync();
        if (Directory.Exists(_carpetaLlaves))
        {
            Directory.Delete(_carpetaLlaves, recursive: true);
        }
    }
}

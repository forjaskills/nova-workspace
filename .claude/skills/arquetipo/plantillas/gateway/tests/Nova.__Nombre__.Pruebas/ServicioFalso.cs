using System.Net;
using Microsoft.AspNetCore.Builder;
using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.Http;
using Microsoft.Extensions.Logging;

namespace Nova.__Nombre__.Pruebas;

/// <summary>
/// Un servicio de mentira en un puerto libre: responde qué ruta y qué token le llegaron.
/// Así se prueba el gateway sin encender nova-seguridad ni los servicios reales.
/// </summary>
public sealed class ServicioFalso : IAsyncDisposable
{
    private readonly WebApplication _app;
    private int _llamadas;

    private ServicioFalso(WebApplication app) => _app = app;

    /// <summary>Dirección base (termina en /), como la que va en ReverseProxy:Clusters.</summary>
    public string Direccion => _app.Urls.First() + "/";

    /// <summary>Cuántos pedidos le llegaron (sin contar /salud).</summary>
    public int Llamadas => Volatile.Read(ref _llamadas);

    public static async Task<ServicioFalso> IniciarAsync()
    {
        var builder = WebApplication.CreateSlimBuilder();
        // Puerto 0: el sistema da uno libre. Solo en la máquina local (loopback).
        builder.WebHost.ConfigureKestrel(kestrel => kestrel.Listen(IPAddress.Loopback, 0));
        builder.Logging.ClearProviders();
        var app = builder.Build();
        var falso = new ServicioFalso(app);

        app.MapGet("/salud", () => "Healthy");
        app.Map("/{**resto}", (HttpContext http) =>
        {
            Interlocked.Increment(ref falso._llamadas);
            return Results.Json(new RespuestaFalsa(
                http.Request.Path.Value ?? "",
                http.Request.Headers.Authorization.ToString()));
        });

        await app.StartAsync();
        return falso;
    }

    public async ValueTask DisposeAsync() => await _app.DisposeAsync();
}

public sealed record RespuestaFalsa(string Ruta, string Autorizacion);

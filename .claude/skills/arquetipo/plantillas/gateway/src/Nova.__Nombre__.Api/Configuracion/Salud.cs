using Microsoft.Extensions.Diagnostics.HealthChecks;

namespace Nova.__Nombre__.Api.Configuracion;

public static class Salud
{
    public static IServiceCollection AgregarSalud(this IServiceCollection servicios)
    {
        servicios.AddHttpClient(nameof(SaludDestinos), cliente => cliente.Timeout = TimeSpan.FromSeconds(3));
        servicios.AddHealthChecks().AddCheck<SaludDestinos>("destinos");
        return servicios;
    }
}

/// <summary>
/// Pregunta <c>/salud</c> a cada servicio al que enruta. Si alguno no responde, el gateway queda
/// «Degraded»: sigue enrutando a los demás y dice cuál falta.
/// </summary>
public sealed class SaludDestinos(IConfiguration configuracion, IHttpClientFactory fabrica) : IHealthCheck
{
    public async Task<HealthCheckResult> CheckHealthAsync(HealthCheckContext contexto, CancellationToken cancelacion = default)
    {
        var cliente = fabrica.CreateClient(nameof(SaludDestinos));
        var caidos = new List<string>();
        foreach (var servicio in configuracion.GetSection("ReverseProxy:Clusters").GetChildren())
        {
            foreach (var destino in servicio.GetSection("Destinations").GetChildren())
            {
                if (!await RespondeAsync(cliente, destino["Address"], cancelacion)) { caidos.Add(servicio.Key); }
            }
        }
        return caidos.Count == 0
            ? HealthCheckResult.Healthy("todos los servicios responden")
            : HealthCheckResult.Degraded($"sin respuesta: {string.Join(", ", caidos)}");
    }

    private static async Task<bool> RespondeAsync(HttpClient cliente, string? direccion, CancellationToken cancelacion)
    {
        if (!Uri.TryCreate(direccion, UriKind.Absolute, out var raiz)) { return false; }
        try
        {
            using var respuesta = await cliente.GetAsync(new Uri(raiz, "salud"), cancelacion);
            return respuesta.IsSuccessStatusCode;
        }
        catch (HttpRequestException) { return false; }
        catch (TaskCanceledException) when (!cancelacion.IsCancellationRequested) { return false; }
    }
}

using System.Threading.RateLimiting;

namespace Nova.__Nombre__.Api.Configuracion;

/// <summary>Límites de pedidos y cabeceras de seguridad: el gateway es la puerta, se ponen aquí.</summary>
public static class Endurecimiento
{
    public static IServiceCollection AgregarEndurecimiento(this IServiceCollection servicios)
    {
        servicios.AddRateLimiter(opciones =>
        {
            opciones.RejectionStatusCode = StatusCodes.Status429TooManyRequests;

            // General: 100 pedidos por minuto por usuario (o por IP si no inició sesión).
            opciones.GlobalLimiter = PartitionedRateLimiter.Create<HttpContext, string>(http =>
                RateLimitPartition.GetFixedWindowLimiter(
                    http.User.Identity?.IsAuthenticated == true
                        ? $"usuario:{http.User.FindFirst("sub")?.Value}"
                        : $"ip:{http.Connection.RemoteIpAddress}",
                    _ => new FixedWindowRateLimiterOptions { PermitLimit = 100, Window = TimeSpan.FromMinutes(1) }));

            // Estricto (login): 5 intentos por minuto por IP, para frenar a quien adivina claves.
            opciones.AddPolicy(Politicas.LimiteEstricto, http =>
                RateLimitPartition.GetFixedWindowLimiter(
                    $"ip:{http.Connection.RemoteIpAddress}",
                    _ => new FixedWindowRateLimiterOptions { PermitLimit = 5, Window = TimeSpan.FromMinutes(1) }));
        });
        return servicios;
    }

    public static WebApplication UsarCabecerasDeSeguridad(this WebApplication app)
    {
        app.Use(async (http, siguiente) =>
        {
            var cabeceras = http.Response.Headers;
            cabeceras.XContentTypeOptions = "nosniff";
            cabeceras.XFrameOptions = "DENY";
            cabeceras["Referrer-Policy"] = "no-referrer";
            await siguiente(http);
        });
        return app;
    }
}

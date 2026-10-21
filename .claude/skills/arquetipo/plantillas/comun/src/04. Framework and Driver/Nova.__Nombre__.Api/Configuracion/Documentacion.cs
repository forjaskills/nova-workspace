using Microsoft.OpenApi;
using Scalar.AspNetCore;

namespace Nova.__Nombre__.Api.Configuracion;

/// <summary>OpenAPI en /openapi/v1.json y la interfaz Scalar en /scalar para probar la API (no en producción).</summary>
public static class Documentacion
{
    public static IServiceCollection AgregarDocumentacion(this IServiceCollection servicios)
    {
        servicios.AddOpenApi(opciones => opciones.AddDocumentTransformer((documento, _, _) =>
        {
            documento.Info = new OpenApiInfo { Title = "Nova __Nombre__", Version = "v1" };
            documento.Components ??= new OpenApiComponents();
            documento.Components.SecuritySchemes ??= new Dictionary<string, IOpenApiSecurityScheme>();
            documento.Components.SecuritySchemes["Bearer"] = new OpenApiSecurityScheme
            {
                Type = SecuritySchemeType.Http,
                Scheme = "bearer",
                BearerFormat = "JWT",
                Description = "Token emitido por nova-seguridad (POST /api/v1/sesion).",
            };
            documento.Security ??= [];
            documento.Security.Add(new OpenApiSecurityRequirement
            {
                [new OpenApiSecuritySchemeReference("Bearer", documento)] = [],
            });
            return Task.CompletedTask;
        }));
        return servicios;
    }

    public static WebApplication MapDocumentacion(this WebApplication app)
    {
        app.MapOpenApi();
        app.MapScalarApiReference(opciones => opciones.WithTitle("Nova __Nombre__"));
        return app;
    }
}

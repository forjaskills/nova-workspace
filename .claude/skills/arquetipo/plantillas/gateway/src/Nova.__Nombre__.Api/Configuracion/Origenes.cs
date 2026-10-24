namespace Nova.__Nombre__.Api.Configuracion;

/// <summary>CORS: qué páginas web pueden llamar al gateway desde el navegador.</summary>
public static class Origenes
{
    public const string Web = "web";

    public static IServiceCollection AgregarOrigenes(this IServiceCollection servicios, IConfiguration configuracion)
    {
        // Solo los orígenes de cada ambiente (appsettings.{Ambiente}.json); nunca «*».
        var permitidos = configuracion.GetSection("Cors:Origenes").Get<string[]>() ?? [];
        servicios.AddCors(opciones => opciones.AddPolicy(Web, politica => politica
            .WithOrigins(permitidos)
            .WithMethods("GET", "POST", "PUT", "PATCH", "DELETE")
            .WithHeaders("Authorization", "Content-Type")));
        return servicios;
    }
}

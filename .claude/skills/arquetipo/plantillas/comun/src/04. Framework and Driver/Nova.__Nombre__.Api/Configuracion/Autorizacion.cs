using System.Security.Claims;
using Nova.__Nombre__.Adaptadores.Controladores;

namespace Nova.__Nombre__.Api.Configuracion;

public static class Autorizacion
{
    public static IServiceCollection AgregarAutorizacion(this IServiceCollection servicios)
    {
        servicios.AddAuthorizationBuilder()
            .AddPolicy(Politicas.Lectura, p => p.RequireAssertion(c => TieneScope(c.User, Politicas.ScopeLectura)))
            .AddPolicy(Politicas.Escritura, p => p.RequireAssertion(c => TieneScope(c.User, Politicas.ScopeEscritura)));
        return servicios;
    }

    /// <summary>El claim <c>scope</c> trae los permisos separados por espacios (estándar OAuth 2.0).</summary>
    private static bool TieneScope(ClaimsPrincipal usuario, string scope) =>
        usuario.Identity?.IsAuthenticated == true
        && (usuario.FindFirst("scope")?.Value.Split(' ').Contains(scope) ?? false);
}

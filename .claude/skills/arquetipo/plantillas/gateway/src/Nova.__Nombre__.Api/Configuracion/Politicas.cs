namespace Nova.__Nombre__.Api.Configuracion;

/// <summary>Nombres que usan las rutas de appsettings (AuthorizationPolicy, RateLimiterPolicy).</summary>
public static class Politicas
{
    /// <summary>La ruta exige un token válido de nova-seguridad. Las rutas abiertas usan «anonymous».</summary>
    public const string Autenticado = "autenticado";

    /// <summary>Límite de intentos para el login: 5 por minuto por IP.</summary>
    public const string LimiteEstricto = "estricto";
}

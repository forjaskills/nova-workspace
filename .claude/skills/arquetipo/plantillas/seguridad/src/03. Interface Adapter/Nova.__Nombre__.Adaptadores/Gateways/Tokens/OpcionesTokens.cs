namespace Nova.__Nombre__.Adaptadores.Gateways.Tokens;

/// <summary>Sección «Tokens» de appsettings.</summary>
public sealed class OpcionesTokens
{
    public string Emisor { get; set; } = "nova-seguridad";

    public string Audiencia { get; set; } = "nova-api";

    public int MinutosVigencia { get; set; } = 60;

    /// <summary>Dónde vive la llave privada. Vacío = %LOCALAPPDATA%\nova\llaves (fuera del repo).</summary>
    public string? CarpetaLlaves { get; set; }
}

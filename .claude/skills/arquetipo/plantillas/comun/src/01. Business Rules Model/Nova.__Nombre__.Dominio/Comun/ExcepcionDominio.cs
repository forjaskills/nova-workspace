namespace Nova.__Nombre__.Dominio.Comun;

/// <summary>Se lanza cuando algo intenta romper una regla del negocio.</summary>
public sealed class ExcepcionDominio(string codigo, string mensaje) : Exception(mensaje)
{
    public string Codigo { get; } = codigo;
}

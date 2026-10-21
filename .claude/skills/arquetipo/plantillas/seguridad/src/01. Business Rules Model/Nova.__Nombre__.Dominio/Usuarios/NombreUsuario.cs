using System.Text.RegularExpressions;
using Nova.__Nombre__.Dominio.Comun;

namespace Nova.__Nombre__.Dominio.Usuarios;

/// <summary>Nombre con el que se inicia sesión: minúsculas, de 3 a 50 caracteres (letras, números, punto, guion).</summary>
public sealed partial record NombreUsuario : ObjetoValor
{
    private NombreUsuario(string valor) => Valor = valor;

    public string Valor { get; }

    public static bool EsValido(string? valor) => valor is not null && Formato().IsMatch(valor.Trim().ToLowerInvariant());

    public static NombreUsuario Crear(string? valor)
    {
        if (!EsValido(valor))
        {
            throw new ExcepcionDominio(
                "nombre_usuario_invalido",
                "El nombre de usuario debe tener de 3 a 50 caracteres: letras, números, punto, guion o guion bajo.");
        }

        return new NombreUsuario(valor!.Trim().ToLowerInvariant());
    }

    public override string ToString() => Valor;

    [GeneratedRegex("^[a-z0-9._-]{3,50}$")]
    private static partial Regex Formato();
}

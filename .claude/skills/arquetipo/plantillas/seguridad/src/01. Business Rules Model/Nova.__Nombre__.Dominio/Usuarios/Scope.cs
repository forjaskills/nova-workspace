using System.Text.RegularExpressions;
using Nova.__Nombre__.Dominio.Comun;

namespace Nova.__Nombre__.Dominio.Usuarios;

/// <summary>Un permiso sobre un servicio, con la forma <c>servicio.accion</c> (p. ej. <c>pedidos.leer</c>).</summary>
public sealed partial record Scope : ObjetoValor
{
    private Scope(string valor) => Valor = valor;

    public string Valor { get; }

    public static Scope Crear(string valor)
    {
        if (!Formato().IsMatch(valor))
        {
            throw new ExcepcionDominio("scope_invalido", $"El scope '{valor}' debe tener la forma servicio.accion.");
        }

        return new Scope(valor);
    }

    public override string ToString() => Valor;

    [GeneratedRegex("^[a-z0-9-]+\\.[a-z0-9-]+$")]
    private static partial Regex Formato();
}

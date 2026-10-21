using Nova.__Nombre__.Dominio.Comun;

namespace Nova.__Nombre__.Dominio.Usuarios;

/// <summary>Un rol agrupa scopes: el usuario recibe los scopes de todos sus roles.</summary>
public sealed class Rol : Entidad<int>
{
    private readonly List<Scope> _scopes = [];

    public Rol(int id, string nombre)
    {
        Id = id;
        Nombre = nombre;
    }

    private Rol()
    {
        Nombre = "";
    }

    public string Nombre { get; private set; }

    public IReadOnlyCollection<Scope> Scopes => _scopes;

    public void PermitirScope(Scope scope)
    {
        if (!_scopes.Contains(scope))
        {
            _scopes.Add(scope);
        }
    }
}

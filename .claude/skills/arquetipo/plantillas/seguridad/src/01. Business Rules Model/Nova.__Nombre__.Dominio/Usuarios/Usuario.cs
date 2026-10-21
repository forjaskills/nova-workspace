using Nova.__Nombre__.Dominio.Comun;

namespace Nova.__Nombre__.Dominio.Usuarios;

/// <summary>Quien inicia sesión. La clave nunca se guarda: solo su hash.</summary>
public sealed class Usuario : RaizAgregado<Guid>
{
    private readonly List<Rol> _roles = [];

    public Usuario(Guid id, NombreUsuario nombreUsuario, string hashClave)
    {
        Id = id;
        NombreUsuario = nombreUsuario;
        HashClave = hashClave;
        Activo = true;
    }

    private Usuario()
    {
        NombreUsuario = null!;
        HashClave = "";
    }

    public NombreUsuario NombreUsuario { get; private set; }

    public string HashClave { get; private set; }

    public bool Activo { get; private set; }

    public IReadOnlyCollection<Rol> Roles => _roles;

    /// <summary>Un usuario desactivado no puede iniciar sesión, aunque su clave sea correcta.</summary>
    public bool PuedeIniciarSesion => Activo;

    public void AsignarRol(Rol rol)
    {
        if (!_roles.Contains(rol))
        {
            _roles.Add(rol);
        }
    }

    public void Desactivar() => Activo = false;

    /// <summary>Los scopes del usuario son la unión de los de sus roles.</summary>
    public IReadOnlyList<string> Scopes() =>
        [.. _roles.SelectMany(r => r.Scopes).Select(s => s.Valor).Distinct().Order(StringComparer.Ordinal)];
}

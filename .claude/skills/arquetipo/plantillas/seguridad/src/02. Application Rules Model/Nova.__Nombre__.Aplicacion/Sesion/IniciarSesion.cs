using Nova.__Nombre__.Aplicacion.Comun;
using Nova.__Nombre__.Dominio.Usuarios;

namespace Nova.__Nombre__.Aplicacion.Sesion;

/// <summary>Caso de uso: valida usuario y clave y emite un JWT con sus roles y scopes.</summary>
public sealed class IniciarSesion(
    IRepositorioUsuarios usuarios,
    IVerificadorClave verificador,
    IEmisorToken emisor) : IIniciarSesion
{
    // El mismo error si el usuario no existe, está inactivo o la clave no coincide:
    // así no se revela qué usuarios existen.
    private static readonly Error CredencialesInvalidas =
        new("credenciales_invalidas", "Usuario o clave incorrectos.", TipoError.NoAutorizado);

    public async Task<Resultado<TokenEmitido>> EjecutarAsync(SolicitudInicioSesion solicitud, CancellationToken cancelacion)
    {
        if (!NombreUsuario.EsValido(solicitud.Usuario) || string.IsNullOrEmpty(solicitud.Clave))
        {
            return CredencialesInvalidas;
        }

        var usuario = await usuarios.ObtenerPorNombreAsync(NombreUsuario.Crear(solicitud.Usuario), cancelacion);
        if (usuario is null || !usuario.PuedeIniciarSesion || !verificador.Verificar(usuario, solicitud.Clave))
        {
            return CredencialesInvalidas;
        }

        return emisor.Emitir(usuario);
    }
}

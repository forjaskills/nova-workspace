using Nova.__Nombre__.Aplicacion.Comun;
using Nova.__Nombre__.Dominio.Usuarios;

namespace Nova.__Nombre__.Aplicacion.Sesion;

/// <summary>Puerto de entrada: lo que el controlador puede pedir.</summary>
public interface IIniciarSesion
{
    Task<Resultado<TokenEmitido>> EjecutarAsync(SolicitudInicioSesion solicitud, CancellationToken cancelacion);
}

/// <summary>Puerto de salida: firma el token (lo implementa un gateway con la llave RSA).</summary>
public interface IEmisorToken
{
    TokenEmitido Emitir(Usuario usuario);
}

/// <summary>Puerto de salida: compara una clave con el hash guardado.</summary>
public interface IVerificadorClave
{
    bool Verificar(Usuario usuario, string clave);
}

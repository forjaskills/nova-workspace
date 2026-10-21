using Nova.__Nombre__.Aplicacion.Sesion;
using Nova.__Nombre__.Dominio.Usuarios;

namespace Nova.__Nombre__.Pruebas.Unitarias.Sesion;

public sealed class IniciarSesionPruebas
{
    private static CancellationToken Cancelacion => TestContext.Current.CancellationToken;

    private readonly Usuario _ana = new(Guid.NewGuid(), NombreUsuario.Crear("ana"), "clave-de-ana");

    [Fact]
    public async Task Con_usuario_y_clave_correctos_emite_el_token()
    {
        var resultado = await CasoDeUso(_ana).EjecutarAsync(new("ana", "clave-de-ana"), Cancelacion);

        Assert.True(resultado.EsExito);
        Assert.Equal("token-de-ana", resultado.Valor!.TokenAcceso);
    }

    [Theory]
    [InlineData("ana", "otra")]   // clave incorrecta
    [InlineData("luis", "x")]     // no existe
    [InlineData("", "x")]         // nombre inválido
    [InlineData("ana", "")]       // sin clave
    public async Task Si_algo_no_cuadra_responde_siempre_el_mismo_error(string usuario, string clave)
    {
        var resultado = await CasoDeUso(_ana).EjecutarAsync(new(usuario, clave), Cancelacion);

        Assert.False(resultado.EsExito);
        Assert.Equal("credenciales_invalidas", resultado.Error!.Codigo);
    }

    [Fact]
    public async Task Un_usuario_desactivado_no_inicia_sesion_aunque_la_clave_sea_correcta()
    {
        _ana.Desactivar();

        var resultado = await CasoDeUso(_ana).EjecutarAsync(new("ana", "clave-de-ana"), Cancelacion);

        Assert.Equal("credenciales_invalidas", resultado.Error!.Codigo);
    }

    private static IniciarSesion CasoDeUso(params Usuario[] usuarios) =>
        new(new RepositorioEnMemoria(usuarios), new VerificadorDePrueba(), new EmisorDePrueba());

    private sealed class RepositorioEnMemoria(Usuario[] usuarios) : IRepositorioUsuarios
    {
        public Task<Usuario?> ObtenerPorNombreAsync(NombreUsuario nombre, CancellationToken cancelacion) =>
            Task.FromResult(usuarios.FirstOrDefault(u => u.NombreUsuario == nombre));
    }

    /// <summary>En estas pruebas el «hash» es la clave misma: lo que se prueba es el caso de uso, no el cifrado.</summary>
    private sealed class VerificadorDePrueba : IVerificadorClave
    {
        public bool Verificar(Usuario usuario, string clave) => usuario.HashClave == clave;
    }

    private sealed class EmisorDePrueba : IEmisorToken
    {
        public TokenEmitido Emitir(Usuario usuario) => new($"token-de-{usuario.NombreUsuario}", "Bearer", 3600);
    }
}

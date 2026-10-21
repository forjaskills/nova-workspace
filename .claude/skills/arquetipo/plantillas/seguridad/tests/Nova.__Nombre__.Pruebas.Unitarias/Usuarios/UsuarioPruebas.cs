using Nova.__Nombre__.Dominio.Comun;
using Nova.__Nombre__.Dominio.Usuarios;

namespace Nova.__Nombre__.Pruebas.Unitarias.Usuarios;

public sealed class UsuarioPruebas
{
    [Fact]
    public void Los_scopes_son_la_union_de_los_de_sus_roles_sin_repetir()
    {
        var cliente = new Rol(1, "cliente");
        cliente.PermitirScope(Scope.Crear("pedidos.leer"));
        var operador = new Rol(2, "operador");
        operador.PermitirScope(Scope.Crear("pedidos.leer"));
        operador.PermitirScope(Scope.Crear("pedidos.escribir"));
        var usuario = new Usuario(Guid.NewGuid(), NombreUsuario.Crear("ana"), "hash");

        usuario.AsignarRol(cliente);
        usuario.AsignarRol(operador);

        Assert.Equal(["pedidos.escribir", "pedidos.leer"], usuario.Scopes());
    }

    [Fact]
    public void Un_usuario_desactivado_no_puede_iniciar_sesion()
    {
        var usuario = new Usuario(Guid.NewGuid(), NombreUsuario.Crear("ana"), "hash");

        usuario.Desactivar();

        Assert.False(usuario.PuedeIniciarSesion);
    }

    [Theory]
    [InlineData("Ana.Demo", "ana.demo")]
    [InlineData("  luis  ", "luis")]
    public void El_nombre_de_usuario_se_guarda_en_minusculas_y_sin_espacios(string escrito, string guardado) =>
        Assert.Equal(guardado, NombreUsuario.Crear(escrito).Valor);

    [Theory]
    [InlineData("ab")]
    [InlineData("con espacio")]
    [InlineData("")]
    public void Un_nombre_de_usuario_invalido_rompe_una_regla(string escrito)
    {
        var error = Assert.Throws<ExcepcionDominio>(() => NombreUsuario.Crear(escrito));

        Assert.Equal("nombre_usuario_invalido", error.Codigo);
    }
}

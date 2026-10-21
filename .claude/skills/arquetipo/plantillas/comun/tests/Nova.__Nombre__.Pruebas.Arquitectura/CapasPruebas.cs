using System.Reflection;
using Microsoft.AspNetCore.Mvc;
using NetArchTest.Rules;
using Nova.__Nombre__.Adaptadores.Controladores;
using Nova.__Nombre__.Aplicacion;
using Nova.__Nombre__.Dominio.Comun;

namespace Nova.__Nombre__.Pruebas.Arquitectura;

/// <summary>
/// Las reglas de las capas, escritas como pruebas: si alguien (o la IA) pone algo donde no va,
/// el build de pruebas se pone en rojo.
/// </summary>
public sealed class CapasPruebas
{
    private const string Raiz = "Nova.__Nombre__";

    private static readonly Assembly Dominio = typeof(Entidad<>).Assembly;
    private static readonly Assembly Aplicacion = typeof(RegistroAplicacion).Assembly;
    private static readonly Assembly Adaptadores = typeof(ControladorQuienSoy).Assembly;
    private static readonly Assembly Api = typeof(Program).Assembly;

    [Fact]
    public void El_dominio_no_depende_de_nadie()
    {
        var resultado = Types.InAssembly(Dominio).ShouldNot().HaveDependencyOnAny(
            $"{Raiz}.Aplicacion", $"{Raiz}.Adaptadores", $"{Raiz}.Api",
            "Microsoft.EntityFrameworkCore", "Microsoft.AspNetCore").GetResult();

        Assert.True(resultado.IsSuccessful, Detalle(resultado));
    }

    [Fact]
    public void La_aplicacion_solo_conoce_el_dominio()
    {
        var resultado = Types.InAssembly(Aplicacion).ShouldNot().HaveDependencyOnAny(
            $"{Raiz}.Adaptadores", $"{Raiz}.Api",
            "Microsoft.EntityFrameworkCore", "Microsoft.AspNetCore", "Microsoft.Data.SqlClient").GetResult();

        Assert.True(resultado.IsSuccessful, Detalle(resultado));
    }

    [Fact]
    public void Los_adaptadores_no_conocen_la_api()
    {
        var resultado = Types.InAssembly(Adaptadores).ShouldNot().HaveDependencyOn($"{Raiz}.Api").GetResult();

        Assert.True(resultado.IsSuccessful, Detalle(resultado));
    }

    [Fact]
    public void Los_controladores_viven_en_adaptadores()
    {
        var resultado = Types.InAssemblies([Dominio, Aplicacion, Adaptadores, Api])
            .That().Inherit(typeof(ControllerBase))
            .Should().ResideInNamespace($"{Raiz}.Adaptadores.Controladores").GetResult();

        Assert.True(resultado.IsSuccessful, Detalle(resultado));
    }

    [Fact]
    public void EF_Core_solo_se_usa_en_los_gateways()
    {
        var fueraDeAdaptadores = Types.InAssemblies([Dominio, Aplicacion, Api])
            .ShouldNot().HaveDependencyOn("Microsoft.EntityFrameworkCore").GetResult();
        var dentroDeAdaptadores = Types.InAssembly(Adaptadores)
            .That().HaveDependencyOn("Microsoft.EntityFrameworkCore")
            .Should().ResideInNamespace($"{Raiz}.Adaptadores.Gateways").GetResult();

        Assert.True(fueraDeAdaptadores.IsSuccessful, Detalle(fueraDeAdaptadores));
        Assert.True(dentroDeAdaptadores.IsSuccessful, Detalle(dentroDeAdaptadores));
    }

    private static string Detalle(NetArchTest.Rules.TestResult resultado) =>
        "Tipos que rompen la regla: " + string.Join(", ", resultado.FailingTypeNames ?? []);
}

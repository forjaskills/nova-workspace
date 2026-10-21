using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Nova.__Nombre__.Adaptadores.Gateways.Claves;
using Nova.__Nombre__.Adaptadores.Gateways.Tokens;
using Nova.__Nombre__.Adaptadores.Gateways.Usuarios;
using Nova.__Nombre__.Aplicacion.Sesion;
using Nova.__Nombre__.Dominio.Usuarios;

namespace Nova.__Nombre__.Adaptadores.Gateways;

public static class RegistroGateways
{
    public static IServiceCollection AgregarGateways(this IServiceCollection servicios)
    {
        // La cadena sale de appsettings.{Ambiente}.json: autenticación de Windows, sin contraseñas.
        servicios.AddDbContext<__Nombre__DbContext>((proveedor, opciones) => opciones.UseSqlServer(
            proveedor.GetRequiredService<IConfiguration>().GetConnectionString("Principal")
            ?? throw new InvalidOperationException("Falta ConnectionStrings:Principal en appsettings.{Ambiente}.json")));
        servicios.AddHealthChecks().AddDbContextCheck<__Nombre__DbContext>("base-de-datos");

        servicios.AddOptions<OpcionesTokens>().BindConfiguration("Tokens");
        servicios.AddSingleton(TimeProvider.System);
        servicios.AddSingleton<LlavesFirma>();
        servicios.AddSingleton<IEmisorToken, EmisorTokenJwt>();
        servicios.AddSingleton<IVerificadorClave, VerificadorClave>();
        servicios.AddScoped<IRepositorioUsuarios, RepositorioUsuarios>();

        // Repositorios: nuevo-modulo agrega aquí los de cada módulo.
        return servicios;
    }
}

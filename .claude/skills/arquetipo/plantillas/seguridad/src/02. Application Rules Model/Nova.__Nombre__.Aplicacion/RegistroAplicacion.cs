using Microsoft.Extensions.DependencyInjection;
using Nova.__Nombre__.Aplicacion.Sesion;

namespace Nova.__Nombre__.Aplicacion;

public static class RegistroAplicacion
{
    public static IServiceCollection AgregarAplicacion(this IServiceCollection servicios)
    {
        servicios.AddScoped<IIniciarSesion, IniciarSesion>();

        // Casos de uso: nuevo-modulo agrega aquí los de cada módulo.
        return servicios;
    }
}

using Microsoft.Extensions.DependencyInjection;

namespace Nova.__Nombre__.Aplicacion;

public static class RegistroAplicacion
{
    public static IServiceCollection AgregarAplicacion(this IServiceCollection servicios)
    {
        // Casos de uso: nuevo-modulo agrega aquí los de cada módulo.
        return servicios;
    }
}

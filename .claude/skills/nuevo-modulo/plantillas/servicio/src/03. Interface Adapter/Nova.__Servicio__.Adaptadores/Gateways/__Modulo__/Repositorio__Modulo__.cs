using Nova.__Servicio__.Dominio.__Modulo__;

namespace Nova.__Servicio__.Adaptadores.Gateways.__Modulo__;

/// <summary>Implementa el puerto del dominio con EF Core sobre SQL Server.</summary>
internal sealed class Repositorio__Modulo__(__Servicio__DbContext contexto) : IRepositorio__Modulo__
{
    // TODO(nuevo-modulo): las consultas del puerto. Lo que solo se lee, con AsNoTracking().

    public void Agregar(__Entidad__ __entidad__) => contexto.Add(__entidad__);

    public Task Guardar(CancellationToken cancelacion) => contexto.SaveChangesAsync(cancelacion);
}

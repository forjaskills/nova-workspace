namespace Nova.__Servicio__.Dominio.__Modulo__;

/// <summary>
/// Puerto de infraestructura: lo que el dominio necesita para guardar y leer __modulo__.
/// El dominio solo lo declara; la implementación (EF Core) vive en Adaptadores.Gateways.__Modulo__.
/// </summary>
public interface IRepositorio__Modulo__
{
    // TODO(nuevo-modulo): las consultas que piden los casos de uso (por Id o número, una página filtrada…).

    void Agregar(__Entidad__ __entidad__);

    Task Guardar(CancellationToken cancelacion);
}

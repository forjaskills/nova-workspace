using Nova.__Servicio__.Dominio.Comun;

namespace Nova.__Servicio__.Dominio.__Modulo__;

/// <summary>
/// Raíz del agregado __Entidad__: la única puerta para cambiarlo.
/// Las reglas del negocio (docs/modulos/__modulo__.md) se escriben AQUÍ, no en el controlador ni en la base.
/// Si una regla se rompe: <c>throw new ExcepcionDominio("__entidad__.codigo", "mensaje para personas")</c>.
/// </summary>
public sealed class __Entidad__ : RaizAgregado<Guid>
{
    private __Entidad__()
    {
    }

    // TODO(nuevo-modulo): propiedades con «private set», un método de fábrica que valida, y un método por cada
    // cosa que se puede hacer con un __Entidad__ (nunca setters públicos).
}

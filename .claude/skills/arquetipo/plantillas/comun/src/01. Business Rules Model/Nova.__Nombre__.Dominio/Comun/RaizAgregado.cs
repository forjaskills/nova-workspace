namespace Nova.__Nombre__.Dominio.Comun;

/// <summary>
/// Entidad principal de un agregado: la única puerta para cambiarlo y la unidad que se guarda.
/// Los repositorios trabajan solo con raíces de agregado.
/// </summary>
public abstract class RaizAgregado<TId> : Entidad<TId> where TId : notnull;

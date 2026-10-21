namespace Nova.__Nombre__.Dominio.Comun;

/// <summary>Objeto con identidad: dos entidades son la misma si tienen el mismo Id.</summary>
public abstract class Entidad<TId> where TId : notnull
{
    public TId Id { get; protected set; } = default!;

    public override bool Equals(object? obj) =>
        obj is Entidad<TId> otra
        && GetType() == otra.GetType()
        && EqualityComparer<TId>.Default.Equals(Id, otra.Id);

    public override int GetHashCode() => HashCode.Combine(GetType(), Id);
}

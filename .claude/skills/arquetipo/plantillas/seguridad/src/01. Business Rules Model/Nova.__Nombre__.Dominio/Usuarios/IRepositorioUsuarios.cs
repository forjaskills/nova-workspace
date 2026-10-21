namespace Nova.__Nombre__.Dominio.Usuarios;

/// <summary>Puerto de infraestructura: el dominio dice qué necesita; un gateway decide cómo (EF Core, SQL Server).</summary>
public interface IRepositorioUsuarios
{
    Task<Usuario?> ObtenerPorNombreAsync(NombreUsuario nombre, CancellationToken cancelacion);
}

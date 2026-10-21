using Microsoft.EntityFrameworkCore;
using Nova.__Nombre__.Dominio.Usuarios;

namespace Nova.__Nombre__.Adaptadores.Gateways.Usuarios;

public sealed class RepositorioUsuarios(__Nombre__DbContext bd) : IRepositorioUsuarios
{
    public Task<Usuario?> ObtenerPorNombreAsync(NombreUsuario nombre, CancellationToken cancelacion) =>
        bd.Set<Usuario>()
            .Include(u => u.Roles)
            .AsNoTracking()
            .FirstOrDefaultAsync(u => u.NombreUsuario == nombre, cancelacion);
}

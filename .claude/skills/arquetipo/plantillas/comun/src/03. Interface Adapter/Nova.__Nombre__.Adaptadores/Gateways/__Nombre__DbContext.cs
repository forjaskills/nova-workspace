using Microsoft.EntityFrameworkCore;

namespace Nova.__Nombre__.Adaptadores.Gateways;

/// <summary>Acceso a la base del servicio. Las tablas las crean los scripts de bd/ (Migrador), no EF.</summary>
public sealed class __Nombre__DbContext(DbContextOptions<__Nombre__DbContext> opciones) : DbContext(opciones)
{
    protected override void OnModelCreating(ModelBuilder modelBuilder) =>
        modelBuilder.ApplyConfigurationsFromAssembly(typeof(__Nombre__DbContext).Assembly);
}

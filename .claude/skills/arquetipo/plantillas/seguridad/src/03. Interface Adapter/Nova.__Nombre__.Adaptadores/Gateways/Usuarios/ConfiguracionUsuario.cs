using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using Nova.__Nombre__.Dominio.Usuarios;

namespace Nova.__Nombre__.Adaptadores.Gateways.Usuarios;

/// <summary>Cómo se guarda un Usuario en las tablas que crea bd/0001-esquema-seguridad.sql.</summary>
public sealed class ConfiguracionUsuario : IEntityTypeConfiguration<Usuario>
{
    public void Configure(EntityTypeBuilder<Usuario> builder)
    {
        builder.ToTable("Usuarios");
        builder.HasKey(u => u.Id);
        builder.Property(u => u.Id).ValueGeneratedNever();
        builder.Property(u => u.NombreUsuario)
            .HasConversion(n => n.Valor, v => NombreUsuario.Crear(v))
            .HasMaxLength(50);
        builder.Property(u => u.HashClave).HasMaxLength(200);
        builder.HasMany(u => u.Roles).WithMany().UsingEntity(
            "UsuarioRoles",
            r => r.HasOne(typeof(Rol)).WithMany().HasForeignKey("RolId"),
            u => u.HasOne(typeof(Usuario)).WithMany().HasForeignKey("UsuarioId"));
    }
}

public sealed class ConfiguracionRol : IEntityTypeConfiguration<Rol>
{
    public void Configure(EntityTypeBuilder<Rol> builder)
    {
        builder.ToTable("Roles");
        builder.HasKey(r => r.Id);
        builder.Property(r => r.Id).ValueGeneratedNever();
        builder.Property(r => r.Nombre).HasMaxLength(50);
        builder.OwnsMany(r => r.Scopes, scope =>
        {
            scope.ToTable("RolScopes");
            scope.WithOwner().HasForeignKey("RolId");
            scope.Property(s => s.Valor).HasColumnName("Scope").HasMaxLength(100);
            scope.HasKey("RolId", nameof(Scope.Valor));
        });
    }
}

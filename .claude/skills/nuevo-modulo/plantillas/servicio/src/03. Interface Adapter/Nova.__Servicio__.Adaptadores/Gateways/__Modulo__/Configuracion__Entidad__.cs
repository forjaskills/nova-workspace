using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using Nova.__Servicio__.Dominio.__Modulo__;

namespace Nova.__Servicio__.Adaptadores.Gateways.__Modulo__;

/// <summary>Cómo se guarda un __Entidad__ en las tablas que crea bd/ (EF no crea ni cambia tablas).</summary>
internal sealed class Configuracion__Entidad__ : IEntityTypeConfiguration<__Entidad__>
{
    public void Configure(EntityTypeBuilder<__Entidad__> __entidad__)
    {
        __entidad__.ToTable("__Modulo__");
        __entidad__.HasKey(e => e.Id);
        __entidad__.Property(e => e.Id).ValueGeneratedNever();
        // TODO(nuevo-modulo): largos, precisión de decimales, conversiones de objetos valor y enums, hijos (OwnsMany).
    }
}

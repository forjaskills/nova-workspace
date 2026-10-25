namespace Nova.__Servicio__.Pruebas.Integracion;

/// <summary>El módulo __Modulo__ dentro del servicio: HTTP → caso de uso → SQL Server (base _PRUEBAS).</summary>
public sealed class __Modulo__Pruebas(FabricaApi fabrica)
{
    private static CancellationToken Cancelacion => TestContext.Current.CancellationToken;

    // Cada fabrica.CrearToken(...) es un usuario distinto (un «sub» nuevo): sirve para probar «solo lo suyo».
    // TODO(nuevo-modulo): sin token → 401 · sin __servicio__.escribir → 403 · crear → 201 · lo de otro → 404 ·
    // cada error de la ficha → 400 con su código.
    private FabricaApi Fabrica => fabrica;
}

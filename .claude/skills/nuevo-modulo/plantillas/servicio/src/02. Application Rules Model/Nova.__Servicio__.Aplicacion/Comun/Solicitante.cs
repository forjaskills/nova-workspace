namespace Nova.__Servicio__.Aplicacion.Comun;

/// <summary>Quién pide algo: su Id (el <c>sub</c> del token) y si puede gestionar lo de todos (operador, admin).</summary>
public sealed record Solicitante(Guid Id, bool GestionaTodos);

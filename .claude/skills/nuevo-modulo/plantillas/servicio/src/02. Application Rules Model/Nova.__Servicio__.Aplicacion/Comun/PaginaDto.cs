namespace Nova.__Servicio__.Aplicacion.Comun;

/// <summary>Una página de resultados: los elementos, cuántos hay en total y qué página es.</summary>
public sealed record PaginaDto<T>(IReadOnlyList<T> Elementos, int Total, int Pagina, int Tamano);

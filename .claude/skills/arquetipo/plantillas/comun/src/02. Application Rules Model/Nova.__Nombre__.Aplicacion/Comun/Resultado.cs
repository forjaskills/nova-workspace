namespace Nova.__Nombre__.Aplicacion.Comun;

public enum TipoError
{
    Validacion,
    NoEncontrado,
    Conflicto,
    NoAutorizado,
}

/// <summary>Un error esperado del negocio: un código estable, un mensaje para personas y su tipo.</summary>
public sealed record Error(string Codigo, string Mensaje, TipoError Tipo);

/// <summary>
/// Lo que devuelve un caso de uso: el valor o el error, nunca los dos.
/// Los errores esperados no se lanzan como excepción; el presentador los convierte en ProblemDetails.
/// </summary>
public sealed class Resultado<T>
{
    private Resultado(T? valor, Error? error)
    {
        Valor = valor;
        Error = error;
    }

    public T? Valor { get; }

    public Error? Error { get; }

    public bool EsExito => Error is null;

    public static Resultado<T> Exito(T valor) => new(valor, null);

    public static Resultado<T> Falla(Error error) => new(default, error);

    public static implicit operator Resultado<T>(T valor) => Exito(valor);

    public static implicit operator Resultado<T>(Error error) => Falla(error);
}

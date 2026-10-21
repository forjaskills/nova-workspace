using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Nova.__Nombre__.Aplicacion.Comun;

namespace Nova.__Nombre__.Adaptadores.Presentadores;

/// <summary>Traduce el resultado de un caso de uso a HTTP; los errores salen como ProblemDetails.</summary>
public static class PresentadorResultado
{
    public static IActionResult Presentar<T>(this ControllerBase controlador, Resultado<T> resultado) =>
        resultado.EsExito ? controlador.Ok(resultado.Valor) : controlador.Problema(resultado.Error!);

    public static IActionResult Problema(this ControllerBase controlador, Error error)
    {
        var estado = error.Tipo switch
        {
            TipoError.Validacion => StatusCodes.Status400BadRequest,
            TipoError.NoEncontrado => StatusCodes.Status404NotFound,
            TipoError.Conflicto => StatusCodes.Status409Conflict,
            TipoError.NoAutorizado => StatusCodes.Status401Unauthorized,
            _ => StatusCodes.Status500InternalServerError,
        };
        var problema = controlador.ProblemDetailsFactory.CreateProblemDetails(
            controlador.HttpContext, estado, title: error.Mensaje);
        problema.Extensions["codigo"] = error.Codigo;
        return new ObjectResult(problema) { StatusCode = estado, ContentTypes = { "application/problem+json" } };
    }
}

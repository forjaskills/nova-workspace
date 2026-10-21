using Nova.__Nombre__.Adaptadores.Controladores;
using Nova.__Nombre__.Adaptadores.Gateways;
using Nova.__Nombre__.Api.Configuracion;
using Nova.__Nombre__.Aplicacion;

var builder = WebApplication.CreateBuilder(args);

builder.Services.AgregarAplicacion();
builder.Services.AgregarGateways();
builder.Services
    .AddControllers()
    .AddApplicationPart(typeof(ControladorQuienSoy).Assembly);
builder.Services.AddProblemDetails();
builder.Services.AgregarAutenticacion(builder.Configuration);
builder.Services.AgregarAutorizacion();
builder.Services.AgregarEndurecimiento();
builder.Services.AgregarDocumentacion();

var app = builder.Build();

app.UseExceptionHandler();
app.UseStatusCodePages();
app.UsarCabecerasDeSeguridad();
app.UseAuthentication();
app.UseAuthorization();
app.UseRateLimiter();

app.MapHealthChecks("/salud").DisableRateLimiting();
app.MapControllers();
if (!app.Environment.IsProduction())
{
    app.MapDocumentacion();
}

app.Run();

/// <summary>Visible para las pruebas de integración (WebApplicationFactory).</summary>
public partial class Program;

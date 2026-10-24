using Nova.__Nombre__.Api.Configuracion;

var builder = WebApplication.CreateBuilder(args);

builder.Services.AddProblemDetails();
builder.Services.AgregarAutenticacion(builder.Configuration);
builder.Services.AgregarOrigenes(builder.Configuration);
builder.Services.AgregarEndurecimiento();
builder.Services.AgregarSalud();
// Las rutas y los servicios de destino viven en appsettings: ReverseProxy:Routes y ReverseProxy:Clusters.
builder.Services.AddReverseProxy().LoadFromConfig(builder.Configuration.GetSection("ReverseProxy"));

var app = builder.Build();

app.UseExceptionHandler();
app.UseStatusCodePages();
app.UsarCabecerasDeSeguridad();
app.UseCors(Origenes.Web);
app.UseAuthentication();
app.UseAuthorization();
app.UseRateLimiter();

app.MapHealthChecks("/salud").DisableRateLimiting();
app.MapReverseProxy();

app.Run();

/// <summary>Visible para las pruebas de integración (WebApplicationFactory).</summary>
public partial class Program;

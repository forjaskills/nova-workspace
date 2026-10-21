// Migrador: aplica los scripts de bd/ en la base del ambiente elegido.
//   dotnet run --project tools/Migrador -- --ambiente DEV
//   dotnet run --project tools/Migrador -- --cadena "Server=...;Database=...;Integrated Security=true"
// La cadena del ambiente se lee del appsettings.{Ambiente}.json de la Api: una sola fuente de verdad.
using System.Text.Json;
using Microsoft.Data.SqlClient;
using Nova.__Nombre__.Migrador;

var ambiente = (Argumento("--ambiente") ?? "DEV").ToUpperInvariant();
try
{
    var cadena = Argumento("--cadena") ?? CadenaDelAmbiente(ambiente);
    if (ambiente is "QA" or "PROD" && Argumento("--cadena") is null)
    {
        Console.WriteLine($"Aviso: en {ambiente} los scripts los ejecuta el DBA o el pipeline, no el dev.");
    }

    MigradorBd.Aplicar(cadena);
    return 0;
}
catch (Exception ex) when (ex is SqlException or InvalidOperationException or FileNotFoundException)
{
    Console.Error.WriteLine($"Error: {ex.Message}");
    return 1;
}

string? Argumento(string nombre)
{
    var i = Array.IndexOf(args, nombre);
    return i >= 0 && i + 1 < args.Length ? args[i + 1] : null;
}

static string CadenaDelAmbiente(string ambiente)
{
    var nombreAmbiente = ambiente switch
    {
        "DEV" => "Development",
        "QA" => "QA",
        "PROD" => "Production",
        _ => throw new InvalidOperationException($"Ambiente desconocido: {ambiente}. Usa DEV, QA o PROD."),
    };

    var raiz = new DirectoryInfo(Directory.GetCurrentDirectory());
    while (raiz is not null && raiz.GetFiles("*.slnx").Length == 0)
    {
        raiz = raiz.Parent;
    }

    if (raiz is null)
    {
        throw new InvalidOperationException("No encuentro la solución (*.slnx): corre el Migrador desde la carpeta del proyecto.");
    }

    var archivo = Path.Combine(raiz.FullName, "src", "04. Framework and Driver", "Nova.__Nombre__.Api", $"appsettings.{nombreAmbiente}.json");
    using var json = JsonDocument.Parse(File.ReadAllText(archivo));
    return json.RootElement.GetProperty("ConnectionStrings").GetProperty("Principal").GetString()
        ?? throw new InvalidOperationException($"Falta ConnectionStrings:Principal en {archivo}");
}

using System.Text.RegularExpressions;
using Microsoft.Data.SqlClient;

namespace Nova.__Nombre__.Migrador;

/// <summary>
/// Aplica en orden los scripts de bd/ que aún no están en dbo.VersionesBd.
/// Correrlo dos veces no hace nada la segunda vez.
/// </summary>
public static partial class MigradorBd
{
    public static int Aplicar(string cadena, Action<string>? escribir = null)
    {
        escribir ??= Console.WriteLine;
        using var conexion = new SqlConnection(cadena);
        conexion.InfoMessage += (_, e) => escribir($"   {e.Message}");
        conexion.Open();
        escribir($"Base: {conexion.Database}");

        Ejecutar(conexion, """
            IF OBJECT_ID('dbo.VersionesBd') IS NULL
                CREATE TABLE dbo.VersionesBd (
                    Script     NVARCHAR(200) NOT NULL CONSTRAINT PK_VersionesBd PRIMARY KEY,
                    AplicadoEn DATETIME2     NOT NULL CONSTRAINT DF_VersionesBd_AplicadoEn DEFAULT SYSUTCDATETIME());
            """);

        var aplicados = Aplicados(conexion);
        var pendientes = Scripts().Where(s => !aplicados.Contains(s.Nombre)).ToList();
        foreach (var (nombre, sql) in pendientes)
        {
            escribir($"Aplicando {nombre}");
            foreach (var lote in SeparadorGo().Split(sql).Where(l => !string.IsNullOrWhiteSpace(l)))
            {
                Ejecutar(conexion, lote);
            }

            Ejecutar(conexion, "INSERT INTO dbo.VersionesBd (Script) VALUES (@script)", nombre);
        }

        escribir(pendientes.Count == 0
            ? "La base ya está al día: 0 scripts aplicados."
            : $"Listo: {pendientes.Count} script(s) aplicado(s).");
        return pendientes.Count;
    }

    private static IEnumerable<(string Nombre, string Sql)> Scripts()
    {
        var ensamblado = typeof(MigradorBd).Assembly;
        foreach (var recurso in ensamblado.GetManifestResourceNames()
                     .Where(r => r.StartsWith("bd/", StringComparison.Ordinal))
                     .Order(StringComparer.Ordinal))
        {
            using var lector = new StreamReader(ensamblado.GetManifestResourceStream(recurso)!);
            yield return (recurso["bd/".Length..], lector.ReadToEnd());
        }
    }

    private static HashSet<string> Aplicados(SqlConnection conexion)
    {
        using var comando = new SqlCommand("SELECT Script FROM dbo.VersionesBd", conexion);
        using var lector = comando.ExecuteReader();
        var aplicados = new HashSet<string>(StringComparer.Ordinal);
        while (lector.Read())
        {
            aplicados.Add(lector.GetString(0));
        }

        return aplicados;
    }

    private static void Ejecutar(SqlConnection conexion, string sql, string? script = null)
    {
        using var comando = new SqlCommand(sql, conexion) { CommandTimeout = 120 };
        if (script is not null)
        {
            comando.Parameters.AddWithValue("@script", script);
        }

        comando.ExecuteNonQuery();
    }

    /// <summary>Separa los lotes por líneas «GO», como sqlcmd y SSMS.</summary>
    [GeneratedRegex(@"^\s*GO\s*$", RegexOptions.Multiline | RegexOptions.IgnoreCase)]
    private static partial Regex SeparadorGo();
}

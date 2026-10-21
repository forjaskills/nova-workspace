using System.Net;
using System.Net.Http.Headers;
using System.Net.Http.Json;
using System.Text.Json;
using Nova.__Nombre__.Adaptadores.Controladores;
using Nova.__Nombre__.Aplicacion.Sesion;

namespace Nova.__Nombre__.Pruebas.Integracion;

public sealed class SesionPruebas(FabricaApi fabrica)
{
    private static CancellationToken Cancelacion => TestContext.Current.CancellationToken;

    [Fact]
    public async Task Con_clave_correcta_devuelve_un_token_que_la_propia_api_acepta()
    {
        var cliente = fabrica.CreateClient();

        var respuesta = await cliente.PostAsJsonAsync("/api/v1/sesion", new SolicitudInicioSesion("admin.demo", "NovaDemo#1"), Cancelacion);
        var token = await respuesta.Content.ReadFromJsonAsync<TokenEmitido>(Cancelacion);
        cliente.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", token!.TokenAcceso);
        var quienSoy = await cliente.GetFromJsonAsync<QuienSoyRespuesta>("/api/v1/quien-soy", Cancelacion);

        Assert.Equal(HttpStatusCode.OK, respuesta.StatusCode);
        Assert.Equal("no-store", respuesta.Headers.CacheControl?.ToString());
        Assert.Equal("admin.demo", quienSoy!.Usuario);
        Assert.Equal(["admin"], quienSoy.Roles);
        Assert.Contains("seguridad.admin", quienSoy.Scopes);
    }

    [Fact]
    public async Task Con_clave_incorrecta_responde_401_con_problem_details()
    {
        var respuesta = await fabrica.CreateClient().PostAsJsonAsync(
            "/api/v1/sesion", new SolicitudInicioSesion("cliente.demo", "otra-clave"), Cancelacion);

        Assert.Equal(HttpStatusCode.Unauthorized, respuesta.StatusCode);
        Assert.Equal("application/problem+json", respuesta.Content.Headers.ContentType?.MediaType);
        using var problema = JsonDocument.Parse(await respuesta.Content.ReadAsStringAsync(Cancelacion));
        Assert.Equal("credenciales_invalidas", problema.RootElement.GetProperty("codigo").GetString());
    }

    [Fact]
    public async Task Publica_su_llave_publica_para_que_otros_validen_los_tokens()
    {
        var cliente = fabrica.CreateClient();

        using var configuracion = JsonDocument.Parse(await cliente.GetStringAsync("/.well-known/openid-configuration", Cancelacion));
        using var llaves = JsonDocument.Parse(await cliente.GetStringAsync("/.well-known/jwks.json", Cancelacion));

        Assert.Equal("nova-seguridad", configuracion.RootElement.GetProperty("issuer").GetString());
        var llave = llaves.RootElement.GetProperty("keys")[0];
        Assert.Equal("RSA", llave.GetProperty("kty").GetString());
        Assert.False(llave.TryGetProperty("d", out _), "La parte privada de la llave nunca debe publicarse.");
    }
}

using System.Net;
using System.Net.Http.Headers;
using System.Net.Http.Json;
using System.Security.Cryptography;
using Microsoft.IdentityModel.Tokens;

namespace Nova.__Nombre__.Pruebas;

/// <summary>Qué publica el gateway, a dónde lo manda y qué deja pasar.</summary>
public sealed class RutasPruebas(FabricaGateway fabrica)
{
    private static CancellationToken Cancelacion => TestContext.Current.CancellationToken;

    [Fact]
    public async Task El_login_va_a_seguridad_sin_el_prefijo()
    {
        var respuesta = await fabrica.CreateClient().PostAsJsonAsync(
            "/seguridad/api/v1/sesion", new { usuario = "cliente.demo", clave = "x" }, Cancelacion);

        var llegada = await respuesta.Content.ReadFromJsonAsync<RespuestaFalsa>(Cancelacion);
        Assert.Equal(HttpStatusCode.OK, respuesta.StatusCode);
        Assert.Equal("/api/v1/sesion", llegada!.Ruta);
    }

    [Fact]
    public async Task Sin_token_responde_401_y_no_llega_al_servicio()
    {
        var antes = fabrica.Servicio.Llamadas;

        var respuesta = await fabrica.CreateClient().GetAsync("/__SERVICIO__/api/v1/quien-soy", Cancelacion);

        Assert.Equal(HttpStatusCode.Unauthorized, respuesta.StatusCode);
        Assert.Equal(antes, fabrica.Servicio.Llamadas);
    }

    [Fact]
    public async Task Con_token_llega_al_servicio_con_el_mismo_token()
    {
        var token = fabrica.CrearToken("cliente.demo");
        var cliente = fabrica.CreateClient();
        cliente.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", token);

        var llegada = await cliente.GetFromJsonAsync<RespuestaFalsa>("/__SERVICIO__/api/v1/quien-soy", Cancelacion);

        Assert.Equal("/api/v1/quien-soy", llegada!.Ruta);
        // El servicio recibe el token para validarlo otra vez (defensa en profundidad).
        Assert.Equal($"Bearer {token}", llegada.Autorizacion);
    }

    [Fact]
    public async Task Un_token_firmado_por_otro_responde_401()
    {
        var cliente = fabrica.CreateClient();
        var llaveAjena = new RsaSecurityKey(RSA.Create(2048)) { KeyId = "pruebas" };
        cliente.DefaultRequestHeaders.Authorization =
            new AuthenticationHeaderValue("Bearer", fabrica.CrearToken("intruso", llaveAjena));

        var respuesta = await cliente.GetAsync("/__SERVICIO__/api/v1/quien-soy", Cancelacion);

        Assert.Equal(HttpStatusCode.Unauthorized, respuesta.StatusCode);
    }

    [Theory]
    [InlineData("/seguridad/scalar")]
    [InlineData("/seguridad/salud")]
    [InlineData("/__SERVICIO__/salud")]
    [InlineData("/otro-servicio/api/v1/algo")]
    public async Task Lo_que_no_se_publica_responde_404(string ruta)
    {
        var respuesta = await fabrica.CreateClient().GetAsync(ruta, Cancelacion);

        Assert.Equal(HttpStatusCode.NotFound, respuesta.StatusCode);
    }
}

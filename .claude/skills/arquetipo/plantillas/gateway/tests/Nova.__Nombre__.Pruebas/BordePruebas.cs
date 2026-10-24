using System.Net;
using System.Text;

namespace Nova.__Nombre__.Pruebas;

/// <summary>Lo que protege la puerta: CORS, límite de intentos, cabeceras y salud.</summary>
public sealed class BordePruebas(FabricaGateway fabrica)
{
    private static CancellationToken Cancelacion => TestContext.Current.CancellationToken;

    [Fact]
    public async Task Cors_deja_pasar_a_la_web()
    {
        var respuesta = await PreguntarCors(FabricaGateway.OrigenWeb);

        Assert.Equal(FabricaGateway.OrigenWeb, respuesta.Headers.GetValues("Access-Control-Allow-Origin").Single());
    }

    [Fact]
    public async Task Cors_no_deja_pasar_a_otro_sitio()
    {
        var respuesta = await PreguntarCors("https://sitio-ajeno.example");

        Assert.False(respuesta.Headers.Contains("Access-Control-Allow-Origin"));
    }

    [Fact]
    public async Task El_sexto_intento_de_login_en_un_minuto_responde_429()
    {
        var estados = new List<HttpStatusCode>();
        for (var intento = 1; intento <= 6; intento++)
        {
            // IP propia de esta prueba, para no gastar los intentos de las demás.
            var contexto = await fabrica.Server.SendAsync(http =>
            {
                http.Request.Method = "POST";
                http.Request.Path = "/seguridad/api/v1/sesion";
                http.Request.ContentType = "application/json";
                http.Request.Body = new MemoryStream(Encoding.UTF8.GetBytes("""{"usuario":"x","clave":"x"}"""));
                http.Connection.RemoteIpAddress = IPAddress.IPv6Loopback;
            }, Cancelacion);
            estados.Add((HttpStatusCode)contexto.Response.StatusCode);
        }

        Assert.All(estados.Take(5), estado => Assert.Equal(HttpStatusCode.OK, estado));
        Assert.Equal(HttpStatusCode.TooManyRequests, estados[5]);
    }

    [Fact]
    public async Task Responde_con_cabeceras_de_seguridad()
    {
        var respuesta = await fabrica.CreateClient().GetAsync("/salud", Cancelacion);

        Assert.Equal("nosniff", respuesta.Headers.GetValues("X-Content-Type-Options").Single());
        Assert.Equal("DENY", respuesta.Headers.GetValues("X-Frame-Options").Single());
    }

    [Fact]
    public async Task Salud_pregunta_a_cada_servicio()
    {
        var respuesta = await fabrica.CreateClient().GetAsync("/salud", Cancelacion);

        Assert.Equal(HttpStatusCode.OK, respuesta.StatusCode);
        Assert.Equal("Healthy", await respuesta.Content.ReadAsStringAsync(Cancelacion));
    }

    private Task<HttpResponseMessage> PreguntarCors(string origen)
    {
        var pregunta = new HttpRequestMessage(HttpMethod.Options, "/__SERVICIO__/api/v1/quien-soy");
        pregunta.Headers.Add("Origin", origen);
        pregunta.Headers.Add("Access-Control-Request-Method", "GET");
        pregunta.Headers.Add("Access-Control-Request-Headers", "authorization");
        return fabrica.CreateClient().SendAsync(pregunta, Cancelacion);
    }
}

using System.Net;

namespace Nova.__Nombre__.Pruebas.Integracion;

public sealed class SaludPruebas(FabricaApi fabrica)
{
    [Fact]
    public async Task La_api_responde_y_llega_a_su_base()
    {
        var respuesta = await fabrica.CreateClient().GetAsync("/salud", TestContext.Current.CancellationToken);

        Assert.Equal(HttpStatusCode.OK, respuesta.StatusCode);
        Assert.Equal("Healthy", await respuesta.Content.ReadAsStringAsync(TestContext.Current.CancellationToken));
    }

    [Fact]
    public async Task Las_respuestas_llevan_cabeceras_de_seguridad()
    {
        var respuesta = await fabrica.CreateClient().GetAsync("/salud", TestContext.Current.CancellationToken);

        Assert.Equal("nosniff", respuesta.Headers.GetValues("X-Content-Type-Options").Single());
        Assert.Equal("DENY", respuesta.Headers.GetValues("X-Frame-Options").Single());
    }
}

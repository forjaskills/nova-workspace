using System.Net;
using System.Net.Http.Headers;
using System.Net.Http.Json;
using System.Security.Cryptography;
using Microsoft.IdentityModel.Tokens;
using Nova.__Nombre__.Adaptadores.Controladores;

namespace Nova.__Nombre__.Pruebas.Integracion;

public sealed class QuienSoyPruebas(FabricaApi fabrica)
{
    private static CancellationToken Cancelacion => TestContext.Current.CancellationToken;

    [Fact]
    public async Task Sin_token_responde_401()
    {
        var respuesta = await fabrica.CreateClient().GetAsync("/api/v1/quien-soy", Cancelacion);

        Assert.Equal(HttpStatusCode.Unauthorized, respuesta.StatusCode);
    }

    [Fact]
    public async Task Con_token_valido_devuelve_quien_eres()
    {
        var cliente = fabrica.CreateClient();
        cliente.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue(
            "Bearer", fabrica.CrearToken("cliente.demo", ["cliente"], ["__nombre__.leer"]));

        var quienSoy = await cliente.GetFromJsonAsync<QuienSoyRespuesta>("/api/v1/quien-soy", Cancelacion);

        Assert.Equal("cliente.demo", quienSoy!.Usuario);
        Assert.Equal(["cliente"], quienSoy.Roles);
        Assert.Equal(["__nombre__.leer"], quienSoy.Scopes);
    }

    [Fact]
    public async Task Un_token_firmado_por_otro_responde_401()
    {
        var cliente = fabrica.CreateClient();
        var llaveAjena = new RsaSecurityKey(RSA.Create(2048)) { KeyId = "pruebas" };
        cliente.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue(
            "Bearer", fabrica.CrearToken("intruso", ["admin"], [], llaveAjena));

        var respuesta = await cliente.GetAsync("/api/v1/quien-soy", Cancelacion);

        Assert.Equal(HttpStatusCode.Unauthorized, respuesta.StatusCode);
    }
}

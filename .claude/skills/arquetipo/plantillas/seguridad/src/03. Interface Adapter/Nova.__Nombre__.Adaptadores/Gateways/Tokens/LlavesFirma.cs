using System.Security.Cryptography;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Options;
using Microsoft.IdentityModel.Tokens;

namespace Nova.__Nombre__.Adaptadores.Gateways.Tokens;

/// <summary>
/// Llave RSA con la que se firman los tokens: una por ambiente, guardada fuera del repositorio
/// y creada al primer arranque. Solo la parte pública sale de aquí (/.well-known/jwks.json).
/// </summary>
public sealed class LlavesFirma : IDisposable
{
    private readonly RSA _rsa = RSA.Create();

    public LlavesFirma(IOptions<OpcionesTokens> opciones, IHostEnvironment ambiente)
    {
        var carpeta = string.IsNullOrWhiteSpace(opciones.Value.CarpetaLlaves)
            ? Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData), "nova", "llaves")
            : Environment.ExpandEnvironmentVariables(opciones.Value.CarpetaLlaves);
        Directory.CreateDirectory(carpeta);

        var archivo = Path.Combine(carpeta, $"nova-seguridad-{ambiente.EnvironmentName}.pem");
        if (File.Exists(archivo))
        {
            _rsa.ImportFromPem(File.ReadAllText(archivo));
        }
        else
        {
            _rsa.KeySize = 2048;
            File.WriteAllText(archivo, _rsa.ExportRSAPrivateKeyPem());
        }

        var publica = _rsa.ExportParameters(includePrivateParameters: false);
        var idLlave = Base64UrlEncoder.Encode(
            JsonWebKeyConverter.ConvertFromRSASecurityKey(new RsaSecurityKey(publica)).ComputeJwkThumbprint());
        LlavePrivada = new RsaSecurityKey(_rsa) { KeyId = idLlave };
        LlavePublica = new RsaSecurityKey(publica) { KeyId = idLlave };
    }

    public RsaSecurityKey LlavePrivada { get; }

    public RsaSecurityKey LlavePublica { get; }

    /// <summary>La llave pública en formato JWK, como la piden los validadores de JWT.</summary>
    public object LlavePublicaJwk()
    {
        var parametros = LlavePublica.Parameters;
        return new
        {
            kty = "RSA",
            use = "sig",
            alg = SecurityAlgorithms.RsaSha256,
            kid = LlavePublica.KeyId,
            n = Base64UrlEncoder.Encode(parametros.Modulus),
            e = Base64UrlEncoder.Encode(parametros.Exponent),
        };
    }

    public void Dispose() => _rsa.Dispose();
}

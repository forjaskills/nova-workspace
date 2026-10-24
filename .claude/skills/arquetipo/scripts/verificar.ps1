<#
.SYNOPSIS
  Verifica un proyecto creado por el arquetipo y termina con una tabla ✅/❌ (código de salida 0 solo
  si todo está en verde). Cada tipo tiene su tabla:
    seguridad · servicio : compila, pruebas, base, arranca, login / acepta el JWT, repo
    gateway              : compila, pruebas, arranca, enruta, protege, CORS y límites, repo
    web                  : dependencias, compila, pruebas, arranca, de punta a punta en un navegador, repo
.EXAMPLE
  .\verificar.ps1 -Nombre seguridad
  .\verificar.ps1 -Nombre pedidos
  .\verificar.ps1 -Nombre gateway
  .\verificar.ps1 -Nombre web
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][string]$Nombre,
    [string]$Espacio
)
# En PowerShell 5.1, $PSScriptRoot está vacío dentro de param(): el valor por defecto se calcula aquí.
if (-not $Espacio) { $Espacio = (Resolve-Path (Join-Path $PSScriptRoot '..\..\..\..')).Path }
# Continue: en PowerShell 5.1, con Stop cualquier línea de stderr de dotnet/npm/git/gh se vuelve excepción.
# Los errores se juzgan por el código de salida de cada comando.
$ErrorActionPreference = 'Continue'
[Console]::OutputEncoding = [Text.Encoding]::UTF8
$utf8 = New-Object Text.UTF8Encoding $false

$registro = @([IO.File]::ReadAllText((Join-Path $Espacio 'proyectos.json'), $utf8) | ConvertFrom-Json)
$registro = @($registro | ForEach-Object { $_ })
$proyecto = $registro | Where-Object { $_.nombre -eq "nova-$Nombre" } | Select-Object -First 1
if (-not $proyecto) { throw "nova-$Nombre no está en proyectos.json. Primero: scripts\generar.ps1" }
$carpeta = Join-Path $Espacio $proyecto.carpeta

$resultados = New-Object System.Collections.Generic.List[object]
$procesos = New-Object System.Collections.Generic.List[System.Diagnostics.Process]

function Anotar([string]$Numero, [string]$Chequeo, [string]$Estado, [string]$Detalle) {
    $icono = @{ ok = '✅'; falla = '❌'; omitido = '⏭' }[$Estado]
    $resultados.Add([pscustomobject]@{ '#' = $Numero; Chequeo = $Chequeo; ' ' = $icono; Detalle = $Detalle })
    Write-Host "$icono $Numero. $Chequeo — $Detalle"
}

function Llamar([string]$Metodo, [string]$Url, [string]$Cuerpo, [string]$Token, [hashtable]$Cabeceras) {
    $parametros = @{ Uri = $Url; Method = $Metodo; Headers = @{}; UseBasicParsing = $true; TimeoutSec = 15 }
    if ($Token) { $parametros.Headers.Authorization = "Bearer $Token" }
    if ($Cabeceras) { foreach ($c in $Cabeceras.Keys) { $parametros.Headers[$c] = $Cabeceras[$c] } }
    # Un GET con cuerpo (aunque sea vacío) falla en PowerShell 5.1: el cuerpo va solo si hay.
    if ($Cuerpo) { $parametros.Body = $Cuerpo; $parametros.ContentType = 'application/json' }
    try {
        $r = Invoke-WebRequest @parametros
        return [pscustomobject]@{ Estado = [int]$r.StatusCode; Cuerpo = $r.Content; Cabeceras = $r.Headers }
    }
    catch {
        $respuesta = $_.Exception.Response
        if ($respuesta) { return [pscustomobject]@{ Estado = [int]$respuesta.StatusCode; Cuerpo = ''; Cabeceras = $respuesta.Headers } }
        return [pscustomobject]@{ Estado = 0; Cuerpo = $_.Exception.Message; Cabeceras = @{} }
    }
}

function Login([string]$Url, [string]$Usuario, [string]$Clave) {
    $cuerpo = @{ usuario = $Usuario; clave = $Clave } | ConvertTo-Json -Compress
    return Llamar 'POST' $Url $cuerpo $null
}

function TokenDe($Respuesta) {
    if ($Respuesta.Estado -eq 200) { return ($Respuesta.Cuerpo | ConvertFrom-Json).tokenAcceso }
    return ''
}

function Migrar([string]$Carpeta) {
    Push-Location $Carpeta
    try { $salida = & dotnet run --project tools/Migrador --no-build -- --ambiente DEV 2>&1 | Out-String }
    finally { Pop-Location }
    return [pscustomobject]@{ Ok = ($LASTEXITCODE -eq 0); Salida = $salida }
}

function Pascal([string]$Texto) { return $Texto.Substring(0, 1).ToUpperInvariant() + $Texto.Substring(1) }

# Levanta la Api ya compilada en su puerto DEV. Devuelve $null si arrancó, o el motivo si no.
function Levantar($Proyecto) {
    $puerto = $Proyecto.puertos.DEV
    if ((Llamar 'GET' "http://localhost:$puerto/salud").Estado -ne 0) {
        return "el puerto $puerto ya está en uso: cierra lo que esté corriendo ahí"
    }
    $p = Pascal $Proyecto.nombre.Substring(5)
    # El gateway no tiene capas: su Api está directo en src/.
    $api = if ($Proyecto.tipo -eq 'gateway') { "src\Nova.$p.Api" } else { "src\04. Framework and Driver\Nova.$p.Api" }
    $bin = Join-Path $Espacio "$($Proyecto.carpeta)\$api\bin\Debug\net10.0"
    $log = Join-Path $env:TEMP "$($Proyecto.nombre)-verificar.log"
    $env:ASPNETCORE_ENVIRONMENT = 'Development'
    $env:ASPNETCORE_URLS = "http://localhost:$puerto"
    try {
        $proceso = Start-Process -FilePath 'dotnet' -ArgumentList "`"Nova.$p.Api.dll`"" -WorkingDirectory $bin `
            -RedirectStandardOutput $log -RedirectStandardError "$log.err" -WindowStyle Hidden -PassThru
    }
    finally {
        Remove-Item Env:ASPNETCORE_ENVIRONMENT, Env:ASPNETCORE_URLS -ErrorAction SilentlyContinue
    }
    $procesos.Add($proceso)
    for ($i = 0; $i -lt 60; $i++) {
        Start-Sleep -Milliseconds 500
        $salud = Llamar 'GET' "http://localhost:$puerto/salud"
        if ($salud.Estado -eq 200) { return $null }
        if ($proceso.HasExited) { return "se cerró al arrancar (ver $log)" }
    }
    return "no respondió /salud en 30 s (ver $log)"
}

# Deja corriendo en DEV otro proyecto del espacio de trabajo (si no lo está): compila, migra y levanta.
# Devuelve $null si quedó arriba, o el motivo si no.
function Encender($Otro) {
    if ((Llamar 'GET' "http://localhost:$($Otro.puertos.DEV)/salud").Estado -eq 200) { return $null }
    $carpetaOtro = Join-Path $Espacio $Otro.carpeta
    & dotnet build $carpetaOtro --nologo -v q 2>&1 | Out-Null
    if ($LASTEXITCODE -ne 0) { return "$($Otro.nombre): no compila" }
    if ($Otro.tipo -in 'seguridad', 'servicio' -and -not (Migrar $carpetaOtro).Ok) { return "$($Otro.nombre): no pude preparar su base" }
    $motivo = Levantar $Otro
    if ($motivo) { return "$($Otro.nombre): $motivo" }
    return $null
}

function EncenderVarios($Lista) {
    foreach ($otro in $Lista) {
        $motivo = Encender $otro
        if ($motivo) { return $motivo }
    }
    return $null
}

# Filas 1 y 2 de los proyectos .NET. Devuelve si compiló.
function CompilarYProbar {
    $build = & dotnet build --nologo 2>&1 | Out-String
    $advertencias = if ($build -match '(\d+) (Advertencia|Warning)') { [int]$Matches[1] } else { 0 }
    $compila = $LASTEXITCODE -eq 0
    if ($compila -and $advertencias -eq 0) { Anotar 1 'Compila' 'ok' 'sin errores ni advertencias' }
    elseif ($compila) { Anotar 1 'Compila' 'falla' "$advertencias advertencia(s)" }
    else { Anotar 1 'Compila' 'falla' (($build -split "`n" | Where-Object { $_ -match 'error' } | Select-Object -First 3) -join ' | ') }
    if (-not $compila) { return $false }

    $titulo = if ($proyecto.tipo -eq 'gateway') { 'Pruebas: rutas, token, CORS y límites' } else { 'Pruebas: unitarias, integración y arquitectura' }
    $pruebas = & dotnet test --no-build 2>&1 | Out-String
    $total = if ($pruebas -match 'total:\s*(\d+)') { $Matches[1] } else { '?' }
    $correctas = if ($pruebas -match '(correcto|succeeded):\s*(\d+)') { $Matches[2] } else { '0' }
    if ($LASTEXITCODE -eq 0) { Anotar 2 $titulo 'ok' "$correctas/$total en verde" }
    else {
        $fallidas = ($pruebas -split "`n" | Where-Object { $_ -match 'con errores|failed' } | Select-Object -First 3) -join ' | '
        Anotar 2 $titulo 'falla' "$correctas/$total · $fallidas"
    }
    return $true
}

function VerificarRepo([string]$Numero) {
    $remoto = if (Test-Path (Join-Path $carpeta '.git')) { & git -C $carpeta remote get-url origin 2>$null } else { $null }
    if (-not $remoto) { Anotar $Numero 'Repo en GitHub' 'omitido' 'aún sin repo (scripts\crear-repo.ps1)'; return }
    $repo = ($remoto -replace '^.*github\.com[:/]', '' -replace '\.git$', '')
    $ramas = @(& gh api "repos/$repo/branches" --jq '.[].name' 2>$null)
    $faltan = @('main', 'develop', 'qa' | Where-Object { $ramas -notcontains $_ })
    & gh api "repos/$repo/branches/main/protection" --silent 2>$null
    $protegida = $LASTEXITCODE -eq 0
    if ($faltan.Count -eq 0 -and $protegida) { Anotar $Numero 'Repo en GitHub' 'ok' "$repo · main, develop, qa · main y develop protegidas" }
    elseif ($faltan.Count -eq 0) { Anotar $Numero 'Repo en GitHub' 'falla' "$repo · ramas ok, pero main no está protegida" }
    else { Anotar $Numero 'Repo en GitHub' 'falla' "$repo · faltan ramas: $($faltan -join ', ')" }
}

function Alterar([string]$Token) {
    # Se cambia un carácter de la firma.
    if (-not $Token) { return 'x' }
    $cambio = if ($Token[-2] -eq 'A') { 'B' } else { 'A' }
    return $Token.Substring(0, $Token.Length - 2) + $cambio + $Token[-1]
}

$seg = $registro | Where-Object { $_.tipo -eq 'seguridad' } | Select-Object -First 1
$servicios = @($registro | Where-Object { $_.tipo -eq 'servicio' })
$gateway = $registro | Where-Object { $_.tipo -eq 'gateway' } | Select-Object -First 1

# ==================================================================================================
function VerificarBackend {
    if (-not (CompilarYProbar)) {
        foreach ($n in 3..6) { Anotar $n '(no se probó)' 'omitido' 'primero tiene que compilar' }
        return
    }

    # 3. Migrador DEV, dos veces (la segunda no debe hacer nada) --------------------------------
    $primera = Migrar $carpeta
    $segunda = Migrar $carpeta
    if ($primera.Ok -and $segunda.Ok -and $segunda.Salida -match '0 scripts aplicados') {
        $aplicados = if ($primera.Salida -match '(\d+) script\(s\)') { $Matches[1] } else { '0' }
        Anotar 3 'Base DEV con el Migrador' 'ok' "$aplicados script(s) nuevos; 2.ª pasada: 0 (idempotente)"
    }
    else { Anotar 3 'Base DEV con el Migrador' 'falla' ((($primera.Salida + $segunda.Salida) -split "`n" | Where-Object { $_ -match 'Error' } | Select-Object -First 2) -join ' | ') }

    # 4. Arranca y responde ---------------------------------------------------------------------
    $motivo = Levantar $proyecto
    $puerto = $proyecto.puertos.DEV
    if ($motivo) { Anotar 4 "Arranca en :$puerto y /salud" 'falla' $motivo }
    else { Anotar 4 "Arranca en :$puerto y /salud" 'ok' 'Healthy (llega a su base)' }

    if ($proyecto.tipo -eq 'seguridad') {
        # 5. Login, clave mala y límite de intentos -------------------------------------------------
        if ($motivo) { Anotar 5 'Login' 'omitido' 'la API no arrancó' }
        else {
            $url = "http://localhost:$puerto/api/v1/sesion"
            $ok = Login $url 'cliente.demo' 'NovaDemo#1'
            $token = TokenDe $ok
            $mala = Login $url 'cliente.demo' 'clave-equivocada'
            $intento = 2
            $limite = 0
            while ($intento -lt 6) {
                $intento++
                $limite = (Login $url 'cliente.demo' 'clave-equivocada').Estado
                if ($limite -eq 429) { break }
            }
            if ($ok.Estado -eq 200 -and $token -and $mala.Estado -eq 401 -and $limite -eq 429) {
                Anotar 5 'Login' 'ok' "cliente.demo → 200 con JWT · clave mala → 401 · intento $intento en 1 min → 429"
            }
            else { Anotar 5 'Login' 'falla' "login $($ok.Estado) · clave mala $($mala.Estado) · intento $intento → $limite" }
        }
        Anotar 6 'Acepta el JWT de Seguridad' 'omitido' 'aplica a servicios'
        return
    }

    Anotar 5 'Login' 'omitido' 'aplica a seguridad'
    # 6. Acepta el token de Seguridad (lo pide de verdad: enciende Seguridad si hace falta) -----
    $detalleSeg = $null
    if ($motivo) { $detalleSeg = 'la API no arrancó' }
    elseif (-not $seg) { $detalleSeg = 'no hay proyecto de seguridad registrado' }
    else { $detalleSeg = Encender $seg }
    if ($detalleSeg) { Anotar 6 'Acepta el JWT de Seguridad' 'falla' $detalleSeg; return }

    $token = TokenDe (Login "http://localhost:$($seg.puertos.DEV)/api/v1/sesion" 'cliente.demo' 'NovaDemo#1')
    $url = "http://localhost:$puerto/api/v1/quien-soy"
    $sinToken = Llamar 'GET' $url $null $null
    $conToken = Llamar 'GET' $url $null $token
    $conAlterado = Llamar 'GET' $url $null (Alterar $token)
    $usuario = if ($conToken.Estado -eq 200) { ($conToken.Cuerpo | ConvertFrom-Json).usuario } else { '' }
    if ($sinToken.Estado -eq 401 -and $conToken.Estado -eq 200 -and $usuario -eq 'cliente.demo' -and $conAlterado.Estado -eq 401) {
        Anotar 6 'Acepta el JWT de Seguridad' 'ok' 'sin token → 401 · token de Seguridad → 200 (cliente.demo) · alterado → 401'
    }
    else { Anotar 6 'Acepta el JWT de Seguridad' 'falla' "token $(if ($token) { 'sí' } else { 'no' }) · sin token $($sinToken.Estado) · con token $($conToken.Estado) · alterado $($conAlterado.Estado)" }
}

# ==================================================================================================
function VerificarGateway {
    if (-not (CompilarYProbar)) {
        foreach ($n in 3..7) { Anotar $n '(no se probó)' 'omitido' 'primero tiene que compilar' }
        return
    }
    Anotar 3 'Base de datos' 'omitido' 'el gateway no tiene base'

    # 4. Arranca y ve a cada servicio (se encienden antes, para que /salud diga Healthy) ------------
    $puerto = $proyecto.puertos.DEV
    $base = "http://localhost:$puerto"
    $motivo = EncenderVarios (@($seg) + $servicios)
    if (-not $motivo) { $motivo = Levantar $proyecto }
    if ($motivo) {
        Anotar 4 "Arranca en :$puerto y /salud" 'falla' $motivo
        foreach ($n in 5..7) { Anotar $n '(no se probó)' 'omitido' 'el gateway no arrancó' }
        return
    }
    $salud = Llamar 'GET' "$base/salud"
    if ($salud.Cuerpo -eq 'Healthy') { Anotar 4 "Arranca en :$puerto y /salud" 'ok' "Healthy (responden nova-seguridad y $($servicios.Count) servicio(s))" }
    else { Anotar 4 "Arranca en :$puerto y /salud" 'falla' "$($salud.Cuerpo) (¿algún servicio apagado?)" }

    # 5. El login pasa por el gateway hasta Seguridad ---------------------------------------------
    $urlLogin = "$base/seguridad/api/v1/sesion"
    $login = Login $urlLogin 'cliente.demo' 'NovaDemo#1'
    $token = TokenDe $login
    if ($token) { Anotar 5 'Enruta a Seguridad' 'ok' "POST /seguridad/api/v1/sesion → 200 con JWT" }
    else { Anotar 5 'Enruta a Seguridad' 'falla' "POST /seguridad/api/v1/sesion → $($login.Estado)" }

    # 6. El servicio solo se alcanza con un token válido ------------------------------------------
    $n = $servicios[0].nombre.Substring(5)
    $url = "$base/$n/api/v1/quien-soy"
    $sinToken = Llamar 'GET' $url $null $null
    $conToken = Llamar 'GET' $url $null $token
    $conAlterado = Llamar 'GET' $url $null (Alterar $token)
    $usuario = if ($conToken.Estado -eq 200) { ($conToken.Cuerpo | ConvertFrom-Json).usuario } else { '' }
    if ($sinToken.Estado -eq 401 -and $conToken.Estado -eq 200 -and $usuario -eq 'cliente.demo' -and $conAlterado.Estado -eq 401) {
        Anotar 6 "Protege /$n" 'ok' "sin token → 401 · con token → 200 (cliente.demo, desde nova-$n) · alterado → 401"
    }
    else { Anotar 6 "Protege /$n" 'falla' "sin token $($sinToken.Estado) · con token $($conToken.Estado) · alterado $($conAlterado.Estado)" }

    # 7. CORS y límite de intentos de login --------------------------------------------------------
    # La web tiene su bloque fijo (30): en DEV, el puerto 3001.
    $origenWeb = "http://localhost:$(30 * 100 + 1)"
    $pregunta = @{ 'Origin' = $origenWeb; 'Access-Control-Request-Method' = 'GET'; 'Access-Control-Request-Headers' = 'authorization' }
    $corsWeb = Llamar 'OPTIONS' $url $null $null $pregunta
    $pregunta.Origin = 'https://sitio-ajeno.example'
    $corsAjeno = Llamar 'OPTIONS' $url $null $null $pregunta
    $webPasa = "$($corsWeb.Cabeceras['Access-Control-Allow-Origin'])" -eq $origenWeb
    $ajenoPasa = [bool]"$($corsAjeno.Cabeceras['Access-Control-Allow-Origin'])"
    $intento = 1
    $limite = 0
    while ($intento -lt 7) {
        $intento++
        $limite = (Login $urlLogin 'cliente.demo' 'clave-equivocada').Estado
        if ($limite -eq 429) { break }
    }
    if ($webPasa -and -not $ajenoPasa -and $limite -eq 429) {
        Anotar 7 'CORS y límites' 'ok' "CORS: $origenWeb sí · otro sitio no · login: intento $intento en 1 min → 429"
    }
    else { Anotar 7 'CORS y límites' 'falla' "CORS web $(if ($webPasa) { 'sí' } else { 'no' }) · otro sitio $(if ($ajenoPasa) { 'sí' } else { 'no' }) · intento $intento → $limite" }
}

# ==================================================================================================
function Npm([string]$Argumentos) {
    # Sin colores: en algunas consolas Vitest y Playwright imprimen códigos ANSI («[32m7 passed») y la tabla
    # leía «0 en verde» aunque las pruebas pasaran (pasó en la MV). Se pide sin color y se limpia lo que quede.
    $env:NO_COLOR = '1'; $env:FORCE_COLOR = '0'
    try { $salida = & cmd /c "npm $Argumentos 2>&1" | Out-String }
    finally { Remove-Item Env:NO_COLOR, Env:FORCE_COLOR -ErrorAction SilentlyContinue }
    $codigo = $LASTEXITCODE
    $salida = $salida -replace "$([char]27)\[[0-9;]*[A-Za-z]", ''
    return [pscustomobject]@{ Ok = ($codigo -eq 0); Salida = $salida }
}

function LevantarWeb {
    $puerto = $proyecto.puertos.DEV
    if ((Llamar 'GET' "http://localhost:$puerto/login").Estado -ne 0) {
        return "el puerto $puerto ya está en uso: cierra lo que esté corriendo ahí"
    }
    $log = Join-Path $env:TEMP "$($proyecto.nombre)-verificar.log"
    # La compilación de producción, apuntando al gateway de DEV.
    $env:NOVA_GATEWAY_URL = "http://localhost:$($gateway.puertos.DEV)"
    try {
        $proceso = Start-Process -FilePath 'node' -ArgumentList 'node_modules/next/dist/bin/next', 'start', '--port', "$puerto" `
            -WorkingDirectory $carpeta -RedirectStandardOutput $log -RedirectStandardError "$log.err" -WindowStyle Hidden -PassThru
    }
    finally { Remove-Item Env:NOVA_GATEWAY_URL -ErrorAction SilentlyContinue }
    $procesos.Add($proceso)
    for ($i = 0; $i -lt 60; $i++) {
        Start-Sleep -Milliseconds 500
        if ((Llamar 'GET' "http://localhost:$puerto/login").Estado -eq 200) { return $null }
        if ($proceso.HasExited) { return "se cerró al arrancar (ver $log)" }
    }
    return "no respondió /login en 30 s (ver $log)"
}

function VerificarWeb {
    $env:NEXT_TELEMETRY_DISABLED = '1'

    # 1. Dependencias exactas del package-lock y sin vulnerabilidades altas -----------------------
    $ci = Npm 'ci --no-audit --no-fund'
    if (-not $ci.Ok) {
        Anotar 1 'Dependencias' 'falla' (($ci.Salida -split "`n" | Where-Object { $_ -match 'ERR' } | Select-Object -First 2) -join ' | ')
        foreach ($n in 2..5) { Anotar $n '(no se probó)' 'omitido' 'primero tienen que instalarse las dependencias' }
        return
    }
    # La compuerta es lo que llega a producción. Lo de desarrollo (lint, pruebas) no se despliega:
    # se informa con nombre para vigilarlo, pero no detiene el proyecto.
    $prod = try { ((Npm 'audit --omit=dev --json').Salida | ConvertFrom-Json).metadata.vulnerabilities } catch { $null }
    $todo = try { (Npm 'audit --json').Salida | ConvertFrom-Json } catch { $null }
    $deDesarrollo = if ($todo) {
        @($todo.vulnerabilities.PSObject.Properties | Where-Object { $_.Value.severity -in 'high', 'critical' -and @($_.Value.via | Where-Object { $_ -isnot [string] }).Count -gt 0 } |
            ForEach-Object { $_.Name })
    } else { @() }
    $notaDesarrollo = if ($deDesarrollo.Count -gt 0) { " · desarrollo: $($todo.metadata.vulnerabilities.high + $todo.metadata.vulnerabilities.critical) alta(s) por $($deDesarrollo -join ', ') (solo lint, sin parche publicado: vigilar)" } else { ' · desarrollo: 0' }
    $navegador = Npm 'exec -- playwright install chromium'
    if (-not $prod) { Anotar 1 'Dependencias' 'falla' 'npm audit no respondió' }
    elseif ($prod.high + $prod.critical -gt 0) { Anotar 1 'Dependencias' 'falla' "npm audit (producción): $($prod.critical) crítica(s) · $($prod.high) alta(s)" }
    elseif (-not $navegador.Ok) { Anotar 1 'Dependencias' 'falla' 'no se pudo instalar el navegador de Playwright' }
    else { Anotar 1 'Dependencias' 'ok' "npm ci · audit de producción: 0 altas o críticas$notaDesarrollo · Chromium listo" }

    # 2. Compila (TypeScript incluido) y lint sin advertencias -------------------------------------
    $build = Npm 'run build'
    $lint = Npm 'run lint'
    $avisos = @($build.Salida -split "`n" | Where-Object { $_ -match '^\s*⚠' -and $_ -notmatch 'telemetry' }).Count
    if ($build.Ok -and $lint.Ok -and $avisos -eq 0) { Anotar 2 'Compila' 'ok' 'next build + TypeScript + lint: sin errores ni advertencias' }
    else {
        $detalle = (($build.Salida + $lint.Salida) -split "`n" | Where-Object { $_ -match 'rror|⚠|warning' } | Select-Object -First 3) -join ' | '
        Anotar 2 'Compila' 'falla' $detalle
        if (-not $build.Ok) { foreach ($n in 3..5) { Anotar $n '(no se probó)' 'omitido' 'primero tiene que compilar' }; return }
    }

    # 3. Pruebas unitarias ----------------------------------------------------------------------
    $unit = Npm 'test'
    $pasadas = if ($unit.Salida -match 'Tests\s+(\d+) passed') { $Matches[1] } else { '0' }
    if ($unit.Ok) { Anotar 3 'Pruebas unitarias (Vitest)' 'ok' "$pasadas en verde" }
    else { Anotar 3 'Pruebas unitarias (Vitest)' 'falla' (($unit.Salida -split "`n" | Where-Object { $_ -match 'FAIL|failed' } | Select-Object -First 3) -join ' | ') }

    # 4. Arranca, con todo lo que hay detrás encendido -------------------------------------------
    $puerto = $proyecto.puertos.DEV
    $motivo = $null
    if (-not $gateway) { $motivo = 'no hay gateway registrado' }
    else { $motivo = EncenderVarios (@($seg) + $servicios + @($gateway)) }
    if (-not $motivo) { $motivo = LevantarWeb }
    if ($motivo) {
        Anotar 4 "Arranca en :$puerto" 'falla' $motivo
        Anotar 5 'De punta a punta' 'omitido' 'la web no arrancó'
        return
    }
    Anotar 4 "Arranca en :$puerto" 'ok' "login responde · detrás: nova-gateway :$($gateway.puertos.DEV), nova-seguridad y $($servicios.Count) servicio(s)"

    # 5. En un navegador de verdad: inicia sesión y llega al servicio a través del gateway ---------
    # Antes, un login a través del gateway: con AUTO_CLOSE (lo trae SQL Server Express) la primera consulta
    # reabre la base y tardó 10 s; Playwright espera 5 y la web salía en rojo sin tener la culpa (pasó al verificar nova-web).
    # Gasta 1 de los 5 intentos por minuto del gateway; Playwright usa 3.
    $reloj = [Diagnostics.Stopwatch]::StartNew()
    $previo = Login "http://localhost:$($gateway.puertos.DEV)/seguridad/api/v1/sesion" 'cliente.demo' 'NovaDemo#1'
    $reloj.Stop()
    if ($previo.Estado -ne 200) {
        Anotar 5 'De punta a punta (Playwright)' 'falla' "el login a través del gateway respondió $($previo.Estado) antes de abrir el navegador (ver nova-seguridad-verificar.log en la carpeta TEMP)"
        return
    }
    $nota = if ($reloj.ElapsedMilliseconds -gt 3000) {
        " · ojo: el primer login tardó $([math]::Round($reloj.ElapsedMilliseconds / 1000, 1)) s (base fría: ¿AUTO_CLOSE activado? lo apaga el DBA)"
    } else { '' }
    $env:BASE_URL = "http://localhost:$puerto"
    try { $e2e = Npm 'run e2e' }
    finally { Remove-Item Env:BASE_URL -ErrorAction SilentlyContinue }
    $pasadas = if ($e2e.Salida -match '(\d+) passed') { $Matches[1] } else { '0' }
    if ($e2e.Ok) { Anotar 5 'De punta a punta (Playwright)' 'ok' "$pasadas en verde: login → $($servicios[0].nombre) por el gateway · clave mala → aviso · sin sesión → login · cerrar sesión$nota" }
    else { Anotar 5 'De punta a punta (Playwright)' 'falla' ((($e2e.Salida -split "`n" | Where-Object { $_ -match '✘|failed|Error:' } | Select-Object -First 3) -join ' | ') + $nota) }
}

# ==================================================================================================
Write-Host "Verificando $($proyecto.nombre) ($($proyecto.tipo))" -ForegroundColor Cyan
Push-Location $carpeta
try {
    switch ($proyecto.tipo) {
        'gateway' { VerificarGateway; VerificarRepo 8 }
        'web' { VerificarWeb; VerificarRepo 6 }
        default { VerificarBackend; VerificarRepo 7 }
    }
}
finally {
    Pop-Location
    # Solo se cierran los procesos que levantó esta verificación (con sus hijos: next start abre otro node).
    foreach ($p in $procesos) { if (-not $p.HasExited) { & taskkill /PID $p.Id /T /F *> $null } }
}

$resultados | Format-Table -AutoSize -Wrap | Out-String -Width 200 | Write-Host
$fallas = @($resultados | Where-Object { $_.' ' -eq '❌' }).Count
if ($fallas -eq 0) { Write-Host "Verificación de $($proyecto.nombre): todo en verde." -ForegroundColor Green; exit 0 }
Write-Host "Verificación de $($proyecto.nombre): $fallas chequeo(s) en rojo." -ForegroundColor Red
exit 1

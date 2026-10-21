<#
.SYNOPSIS
  Verifica un proyecto creado por el arquetipo y termina con una tabla ✅/❌ (código de salida 0 solo
  si todo está en verde). Cada tipo tiene su tabla:
    seguridad · servicio : compila, pruebas, base, arranca, login / acepta el JWT, repo
.EXAMPLE
  .\verificar.ps1 -Nombre seguridad
  .\verificar.ps1 -Nombre pedidos
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
    $api = "src\04. Framework and Driver\Nova.$p.Api"
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

# Filas 1 y 2 de los proyectos .NET. Devuelve si compiló.
function CompilarYProbar {
    $build = & dotnet build --nologo 2>&1 | Out-String
    $advertencias = if ($build -match '(\d+) (Advertencia|Warning)') { [int]$Matches[1] } else { 0 }
    $compila = $LASTEXITCODE -eq 0
    if ($compila -and $advertencias -eq 0) { Anotar 1 'Compila' 'ok' 'sin errores ni advertencias' }
    elseif ($compila) { Anotar 1 'Compila' 'falla' "$advertencias advertencia(s)" }
    else { Anotar 1 'Compila' 'falla' (($build -split "`n" | Where-Object { $_ -match 'error' } | Select-Object -First 3) -join ' | ') }
    if (-not $compila) { return $false }

    $titulo = 'Pruebas: unitarias, integración y arquitectura'
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
Write-Host "Verificando $($proyecto.nombre) ($($proyecto.tipo))" -ForegroundColor Cyan
Push-Location $carpeta
try {
    VerificarBackend
    VerificarRepo 7
}
finally {
    Pop-Location
    # Solo se cierran los procesos que levantó esta verificación (con sus hijos).
    foreach ($p in $procesos) { if (-not $p.HasExited) { & taskkill /PID $p.Id /T /F *> $null } }
}

$resultados | Format-Table -AutoSize -Wrap | Out-String -Width 200 | Write-Host
$fallas = @($resultados | Where-Object { $_.' ' -eq '❌' }).Count
if ($fallas -eq 0) { Write-Host "Verificación de $($proyecto.nombre): todo en verde." -ForegroundColor Green; exit 0 }
Write-Host "Verificación de $($proyecto.nombre): $fallas chequeo(s) en rojo." -ForegroundColor Red
exit 1

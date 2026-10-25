<#
.SYNOPSIS
  Verifica un módulo agregado con nuevo-modulo y termina con una tabla ✅/❌ (código de salida 0 solo si todo está
  en verde): compila, pruebas (con las de arquitectura), base, permisos, API por el gateway, web y rama.
.EXAMPLE
  .\verificar.ps1 -Servicio pedidos -Modulo pedidos
#>
[CmdletBinding()]
param(
    # El servicio que recibe el módulo (nombre de arquetipo: pedidos → proyectos/nova-pedidos).
    [Parameter(Mandatory = $true)][string]$Servicio,
    # El módulo en minúsculas y plural, como va en la ruta: pedidos → /api/v1/pedidos.
    [Parameter(Mandatory = $true)][string]$Modulo,
    [string]$Espacio
)
# En PowerShell 5.1, $PSScriptRoot está vacío dentro de param(): el valor por defecto se calcula aquí.
if (-not $Espacio) { $Espacio = (Resolve-Path (Join-Path $PSScriptRoot '..\..\..\..')).Path }
# Continue: en PowerShell 5.1, con Stop cualquier línea de stderr de dotnet/npm/git se vuelve excepción.
$ErrorActionPreference = 'Continue'
[Console]::OutputEncoding = [Text.Encoding]::UTF8
$utf8 = New-Object Text.UTF8Encoding $false

$registro = @([IO.File]::ReadAllText((Join-Path $Espacio 'proyectos.json'), $utf8) | ConvertFrom-Json)
$registro = @($registro | ForEach-Object { $_ })
$proyecto = $registro | Where-Object { $_.nombre -eq "nova-$Servicio" -and $_.tipo -eq 'servicio' } | Select-Object -First 1
if (-not $proyecto) { throw "nova-$Servicio no es un servicio registrado en proyectos.json." }
$seg = $registro | Where-Object { $_.tipo -eq 'seguridad' } | Select-Object -First 1
$gateway = $registro | Where-Object { $_.tipo -eq 'gateway' } | Select-Object -First 1
$web = $registro | Where-Object { $_.tipo -eq 'web' } | Select-Object -First 1
$carpeta = Join-Path $Espacio $proyecto.carpeta

$resultados = New-Object System.Collections.Generic.List[object]
$procesos = New-Object System.Collections.Generic.List[System.Diagnostics.Process]

function Anotar([string]$Numero, [string]$Chequeo, [string]$Estado, [string]$Detalle) {
    $icono = @{ ok = '✅'; falla = '❌'; omitido = '⏭' }[$Estado]
    $resultados.Add([pscustomobject]@{ '#' = $Numero; Chequeo = $Chequeo; ' ' = $icono; Detalle = $Detalle })
    Write-Host "$icono $Numero. $Chequeo — $Detalle"
}

function Llamar([string]$Metodo, [string]$Url, [string]$Cuerpo, [string]$Token) {
    $parametros = @{ Uri = $Url; Method = $Metodo; Headers = @{}; UseBasicParsing = $true; TimeoutSec = 30 }
    if ($Token) { $parametros.Headers.Authorization = "Bearer $Token" }
    # Un GET con cuerpo (aunque sea vacío) falla en PowerShell 5.1: el cuerpo va solo si hay.
    if ($Cuerpo) { $parametros.Body = [Text.Encoding]::UTF8.GetBytes($Cuerpo); $parametros.ContentType = 'application/json; charset=utf-8' }
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

function Token([string]$Url, [string]$Usuario) {
    $r = Llamar 'POST' $Url (@{ usuario = $Usuario; clave = 'NovaDemo#1' } | ConvertTo-Json -Compress) $null
    if ($r.Estado -eq 200) { return ($r.Cuerpo | ConvertFrom-Json).tokenAcceso }
    return ''
}

# Los scopes que trae un JWT (la parte del medio es JSON en base64url).
function ScopesDe([string]$Jwt) {
    if (-not $Jwt) { return @() }
    $medio = $Jwt.Split('.')[1].Replace('-', '+').Replace('_', '/')
    $medio += '=' * ((4 - $medio.Length % 4) % 4)
    $datos = [Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($medio)) | ConvertFrom-Json
    return @("$($datos.scope)".Split(' ', [StringSplitOptions]::RemoveEmptyEntries))
}

function Migrar([string]$Carpeta) {
    Push-Location $Carpeta
    try { $salida = & dotnet run --project tools/Migrador -- --ambiente DEV 2>&1 | Out-String }
    finally { Pop-Location }
    return [pscustomobject]@{ Ok = ($LASTEXITCODE -eq 0); Salida = $salida }
}

function Pascal([string]$Texto) { return $Texto.Substring(0, 1).ToUpperInvariant() + $Texto.Substring(1) }

# Levanta la Api ya compilada de un proyecto en su puerto DEV. Devuelve $null si arrancó, o el motivo si no.
function Levantar($Otro) {
    $puerto = $Otro.puertos.DEV
    if ((Llamar 'GET' "http://localhost:$puerto/salud").Estado -ne 0) { return "el puerto $puerto ya está en uso: cierra lo que esté corriendo ahí" }
    $p = Pascal $Otro.nombre.Substring(5)
    $api = if ($Otro.tipo -eq 'gateway') { "src\Nova.$p.Api" } else { "src\04. Framework and Driver\Nova.$p.Api" }
    $bin = Join-Path $Espacio "$($Otro.carpeta)\$api\bin\Debug\net10.0"
    $log = Join-Path $env:TEMP "$($Otro.nombre)-modulo.log"
    $env:ASPNETCORE_ENVIRONMENT = 'Development'
    $env:ASPNETCORE_URLS = "http://localhost:$puerto"
    try {
        $proceso = Start-Process -FilePath 'dotnet' -ArgumentList "`"Nova.$p.Api.dll`"" -WorkingDirectory $bin `
            -RedirectStandardOutput $log -RedirectStandardError "$log.err" -WindowStyle Hidden -PassThru
    }
    finally { Remove-Item Env:ASPNETCORE_ENVIRONMENT, Env:ASPNETCORE_URLS -ErrorAction SilentlyContinue }
    $procesos.Add($proceso)
    for ($i = 0; $i -lt 60; $i++) {
        Start-Sleep -Milliseconds 500
        if ((Llamar 'GET' "http://localhost:$puerto/salud").Estado -eq 200) { return $null }
        if ($proceso.HasExited) { return "se cerró al arrancar (ver $log)" }
    }
    return "no respondió /salud en 30 s (ver $log)"
}

# Compila, migra (si tiene base) y levanta otro proyecto, salvo que ya esté corriendo.
function Encender($Otro) {
    if ((Llamar 'GET' "http://localhost:$($Otro.puertos.DEV)/salud").Estado -eq 200) { return $null }
    $c = Join-Path $Espacio $Otro.carpeta
    & dotnet build $c --nologo -v q 2>&1 | Out-Null
    if ($LASTEXITCODE -ne 0) { return "$($Otro.nombre): no compila" }
    if ($Otro.tipo -in 'seguridad', 'servicio' -and -not (Migrar $c).Ok) { return "$($Otro.nombre): no pude preparar su base" }
    $motivo = Levantar $Otro
    if ($motivo) { return "$($Otro.nombre): $motivo" }
    return $null
}

# ==================================================================================================
function VerificarServicio {
    # 1. Compila ---------------------------------------------------------------------------------
    $build = & dotnet build --nologo 2>&1 | Out-String
    $advertencias = if ($build -match '(\d+) (Advertencia|Warning)') { [int]$Matches[1] } else { 0 }
    $compila = $LASTEXITCODE -eq 0
    if ($compila -and $advertencias -eq 0) { Anotar 1 "Compila $($proyecto.nombre)" 'ok' 'sin errores ni advertencias' }
    elseif ($compila) { Anotar 1 "Compila $($proyecto.nombre)" 'falla' "$advertencias advertencia(s)" }
    else { Anotar 1 "Compila $($proyecto.nombre)" 'falla' (($build -split "`n" | Where-Object { $_ -match 'error' } | Select-Object -First 3) -join ' | ') }
    if (-not $compila) { foreach ($n in 2..5) { Anotar $n '(no se probó)' 'omitido' 'primero tiene que compilar' }; return }

    # 2. Pruebas: unitarias, integración y arquitectura ------------------------------------------
    $pruebas = & dotnet test --no-build 2>&1 | Out-String
    $total = if ($pruebas -match 'total:\s*(\d+)') { $Matches[1] } else { '?' }
    $correctas = if ($pruebas -match '(correcto|succeeded):\s*(\d+)') { $Matches[2] } else { '0' }
    $arquitectura = @(& dotnet test --no-build tests/Nova.$(Pascal $Servicio).Pruebas.Arquitectura 2>&1 | Out-String)
    $arqOk = $LASTEXITCODE -eq 0
    if ($pruebas -match 'error:\s*0' -and $arqOk) { Anotar 2 'Pruebas (con las de arquitectura)' 'ok' "$correctas/$total en verde · capas respetadas" }
    else {
        $fallidas = ($pruebas -split "`n" | Where-Object { $_ -match 'con errores|failed|Tipos que rompen' } | Select-Object -First 3) -join ' | '
        Anotar 2 'Pruebas (con las de arquitectura)' 'falla' "$correctas/$total · $fallidas"
    }

    # 3. Base DEV: los scripts nuevos se aplican y la 2.ª pasada no hace nada ---------------------
    $primera = Migrar $carpeta
    $segunda = Migrar $carpeta
    if ($primera.Ok -and $segunda.Ok -and $segunda.Salida -match '0 scripts aplicados') {
        $aplicados = if ($primera.Salida -match '(\d+) script\(s\)') { $Matches[1] } else { '0' }
        Anotar 3 'Base DEV con el Migrador' 'ok' "$aplicados script(s) nuevos; 2.ª pasada: 0 (idempotente)"
    }
    else { Anotar 3 'Base DEV con el Migrador' 'falla' ((($primera.Salida + $segunda.Salida) -split "`n" | Where-Object { $_ -match 'Error|Msg' } | Select-Object -First 2) -join ' | ') }

    # 4. Permisos: el script de scopes vive en seguridad; el token de cliente.demo los trae --------
    if (-not $seg) { Anotar 4 'Permisos en el token' 'falla' 'no hay proyecto de seguridad registrado'; return }
    $carpetaSeg = Join-Path $Espacio $seg.carpeta
    & dotnet build $carpetaSeg --nologo -v q 2>&1 | Out-Null
    $migSeg = Migrar $carpetaSeg
    $motivo = if ($migSeg.Ok) { Encender $seg } else { "$($seg.nombre): no pude aplicar sus scripts" }
    if (-not $motivo -and $gateway) { $motivo = Encender $proyecto }
    if (-not $motivo -and $gateway) { $motivo = Encender $gateway }
    if ($motivo) { Anotar 4 'Permisos en el token' 'falla' $motivo; Anotar 5 'API por el gateway' 'omitido' $motivo; return }
    $base = if ($gateway) { "http://localhost:$($gateway.puertos.DEV)" } else { $null }
    $login = if ($base) { "$base/seguridad/api/v1/sesion" } else { "http://localhost:$($seg.puertos.DEV)/api/v1/sesion" }
    $token = Token $login 'cliente.demo'
    $scopes = ScopesDe $token
    $faltan = @("$Servicio.leer", "$Servicio.escribir" | Where-Object { $scopes -notcontains $_ })
    if ($token -and $faltan.Count -eq 0) { Anotar 4 'Permisos en el token' 'ok' "cliente.demo trae $Servicio.leer y $Servicio.escribir" }
    elseif ($token) { Anotar 4 'Permisos en el token' 'falla' "al token de cliente.demo le faltan: $($faltan -join ', ') (¿el script de scopes en $($seg.nombre)?)" }
    else { Anotar 4 'Permisos en el token' 'falla' 'cliente.demo no pudo iniciar sesión' }

    # 5. La API del módulo, de verdad, por el gateway ---------------------------------------------
    if (-not $base) { Anotar 5 'API por el gateway' 'omitido' 'aún no hay gateway (arquetipo -Tipo gateway)'; return }
    $url = "$base/$Servicio/api/v1/$Modulo"
    $ejemplo = Join-Path $carpeta "docs\modulos\$Modulo.ejemplo.json"
    $sinToken = Llamar 'GET' $url $null $null
    $lista = Llamar 'GET' $url $null $token
    $creado = if (Test-Path $ejemplo) { Llamar 'POST' $url ([IO.File]::ReadAllText($ejemplo, $utf8)) $token } else { $null }
    $detalle = $null
    if ($creado -and $creado.Estado -eq 201) {
        $ubicacion = "$($creado.Cabeceras.Location)" -replace '^https?://[^/]+', ''
        $detalle = Llamar 'GET' "$base/$Servicio$ubicacion" $null $token
    }
    $antes = if ($lista.Estado -eq 200) { ($lista.Cuerpo | ConvertFrom-Json).total } else { $null }
    if (-not $creado) { Anotar 5 'API por el gateway' 'falla' "falta docs\modulos\$Modulo.ejemplo.json (el cuerpo de ejemplo para crear)" }
    elseif ($sinToken.Estado -eq 401 -and $lista.Estado -eq 200 -and $creado.Estado -eq 201 -and $detalle.Estado -eq 200) {
        Anotar 5 'API por el gateway' 'ok' "sin token → 401 · listar → 200 ($antes de cliente.demo) · crear → 201 · ver lo creado → 200"
    }
    else { Anotar 5 'API por el gateway' 'falla' "sin token $($sinToken.Estado) · listar $($lista.Estado) · crear $($creado.Estado) · ver lo creado $(if ($detalle) { $detalle.Estado } else { '-' })" }
}

function VerificarRama {
    if (-not (Test-Path (Join-Path $carpeta '.git'))) { Anotar 7 'Rama del módulo' 'omitido' 'el servicio aún no es un repo git'; return }
    $rama = & git -C $carpeta branch --show-current 2>$null
    $pendientes = @(& git -C $carpeta status --porcelain 2>$null).Count
    if ($rama -eq "feature/modulo-$Modulo" -and $pendientes -eq 0) { Anotar 7 'Rama del módulo' 'ok' "$rama · todo commiteado, lista para el PR a develop" }
    elseif ($rama -ne "feature/modulo-$Modulo") { Anotar 7 'Rama del módulo' 'falla' "estás en «$rama»: el módulo va en feature/modulo-$Modulo" }
    else { Anotar 7 'Rama del módulo' 'falla' "$rama · $pendientes archivo(s) sin commitear" }
}

# ==================================================================================================
Write-Host "Verificando el módulo $Modulo en $($proyecto.nombre)" -ForegroundColor Cyan
Push-Location $carpeta
try {
    VerificarServicio
    Anotar 6 'Web' 'omitido' 'esta versión de la skill todavía no agrega pantallas'
    VerificarRama
}
finally {
    Pop-Location
    # Solo se cierran los procesos que levantó esta verificación.
    foreach ($p in $procesos) { if (-not $p.HasExited) { & taskkill /PID $p.Id /T /F *> $null } }
}

$resultados | Format-Table -AutoSize -Wrap | Out-String -Width 200 | Write-Host
$fallas = @($resultados | Where-Object { $_.' ' -eq '❌' }).Count
if ($fallas -eq 0) { Write-Host "Módulo $Modulo en $($proyecto.nombre): todo en verde." -ForegroundColor Green; exit 0 }
Write-Host "Módulo $Modulo en $($proyecto.nombre): $fallas chequeo(s) en rojo." -ForegroundColor Red
exit 1

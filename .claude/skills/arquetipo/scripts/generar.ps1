<#
.SYNOPSIS
  Crea un proyecto nuevo a partir de las plantillas del arquetipo.
.EXAMPLE
  .\generar.ps1 -Tipo seguridad -Nombre seguridad
  .\generar.ps1 -Tipo servicio -Nombre pedidos
  .\generar.ps1 -Tipo gateway -Nombre gateway
  .\generar.ps1 -Tipo web -Nombre web
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][ValidateSet('servicio', 'seguridad', 'gateway', 'web')][string]$Tipo,
    [Parameter(Mandatory = $true)][string]$Nombre,
    # Raíz del espacio de trabajo (la carpeta que tiene .claude/ y proyectos/).
    [string]$Espacio,
    # Servicio: nombre del proyecto de seguridad que emite sus tokens (por defecto, el único registrado).
    [string]$Seguridad
)
# En PowerShell 5.1, $PSScriptRoot está vacío dentro de param(): el valor por defecto se calcula aquí.
if (-not $Espacio) { $Espacio = (Resolve-Path (Join-Path $PSScriptRoot '..\..\..\..')).Path }
$ErrorActionPreference = 'Stop'
[Console]::OutputEncoding = [Text.Encoding]::UTF8
$utf8 = New-Object Text.UTF8Encoding $false

function Detener([string]$Mensaje) { Write-Host "❌ $Mensaje" -ForegroundColor Red; exit 1 }

# 1. Validar parámetros ---------------------------------------------------------------
if ($Nombre -cnotmatch '^[a-z][a-z0-9]{2,29}$') {
    Detener "Nombre inválido: '$Nombre'. Usa minúsculas y números, de 3 a 30 caracteres, empezando por letra (p. ej. pedidos)."
}
$NombrePascal = $Nombre.Substring(0, 1).ToUpperInvariant() + $Nombre.Substring(1)
$carpeta = "nova-$Nombre"
$destino = Join-Path $Espacio "proyectos\$carpeta"
if (Test-Path $destino) { Detener "Ya existe $destino. No sobrescribo proyectos." }

# 2. Leer el registro del espacio de trabajo -------------------------------------------
$rutaRegistro = Join-Path $Espacio 'proyectos.json'
$registro = @()
if (Test-Path $rutaRegistro) {
    $leido = [IO.File]::ReadAllText($rutaRegistro, $utf8) | ConvertFrom-Json
    $registro = @($leido | Where-Object { $_ })
}
if ($registro | Where-Object { $_.nombre -eq $carpeta }) { Detener "$carpeta ya está en proyectos.json." }

# 3. Puertos: un bloque de 100 por proyecto (PROD = bloque*100, DEV +1, QA +2) ----------
$bloquesUsados = @($registro | ForEach-Object { [int][math]::Floor($_.puertos.PROD / 100) })
# Seguridad, gateway y web son uno por espacio de trabajo, con su bloque fijo.
$fijos = @{ seguridad = 51; gateway = 52; web = 30 }
if ($fijos.ContainsKey($Tipo)) {
    $bloque = $fijos[$Tipo]
    if ($bloquesUsados -contains $bloque) { Detener "Ya hay un proyecto $Tipo en el espacio de trabajo." }
}
else {
    # 50 para el primer servicio; 51 seguridad, 52 gateway y 30 web están reservados.
    $bloque = @(50) + (53..99) | Where-Object { $bloquesUsados -notcontains $_ } | Select-Object -First 1
}
$puertos = [ordered]@{ DEV = $bloque * 100 + 1; QA = $bloque * 100 + 2; PROD = $bloque * 100 }

$base = "Nova$NombrePascal"
# Diccionario que distingue mayúsculas: __Nombre__ (Pedidos) y __nombre__ (pedidos) son marcadores distintos.
$reemplazos = New-Object System.Collections.Specialized.OrderedDictionary ([StringComparer]::Ordinal)
$reemplazos['__Nombre__'] = $NombrePascal
$reemplazos['__nombre__'] = $Nombre
$reemplazos['__BASE__'] = $base
$reemplazos['__PUERTO_DEV__'] = "$($puertos.DEV)"
$reemplazos['__PUERTO_QA__'] = "$($puertos.QA)"
$reemplazos['__PUERTO_PROD__'] = "$($puertos.PROD)"

if ($Tipo -eq 'servicio') {
    $candidatos = @($registro | Where-Object { $_.tipo -eq 'seguridad' -and (-not $Seguridad -or $_.nombre -eq "nova-$Seguridad") })
    if ($candidatos.Count -eq 0) {
        Detener 'No hay proyecto de seguridad que emita los tokens. Primero: /arquetipo seguridad seguridad'
    }
    $seg = $candidatos[0]
    $reemplazos['__SEG_PUERTO_DEV__'] = "$($seg.puertos.DEV)"
    $reemplazos['__SEG_PUERTO_QA__'] = "$($seg.puertos.QA)"
    $reemplazos['__SEG_PUERTO_PROD__'] = "$($seg.puertos.PROD)"
}

$ambientes = 'DEV', 'QA', 'PROD'
$desfase = @{ DEV = 1; QA = 2; PROD = 0 }
if ($Tipo -eq 'gateway') {
    # Enruta a seguridad y a cada servicio registrado: sin ellos no hay a dónde mandar nada.
    $seg = $registro | Where-Object { $_.tipo -eq 'seguridad' } | Select-Object -First 1
    $servicios = @($registro | Where-Object { $_.tipo -eq 'servicio' })
    if (-not $seg) { Detener 'El gateway necesita un proyecto de seguridad. Primero: /arquetipo seguridad seguridad' }
    if ($servicios.Count -eq 0) { Detener 'El gateway necesita al menos un servicio al que enrutar. Primero: /arquetipo servicio pedidos' }
    $rutas = ''
    $tabla = ''
    $destinos = @{ DEV = ''; QA = ''; PROD = '' }
    foreach ($s in $servicios) {
        $n = $s.nombre.Substring(5)
        $rutas += ",`n      `"$n`": {`n        `"ClusterId`": `"$n`",`n        `"AuthorizationPolicy`": `"autenticado`",`n" +
            "        `"Match`": { `"Path`": `"/$n/api/{**resto}`" },`n        `"Transforms`": [ { `"PathRemovePrefix`": `"/$n`" } ]`n      }"
        $tabla += " · ``/$n/api/…`` → $($s.nombre) (con token)"
        foreach ($a in $ambientes) {
            $destinos[$a] += ",`n      `"$n`": {`n        `"Destinations`": { `"principal`": { `"Address`": `"http://localhost:$($s.puertos.$a)/`" } }`n      }"
        }
    }
    foreach ($a in $ambientes) {
        $reemplazos["__SEG_PUERTO_${a}__"] = "$($seg.puertos.$a)"
        # La web tiene su bloque fijo (30): el gateway ya sabe a qué origen abrirle CORS.
        $reemplazos["__WEB_PUERTO_${a}__"] = "$($fijos.web * 100 + $desfase[$a])"
        $reemplazos["__DESTINOS_${a}__"] = $destinos[$a]
    }
    $reemplazos['__RUTAS_SERVICIOS__'] = $rutas
    $reemplazos['__TABLA_RUTAS__'] = $tabla
    # Las pruebas usan el primer servicio como ejemplo de ruta protegida.
    $reemplazos['__SERVICIO__'] = $servicios[0].nombre.Substring(5)
}
if ($Tipo -eq 'web') {
    # La web solo habla con el gateway: él la lleva a seguridad y a los servicios.
    $gw = $registro | Where-Object { $_.tipo -eq 'gateway' } | Select-Object -First 1
    if (-not $gw) { Detener 'La web necesita el gateway. Primero: /arquetipo gateway gateway' }
    $servicioWeb = $registro | Where-Object { $_.tipo -eq 'servicio' } | Select-Object -First 1
    foreach ($a in $ambientes) { $reemplazos["__GW_PUERTO_${a}__"] = "$($gw.puertos.$a)" }
    # La primera página llega a este servicio a través del gateway.
    $reemplazos['__SERVICIO__'] = $servicioWeb.nombre.Substring(5)
    $reemplazos['__Servicio__'] = $reemplazos['__SERVICIO__'].Substring(0, 1).ToUpperInvariant() + $reemplazos['__SERVICIO__'].Substring(1)
}

function Reemplazar([string]$texto) {
    foreach ($clave in $reemplazos.Keys) { $texto = $texto.Replace($clave, $reemplazos[$clave]) }
    return $texto
}

# 4. Copiar plantillas: primero comun/, luego la del tipo (pisa lo que repite) ----------
#    El gateway no tiene capas: de comun/ solo toma la configuración de la raíz (.editorconfig,
#    Directory.Build.props, global.json…). La web no es .NET: sale entera de su plantilla.
$plantillas = Join-Path $PSScriptRoot '..\plantillas'
$capas = switch ($Tipo) { 'gateway' { 'comun-raiz', 'gateway' } 'web' { , 'web' } default { 'comun', $Tipo } }
foreach ($capa in $capas) {
    $soloRaiz = $capa -eq 'comun-raiz'
    $raiz = (Resolve-Path (Join-Path $plantillas $(if ($soloRaiz) { 'comun' } else { $capa }))).Path
    foreach ($archivo in Get-ChildItem -Path $raiz -Recurse:(-not $soloRaiz) -File -Force) {
        $relativo = Reemplazar $archivo.FullName.Substring($raiz.Length + 1)
        $salida = Join-Path $destino $relativo
        [void][IO.Directory]::CreateDirectory((Split-Path $salida -Parent))
        # Fin de línea CRLF (lo que pide .editorconfig): git no avisa nada al hacer commit en Windows.
        $contenido = (Reemplazar ([IO.File]::ReadAllText($archivo.FullName, $utf8))) -replace "`r?`n", "`r`n"
        [IO.File]::WriteAllText($salida, $contenido, $utf8)
    }
}

# 5. Nada debe quedar sin reemplazar ------------------------------------------------------
$sobras = Get-ChildItem -Path $destino -Recurse -File -Force |
    Select-String -Pattern '__(Nombre|nombre|Servicio|[A-Z][A-Z0-9_]*[A-Z0-9])__' -CaseSensitive
if ($sobras) {
    $sobras | ForEach-Object { Write-Host "  $($_.Path):$($_.LineNumber)" }
    Detener 'Quedaron marcadores sin reemplazar en la plantilla.'
}

# 6. Registrar el proyecto ---------------------------------------------------------------
$registro += [pscustomobject][ordered]@{
    nombre  = $carpeta
    tipo    = $Tipo
    carpeta = "proyectos/$carpeta"
    repo    = $null
    puertos = $puertos
    # El gateway y la web no tienen base de datos.
    bases   = if ($Tipo -in 'gateway', 'web') { $null } else { [ordered]@{ DEV = "${base}_DEV"; QA = "${base}_QA"; PROD = "${base}_PROD"; PRUEBAS = "${base}_PRUEBAS" } }
}
[IO.File]::WriteAllText($rutaRegistro, (ConvertTo-Json -InputObject @($registro) -Depth 5), $utf8)

Write-Host ''
Write-Host "Creado $carpeta ($Tipo) en proyectos/$carpeta" -ForegroundColor Green
if ($Tipo -ne 'web') { Write-Host "  Solución : Nova.$NombrePascal.slnx" }
Write-Host "  Puertos  : DEV $($puertos.DEV) · QA $($puertos.QA) · PROD $($puertos.PROD)"
if ($Tipo -in 'seguridad', 'servicio') { Write-Host "  Bases    : ${base}_DEV · ${base}_QA · ${base}_PROD" }
if ($Tipo -eq 'servicio') { Write-Host "  Tokens de: $($seg.nombre) (DEV :$($seg.puertos.DEV))" }
if ($Tipo -eq 'gateway') {
    Write-Host "  Rutas    : /seguridad → $($seg.nombre)$(($servicios | ForEach-Object { " · /$($_.nombre.Substring(5)) → $($_.nombre)" }) -join '')"
    Write-Host "  CORS     : http://localhost:$($fijos.web * 100 + 1) (DEV)"
}
if ($Tipo -eq 'web') { Write-Host "  Gateway  : $($gw.nombre) (DEV :$($gw.puertos.DEV))" }
Write-Host 'Siguiente: scripts\verificar.ps1'

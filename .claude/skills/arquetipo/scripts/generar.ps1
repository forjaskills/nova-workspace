<#
.SYNOPSIS
  Crea un proyecto nuevo a partir de las plantillas del arquetipo.
.EXAMPLE
  .\generar.ps1 -Tipo seguridad -Nombre seguridad
  .\generar.ps1 -Tipo servicio -Nombre pedidos
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][ValidateSet('servicio', 'seguridad')][string]$Tipo,
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
# Seguridad es uno por espacio de trabajo, con su bloque fijo.
$fijos = @{ seguridad = 51 }
if ($fijos.ContainsKey($Tipo)) {
    $bloque = $fijos[$Tipo]
    if ($bloquesUsados -contains $bloque) { Detener "Ya hay un proyecto $Tipo en el espacio de trabajo." }
}
else {
    # 50 para el primer servicio; 51 es de seguridad y 52 queda reservado.
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

function Reemplazar([string]$texto) {
    foreach ($clave in $reemplazos.Keys) { $texto = $texto.Replace($clave, $reemplazos[$clave]) }
    return $texto
}

# 4. Copiar plantillas: primero comun/, luego la del tipo (pisa lo que repite) ----------
$plantillas = Join-Path $PSScriptRoot '..\plantillas'
foreach ($capa in 'comun', $Tipo) {
    $raiz = (Resolve-Path (Join-Path $plantillas $capa)).Path
    foreach ($archivo in Get-ChildItem -Path $raiz -Recurse -File -Force) {
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
    bases   = [ordered]@{ DEV = "${base}_DEV"; QA = "${base}_QA"; PROD = "${base}_PROD"; PRUEBAS = "${base}_PRUEBAS" }
}
[IO.File]::WriteAllText($rutaRegistro, (ConvertTo-Json -InputObject @($registro) -Depth 5), $utf8)

Write-Host ''
Write-Host "Creado $carpeta ($Tipo) en proyectos/$carpeta" -ForegroundColor Green
Write-Host "  Solución : Nova.$NombrePascal.slnx"
Write-Host "  Puertos  : DEV $($puertos.DEV) · QA $($puertos.QA) · PROD $($puertos.PROD)"
Write-Host "  Bases    : ${base}_DEV · ${base}_QA · ${base}_PROD"
if ($Tipo -eq 'servicio') { Write-Host "  Tokens de: $($seg.nombre) (DEV :$($seg.puertos.DEV))" }
Write-Host 'Siguiente: scripts\verificar.ps1'

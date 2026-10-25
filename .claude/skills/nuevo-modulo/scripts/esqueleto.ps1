<#
.SYNOPSIS
  Crea el esqueleto de un módulo de negocio en un servicio del arquetipo: un archivo en cada capa, en su lugar,
  con los nombres de la convención y marcas TODO(nuevo-modulo) donde van las reglas. No escribe reglas de negocio
  (eso lo hace Claude con la ficha del módulo) y nunca sobrescribe un archivo.
.EXAMPLE
  .\esqueleto.ps1 -Servicio pedidos -Modulo Pedidos -Entidad Pedido
#>
[CmdletBinding()]
param(
    # El servicio que recibe el módulo (nombre de arquetipo: pedidos → proyectos/nova-pedidos).
    [Parameter(Mandatory = $true)][string]$Servicio,
    # El módulo en PascalCase y plural: Pedidos, Productos, Clientes.
    [Parameter(Mandatory = $true)][string]$Modulo,
    # La raíz del agregado en PascalCase y singular: Pedido, Producto, Cliente.
    [Parameter(Mandatory = $true)][string]$Entidad,
    [string]$Espacio
)
# En PowerShell 5.1, $PSScriptRoot está vacío dentro de param(): el valor por defecto se calcula aquí.
if (-not $Espacio) { $Espacio = (Resolve-Path (Join-Path $PSScriptRoot '..\..\..\..')).Path }
$ErrorActionPreference = 'Stop'
[Console]::OutputEncoding = [Text.Encoding]::UTF8
$utf8 = New-Object Text.UTF8Encoding $false

function Detener([string]$Mensaje) { Write-Host "❌ $Mensaje" -ForegroundColor Red; exit 1 }

# 1. Validar --------------------------------------------------------------------------------------
foreach ($par in @(@('Modulo', $Modulo), @('Entidad', $Entidad))) {
    if ($par[1] -cnotmatch '^[A-Z][A-Za-z]{2,29}$') { Detener "-$($par[0]) inválido: '$($par[1])'. PascalCase, solo letras (p. ej. Pedidos / Pedido)." }
}
if ($Modulo -eq $Entidad) { Detener '-Modulo va en plural y -Entidad en singular (Pedidos / Pedido): no pueden ser iguales.' }
$registro = @([IO.File]::ReadAllText((Join-Path $Espacio 'proyectos.json'), $utf8) | ConvertFrom-Json) | ForEach-Object { $_ }
$proyecto = $registro | Where-Object { $_.nombre -eq "nova-$Servicio" -and $_.tipo -eq 'servicio' } | Select-Object -First 1
if (-not $proyecto) { Detener "nova-$Servicio no es un servicio registrado en proyectos.json (los módulos van en servicios de arquetipo)." }
$seg = $registro | Where-Object { $_.tipo -eq 'seguridad' } | Select-Object -First 1

$ServicioP = $Servicio.Substring(0, 1).ToUpperInvariant() + $Servicio.Substring(1)
$moduloMin = $Modulo.ToLowerInvariant()
$entidadCamel = $Entidad.Substring(0, 1).ToLowerInvariant() + $Entidad.Substring(1)
$carpeta = Join-Path $Espacio $proyecto.carpeta
if (Test-Path (Join-Path $carpeta "src\01. Business Rules Model\Nova.$ServicioP.Dominio\$Modulo")) {
    Detener "El módulo $Modulo ya existe en $($proyecto.nombre). No sobrescribo módulos."
}

# 2. Rama: el módulo se trabaja en feature/modulo-<modulo> (GitFlow) --------------------------------
function PrepararRama([string]$Repo) {
    if (-not (Test-Path (Join-Path $Repo '.git'))) { return 'sin git (todavía no es un repo)' }
    # Continue: en PowerShell 5.1, con Stop cualquier aviso de git en stderr se vuelve excepción. Se juzga por $LASTEXITCODE.
    $previo = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    try {
        $rama = & git -C $Repo branch --show-current
        $objetivo = "feature/modulo-$moduloMin"
        if ($rama -eq $objetivo) { return "ya en $objetivo" }
        if (@(& git -C $Repo status --porcelain).Count -gt 0) { Detener "$Repo tiene cambios sin commitear: commitéalos o guárdalos antes de empezar el módulo." }
        if ($rama -ne 'develop') { & git -C $Repo switch develop 2>&1 | Out-Null; if ($LASTEXITCODE -ne 0) { Detener "$Repo no tiene rama develop." } }
        & git -C $Repo rev-parse --abbrev-ref '@{u}' 2>&1 | Out-Null
        $traerDeGitHub = $LASTEXITCODE -eq 0
        if ($traerDeGitHub) {
            & git -C $Repo pull --ff-only 2>&1 | Out-Null
            if ($LASTEXITCODE -ne 0) { Detener "No pude actualizar develop en $Repo (git pull --ff-only)." }
        }
        & git -C $Repo switch -c $objetivo 2>&1 | Out-Null
        if ($LASTEXITCODE -ne 0) { Detener "No pude crear la rama $objetivo en $Repo." }
        return "rama $objetivo (desde develop$(if ($traerDeGitHub) { ' al día con GitHub' }))"
    }
    finally { $ErrorActionPreference = $previo }
}

# 3. Copiar una plantilla reemplazando los nombres (en rutas y contenido), sin sobrescribir ---------
function Siguiente([string]$CarpetaBd) {
    $numeros = @(Get-ChildItem $CarpetaBd -File -ErrorAction SilentlyContinue |
        Where-Object { $_.Name -match '^(\d{4})-' } | ForEach-Object { [int]$Matches[1] })
    $mayor = if ($numeros.Count) { ($numeros | Measure-Object -Maximum).Maximum } else { 0 }
    return '{0:D4}' -f ([int]$mayor + 1)
}

function Copiar([string]$Origen, [string]$Destino, [object[]]$Cambios) {
    $creados = @()
    foreach ($archivo in Get-ChildItem $Origen -Recurse -File) {
        $relativo = $archivo.FullName.Substring($Origen.Length).TrimStart('\')
        foreach ($c in $Cambios) { $relativo = $relativo.Replace($c[0], $c[1]) }
        $final = Join-Path $Destino $relativo
        if (Test-Path $final) { Write-Host "  · ya existe, no lo toco: $relativo" -ForegroundColor DarkYellow; continue }
        $texto = [IO.File]::ReadAllText($archivo.FullName, $utf8)
        foreach ($c in $Cambios) { $texto = $texto.Replace($c[0], $c[1]) }
        New-Item -ItemType Directory -Force (Split-Path $final) | Out-Null
        [IO.File]::WriteAllText($final, $texto, $utf8)
        $creados += $relativo
    }
    return $creados
}

# Inserta líneas justo después de la marca «nuevo-modulo agrega aquí…» de un archivo de registro.
function Registrar([string]$Archivo, [string[]]$Lineas, [string[]]$Usings) {
    $texto = [IO.File]::ReadAllText($Archivo, $utf8)
    if ($texto.Contains("// módulo $Modulo")) { return }
    $marca = [regex]::Match($texto, '(?m)^.*nuevo-modulo agrega aquí.*\r?\n')
    if (-not $marca.Success) { Detener "No encuentro la marca «nuevo-modulo agrega aquí» en $Archivo." }
    $fin = if ($texto.Contains("`r`n")) { "`r`n" } else { "`n" }
    $texto = $texto.Insert($marca.Index + $marca.Length, (($Lineas | ForEach-Object { "        $_" }) -join $fin) + $fin)
    foreach ($using in @($Usings | Where-Object { $_ -and -not $texto.Contains("$_;") })) {
        $existentes = [regex]::Matches($texto, '(?m)^using [^\r\n]+;\r?\n')
        $donde = if ($existentes.Count) { $existentes[$existentes.Count - 1].Index + $existentes[$existentes.Count - 1].Length } else { 0 }
        $texto = $texto.Insert($donde, "$using;$fin")
    }
    [IO.File]::WriteAllText($Archivo, $texto, $utf8)
}

$plantillas = Join-Path $PSScriptRoot '..\plantillas' | Resolve-Path | Select-Object -ExpandProperty Path
Write-Host "Módulo $Modulo ($Entidad) en $($proyecto.nombre)" -ForegroundColor Cyan
# Todo lo que se puede calcular o rechazar va antes de escribir el primer archivo (si no, un error deja el módulo a medias).
$numero = Siguiente (Join-Path $carpeta 'bd')
$carpetaSeg = $null; $numeroSeg = $null; $yaEsta = $null
if ($seg) {
    $carpetaSeg = Join-Path $Espacio $seg.carpeta
    $yaEsta = Get-ChildItem (Join-Path $carpetaSeg 'bd') -Filter *.sql |
        Where-Object { [IO.File]::ReadAllText($_.FullName, $utf8).Contains("N'$Servicio.leer'") } | Select-Object -First 1
    if (-not $yaEsta) { $numeroSeg = Siguiente (Join-Path $carpetaSeg 'bd') }
}
$ramaServicio = PrepararRama $carpeta
$ramaSeg = if ($numeroSeg) { PrepararRama $carpetaSeg } else { $null }
# Pares (no un hashtable: en PowerShell las claves no distinguen mayúsculas y __Modulo__ chocaría con __modulo__).
$cambios = @(
    @('__NNNN__', $numero), @('__Servicio__', $ServicioP), @('__servicio__', $Servicio),
    @('__Modulo__', $Modulo), @('__modulo__', $moduloMin), @('__Entidad__', $Entidad), @('__entidad__', $entidadCamel))
$creados = Copiar (Join-Path $plantillas 'servicio') $carpeta $cambios

$adaptadores = Join-Path $carpeta "src\03. Interface Adapter\Nova.$ServicioP.Adaptadores\Gateways\RegistroGateways.cs"
Registrar $adaptadores @("// módulo $Modulo", "servicios.AddScoped<IRepositorio$Modulo, Repositorio$Modulo>();") `
    @("using Nova.$ServicioP.Adaptadores.Gateways.$Modulo", "using Nova.$ServicioP.Dominio.$Modulo")
Registrar (Join-Path $carpeta "src\02. Application Rules Model\Nova.$ServicioP.Aplicacion\RegistroAplicacion.cs") `
    @("// módulo $Modulo · TODO(nuevo-modulo): servicios.AddScoped<IPuerto, CasoDeUso>(); por cada caso de uso") $null

# 4. Permisos: el primer módulo de un servicio trae sus scopes a nova-seguridad ---------------------
$permisos = 'sin proyecto de seguridad registrado'
if ($yaEsta) { $permisos = "$($seg.nombre) ya da $Servicio.leer/.escribir ($($yaEsta.Name))" }
elseif ($numeroSeg) {
    $nuevos = Copiar (Join-Path $plantillas 'seguridad') $carpetaSeg @(@('__NNNN__', $numeroSeg), @('__servicio__', $Servicio))
    $permisos = "$($seg.nombre): $($nuevos -join ', ') · $ramaSeg"
}

# 5. Resumen ----------------------------------------------------------------------------------------
Write-Host ''
Write-Host "$($proyecto.nombre) · $ramaServicio" -ForegroundColor Green
$capas = [ordered]@{ '01. Business' = 'Dominio'; '02. Application' = 'Aplicación'; '03. Interface' = 'Adaptadores'; 'tests' = 'Pruebas'; 'bd' = 'Base'; 'docs' = 'Ficha' }
foreach ($c in $capas.Keys) {
    $deCapa = @($creados | Where-Object { $_ -like "*$c*" -or $_.StartsWith($c) } | ForEach-Object { Split-Path $_ -Leaf })
    if ($deCapa.Count) { Write-Host ("  {0,-12} {1}" -f $capas[$c], ($deCapa -join ' · ')) }
}
Write-Host "  Permisos     $permisos"
Write-Host ''
& dotnet build $carpeta --nologo -v q 2>&1 | Out-Null
if ($LASTEXITCODE -eq 0) { Write-Host '✅ El esqueleto compila.' -ForegroundColor Green }
else { Write-Host '❌ El esqueleto no compila: revisa con dotnet build.' -ForegroundColor Red; exit 1 }
Write-Host "Siguiente: llenar docs\modulos\$moduloMin.md (la ficha) y escribir cada TODO(nuevo-modulo); después scripts\verificar.ps1 -Servicio $Servicio -Modulo $moduloMin"

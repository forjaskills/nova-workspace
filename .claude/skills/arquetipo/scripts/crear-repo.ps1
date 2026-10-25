<#
.SYNOPSIS
  Sube un proyecto del arquetipo a GitHub: revisa que no lleve secretos, crea el repo con gh,
  las ramas main/develop/qa y protege main y develop (solo entran por PR).
.EXAMPLE
  .\crear-repo.ps1 -Nombre seguridad -Simular     # solo revisa, no toca GitHub
  .\crear-repo.ps1 -Nombre seguridad
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][string]$Nombre,
    [string]$Espacio,
    # Dueño del repo (usuario u organización). Por defecto, la cuenta con la que está logueado gh.
    [string]$Propietario,
    # GitHub Free solo protege ramas en repos públicos.
    [ValidateSet('public', 'private')][string]$Visibilidad = 'public',
    [switch]$Simular
)
# En PowerShell 5.1, $PSScriptRoot está vacío dentro de param(): el valor por defecto se calcula aquí.
if (-not $Espacio) { $Espacio = (Resolve-Path (Join-Path $PSScriptRoot '..\..\..\..')).Path }
$ErrorActionPreference = 'Continue'
[Console]::OutputEncoding = [Text.Encoding]::UTF8
$utf8 = New-Object Text.UTF8Encoding $false

function Detener([string]$Mensaje) { Write-Host "❌ $Mensaje" -ForegroundColor Red; exit 1 }
function Paso([string]$Mensaje) { Write-Host "→ $Mensaje" -ForegroundColor Cyan }

$rutaRegistro = Join-Path $Espacio 'proyectos.json'
$registro = @([IO.File]::ReadAllText($rutaRegistro, $utf8) | ConvertFrom-Json)
$registro = @($registro | ForEach-Object { $_ })
$proyecto = $registro | Where-Object { $_.nombre -eq "nova-$Nombre" } | Select-Object -First 1
if (-not $proyecto) { Detener "nova-$Nombre no está en proyectos.json." }
$carpeta = Join-Path $Espacio $proyecto.carpeta
if (Test-Path (Join-Path $carpeta '.git')) { Detener "$($proyecto.nombre) ya es un repositorio git: no lo vuelvo a crear." }

# 1. ¿Con qué identidad se van a firmar los commits? ------------------------------------------
Paso 'Identidad de git'
$correo = (& git -C $carpeta config user.email) 2>$null
if ($correo -notmatch '@users\.noreply\.github\.com$') {
    Detener ("El correo de git no es el noreply de GitHub, y quedaría público en cada commit.`n" +
        '   Configúralo con: git config --global user.email "<id>+<usuario>@users.noreply.github.com"')
}
Write-Host "   commits como $((& git -C $carpeta config user.name) 2>$null) <$correo>"

# 2. ¿Lleva algo que no debe salir? ----------------------------------------------------------
Paso 'Buscando secretos y datos de la PC'
$patrones = [ordered]@{
    'contraseña en cadena de conexión' = '(?i)(password|pwd)\s*='
    'llave privada'                    = '-----BEGIN [A-Z ]*PRIVATE KEY-----'
    'ruta de usuario de Windows'       = '(?i)[a-z]:\\users\\[^\\\s"]+'
    'correo'                           = '[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}'
    'dirección IP'                     = '\b(?!127\.0\.0\.1\b)(\d{1,3}\.){3}\d{1,3}\b'
    'token de GitHub'                  = '\bgh[pousr]_[A-Za-z0-9]{20,}'
}
# Lo mismo que ignora el .gitignore de cada tipo: eso no se sube. Las carpetas ignoradas ni se recorren:
# node_modules tiene decenas de miles de archivos y Get-ChildItem -Recurse tardaba minutos en PowerShell 5.1.
$ignoradas = 'bin', 'obj', '.vs', '.git', 'TestResults', 'node_modules', '.next', 'test-results', 'playwright-report'
$pendientes = New-Object System.Collections.Generic.Stack[string]
$pendientes.Push($carpeta)
$archivos = while ($pendientes.Count -gt 0) {
    $actual = $pendientes.Pop()
    foreach ($sub in [IO.Directory]::GetDirectories($actual)) {
        if ($ignoradas -notcontains (Split-Path $sub -Leaf)) { $pendientes.Push($sub) }
    }
    Get-ChildItem -LiteralPath $actual -File -Force | Where-Object { $_.Name -notmatch '^(next-env\.d\.ts|.*\.tsbuildinfo|.*\.log)$' }
}
$hallazgos = foreach ($tipo in $patrones.Keys) {
    $archivos | Select-String -Pattern $patrones[$tipo] |
        Where-Object { $tipo -ne 'correo' -or $_.Line -notmatch 'noreply' } |
        ForEach-Object { "   $tipo · $($_.Path.Substring($carpeta.Length + 1)):$($_.LineNumber)" }
}
if ($hallazgos) { $hallazgos | Write-Host; Detener 'Encontré datos que no deben subirse. Revísalos antes de crear el repo.' }
Write-Host "   $($archivos.Count) archivos revisados: limpio"

# 3. GitHub ------------------------------------------------------------------------------------
Paso 'Sesión de gh'
# Se pregunta por la cuenta activa (gh auth status falla si otra cuenta guardada está vencida).
$cuenta = (& gh api user --jq .login) 2>$null
if ($LASTEXITCODE -ne 0 -or -not $cuenta) { Detener 'gh no tiene una sesión activa. Corre: gh auth login' }
Write-Host "   gh como $cuenta"
if (-not $Propietario) { $Propietario = $cuenta }
$repo = "$Propietario/$($proyecto.nombre)"
& gh repo view $repo *> $null
if ($LASTEXITCODE -eq 0) { Detener "El repo $repo ya existe en GitHub." }
Write-Host "   se creará $repo ($Visibilidad)"

if ($Simular) {
    Write-Host ''
    Write-Host 'Simulación: todo listo para crear el repo. Pasos que faltan (sin -Simular):' -ForegroundColor Yellow
    Write-Host "   git init -b main · commit inicial · gh repo create $repo --$Visibilidad --push"
    Write-Host '   ramas develop y qa · rama por defecto develop · protección de main y develop'
    exit 0
}

Push-Location $carpeta
try {
    Paso 'Commit inicial en main'
    & git init -b main --quiet
    & git add --all
    & git commit --quiet -m "Proyecto creado con la skill arquetipo (tipo $($proyecto.tipo))"
    if ($LASTEXITCODE -ne 0) { Detener 'No se pudo hacer el commit inicial.' }

    Paso "Creando $repo"
    $descripcion = switch ($proyecto.tipo) {
        'seguridad' { 'Nova Retail: seguridad (login y JWT). Proyecto de ejemplo de Forja Skills.' }
        'gateway' { 'Nova Retail: API pública (YARP: rutas, JWT, CORS, límites). Proyecto de ejemplo de Forja Skills.' }
        'web' { 'Nova Retail: frontend Next.js (App Router, TypeScript). Proyecto de ejemplo de Forja Skills.' }
        default { "Nova Retail: API de $Nombre. Proyecto de ejemplo de Forja Skills." }
    }
    & gh repo create $repo "--$Visibilidad" --source . --remote origin --push --description $descripcion *> $null
    if ($LASTEXITCODE -ne 0) { Detener 'gh no pudo crear el repo.' }

    Paso 'Ramas develop y qa'
    foreach ($rama in 'develop', 'qa') {
        & git branch $rama main
        & git push --quiet -u origin $rama *> $null
        if ($LASTEXITCODE -ne 0) { Detener "No se pudo subir la rama $rama." }
    }
    & git checkout --quiet develop
    & gh repo edit $repo --default-branch develop *> $null
    Write-Host "   https://github.com/$repo"

    Paso 'Protegiendo main, develop y qa (solo por PR)'
    # Las ramas feature/ se borran solas al unirse: el repo no se llena de ramas viejas.
    & gh api -X PATCH "repos/$repo" -F delete_branch_on_merge=true --silent *> $null
    $proteccion = '{"required_status_checks":null,"enforce_admins":true,' +
        '"required_pull_request_reviews":{"required_approving_review_count":0},"restrictions":null,' +
        '"allow_force_pushes":false,"allow_deletions":false}'
    # A archivo y no por tubería: PowerShell 5.1 altera el texto que pasa por | a un programa nativo
    # y GitHub responde «Problems parsing JSON».
    $archivoProteccion = [IO.Path]::GetTempFileName()
    [IO.File]::WriteAllText($archivoProteccion, $proteccion, $utf8)
    foreach ($rama in 'main', 'develop', 'qa') {
        $salida = & gh api -X PUT "repos/$repo/branches/$rama/protection" --input $archivoProteccion 2>&1 | Out-String
        if ($LASTEXITCODE -ne 0) {
            $motivo = ($salida -split "`r?`n" | Where-Object { $_ -match '^gh:' } | Select-Object -First 1)
            if (-not $motivo) { $motivo = $salida.Trim() }
            Write-Host "   ⚠ no se pudo proteger ${rama}: $motivo" -ForegroundColor Yellow
            if ($Visibilidad -eq 'private') { Write-Host '     (en GitHub Free, solo los repos públicos permiten proteger ramas)' -ForegroundColor Yellow }
        }
    }
    Remove-Item $archivoProteccion -ErrorAction SilentlyContinue
}
finally {
    Pop-Location
}

# 4. Registrar el repo ----------------------------------------------------------------------------
$proyecto.repo = "https://github.com/$repo"
[IO.File]::WriteAllText($rutaRegistro, (ConvertTo-Json -InputObject @($registro) -Depth 5), $utf8)
Write-Host "✅ $repo listo: main · develop (por defecto) · qa" -ForegroundColor Green

# Hook PostToolUse (Edit y Write): cada .cs que Claude edita queda con el formato del equipo (.editorconfig).
# Solo espacios, sangría y saltos de línea (dotnet format whitespace): no compila, así tarda un segundo.
$accion = [Console]::In.ReadToEnd() | ConvertFrom-Json
$archivo = $accion.tool_input.file_path
if (-not $archivo -or $archivo -notmatch '\.cs$' -or -not (Test-Path $archivo)) { exit 0 }

$carpeta = Split-Path $archivo -Parent
dotnet format whitespace $carpeta --folder --include $archivo 2>&1 | Out-Null
if ($LASTEXITCODE -ne 0) {
    [Console]::Error.WriteLine("dotnet format no pudo dar formato a $(Split-Path $archivo -Leaf)")
    exit 1   # después de editar ya no se puede impedir nada: solo se avisa
}
exit 0

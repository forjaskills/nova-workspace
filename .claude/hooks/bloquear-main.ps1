# Hook PreToolUse (Bash y PowerShell): en main no se hace commit ni push.
# Claude Code manda la acción como JSON por la entrada estándar. Código 2 = se bloquea y Claude lee el mensaje.
$accion = [Console]::In.ReadToEnd() | ConvertFrom-Json
$comando = $accion.tool_input.command
if ($comando -notmatch '\bgit\b.*\b(commit|push)\b') { exit 0 }

# El repo es la carpeta del comando (git -C carpeta, cd carpeta && ..., Set-Location carpeta; ...) o la de la sesión.
$carpeta = $accion.cwd
if ($comando -match '(?:\bgit\s+-C|\bcd|\bSet-Location|\bPush-Location)\s+(?:"([^"]+)"|''([^'']+)''|([^\s;&|]+))') {
    $ruta = @($Matches[1], $Matches[2], $Matches[3]) | Where-Object { $_ } | Select-Object -First 1
    $ruta = $ruta -replace '^/([a-zA-Z])/', '$1:/'          # /c/Users/... de Git Bash
    $carpeta = if ([IO.Path]::IsPathRooted($ruta)) { $ruta } else { Join-Path $accion.cwd $ruta }
}
$rama = git -C $carpeta branch --show-current 2>$null
if ($rama -eq 'main' -or $comando -match '\bpush\b.*\bmain\b') {
    [Console]::Error.WriteLine('En main no se hace commit ni push: crea una rama feature (git switch -c feature/...) y abre un pull request.')
    exit 2
}
exit 0

param(
    [switch]$Remove
)

$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$serverScript = Join-Path $projectRoot 'preview-server.ps1'
$startupDirectory = [Environment]::GetFolderPath('Startup')
$shortcutPath = Join-Path $startupDirectory 'Wuwei Dictionary Preview.lnk'

if ($Remove) {
    Remove-Item -LiteralPath $shortcutPath -Force -ErrorAction SilentlyContinue
    Write-Host "Removed startup shortcut: $shortcutPath"
    exit 0
}

if (-not (Test-Path -LiteralPath $serverScript)) {
    throw "Missing preview server script: $serverScript"
}

$powershellPath = (Get-Command powershell.exe -ErrorAction Stop).Source
$shell = New-Object -ComObject WScript.Shell
$shortcut = $shell.CreateShortcut($shortcutPath)
$shortcut.TargetPath = $powershellPath
$shortcut.Arguments = "-NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File `"$serverScript`" -StartupDelaySeconds 20"
$shortcut.WorkingDirectory = $projectRoot
$shortcut.Description = 'Start the Wuwei Dictionary local web preview after Windows logon'
$shortcut.WindowStyle = 7
$shortcut.Save()

Write-Host "Installed startup shortcut: $shortcutPath"

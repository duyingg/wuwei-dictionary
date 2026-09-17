param(
    [int]$Port = 4173,
    [int]$StartupDelaySeconds = 0
)

$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$webRoot = Join-Path $projectRoot 'build\web'
$indexPath = Join-Path $webRoot 'index.html'
$previewUrl = "http://127.0.0.1:$Port/"
$statusPath = Join-Path $projectRoot 'build\preview-server-status.txt'
$pidPath = Join-Path $projectRoot 'build\preview-server.pid'
$stdoutPath = Join-Path $projectRoot 'build\preview-server.stdout.log'
$stderrPath = Join-Path $projectRoot 'build\preview-server.stderr.log'

function Write-PreviewStatus([string]$Message) {
    $parent = Split-Path -Parent $statusPath
    if (-not (Test-Path -LiteralPath $parent)) {
        New-Item -ItemType Directory -Path $parent -Force | Out-Null
    }
    $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    Set-Content -LiteralPath $statusPath -Value "[$timestamp] $Message" -Encoding UTF8
}

function Test-DictionaryPreview {
    try {
        $response = Invoke-WebRequest -Uri $previewUrl -UseBasicParsing -TimeoutSec 2
        return $response.StatusCode -eq 200 -and
            $response.Content.Contains('flutter_bootstrap.js')
    } catch {
        return $false
    }
}

function Test-PreviewPortOpen {
    $client = New-Object System.Net.Sockets.TcpClient
    try {
        $connection = $client.ConnectAsync('127.0.0.1', $Port)
        return $connection.Wait(1000) -and $client.Connected
    } catch {
        return $false
    } finally {
        $client.Dispose()
    }
}

try {
    if ($StartupDelaySeconds -gt 0) {
        Start-Sleep -Seconds $StartupDelaySeconds
    }

    if (Test-DictionaryPreview) {
        Write-PreviewStatus "Preview already running at $previewUrl"
        exit 0
    }

    if (Test-PreviewPortOpen) {
        throw "Port $Port is occupied, but it is not serving the dictionary preview."
    }

    if (-not (Test-Path -LiteralPath $indexPath)) {
        throw "Web build not found at $indexPath. Run preview.cmd once to build it."
    }

    $pythonCommand = Get-Command python -ErrorAction SilentlyContinue
    $pythonArguments = @('-m', 'http.server', "$Port", '--bind', '127.0.0.1', '--directory', 'build\web')
    if (-not $pythonCommand) {
        $pythonCommand = Get-Command py -ErrorAction SilentlyContinue
        $pythonArguments = @('-3', '-m', 'http.server', "$Port", '--bind', '127.0.0.1', '--directory', 'build\web')
    }
    if (-not $pythonCommand) {
        throw 'Python was not found. Install Python or update preview-server.ps1.'
    }

    Remove-Item -LiteralPath $stdoutPath, $stderrPath -Force -ErrorAction SilentlyContinue
    $serverProcess = Start-Process `
        -FilePath $pythonCommand.Source `
        -ArgumentList $pythonArguments `
        -WorkingDirectory $projectRoot `
        -WindowStyle Hidden `
        -RedirectStandardOutput $stdoutPath `
        -RedirectStandardError $stderrPath `
        -PassThru
    Set-Content -LiteralPath $pidPath -Value $serverProcess.Id -Encoding ASCII

    for ($attempt = 0; $attempt -lt 40; $attempt++) {
        Start-Sleep -Milliseconds 250
        if (Test-DictionaryPreview) {
            Write-PreviewStatus "Preview started at $previewUrl (PID $($serverProcess.Id))."
            exit 0
        }
        if ($serverProcess.HasExited) {
            $detail = if (Test-Path -LiteralPath $stderrPath) {
                (Get-Content -LiteralPath $stderrPath -Raw -ErrorAction SilentlyContinue).Trim()
            } else {
                ''
            }
            throw "Preview server exited with code $($serverProcess.ExitCode). $detail"
        }
    }

    throw "Preview server did not become ready at $previewUrl."
} catch {
    Write-PreviewStatus "FAILED: $($_.Exception.Message)"
    throw
}

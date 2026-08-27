[CmdletBinding()]
param(
    [string]$CodeQL = "codeql"
)

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
$databaseRoot = Join-Path $root ".codeql"
$database = Join-Path $databaseRoot "demo-db"
$artifacts = Join-Path $root "artifacts\codeql"
$sarif = Join-Path $artifacts "codeql-demo.sarif"

function Invoke-Checked {
    param(
        [string]$Command,
        [string[]]$Arguments
    )

    & $Command @Arguments
    if ($LASTEXITCODE -ne 0) {
        throw "'$Command $($Arguments -join ' ')' failed with exit code $LASTEXITCODE."
    }
}

Push-Location $root
try {
    if (-not (Get-Command $CodeQL -ErrorAction SilentlyContinue)) {
        throw "CodeQL CLI was not found. Install it and pass its path with -CodeQL if it is not on PATH."
    }

    $sdkVersion = (& dotnet --version).Trim()
    if (-not $sdkVersion.StartsWith("10.")) {
        throw ".NET 10 SDK is required; found '$sdkVersion'."
    }

    Invoke-Checked dotnet @("restore", "CodeQLDemo.sln")
    Invoke-Checked $CodeQL @("pack", "download", "codeql/csharp-queries@1.9.2")
    Invoke-Checked $CodeQL @("pack", "install", "codeql\demo-queries")
    Invoke-Checked $CodeQL @("pack", "install", "codeql\demo-query-tests")
    Invoke-Checked $CodeQL @("query", "compile", "--check-only", "codeql\demo-queries\src")
    Invoke-Checked $CodeQL @("test", "run", "codeql\demo-query-tests")
    Invoke-Checked dotnet @("test", "CodeQLDemo.sln", "--configuration", "Release", "--no-restore")
    Invoke-Checked dotnet @("clean", "CodeQLDemo.sln", "--configuration", "Release")

    if (Test-Path -LiteralPath $database) {
        Remove-Item -LiteralPath $database -Recurse -Force
    }
    if (Test-Path -LiteralPath $artifacts) {
        Remove-Item -LiteralPath $artifacts -Recurse -Force
    }
    New-Item -ItemType Directory -Path $databaseRoot -Force | Out-Null
    New-Item -ItemType Directory -Path $artifacts | Out-Null

    Invoke-Checked $CodeQL @(
        "database", "create", $database,
        "--language=csharp",
        "--source-root=$root",
        "--command=dotnet build CodeQLDemo.sln --configuration Release --no-restore"
    )
    Invoke-Checked $CodeQL @(
        "database", "analyze", $database,
        "codeql/csharp-queries@1.9.2:codeql-suites/csharp-security-and-quality.qls",
        "codeql\demo-queries\suites\engagement.qls",
        "--format=sarif-latest",
        "--output=$sarif",
        "--sarif-add-baseline-file-info",
        "--threads=0"
    )

    Write-Host "CodeQL analysis complete: $sarif"
}
finally {
    Pop-Location
}

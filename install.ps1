[CmdletBinding(DefaultParameterSetName = "Project")]
param(
    [Parameter(ParameterSetName = "Project")]
    [string]$ProjectPath = (Get-Location).Path,

    [Parameter(Mandatory = $true, ParameterSetName = "Global")]
    [switch]$Global
)

$ErrorActionPreference = "Stop"

$Root = Split-Path -Parent $MyInvocation.MyCommand.Path
$Source = Join-Path $Root ".claude\commands"
$Files = @("audit.md", "spec.md", "build.md", "review.md", "architect.md")

if ($Global) {
    $Destination = Join-Path $HOME ".claude\commands"
} else {
    $ResolvedProject = [System.IO.Path]::GetFullPath($ProjectPath)
    $Destination = Join-Path $ResolvedProject ".claude\commands"
}

foreach ($File in $Files) {
    $SourceFile = Join-Path $Source $File
    if (-not (Test-Path -LiteralPath $SourceFile -PathType Leaf)) {
        throw "Missing source command: $SourceFile"
    }
}

New-Item -ItemType Directory -Force -Path $Destination | Out-Null

foreach ($File in $Files) {
    Copy-Item -LiteralPath (Join-Path $Source $File) -Destination (Join-Path $Destination $File) -Force
}

Write-Host "Installed Claude Code workflow commands in: $Destination"

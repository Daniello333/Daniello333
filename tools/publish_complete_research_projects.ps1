<#
Publishes the curated research source ZIPs into TWO DEDICATED repositories:
  https://github.com/Daniello333/cellscope-ml
  https://github.com/Daniello333/prm-targeted-proteomics

Prerequisites:
  - Git for Windows, with GitHub push authentication
  - The two *github-ready.zip files next to this script
  - Windows PowerShell 5.1+ / PowerShell 7+

Run dry-run (creates local commits only):
  powershell -ExecutionPolicy Bypass -File .\publish_complete_research_projects.ps1

Publish to GitHub:
  powershell -ExecutionPolicy Bypass -File .\publish_complete_research_projects.ps1 -Publish

The script preserves unrelated files, does not force-push or delete repositories,
refuses obvious secrets/large files, and refuses to publish an unexpectedly small ZIP.
#>
[CmdletBinding()]
param(
    [string]$CellScopeZip = '',
    [string]$PrmZip = '',
    [switch]$Publish
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# Resolve ZIP defaults after parameter binding: $PSScriptRoot is reliable in the script body.
if ([string]::IsNullOrWhiteSpace($CellScopeZip)) {
    $CellScopeZip = Join-Path -Path $PSScriptRoot -ChildPath 'cellscope-ml-v1.0-github-ready.zip'
}
if ([string]::IsNullOrWhiteSpace($PrmZip)) {
    $PrmZip = Join-Path -Path $PSScriptRoot -ChildPath 'prm-targeted-proteomics-github-ready.zip'
}

if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    throw 'Git is not installed. Install Git for Windows, reopen PowerShell and try again.'
}

$plans = @(
    [pscustomobject]@{
        Name    = 'cellscope-ml'
        Url     = 'https://github.com/Daniello333/cellscope-ml.git'
        Zip     = $CellScopeZip
        Minimum = 60
    },
    [pscustomobject]@{
        Name    = 'prm-targeted-proteomics'
        Url     = 'https://github.com/Daniello333/prm-targeted-proteomics.git'
        Zip     = $PrmZip
        Minimum = 10
    }
)

foreach ($p in $plans) {
    if (-not (Test-Path -LiteralPath $p.Zip -PathType Leaf)) {
        throw "Missing source package: $($p.Zip). Put the script and both ZIP files in one folder."
    }
}

$workspace = Join-Path ([IO.Path]::GetTempPath()) ('portfolio-publish-' + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $workspace -Force | Out-Null

function Assert-Exit([string]$Action) {
    if ($LASTEXITCODE -ne 0) { throw "$Action failed. Your local copy is at: $workspace" }
}

function Get-SourceRoot([string]$Dir) {
    $root = $Dir
    for ($i = 0; $i -lt 4; $i++) {
        $entries = @(Get-ChildItem -LiteralPath $root -Force)
        $dirs = @($entries | Where-Object { $_.PSIsContainer })
        $files = @($entries | Where-Object { -not $_.PSIsContainer })
        if ($dirs.Count -eq 1 -and $files.Count -eq 0) {
            $root = $dirs[0].FullName
        } else { break }
    }
    return $root
}

function Is-Excluded([string]$RelativePath, [long]$Bytes) {
    $path = $RelativePath.Replace('\', '/')
    $segments = @($path.Split('/'))
    $forbiddenDirs = @('.git', '.venv', 'venv', '__pycache__', '.pytest_cache',
                       '.mypy_cache', '.ruff_cache', '.idea', '.ipynb_checkpoints', 'node_modules')
    foreach ($seg in $segments) {
        if ($forbiddenDirs -contains $seg) { return $true }
    }
    if ($path -match '(^|/)(\.env($|\.)|id_rsa|id_ed25519|credentials\.json|secrets\.json|.*\.(pem|p12|key)$)') {
        throw "Potential secret file found. Review the export before publishing: $RelativePath"
    }
    if ($Bytes -gt 15000000) {
        throw "Unexpected file larger than 15 MB in curated ZIP: $RelativePath"
    }
    return $false
}

$prepared = @()
foreach ($p in $plans) {
    Write-Host ""
    Write-Host "Preparing $($p.Name) ..." -ForegroundColor Cyan
    $destination = Join-Path $workspace $p.Name
    & git clone --quiet -- $p.Url $destination
    Assert-Exit "Clone of $($p.Name)"

    $branch = (& git -C $destination branch --show-current).Trim()
    Assert-Exit "Read branch of $($p.Name)"
    if (-not $branch) { throw "No default branch found for $($p.Name)." }

    $expanded = Join-Path $workspace ('extracted-' + $p.Name)
    New-Item -ItemType Directory -Path $expanded -Force | Out-Null
    Expand-Archive -LiteralPath $p.Zip -DestinationPath $expanded -Force
    $sourceRoot = Get-SourceRoot $expanded

    $files = @(Get-ChildItem -LiteralPath $sourceRoot -Recurse -File -Force)
    if ($files.Count -lt $p.Minimum) {
        throw "Expected at least $($p.Minimum) files in $($p.Zip), found $($files.Count). Aborting."
    }
    $count = 0
    foreach ($file in $files) {
        $relative = $file.FullName.Substring($sourceRoot.Length).TrimStart([char[]]@('\', '/'))
        if ((Is-Excluded $relative $file.Length)) { continue }
        $destFile = Join-Path $destination $relative
        New-Item -ItemType Directory -Path (Split-Path -Parent $destFile) -Force | Out-Null
        Copy-Item -LiteralPath $file.FullName -Destination $destFile -Force
        # Normalize trailing whitespace in curated Markdown and R source files.
        # Only end-of-line horizontal whitespace is changed, never program statements.
        if ($file.Extension -in @('.md', '.R', '.r')) {
            $sourceText = [System.IO.File]::ReadAllText($destFile)
            $cleanText = [regex]::Replace($sourceText, '(?m)[ \t]+(?=\r?$)', '')
            if ($cleanText -cne $sourceText) {
                [System.IO.File]::WriteAllText(
                    $destFile, $cleanText, [System.Text.UTF8Encoding]::new($false)
                )
            }
        }
        $count++
    }
    Write-Host "Imported $count curated files into $($p.Name)." -ForegroundColor Green

    & git -C $destination add --all
    Assert-Exit "Staging $($p.Name)"
    & git -C $destination diff --cached --check
    Assert-Exit "Whitespace checks for $($p.Name)"

    $changed = @(& git -C $destination diff --cached --name-only)
    Assert-Exit "Inspect staged changes of $($p.Name)"
    $hasChanges = @($changed | Where-Object { $_ -ne '' }).Count -gt 0

    if ($hasChanges) {
        & git -C $destination --no-pager diff --cached --stat
        Assert-Exit "Diff summary for $($p.Name)"
        & git -C $destination commit -m 'feat: publish complete curated research source export'
        Assert-Exit "Commit to $($p.Name)"
    } else {
        Write-Host "No differences found in $($p.Name)."
    }
    $prepared += [pscustomobject]@{
        Name = $p.Name; Branch = $branch; Local = $destination; HasChanges = $hasChanges
    }
}

Write-Host ""
if ($Publish) {
    foreach ($item in $prepared) {
        if ($item.HasChanges) {
            & git -C $item.Local push origin "HEAD:$($item.Branch)"
            Assert-Exit "Push to $($item.Name)"
        }
        Write-Host "Published: https://github.com/Daniello333/$($item.Name)" -ForegroundColor Green
    }
} else {
    Write-Host "Dry run complete: local commits were made, but nothing was pushed." -ForegroundColor Yellow
    Write-Host "Review the diffs in $workspace, then rerun with -Publish."
}
Write-Host "Workspace: $workspace"

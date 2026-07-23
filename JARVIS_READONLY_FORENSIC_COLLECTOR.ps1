# JARVIS_READONLY_FORENSIC_COLLECTOR.ps1
# One-shot forensic discovery of JARVIS media stack
# Safe, read-only filesystem and Git inspection
# Generates JSON and Markdown reports
# No cloning, no installation, no mutations

param(
    [string]$JarvisRoot = "C:\Users\rober\Documents\aivideo\jarvis",
    [string]$ReportDir = $null
)

# Initialize report directory
if (-not $ReportDir) {
    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $ReportDir = Join-Path $JarvisRoot "forensic_reports\$timestamp"
}

# Create report directory
New-Item -ItemType Directory -Force -Path $ReportDir | Out-Null
Write-Host "Forensic reports will be saved to: $ReportDir"

# Initialize collections
$repositories = @()
$models = @()
$pythonEnvs = @()
$nodeProjects = @()
$comfyuiInstances = @()
$dockerIndicators = @()
$launchScripts = @()
$architectureDocuments = @()
$errors = @()
$warnings = @()
$diskUsage = @{}

# Helper function: Safe error handling
function Add-Error {
    param([string]$Path, [string]$Message)
    $errors += @{
        path    = $Path
        message = $Message
        time    = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    }
}

# Helper function: Normalize Git remotes
function Normalize-RemoteUrl {
    param([string]$Url)
    if (-not $Url) { return $null }
    # Remove trailing .git
    $normalized = $Url -replace '\.git$', ''
    # Convert ssh to https form for comparison
    $normalized = $normalized -replace '^git@github\.com:', 'github.com/'
    $normalized = $normalized -replace '^git@gitlab\.com:', 'gitlab.com/'
    return $normalized
}

# 1. RECURSIVE GIT REPOSITORY DISCOVERY
Write-Host "`n=== Phase 1: Git Repository Discovery ===" -ForegroundColor Cyan

$gitDirs = Get-ChildItem -Path $JarvisRoot -Filter ".git" -Recurse -Directory -ErrorAction SilentlyContinue

foreach ($gitDir in $gitDirs) {
    try {
        $repoPath = $gitDir.Parent.FullName
        $repoName = $gitDir.Parent.Name
        
        # Avoid nested repos
        $parent = Split-Path -Parent $repoPath
        if ($parent -and (Test-Path (Join-Path $parent ".git"))) {
            continue
        }
        
        Push-Location $repoPath
        
        # Git metadata
        $remotes = @()
        $remoteOutput = & git remote -v 2>$null
        if ($remoteOutput) {
            $remoteLines = $remoteOutput -split "`n" | Where-Object { $_ -match '\s+' }
            $uniqueRemotes = @{}
            foreach ($line in $remoteLines) {
                $parts = $line -split '\s+' | Where-Object { $_ }
                if ($parts.Count -ge 3) {
                    $name = $parts[0]
                    $url = $parts[1]
                    $normalized = Normalize-RemoteUrl $url
                    if (-not $uniqueRemotes.ContainsKey($name)) {
                        $remotes += @{
                            name       = $name
                            url        = $url
                            normalized = $normalized
                        }
                        $uniqueRemotes[$name] = $url
                    }
                }
            }
        }
        
        $currentBranch = & git rev-parse --abbrev-ref HEAD 2>$null
        $currentCommit = & git rev-parse HEAD 2>$null
        $commitDate = & git log -1 --format=%ai HEAD 2>$null
        $isDirty = & git status --porcelain 2>$null | Measure-Object -Line | Select-Object -ExpandProperty Lines
        
        $submodules = @()
        $gitmodules = Join-Path $repoPath ".gitmodules"
        if (Test-Path $gitmodules) {
            $content = Get-Content $gitmodules
            $submodules = $content | Select-String "path\s*=\s*(.+)" | ForEach-Object { $_.Matches.Groups[1].Value.Trim() }
        }
        
        # Classify by content indicators
        $keywords = @()
        $repoFiles = Get-ChildItem -Path $repoPath -Recurse -File -Depth 3 -ErrorAction SilentlyContinue | 
            Select-Object -ExpandProperty Name | Select-Object -First 500
        
        $classificationKeywords = @(
            'video', 'diffusion', 'wan', 'ltx', 'cogvideo', 'hunyuan', 'animatediff',
            'music', 'ace-step', 'musicgen', 'bark',
            'demucs', 'vocal', 'separation', 'stem',
            'denoise', 'deepfilter', 'whisper',
            'pedalboard', 'vst', 'mix', 'master',
            'pyscenedetect', 'scene', 'beat', 'edit',
            'comfyui', 'vimax', 'orchestrat', 'agent',
            'ffmpeg', 'rendering'
        )
        
        foreach ($keyword in $classificationKeywords) {
            if ($repoFiles -match $keyword) {
                $keywords += $keyword
                break
            }
        }
        
        # Disk footprint
        $size = 0
        try {
            $size = (Get-ChildItem -Path $repoPath -Recurse -File -ErrorAction SilentlyContinue | 
                Measure-Object -Property Length -Sum).Sum
        } catch {
            # Silently skip if inaccessible
        }
        
        $repositories += @{
            name              = $repoName
            path              = $repoPath
            remotes           = $remotes
            currentBranch     = $currentBranch
            currentCommit     = $currentCommit
            commitDate        = $commitDate
            isDirty           = if ($isDirty -gt 0) { $true } else { $false }
            dirtyLines        = $isDirty
            submodules        = $submodules
            classificationKeywords = $keywords
            diskSizeBytes     = $size
            discoveryTime     = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        }
        
        Pop-Location
        Write-Host "  Found: $repoName ($currentCommit)"
    }
    catch {
        Add-Error $gitDir.Parent.FullName "Git inspection failed: $_"
        Pop-Location -ErrorAction SilentlyContinue
    }
}

# 2. DUPLICATE DETECTION
Write-Host "`n=== Phase 2: Duplicate Detection ===" -ForegroundColor Cyan

$remoteIndex = @{}
$duplicates = @()

foreach ($repo in $repositories) {
    foreach ($remote in $repo.remotes) {
        $normalized = $remote.normalized
        if (-not $normalized) { continue }
        
        if (-not $remoteIndex.ContainsKey($normalized)) {
            $remoteIndex[$normalized] = @()
        }
        $remoteIndex[$normalized] += @{
            name = $repo.name
            path = $repo.path
        }
    }
}

foreach ($normalized in $remoteIndex.Keys) {
    if ($remoteIndex[$normalized].Count -gt 1) {
        $duplicates += @{
            normalizedRemote = $normalized
            locations        = $remoteIndex[$normalized]
            count            = $remoteIndex[$normalized].Count
        }
    }
}

if ($duplicates.Count -gt 0) {
    Write-Host "  Found $($duplicates.Count) duplicate remote(s)"
} else {
    Write-Host "  No duplicates detected"
}

# 3. COMFYUI FORENSICS
Write-Host "`n=== Phase 3: ComfyUI Detection ===" -ForegroundColor Cyan

$comfyuiRepo = $repositories | Where-Object { $_.path -match 'comfyui' -or $_.classificationKeywords -contains 'comfyui' } | Select-Object -First 1

if ($comfyuiRepo) {
    $customNodesPath = Join-Path $comfyuiRepo.path "custom_nodes"
    $customNodes = @()
    
    if (Test-Path $customNodesPath) {
        $nodesDirs = Get-ChildItem -Path $customNodesPath -Directory -ErrorAction SilentlyContinue
        foreach ($nodeDir in $nodesDirs) {
            try {
                $gitConfig = Join-Path $nodeDir.FullName ".git\config"
                $remote = $null
                if (Test-Path $gitConfig) {
                    $configContent = Get-Content $gitConfig
                    $remote = $configContent | Select-String 'url\s*=\s*(.+)' | ForEach-Object { $_.Matches.Groups[1].Value.Trim() }
                }
                
                $customNodes += @{
                    name   = $nodeDir.Name
                    path   = $nodeDir.FullName
                    remote = $remote
                }
            }
            catch {
                Add-Error $nodeDir.FullName "ComfyUI node inspection failed: $_"
            }
        }
    }
    
    $modelPath = Join-Path $comfyuiRepo.path "models"
    $modelDirs = @()
    if (Test-Path $modelPath) {
        $modelDirs = Get-ChildItem -Path $modelPath -Directory -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Name
    }
    
    $comfyuiInstances += @{
        path          = $comfyuiRepo.path
        commit        = $comfyuiRepo.currentCommit
        branch        = $comfyuiRepo.currentBranch
        customNodes   = $customNodes
        modelDirs     = $modelDirs
        customNodeCount = $customNodes.Count
    }
    
    Write-Host "  Found ComfyUI at: $($comfyuiRepo.path)"
    Write-Host "  Custom nodes: $($customNodes.Count)"
} else {
    Write-Host "  No ComfyUI installation detected"
}

# 4. VIMAX FORENSICS
Write-Host "`n=== Phase 4: ViMax Detection ===" -ForegroundColor Cyan

$vimaxRepo = $repositories | Where-Object { $_.path -match 'vimax' -or $_.classificationKeywords -contains 'vimax' } | Select-Object -First 1
$vimaxStatus = if ($vimaxRepo) { "FOUND" } else { "NOT_FOUND" }

if ($vimaxRepo) {
    Write-Host "  Found ViMax at: $($vimaxRepo.path)"
    Write-Host "  Branch: $($vimaxRepo.currentBranch), Commit: $($vimaxRepo.currentCommit)"
} else {
    Write-Host "  ViMax not detected"
}

# 5. MODEL INVENTORY
Write-Host "`n=== Phase 5: Model Files ===" -ForegroundColor Cyan

$modelExtensions = @('*.gguf', '*.safetensors', '*.ckpt', '*.pt', '*.pth', '*.onnx', '*.bin')
$modelFiles = @()

foreach ($ext in $modelExtensions) {
    try {
        $found = Get-ChildItem -Path $JarvisRoot -Filter $ext -Recurse -File -ErrorAction SilentlyContinue
        foreach ($file in $found) {
            $modelFiles += @{
                name   = $file.Name
                path   = $file.FullName
                ext    = $file.Extension
                sizeGB = [math]::Round($file.Length / 1GB, 2)
            }
        }
    }
    catch {
        Add-Error $JarvisRoot "Model search failed for $ext : $_"
    }
}

Write-Host "  Found $($modelFiles.Count) model file(s)"

# 6. PYTHON ENVIRONMENTS
Write-Host "`n=== Phase 6: Python Environments ===" -ForegroundColor Cyan

$pythonPatterns = @('*venv', '*.venv', '*conda*')
$pythonEnvDirs = @()

foreach ($pattern in $pythonPatterns) {
    try {
        $found = Get-ChildItem -Path $JarvisRoot -Filter $pattern -Recurse -Directory -ErrorAction SilentlyContinue | 
            Where-Object { Test-Path (Join-Path $_.FullName "pyvenv.cfg") -or Test-Path (Join-Path $_.FullName "activate.bat") }
        
        foreach ($env in $found) {
            $pythonEnvs += @{
                name = $env.Name
                path = $env.FullName
                type = if (Test-Path (Join-Path $env.FullName "pyvenv.cfg")) { "venv" } else { "conda" }
            }
        }
    }
    catch {
        Add-Error $JarvisRoot "Python environment search failed: $_"
    }
}

# Look for requirements.txt and pyproject.toml
$requirementsFiles = Get-ChildItem -Path $JarvisRoot -Include 'requirements*.txt', 'pyproject.toml', 'poetry.lock', 'uv.lock', 'Pipfile' -Recurse -File -ErrorAction SilentlyContinue
Write-Host "  Found $($pythonEnvs.Count) Python environment(s)"
Write-Host "  Found $($requirementsFiles.Count) dependency file(s)"

# 7. NODE / FRONTEND ENVIRONMENTS
Write-Host "`n=== Phase 7: Node.js Projects ===" -ForegroundColor Cyan

$packageJsonFiles = Get-ChildItem -Path $JarvisRoot -Filter 'package.json' -Recurse -File -ErrorAction SilentlyContinue

foreach ($pkgFile in $packageJsonFiles) {
    try {
        $content = Get-Content $pkgFile -Raw | ConvertFrom-Json
        $nodeProjects += @{
            name = $content.name
            path = $pkgFile.Directory.FullName
            type = if ($content.type -eq 'module') { 'ES6' } else { 'CommonJS' }
        }
    }
    catch {
        Add-Error $pkgFile.FullName "package.json parsing failed: $_"
    }
}

Write-Host "  Found $($nodeProjects.Count) Node.js project(s)"

# 8. DOCKER / WSL INDICATORS
Write-Host "`n=== Phase 8: Docker / WSL Indicators ===" -ForegroundColor Cyan

$dockerFiles = Get-ChildItem -Path $JarvisRoot -Include 'Dockerfile', 'docker-compose.yml', 'compose.yml' -Recurse -File -ErrorAction SilentlyContinue
$devContainers = Get-ChildItem -Path $JarvisRoot -Include '.devcontainer*' -Recurse -Directory -ErrorAction SilentlyContinue

foreach ($file in $dockerFiles) {
    $dockerIndicators += @{
        file = $file.Name
        path = $file.FullName
    }
}

Write-Host "  Found $($dockerIndicators.Count) Docker file(s)"
Write-Host "  Found $($devContainers.Count) devcontainer(s)"

# 9. LAUNCH SCRIPTS
Write-Host "`n=== Phase 9: Launch Scripts ===" -ForegroundColor Cyan

$scriptExtensions = @('*.ps1', '*.bat', '*.cmd', '*.sh')
foreach ($ext in $scriptExtensions) {
    try {
        $found = Get-ChildItem -Path $JarvisRoot -Filter $ext -Recurse -File -ErrorAction SilentlyContinue | 
            Where-Object { $_.Directory.Name -notmatch 'node_modules|\.git|venv' } |
            Select-Object -First 100
        
        foreach ($script in $found) {
            $launchScripts += @{
                name = $script.Name
                path = $script.FullName
                ext  = $script.Extension
            }
        }
    }
    catch {
        Add-Error $JarvisRoot "Launch script search failed for $ext : $_"
    }
}

Write-Host "  Found $($launchScripts.Count) launch script(s)"

# 10. ARCHITECTURE / AUDIT DOCUMENTS
Write-Host "`n=== Phase 10: Architecture Documents ===" -ForegroundColor Cyan

$docPatterns = @('*JARVIS*', '*HERMES*', '*PHASE*', '*AUDIT*', '*STACK*', '*ARCHITECTURE*', '*MEDIA*', '*VIDEO*', '*MUSIC*', '*BENCHMARK*')
foreach ($pattern in $docPatterns) {
    try {
        $found = Get-ChildItem -Path $JarvisRoot -Filter "$pattern.md" -Recurse -File -ErrorAction SilentlyContinue
        foreach ($doc in $found) {
            $architectureDocuments += @{
                name = $doc.Name
                path = $doc.FullName
                size = $doc.Length
            }
        }
    }
    catch {
        Add-Error $JarvisRoot "Architecture document search failed: $_"
    }
}

Write-Host "  Found $($architectureDocuments.Count) architecture document(s)"

# 11. DISK USAGE SUMMARY
Write-Host "`n=== Phase 11: Disk Usage ===" -ForegroundColor Cyan

try {
    $rootSize = (Get-ChildItem -Path $JarvisRoot -Recurse -File -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum
    $diskUsage["JARVIS_ROOT_BYTES"] = $rootSize
    $diskUsage["JARVIS_ROOT_GB"] = [math]::Round($rootSize / 1GB, 2)
    
    $researchRoot = Join-Path $JarvisRoot "research"
    if (Test-Path $researchRoot) {
        $researchSize = (Get-ChildItem -Path $researchRoot -Recurse -File -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum
        $diskUsage["RESEARCH_ROOT_BYTES"] = $researchSize
        $diskUsage["RESEARCH_ROOT_GB"] = [math]::Round($researchSize / 1GB, 2)
    }
    
    foreach ($repo in $repositories) {
        $diskUsage[$repo.name] = @{
            bytes = $repo.diskSizeBytes
            gb    = [math]::Round($repo.diskSizeBytes / 1GB, 2)
        }
    }
    
    Write-Host "  JARVIS root: $($diskUsage['JARVIS_ROOT_GB']) GB"
} catch {
    Add-Error $JarvisRoot "Disk usage calculation failed: $_"
}

# GENERATE JSON REPORT
Write-Host "`n=== Generating JSON Report ===" -ForegroundColor Cyan

$jsonReport = @{
    metadata = @{
        timestamp        = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        jarvisRoot       = $JarvisRoot
        researchRoot     = Join-Path $JarvisRoot "research"
        collectorVersion = "1.0"
    }
    summary  = @{
        totalRepositories     = $repositories.Count
        totalModels           = $modelFiles.Count
        totalPythonEnvs       = $pythonEnvs.Count
        totalNodeProjects     = $nodeProjects.Count
        totalDuplicates       = $duplicates.Count
        comfyuiFound          = if ($comfyuiRepo) { $true } else { $false }
        vimaxStatus           = $vimaxStatus
        totalErrors           = $errors.Count
        totalWarnings         = $warnings.Count
    }
    repositories   = $repositories
    duplicates     = $duplicates
    comfyui        = $comfyuiInstances
    vimax          = @{
        status = $vimaxStatus
        repo   = $vimaxRepo
    }
    models         = $modelFiles
    pythonEnvs     = $pythonEnvs
    nodeProjects   = $nodeProjects
    dockerIndicators = $dockerIndicators
    launchScripts  = $launchScripts
    architectureDocuments = $architectureDocuments
    diskUsage      = $diskUsage
    errors         = $errors
    warnings       = $warnings
}

$jsonPath = Join-Path $ReportDir "JARVIS_FORENSIC_SNAPSHOT.json"
$jsonReport | ConvertTo-Json -Depth 10 | Set-Content -Path $jsonPath
Write-Host "JSON report saved: $jsonPath"

# GENERATE MARKDOWN REPORT
Write-Host "`n=== Generating Markdown Report ===" -ForegroundColor Cyan

$mdContent = @"
# JARVIS Forensic Snapshot Report

**Generated:** $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")  
**JARVIS Root:** $JarvisRoot  
**Research Root:** $(Join-Path $JarvisRoot 'research')

## Summary

- **Git Repositories Found:** $($repositories.Count)
- **Model Files Discovered:** $($modelFiles.Count)
- **Python Environments:** $($pythonEnvs.Count)
- **Node.js Projects:** $($nodeProjects.Count)
- **Duplicate Remotes:** $($duplicates.Count)
- **ComfyUI Installed:** $(if ($comfyuiRepo) { "YES" } else { "NO" })
- **ViMax Status:** $vimaxStatus
- **Disk Usage:** $($diskUsage['JARVIS_ROOT_GB']) GB
- **Errors/Warnings:** $($errors.Count) errors, $($warnings.Count) warnings

## Git Repositories

| Repository | Path | Branch | Commit | Dirty | Size (GB) | Keywords |
|-----------|------|--------|--------|-------|-----------|----------|
"@

foreach ($repo in $repositories | Sort-Object -Property name) {
    $keywords = if ($repo.classificationKeywords) { ($repo.classificationKeywords -join ', ') } else { "—" }
    $sizeGb = [math]::Round($repo.diskSizeBytes / 1GB, 2)
    $dirty = if ($repo.isDirty) { "YES ($($repo.dirtyLines) lines)" } else { "NO" }
    $commit = $repo.currentCommit.Substring(0, 7)
    $mdContent += "`n| $($repo.name) | `.../$($repo.name) | $($repo.currentBranch) | $commit | $dirty | $sizeGb | $keywords |"
}

if ($duplicates.Count -gt 0) {
    $mdContent += "`n`n## Duplicate Remotes (Same Repository, Multiple Locations)

| Remote | Count | Locations |
|--------|-------|-----------|
"
    foreach ($dup in $duplicates) {
        $locations = ($dup.locations | ForEach-Object { $_.name }) -join ', '
        $mdContent += "`n| $($dup.normalizedRemote) | $($dup.count) | $locations |"
    }
}

if ($comfyuiRepo) {
    $mdContent += "`n`n## ComfyUI Installation

- **Path:** $($comfyuiInstances[0].path)
- **Branch:** $($comfyuiInstances[0].branch)
- **Commit:** $($comfyuiInstances[0].commit)
- **Custom Nodes Installed:** $($comfyuiInstances[0].customNodeCount)
- **Model Directories:** $($comfyuiInstances[0].modelDirs.Count)

### Custom Nodes

| Node | Path | Remote |
|------|------|--------|
"
    foreach ($node in $comfyuiInstances[0].customNodes) {
        $remote = if ($node.remote) { $node.remote } else { "—" }
        $mdContent += "`n| $($node.name) | `.../$($node.name) | $remote |"
    }
}

if ($vimaxRepo) {
    $mdContent += "`n`n## ViMax Installation

- **Path:** $($vimaxRepo.path)
- **Branch:** $($vimaxRepo.currentBranch)
- **Commit:** $($vimaxRepo.currentCommit)
- **Status:** FOUND
"
} else {
    $mdContent += "`n`n## ViMax Status

**NOT DETECTED** in repository scan.
"
}

if ($modelFiles.Count -gt 0) {
    $mdContent += "`n`n## Model Files

| Model | Format | Size (GB) |
|-------|--------|-----------|
"
    foreach ($model in $modelFiles | Sort-Object -Property sizeGB -Descending | Select-Object -First 50) {
        $mdContent += "`n| $($model.name) | $($model.ext) | $($model.sizeGB) |"
    }
    if ($modelFiles.Count -gt 50) {
        $mdContent += "`n| ... | ... | ... |`n| *Total: $($modelFiles.Count) models* | | |"
    }
}

if ($pythonEnvs.Count -gt 0) {
    $mdContent += "`n`n## Python Environments

| Environment | Path | Type |
|-------------|------|------|
"
    foreach ($env in $pythonEnvs) {
        $mdContent += "`n| $($env.name) | `.../$($env.name) | $($env.type) |"
    }
}

if ($launchScripts.Count -gt 0) {
    $mdContent += "`n`n## Launch Scripts (Sample)

| Script | Path |
|--------|------|
"
    foreach ($script in $launchScripts | Select-Object -First 20) {
        $mdContent += "`n| $($script.name) | `.../$($script.name) |"
    }
    if ($launchScripts.Count -gt 20) {
        $mdContent += "`n| ... | ... |`n| *Total: $($launchScripts.Count) scripts* | |"
    }
}

if ($architectureDocuments.Count -gt 0) {
    $mdContent += "`n`n## Architecture / Audit Documents

| Document | Path |
|----------|------|
"
    foreach ($doc in $architectureDocuments) {
        $mdContent += "`n| $($doc.name) | `.../$($doc.name) |"
    }
}

if ($errors.Count -gt 0) {
    $mdContent += "`n`n## Errors During Collection

| Path | Error |
|------|-------|
"
    foreach ($err in $errors | Select-Object -First 20) {
        $mdContent += "`n| `.../ | $($err.message) |"
    }
    if ($errors.Count -gt 20) {
        $mdContent += "`n| ... | ... |`n| *Total: $($errors.Count) errors* | |"
    }
}

$mdPath = Join-Path $ReportDir "JARVIS_FORENSIC_SNAPSHOT.md"
Set-Content -Path $mdPath -Value $mdContent
Write-Host "Markdown report saved: $mdPath"

# COMPLETION
Write-Host "`n=== Collection Complete ===" -ForegroundColor Green
Write-Host "Reports saved to: $ReportDir"
Write-Host "  - JSON: JARVIS_FORENSIC_SNAPSHOT.json"
Write-Host "  - Markdown: JARVIS_FORENSIC_SNAPSHOT.md"
Write-Host ""
Write-Host "Summary:"
Write-Host "  Repositories: $($repositories.Count)"
Write-Host "  Models: $($modelFiles.Count)"
Write-Host "  Duplicates: $($duplicates.Count)"
Write-Host "  Errors: $($errors.Count)"

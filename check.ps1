<#
.SYNOPSIS
    Prueft ob alle Neovim-Abhaengigkeiten korrekt installiert sind

.EXAMPLE
    .\check.ps1
#>

$ErrorActionPreference = "SilentlyContinue"

function Write-OK { param($msg) Write-Host "  [OK] " -ForegroundColor Green -NoNewline; Write-Host $msg }
function Write-Fail { param($msg) Write-Host "  [--] " -ForegroundColor Red -NoNewline; Write-Host $msg }
function Write-Info { param($msg) Write-Host "  [i]  " -ForegroundColor Cyan -NoNewline; Write-Host $msg }

function Test-Tool {
    param(
        [string]$Command,
        [string]$Name,
        [string]$VersionArg = "--version",
        [string]$InstallHint = ""
    )

    $result = Get-Command $Command -ErrorAction SilentlyContinue
    if ($result) {
        $version = ""
        try {
            $version = (& $Command $VersionArg 2>&1 | Select-Object -First 1) -replace '\s+', ' '
            if ($version.Length -gt 60) { $version = $version.Substring(0, 60) + "..." }
        } catch {}

        Write-Host "  [OK] " -ForegroundColor Green -NoNewline
        Write-Host "$Name" -NoNewline
        if ($version) { Write-Host " - $version" -ForegroundColor DarkGray } else { Write-Host "" }
        return $true
    } else {
        Write-Host "  [--] " -ForegroundColor Red -NoNewline
        Write-Host "$Name" -NoNewline
        if ($InstallHint) { Write-Host " ($InstallHint)" -ForegroundColor Yellow } else { Write-Host "" }
        return $false
    }
}

function Test-Path-Exists {
    param(
        [string]$Path,
        [string]$Name
    )

    if (Test-Path $Path) {
        Write-OK "$Name"
        return $true
    } else {
        Write-Fail "$Name nicht gefunden: $Path"
        return $false
    }
}

# Header
Write-Host @"

 _   _                 _              ____ _               _
| \ | | ___  _____   _(_)_ __ ___    / ___| |__   ___  ___| | __
|  \| |/ _ \/ _ \ \ / / | '_ ` _ \  | |   | '_ \ / _ \/ __| |/ /
| |\  |  __/ (_) \ V /| | | | | | | | |___| | | |  __/ (__|   <
|_| \_|\___|\___/ \_/ |_|_| |_| |_|  \____|_| |_|\___|\___|_|\_\

"@ -ForegroundColor Magenta

$failed = 0
$passed = 0

# ============================================================================
# KERN-TOOLS
# ============================================================================
Write-Host "`n=== Kern-Tools ===" -ForegroundColor Yellow

if (Test-Tool "nvim" "Neovim" "-v" "winget install Neovim.Neovim") { $passed++ } else { $failed++ }
if (Test-Tool "git" "Git" "--version" "winget install Git.Git") { $passed++ } else { $failed++ }

# ============================================================================
# COMPILER & BUILD
# ============================================================================
Write-Host "`n=== Compiler (Treesitter) ===" -ForegroundColor Yellow

$hasCompiler = $false
# Zig zuerst pruefen (bevorzugt)
if (Test-Tool "zig" "Zig" "version" "winget install zig.zig") { $hasCompiler = $true; $passed++ }
elseif (Test-Tool "clang" "Clang" "--version" "winget install LLVM.LLVM") { $hasCompiler = $true; $passed++ }
elseif (Test-Tool "gcc" "GCC" "--version") { $hasCompiler = $true; $passed++ }
elseif (Test-Tool "cl" "MSVC (cl.exe)" "" "Visual Studio Build Tools") { $hasCompiler = $true; $passed++ }
else { $failed++ }

if (-not $hasCompiler) {
    Write-Info "Mindestens einer benoetigt: zig (empfohlen), clang, gcc oder cl"
}

# ============================================================================
# SUCH-TOOLS (Telescope)
# ============================================================================
Write-Host "`n=== Such-Tools (Telescope) ===" -ForegroundColor Yellow

if (Test-Tool "rg" "ripgrep" "--version" "winget install BurntSushi.ripgrep.MSVC") { $passed++ } else { $failed++ }
if (Test-Tool "fd" "fd" "--version" "winget install sharkdp.fd") { $passed++ } else { $failed++ }
if (Test-Tool "fzf" "fzf" "--version" "winget install junegunn.fzf") { $passed++ } else { $failed++ }

# ============================================================================
# GIT TOOLS
# ============================================================================
Write-Host "`n=== Git Tools ===" -ForegroundColor Yellow

if (Test-Tool "lazygit" "lazygit" "--version" "winget install JesseDuffield.lazygit") { $passed++ } else { $failed++ }

# ============================================================================
# .NET / C# ENTWICKLUNG
# ============================================================================
Write-Host "`n=== .NET / C# Entwicklung ===" -ForegroundColor Yellow

if (Test-Tool "dotnet" ".NET SDK" "--version" "winget install Microsoft.DotNet.SDK.8") { $passed++ } else { $failed++ }

# OmniSharp
$omniSharpPath = "$env:LOCALAPPDATA\omnisharp\OmniSharp.exe"
if (Test-Path $omniSharpPath) {
    Write-OK "OmniSharp ($omniSharpPath)"
    $passed++
} elseif (Get-Command "OmniSharp" -ErrorAction SilentlyContinue) {
    Write-OK "OmniSharp (im PATH)"
    $passed++
} else {
    Write-Fail "OmniSharp (install.ps1 erneut ausfuehren)"
    $failed++
}

# netcoredbg
$netcoredbgPath = "$env:LOCALAPPDATA\netcoredbg\netcoredbg.exe"
if (Test-Path $netcoredbgPath) {
    Write-OK "netcoredbg ($netcoredbgPath)"
    $passed++
} elseif (Get-Command "netcoredbg" -ErrorAction SilentlyContinue) {
    Write-OK "netcoredbg (im PATH)"
    $passed++
} else {
    Write-Fail "netcoredbg (install.ps1 erneut ausfuehren)"
    $failed++
}

# ============================================================================
# LUA ENTWICKLUNG
# ============================================================================
Write-Host "`n=== Lua Entwicklung ===" -ForegroundColor Yellow

if (Test-Tool "lua-language-server" "Lua Language Server" "--version" "winget install sumneko.lua-language-server") { $passed++ } else { $failed++ }

# ============================================================================
# NEOVIM KONFIGURATION
# ============================================================================
Write-Host "`n=== Neovim Konfiguration ===" -ForegroundColor Yellow

$nvimConfigPath = "$env:LOCALAPPDATA\nvim"
if (Test-Path "$nvimConfigPath\init.lua") {
    Write-OK "Neovim Config ($nvimConfigPath)"
    $passed++

    # Pruefe ob lazy.nvim installiert ist
    $lazyPath = "$env:LOCALAPPDATA\nvim-data\lazy\lazy.nvim"
    if (Test-Path $lazyPath) {
        Write-OK "lazy.nvim Plugin Manager"
    } else {
        Write-Info "lazy.nvim wird beim ersten nvim-Start installiert"
    }
} else {
    Write-Fail "Neovim Config nicht gefunden"
    Write-Info "git clone https://github.com/ulfbert-san/nvimconfig.git $nvimConfigPath"
    $failed++
}

# ============================================================================
# LOKALES PLUGIN
# ============================================================================
Write-Host "`n=== Lokales Plugin ===" -ForegroundColor Yellow

$asyncompletePath = "C:\Users\$env:USERNAME\Repos\asyncomplete-omnisharp"
if (Test-Path "$asyncompletePath\.git") {
    Write-OK "asyncomplete-omnisharp ($asyncompletePath)"
    $passed++
} else {
    Write-Fail "asyncomplete-omnisharp nicht gefunden"
    Write-Info "git clone https://github.com/ulfbert-san/asyncomplete-omnisharp.git $asyncompletePath"
    $failed++
}

# ============================================================================
# OPTIONAL: FLUTTER
# ============================================================================
Write-Host "`n=== Optional: Flutter ===" -ForegroundColor Yellow

if (Test-Tool "flutter" "Flutter SDK" "--version") {
    $passed++
} else {
    Write-Info "Flutter ist optional - nur fuer Flutter/Dart Entwicklung"
}

# ============================================================================
# ZUSAMMENFASSUNG
# ============================================================================
Write-Host "`n" + ("=" * 50)

$total = $passed + $failed
$percent = if ($total -gt 0) { [math]::Round(($passed / $total) * 100) } else { 0 }

if ($failed -eq 0) {
    Write-Host "ALLES BEREIT! " -ForegroundColor Green -NoNewline
    Write-Host "($passed/$total Tools installiert)"
    Write-Host "`nStarte Neovim mit: nvim" -ForegroundColor Cyan
} else {
    Write-Host "TEILWEISE BEREIT: " -ForegroundColor Yellow -NoNewline
    Write-Host "$passed/$total Tools installiert ($percent%)"
    Write-Host "`n$failed Tool(s) fehlen - siehe Hinweise oben" -ForegroundColor Yellow
}

Write-Host ""

# Return exit code
exit $failed

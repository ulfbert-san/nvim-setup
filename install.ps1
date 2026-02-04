#Requires -RunAsAdministrator
<#
.SYNOPSIS
    Vollstaendige Neovim-Installation mit allen Abhaengigkeiten fuer ulfbert-san/nvimconfig

.DESCRIPTION
    Dieses Skript installiert:
    - Neovim
    - Git (falls nicht vorhanden)
    - C-Compiler (LLVM/Clang fuer Treesitter)
    - ripgrep (fuer Telescope live grep)
    - fd (fuer schnellere Dateisuche)
    - fzf (Fuzzy Finder)
    - lazygit (Git TUI)
    - .NET SDK (fuer C# Entwicklung)
    - lua-language-server
    - OmniSharp (C# LSP)
    - netcoredbg (C# Debugger)
    - Eine Nerd Font (fuer Icons)

.NOTES
    Ausfuehren als Administrator!

.EXAMPLE
    .\install.ps1
    .\install.ps1 -SkipFlutter    # Ohne Flutter SDK
    .\install.ps1 -Minimal        # Nur Basis-Tools
#>

param(
    [switch]$SkipFlutter,
    [switch]$Minimal,
    [switch]$DryRun
)

$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"

# Farben fuer Output
function Write-Step { param($msg) Write-Host "`n[*] $msg" -ForegroundColor Cyan }
function Write-Success { param($msg) Write-Host "[+] $msg" -ForegroundColor Green }
function Write-Warning { param($msg) Write-Host "[!] $msg" -ForegroundColor Yellow }
function Write-Error { param($msg) Write-Host "[-] $msg" -ForegroundColor Red }

# ============================================================================
# KONFIGURATION
# ============================================================================

$NvimConfigRepo = "https://github.com/ulfbert-san/nvimconfig.git"
$NvimConfigPath = "$env:LOCALAPPDATA\nvim"

# Lokales Plugin
$AsyncompleteRepo = "https://github.com/ulfbert-san/asyncomplete-omnisharp.git"
$AsyncompletePath = "C:\Users\$env:USERNAME\Repos\asyncomplete-omnisharp"

# Tools die via winget installiert werden
$WingetPackages = @(
    @{ Id = "Neovim.Neovim"; Name = "Neovim" },
    @{ Id = "Git.Git"; Name = "Git" },
    @{ Id = "LLVM.LLVM"; Name = "LLVM/Clang (C-Compiler)" },
    @{ Id = "BurntSushi.ripgrep.MSVC"; Name = "ripgrep" },
    @{ Id = "sharkdp.fd"; Name = "fd" },
    @{ Id = "junegunn.fzf"; Name = "fzf" },
    @{ Id = "JesseDuffield.lazygit"; Name = "lazygit" },
    @{ Id = "Microsoft.DotNet.SDK.8"; Name = ".NET SDK 8" },
    @{ Id = "sumneko.lua-language-server"; Name = "Lua Language Server" }
)

$MinimalPackages = @(
    @{ Id = "Neovim.Neovim"; Name = "Neovim" },
    @{ Id = "Git.Git"; Name = "Git" },
    @{ Id = "LLVM.LLVM"; Name = "LLVM/Clang (C-Compiler)" },
    @{ Id = "BurntSushi.ripgrep.MSVC"; Name = "ripgrep" },
    @{ Id = "sharkdp.fd"; Name = "fd" }
)

# ============================================================================
# HILFSFUNKTIONEN
# ============================================================================

function Test-CommandExists {
    param($Command)
    $null -ne (Get-Command $Command -ErrorAction SilentlyContinue)
}

function Install-WingetPackage {
    param($Package)

    Write-Step "Installiere $($Package.Name)..."

    if ($DryRun) {
        Write-Warning "DryRun: winget install --id $($Package.Id) -e --silent"
        return
    }

    $result = winget list --id $Package.Id 2>$null
    if ($LASTEXITCODE -eq 0 -and $result -match $Package.Id) {
        Write-Success "$($Package.Name) ist bereits installiert"
        return
    }

    winget install --id $Package.Id -e --silent --accept-package-agreements --accept-source-agreements
    if ($LASTEXITCODE -eq 0) {
        Write-Success "$($Package.Name) erfolgreich installiert"
    } else {
        Write-Warning "$($Package.Name) Installation fehlgeschlagen - manuell installieren"
    }
}

function Install-OmniSharp {
    Write-Step "Installiere OmniSharp..."

    $omniSharpPath = "$env:LOCALAPPDATA\omnisharp"

    if (Test-Path "$omniSharpPath\OmniSharp.exe") {
        Write-Success "OmniSharp ist bereits installiert"
        return
    }

    if ($DryRun) {
        Write-Warning "DryRun: Wuerde OmniSharp nach $omniSharpPath installieren"
        return
    }

    # Neueste Version von GitHub holen
    $releases = Invoke-RestMethod "https://api.github.com/repos/OmniSharp/omnisharp-roslyn/releases/latest"
    $asset = $releases.assets | Where-Object { $_.name -match "omnisharp-win-x64-net6" } | Select-Object -First 1

    if (-not $asset) {
        Write-Warning "Konnte OmniSharp Release nicht finden - manuell installieren"
        Write-Warning "https://github.com/OmniSharp/omnisharp-roslyn/releases"
        return
    }

    $zipPath = "$env:TEMP\omnisharp.zip"
    Write-Host "    Downloading $($asset.name)..."
    Invoke-WebRequest -Uri $asset.browser_download_url -OutFile $zipPath

    New-Item -ItemType Directory -Force -Path $omniSharpPath | Out-Null
    Expand-Archive -Path $zipPath -DestinationPath $omniSharpPath -Force
    Remove-Item $zipPath

    # Zum PATH hinzufuegen
    $currentPath = [Environment]::GetEnvironmentVariable("PATH", "User")
    if ($currentPath -notlike "*$omniSharpPath*") {
        [Environment]::SetEnvironmentVariable("PATH", "$currentPath;$omniSharpPath", "User")
        Write-Success "OmniSharp zum PATH hinzugefuegt"
    }

    Write-Success "OmniSharp installiert nach $omniSharpPath"
}

function Install-NetCoreDbg {
    Write-Step "Installiere netcoredbg..."

    $dbgPath = "$env:LOCALAPPDATA\netcoredbg"

    if (Test-Path "$dbgPath\netcoredbg.exe") {
        Write-Success "netcoredbg ist bereits installiert"
        return
    }

    if ($DryRun) {
        Write-Warning "DryRun: Wuerde netcoredbg nach $dbgPath installieren"
        return
    }

    # Neueste Version von GitHub holen
    $releases = Invoke-RestMethod "https://api.github.com/repos/Samsung/netcoredbg/releases/latest"
    $asset = $releases.assets | Where-Object { $_.name -match "win64" } | Select-Object -First 1

    if (-not $asset) {
        Write-Warning "Konnte netcoredbg Release nicht finden - manuell installieren"
        Write-Warning "https://github.com/Samsung/netcoredbg/releases"
        return
    }

    $zipPath = "$env:TEMP\netcoredbg.zip"
    Write-Host "    Downloading $($asset.name)..."
    Invoke-WebRequest -Uri $asset.browser_download_url -OutFile $zipPath

    New-Item -ItemType Directory -Force -Path $dbgPath | Out-Null
    Expand-Archive -Path $zipPath -DestinationPath $dbgPath -Force
    Remove-Item $zipPath

    # netcoredbg ist in einem Unterordner
    $subDir = Get-ChildItem -Path $dbgPath -Directory | Select-Object -First 1
    if ($subDir -and (Test-Path "$($subDir.FullName)\netcoredbg.exe")) {
        Move-Item "$($subDir.FullName)\*" $dbgPath -Force
        Remove-Item $subDir.FullName -Force -Recurse -ErrorAction SilentlyContinue
    }

    # Zum PATH hinzufuegen
    $currentPath = [Environment]::GetEnvironmentVariable("PATH", "User")
    if ($currentPath -notlike "*$dbgPath*") {
        [Environment]::SetEnvironmentVariable("PATH", "$currentPath;$dbgPath", "User")
        Write-Success "netcoredbg zum PATH hinzugefuegt"
    }

    Write-Success "netcoredbg installiert nach $dbgPath"
}

function Install-NerdFont {
    Write-Step "Installiere Nerd Font (JetBrainsMono)..."

    $fontDir = "$env:LOCALAPPDATA\Microsoft\Windows\Fonts"

    if (Get-ChildItem "$fontDir\JetBrains*Nerd*" -ErrorAction SilentlyContinue) {
        Write-Success "JetBrainsMono Nerd Font ist bereits installiert"
        return
    }

    if ($DryRun) {
        Write-Warning "DryRun: Wuerde JetBrainsMono Nerd Font installieren"
        return
    }

    # Via winget oder manuell
    $result = winget install --id "DEVCOM.JetBrainsMonoNerdFont" -e --silent 2>$null
    if ($LASTEXITCODE -eq 0) {
        Write-Success "JetBrainsMono Nerd Font installiert"
    } else {
        Write-Warning "Nerd Font manuell installieren: https://www.nerdfonts.com/font-downloads"
    }
}

function Install-FlutterSDK {
    Write-Step "Installiere Flutter SDK..."

    if (Test-CommandExists "flutter") {
        Write-Success "Flutter ist bereits installiert"
        return
    }

    if ($DryRun) {
        Write-Warning "DryRun: Wuerde Flutter SDK installieren"
        return
    }

    Write-Warning "Flutter SDK muss manuell installiert werden:"
    Write-Host "    1. Download: https://docs.flutter.dev/get-started/install/windows" -ForegroundColor White
    Write-Host "    2. Extrahieren nach C:\flutter" -ForegroundColor White
    Write-Host "    3. C:\flutter\bin zum PATH hinzufuegen" -ForegroundColor White
    Write-Host "    4. 'flutter doctor' ausfuehren" -ForegroundColor White
}

function Clone-NvimConfig {
    Write-Step "Klone Neovim Konfiguration..."

    if (Test-Path "$NvimConfigPath\.git") {
        Write-Success "Neovim Konfiguration existiert bereits"
        Write-Host "    Aktualisiere mit git pull..."
        Push-Location $NvimConfigPath
        git pull
        Pop-Location
        return
    }

    if ($DryRun) {
        Write-Warning "DryRun: git clone $NvimConfigRepo $NvimConfigPath"
        return
    }

    if (Test-Path $NvimConfigPath) {
        Write-Warning "Backup existierender Konfiguration..."
        $backup = "$NvimConfigPath.backup.$(Get-Date -Format 'yyyyMMdd-HHmmss')"
        Move-Item $NvimConfigPath $backup
        Write-Host "    Backup erstellt: $backup"
    }

    git clone $NvimConfigRepo $NvimConfigPath
    Write-Success "Neovim Konfiguration geklont nach $NvimConfigPath"
}

function Setup-AsyncompleteOmnisharp {
    Write-Step "Klone asyncomplete-omnisharp Plugin..."

    if (Test-Path "$AsyncompletePath\.git") {
        Write-Success "asyncomplete-omnisharp existiert bereits"
        Write-Host "    Aktualisiere mit git pull..."
        Push-Location $AsyncompletePath
        git pull
        Pop-Location
        return
    }

    if ($DryRun) {
        Write-Warning "DryRun: git clone $AsyncompleteRepo $AsyncompletePath"
        return
    }

    # Stelle sicher dass Repos-Ordner existiert
    $reposDir = Split-Path $AsyncompletePath -Parent
    if (-not (Test-Path $reposDir)) {
        New-Item -ItemType Directory -Force -Path $reposDir | Out-Null
    }

    git clone $AsyncompleteRepo $AsyncompletePath
    if ($LASTEXITCODE -eq 0) {
        Write-Success "asyncomplete-omnisharp geklont nach $AsyncompletePath"
    } else {
        Write-Warning "asyncomplete-omnisharp konnte nicht geklont werden"
    }
}

function Refresh-Environment {
    Write-Step "Aktualisiere Umgebungsvariablen..."

    $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")

    Write-Success "PATH aktualisiert"
}

# ============================================================================
# HAUPTPROGRAMM
# ============================================================================

Write-Host @"

 _   _                 _             ____       _
| \ | | ___  _____   _(_)_ __ ___   / ___|  ___| |_ _   _ _ __
|  \| |/ _ \/ _ \ \ / / | '_ ` _ \  \___ \ / _ \ __| | | | '_ \
| |\  |  __/ (_) \ V /| | | | | | |  ___) |  __/ |_| |_| | |_) |
|_| \_|\___|\___/ \_/ |_|_| |_| |_| |____/ \___|\__|\__,_| .__/
                                                         |_|
"@ -ForegroundColor Magenta

Write-Host "Neovim Setup fuer: $NvimConfigRepo" -ForegroundColor White
Write-Host "=" * 60

if ($DryRun) {
    Write-Warning "DryRun Modus - keine Aenderungen werden vorgenommen"
}

# Winget pruefen
if (-not (Test-CommandExists "winget")) {
    Write-Error "winget nicht gefunden! Bitte Windows App Installer installieren."
    Write-Host "https://aka.ms/getwinget"
    exit 1
}

# Pakete waehlen
$packages = if ($Minimal) { $MinimalPackages } else { $WingetPackages }

# Basis-Tools installieren
Write-Host "`n=== Basis-Tools ===" -ForegroundColor Yellow
foreach ($pkg in $packages) {
    Install-WingetPackage $pkg
}

# Spezielle Tools
if (-not $Minimal) {
    Write-Host "`n=== Entwicklungstools ===" -ForegroundColor Yellow
    Install-OmniSharp
    Install-NetCoreDbg
    Install-NerdFont

    if (-not $SkipFlutter) {
        Install-FlutterSDK
    }
}

# Umgebung aktualisieren
Refresh-Environment

# Neovim Konfiguration klonen
Write-Host "`n=== Neovim Konfiguration ===" -ForegroundColor Yellow
Clone-NvimConfig

# Lokales Plugin Hinweis
if (-not $Minimal) {
    Setup-AsyncompleteOmnisharp
}

# Zusammenfassung
Write-Host "`n" + "=" * 60
Write-Host "INSTALLATION ABGESCHLOSSEN!" -ForegroundColor Green
Write-Host "=" * 60

Write-Host "`nNaechste Schritte:" -ForegroundColor Yellow
Write-Host "  1. Terminal neu starten (fuer PATH Aenderungen)"
Write-Host "  2. 'nvim' starten - Plugins werden automatisch installiert"
Write-Host "  3. In Neovim ':checkhealth' ausfuehren"

if (-not $Minimal -and -not $SkipFlutter) {
    Write-Host "`nFalls du Flutter nutzt:" -ForegroundColor Yellow
    Write-Host "  - Flutter SDK manuell installieren"
    Write-Host "  - 'flutter doctor' ausfuehren"
}

Write-Host "`nInstallierte Tools pruefen:" -ForegroundColor Cyan
$tools = @("nvim", "git", "clang", "rg", "fd", "fzf", "lazygit", "dotnet", "lua-language-server")
foreach ($tool in $tools) {
    $status = if (Test-CommandExists $tool) { "[OK]" } else { "[--]" }
    $color = if ($status -eq "[OK]") { "Green" } else { "Yellow" }
    Write-Host "  $status $tool" -ForegroundColor $color
}

Write-Host ""

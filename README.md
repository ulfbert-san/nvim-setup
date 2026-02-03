# Neovim Setup

Automatisches Installationsskript fuer meine Neovim-Konfiguration [ulfbert-san/nvimconfig](https://github.com/ulfbert-san/nvimconfig).

## Schnellstart

PowerShell als **Administrator** oeffnen und ausfuehren:

```powershell
irm https://raw.githubusercontent.com/ulfbert-san/nvim-setup/main/install.ps1 | iex
```

Oder manuell:

```powershell
git clone https://github.com/ulfbert-san/nvim-setup.git
cd nvim-setup
.\install.ps1
```

## Was wird installiert?

### Basis-Tools (winget)

| Tool | Zweck |
|------|-------|
| Neovim | Der Editor |
| Git | Versionskontrolle & Plugin-Management |
| LLVM/Clang | C-Compiler fuer Treesitter |
| ripgrep | Schnelle Textsuche (Telescope) |
| fd | Schnelle Dateisuche (Telescope) |
| fzf | Fuzzy Finder |
| lazygit | Git TUI |
| .NET SDK 8 | C# Entwicklung |
| lua-language-server | Lua LSP |

### Zusaetzliche Tools (manuell heruntergeladen)

| Tool | Zweck | Installationspfad |
|------|-------|-------------------|
| OmniSharp | C# Language Server | `%LOCALAPPDATA%\omnisharp` |
| netcoredbg | .NET Debugger | `%LOCALAPPDATA%\netcoredbg` |
| JetBrainsMono Nerd Font | Icons im Terminal | System Fonts |

### Optional

| Tool | Zweck |
|------|-------|
| Flutter SDK | Flutter/Dart Entwicklung (manuell) |

## Installationsoptionen

```powershell
# Vollstaendige Installation
.\install.ps1

# Ohne Flutter-Hinweise
.\install.ps1 -SkipFlutter

# Nur Basis-Tools (Neovim, Git, Clang, ripgrep, fd)
.\install.ps1 -Minimal

# Testlauf ohne Aenderungen
.\install.ps1 -DryRun
```

## Nach der Installation

1. **Terminal neu starten** (wichtig fuer PATH-Aenderungen)

2. **Neovim starten:**
   ```
   nvim
   ```
   Beim ersten Start werden automatisch alle Plugins installiert.

3. **Gesundheitscheck:**
   In Neovim `:checkhealth` ausfuehren.

## Abhaengigkeiten der Neovim-Konfiguration

```
nvimconfig
├── Plugin Manager: lazy.nvim (automatisch)
├── Treesitter: benoetigt C-Compiler (clang/gcc/zig)
├── Telescope: benoetigt ripgrep, fd
├── LSP
│   ├── lua-language-server (Lua)
│   └── OmniSharp (C#)
├── Debugger
│   └── netcoredbg via Vimspector (C#/.NET)
├── Git Integration
│   └── lazygit via snacks.nvim
└── Optional
    └── flutter-tools.nvim (Flutter SDK)
```

## Manuelle Installation einzelner Komponenten

### OmniSharp
```powershell
# Download von https://github.com/OmniSharp/omnisharp-roslyn/releases
# Entpacken nach %LOCALAPPDATA%\omnisharp
# Zum PATH hinzufuegen
```

### netcoredbg
```powershell
# Download von https://github.com/Samsung/netcoredbg/releases
# Entpacken nach %LOCALAPPDATA%\netcoredbg
# Zum PATH hinzufuegen
```

### Flutter SDK
```powershell
# Download von https://docs.flutter.dev/get-started/install/windows
# Entpacken nach C:\flutter
# C:\flutter\bin zum PATH hinzufuegen
flutter doctor
```

## Lokales Plugin

Die Konfiguration referenziert ein lokales Plugin:
```
C:\Users\<USERNAME>\Repos\asyncomplete-omnisharp
```

Falls du dieses Plugin verwendest, stelle sicher dass es an diesem Pfad existiert.

## Troubleshooting

### Treesitter Compiler-Fehler
Stelle sicher dass `clang` im PATH ist:
```powershell
clang --version
```

### OmniSharp startet nicht
```powershell
# Pruefen ob OmniSharp im PATH ist
where.exe OmniSharp.exe

# Manuell testen
OmniSharp.exe --help
```

### Icons werden nicht angezeigt
1. Nerd Font installiert?
2. Terminal verwendet die Nerd Font?
   - Windows Terminal: Settings > Profile > Appearance > Font face

### :checkhealth Fehler
In Neovim `:checkhealth` ausfuehren und den Anweisungen folgen.

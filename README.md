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
| .NET SDK 10 | C# Entwicklung |

### Von Mason / Plugins automatisch installiert

Diese Tools werden **nicht** mehr manuell heruntergeladen, sondern beim ersten
`nvim`-Start (bzw. on demand) verwaltet:

| Tool | Zweck | Verwaltet von |
|------|-------|---------------|
| lua-language-server | Lua LSP | Mason (`ensure_installed` in `mason.lua`) |
| netcoredbg | .NET Debugger | Mason (`mason-nvim-dap`) |
| OmniSharp | C# Language Server | omnisharp-vim (`:OmniSharpInstall`) |

### Zusaetzliche Tools (manuell heruntergeladen)

| Tool | Zweck | Installationspfad |
|------|-------|-------------------|
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

   Beim ersten Start installiert Mason automatisch `lua-language-server`
   und `netcoredbg`.

3. **C#-Server installieren (einmalig):**
   In Neovim `:OmniSharpInstall` ausfuehren - laedt den OmniSharp net6-Server
   fuer omnisharp-vim herunter.

4. **Gesundheitscheck:**
   In Neovim `:checkhealth` und `:Mason` ausfuehren.

## Abhaengigkeiten der Neovim-Konfiguration

```
nvimconfig
├── Plugin Manager: lazy.nvim (automatisch)
├── Tool-Manager: Mason (verwaltet LSP/DAP-Binaries automatisch)
├── Treesitter: benoetigt C-Compiler (clang/gcc/zig)
├── Telescope: benoetigt ripgrep, fd
├── LSP
│   ├── lua-language-server (Lua) - via Mason
│   └── omnisharp-vim + OmniSharp (C#) - via :OmniSharpInstall
├── Completion
│   └── asyncomplete.vim + asyncomplete-omnisharp (lokales Plugin)
├── Debugger
│   └── nvim-dap + netcoredbg (C#/.NET) - netcoredbg via Mason
├── Git Integration
│   └── lazygit via snacks.nvim
└── Optional
    └── flutter-tools.nvim (Flutter SDK)
```

## Manuelle Installation einzelner Komponenten

### OmniSharp (C# Server)
Wird von omnisharp-vim verwaltet - kein manueller Download noetig:
```
:OmniSharpInstall      " in Neovim ausfuehren
```
Installationspfad: `%LOCALAPPDATA%\omnisharp-vim\omnisharp-roslyn\`

### netcoredbg / lua-language-server
Werden von Mason verwaltet (automatisch beim ersten Start). Manuell:
```
:Mason                 " UI oeffnen
:MasonInstall netcoredbg lua-language-server
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
```
" In Neovim: Server (neu) installieren
:OmniSharpInstall

" Server-Status / Logs
:OmniSharpStatus
```
Der Server liegt unter `%LOCALAPPDATA%\omnisharp-vim\omnisharp-roslyn\`.
Wichtig: Die Config nutzt den net6-Build (`OmniSharp_server_use_net6 = 1`),
da der .NET-Framework-Build mit .NET 9/10 SDKs bricht.

### Icons werden nicht angezeigt
1. Nerd Font installiert?
2. Terminal verwendet die Nerd Font?
   - Windows Terminal: Settings > Profile > Appearance > Font face

### :checkhealth Fehler
In Neovim `:checkhealth` ausfuehren und den Anweisungen folgen.

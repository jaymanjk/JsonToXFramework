# Axbus Framework — Scripts
<!-- Copyright (c) 2026 Axel Johnson International. All rights reserved. -->

This folder contains automation scripts for the Axbus framework.
The goal is **zero manual setup** — clone the repository, run one script,
start coding immediately.

---

## Scripts

### `setup-axbus.ps1` — Full Solution Setup

**Purpose:** Creates the entire Axbus Visual Studio solution from scratch.
Run this once after cloning the repository.

**What it does:**
1. Validates prerequisites (.NET 8 SDK, Git)
2. Creates `Axbus.sln` solution file
3. Creates all 16 projects with correct templates
4. Creates all 50+ folder structures
5. Sets all project references
6. Installs all NuGet packages
7. Creates `Directory.Build.props` and `Directory.Build.targets`
8. Creates `GlobalUsings.cs` per project
9. Creates `appsettings.json` stubs for client projects
10. Creates `manifest.json` stubs for plugin projects
11. Creates sample test data JSON files
12. Builds the solution to verify zero errors
13. Prints next steps summary

**Prerequisites:**
- [.NET 8 SDK](https://dotnet.microsoft.com/download/dotnet/8.0) installed
- [Git](https://git-scm.com) installed
- Run from the **repository root** (same folder as `.git`)

**How to run:**
```powershell
# Clone the repository
git clone https://github.com/your-org/JsonToXFramework
cd JsonToXFramework

# Run setup script
.\scripts\setup-axbus.ps1
```

**Expected output:**
```
===============================================================================
  Axbus Framework — Solution Setup Script v1.0.0
  Copyright (c) 2026 Axel Johnson International. All rights reserved.
===============================================================================

  [1] Validating Prerequisites
  -----------------------------------------------------------------------
      ✅ Running from repository root
      ✅ .NET SDK found: 8.0.x
      ✅ Git found: git version 2.x.x
      ✅ All prerequisites validated

  [2] Creating Solution File
  ...

===============================================================================
  ✅ Axbus Framework — Setup Complete!
===============================================================================
```

**How long does it take?**
Approximately 3-5 minutes depending on internet speed for NuGet downloads.

**Is it safe to re-run?**
Yes — the script is idempotent. Running it again on an existing setup is safe.
You will be prompted before overwriting the solution file.

---

## Adding New Scripts

When adding new scripts to this folder, follow these conventions:

| Convention | Rule |
|---|---|
| **Naming** | `verb-noun.ps1` e.g. `setup-axbus.ps1`, `new-plugin.ps1` |
| **Header** | Include copyright comment at top |
| **Error handling** | Use `$ErrorActionPreference = "Stop"` |
| **Output** | Use `Write-Step`, `Write-Success`, `Write-Info` helpers |
| **Idempotent** | Scripts should be safe to run multiple times |
| **Documentation** | Add entry to this README for every new script |

---

## Planned Future Scripts

| Script | Purpose | Status |
|---|---|---|
| `setup-axbus.ps1` | Full solution setup | ✅ Done |
| `new-plugin.ps1` | Scaffold a new plugin project | 📋 Planned |
| `new-connector.ps1` | Scaffold a new connector project | 📋 Planned |
| `run-tests.ps1` | Run all tests with coverage report | 📋 Planned |
| `publish-nuget.ps1` | Pack and publish NuGet packages | 📋 Planned |

---

*Copyright (c) 2026 Axel Johnson International. All rights reserved.*
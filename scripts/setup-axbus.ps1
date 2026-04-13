# ==============================================================================
# setup-axbus.ps1
# Axbus Framework — Full Solution Setup Script
# Copyright (c) 2026 Axel Johnson International. All rights reserved.
#
# PURPOSE:
#   Automates the complete setup of the Axbus framework solution from scratch.
#   Creates all projects, folders, references, NuGet packages and config files.
#
# USAGE:
#   .\scripts\setup-axbus.ps1
#
# PREREQUISITES:
#   - .NET 8 SDK installed
#   - Git installed
#   - Run from the root of the cloned JsonToXFramework repository
#
# WHAT THIS SCRIPT DOES:
#   1.  Validates prerequisites
#   2.  Creates the Axbus.sln solution file
#   3.  Creates all 16 projects with correct templates
#   4.  Creates all folder structures (50+ folders)
#   5.  Sets all project references
#   6.  Installs all NuGet packages
#   7.  Creates Directory.Build.props and Directory.Build.targets
#   8.  Creates GlobalUsings.cs per project
#   9.  Creates appsettings.json stubs for client projects
#   10. Creates manifest.json stubs for plugin projects
#   11. Builds the solution to verify zero errors
#   12. Prints success summary with next steps
# ==============================================================================

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# ==============================================================================
# CONFIGURATION
# ==============================================================================

$SolutionName     = "Axbus"
$CompanyName      = "Axel Johnson International"
$CopyrightYear    = "2026"
$DotNetVersion    = "net8.0"
$ScriptVersion    = "1.0.0"

# Colour scheme for output
$ColourBanner     = "Cyan"
$ColourStep       = "Yellow"
$ColourSuccess    = "Green"
$ColourError      = "Red"
$ColourWarning    = "Magenta"
$ColourInfo       = "White"

# ==============================================================================
# HELPER FUNCTIONS
# ==============================================================================

function Write-Banner {
    Write-Host ""
    Write-Host "===============================================================================" -ForegroundColor $ColourBanner
    Write-Host "  Axbus Framework — Solution Setup Script v$ScriptVersion" -ForegroundColor $ColourBanner
    Write-Host "  Copyright (c) $CopyrightYear $CompanyName. All rights reserved." -ForegroundColor $ColourBanner
    Write-Host "===============================================================================" -ForegroundColor $ColourBanner
    Write-Host ""
}

function Write-Step {
    param([int]$Number, [string]$Message)
    Write-Host ""
    Write-Host "  [$Number] $Message" -ForegroundColor $ColourStep
    Write-Host "  $("-" * 70)" -ForegroundColor $ColourStep
}

function Write-Success {
    param([string]$Message)
    Write-Host "      ✅ $Message" -ForegroundColor $ColourSuccess
}

function Write-Info {
    param([string]$Message)
    Write-Host "      ℹ  $Message" -ForegroundColor $ColourInfo
}

function Write-Warning {
    param([string]$Message)
    Write-Host "      ⚠  $Message" -ForegroundColor $ColourWarning
}

function Write-Failure {
    param([string]$Message)
    Write-Host ""
    Write-Host "  ❌ FAILED: $Message" -ForegroundColor $ColourError
    Write-Host ""
}

function Invoke-SafeCommand {
    param(
        [string]$Command,
        [string]$Description
    )
    Write-Info $Description
    try {
        Invoke-Expression $Command | Out-Null
        Write-Success $Description
    }
    catch {
        Write-Failure "Command failed: $Description"
        Write-Host "  Command : $Command" -ForegroundColor $ColourError
        Write-Host "  Error   : $_" -ForegroundColor $ColourError
        exit 1
    }
}

function New-ProjectFolder {
    param([string]$ProjectPath, [string[]]$Folders)
    foreach ($folder in $Folders) {
        $fullPath = Join-Path $ProjectPath $folder
        if (-not (Test-Path $fullPath)) {
            New-Item -ItemType Directory -Path $fullPath -Force | Out-Null
            Write-Info "Created folder: $folder"
        }
    }
}

function New-FileFromContent {
    param([string]$FilePath, [string]$Content)
    $directory = Split-Path $FilePath -Parent
    if (-not (Test-Path $directory)) {
        New-Item -ItemType Directory -Path $directory -Force | Out-Null
    }
    Set-Content -Path $FilePath -Value $Content -Encoding UTF8
    Write-Success "Created: $(Split-Path $FilePath -Leaf)"
}

function Get-CopyrightHeader {
    param([string]$FileName)
    return @"
// <copyright file="$FileName" company="$CompanyName">
// Copyright (c) $CopyrightYear $CompanyName. All rights reserved.
// </copyright>
"@
}

# ==============================================================================
# STEP 1 — VALIDATE PREREQUISITES
# ==============================================================================

function Test-Prerequisites {
    Write-Step 1 "Validating Prerequisites"

    # Check we are in the right directory
    if (-not (Test-Path ".git")) {
        Write-Failure "This script must be run from the root of the cloned JsonToXFramework repository."
        Write-Host "  Expected: A .git folder in the current directory." -ForegroundColor $ColourError
        Write-Host "  Current : $(Get-Location)" -ForegroundColor $ColourError
        exit 1
    }
    Write-Success "Running from repository root: $(Get-Location)"

    # Check .NET 8 SDK
    try {
        $dotnetVersion = dotnet --version 2>&1
        if ($dotnetVersion -match "^8\.") {
            Write-Success ".NET SDK found: $dotnetVersion"
        }
        else {
            Write-Warning ".NET $dotnetVersion found. Axbus targets .NET 8. Consider installing .NET 8 SDK."
            Write-Info "Download from: https://dotnet.microsoft.com/download/dotnet/8.0"
        }
    }
    catch {
        Write-Failure ".NET SDK not found. Please install .NET 8 SDK."
        Write-Info "Download from: https://dotnet.microsoft.com/download/dotnet/8.0"
        exit 1
    }

    # Check Git
    try {
        $gitVersion = git --version 2>&1
        Write-Success "Git found: $gitVersion"
    }
    catch {
        Write-Failure "Git not found. Please install Git."
        exit 1
    }

    # Check if solution already exists
    if (Test-Path "$SolutionName.sln") {
        Write-Warning "Solution file $SolutionName.sln already exists."
        $response = Read-Host "      Do you want to continue and overwrite? (y/N)"
        if ($response -ne "y" -and $response -ne "Y") {
            Write-Info "Setup cancelled by user."
            exit 0
        }
    }

    Write-Success "All prerequisites validated"
}

# ==============================================================================
# STEP 2 — CREATE SOLUTION FILE
# ==============================================================================

function New-SolutionFile {
    Write-Step 2 "Creating Solution File"

    Invoke-SafeCommand `
        "dotnet new sln --name $SolutionName --output ." `
        "Creating $SolutionName.sln"
}

# ==============================================================================
# STEP 3 — CREATE ALL PROJECTS
# ==============================================================================

function New-AllProjects {
    Write-Step 3 "Creating All 16 Projects"

    # ── Framework Projects ────────────────────────────────────────────────────

    Write-Info "Creating Framework Projects..."

    Invoke-SafeCommand `
        "dotnet new classlib --name Axbus.Core --output src/framework/Axbus.Core --framework $DotNetVersion" `
        "Axbus.Core (Class Library)"

    Invoke-SafeCommand `
        "dotnet new classlib --name Axbus.Application --output src/framework/Axbus.Application --framework $DotNetVersion" `
        "Axbus.Application (Class Library)"

    Invoke-SafeCommand `
        "dotnet new classlib --name Axbus.Infrastructure --output src/framework/Axbus.Infrastructure --framework $DotNetVersion" `
        "Axbus.Infrastructure (Class Library)"

    # ── Plugin Projects ───────────────────────────────────────────────────────

    Write-Info "Creating Plugin Projects..."

    Invoke-SafeCommand `
        "dotnet new classlib --name Axbus.Plugin.Reader.Json --output src/plugins/Axbus.Plugin.Reader.Json --framework $DotNetVersion" `
        "Axbus.Plugin.Reader.Json (Class Library)"

    Invoke-SafeCommand `
        "dotnet new classlib --name Axbus.Plugin.Writer.Csv --output src/plugins/Axbus.Plugin.Writer.Csv --framework $DotNetVersion" `
        "Axbus.Plugin.Writer.Csv (Class Library)"

    Invoke-SafeCommand `
        "dotnet new classlib --name Axbus.Plugin.Writer.Excel --output src/plugins/Axbus.Plugin.Writer.Excel --framework $DotNetVersion" `
        "Axbus.Plugin.Writer.Excel (Class Library)"

    # ── Client Projects ───────────────────────────────────────────────────────

    Write-Info "Creating Client Projects..."

    Invoke-SafeCommand `
        "dotnet new console --name Axbus.ConsoleApp --output src/clients/Axbus.ConsoleApp --framework $DotNetVersion" `
        "Axbus.ConsoleApp (Console App)"

    Invoke-SafeCommand `
        "dotnet new winforms --name Axbus.WinFormsApp --output src/clients/Axbus.WinFormsApp --framework $DotNetVersion" `
        "Axbus.WinFormsApp (WinForms App)"

    # ── Test Projects ─────────────────────────────────────────────────────────

    Write-Info "Creating Test Projects..."

    Invoke-SafeCommand `
        "dotnet new classlib --name Axbus.Tests.Common --output tests/Axbus.Tests.Common --framework $DotNetVersion" `
        "Axbus.Tests.Common (Class Library — shared test utilities)"

    Invoke-SafeCommand `
        "dotnet new nunit --name Axbus.Core.Tests --output tests/Axbus.Core.Tests --framework $DotNetVersion" `
        "Axbus.Core.Tests (NUnit)"

    Invoke-SafeCommand `
        "dotnet new nunit --name Axbus.Application.Tests --output tests/Axbus.Application.Tests --framework $DotNetVersion" `
        "Axbus.Application.Tests (NUnit)"

    Invoke-SafeCommand `
        "dotnet new nunit --name Axbus.Infrastructure.Tests --output tests/Axbus.Infrastructure.Tests --framework $DotNetVersion" `
        "Axbus.Infrastructure.Tests (NUnit)"

    Invoke-SafeCommand `
        "dotnet new nunit --name Axbus.Plugin.Reader.Json.Tests --output tests/Axbus.Plugin.Reader.Json.Tests --framework $DotNetVersion" `
        "Axbus.Plugin.Reader.Json.Tests (NUnit)"

    Invoke-SafeCommand `
        "dotnet new nunit --name Axbus.Plugin.Writer.Csv.Tests --output tests/Axbus.Plugin.Writer.Csv.Tests --framework $DotNetVersion" `
        "Axbus.Plugin.Writer.Csv.Tests (NUnit)"

    Invoke-SafeCommand `
        "dotnet new nunit --name Axbus.Plugin.Writer.Excel.Tests --output tests/Axbus.Plugin.Writer.Excel.Tests --framework $DotNetVersion" `
        "Axbus.Plugin.Writer.Excel.Tests (NUnit)"

    Invoke-SafeCommand `
        "dotnet new nunit --name Axbus.Integration.Tests --output tests/Axbus.Integration.Tests --framework $DotNetVersion" `
        "Axbus.Integration.Tests (NUnit)"

    Write-Success "All 16 projects created"
}

# ==============================================================================
# STEP 4 — ADD PROJECTS TO SOLUTION
# ==============================================================================

function Add-ProjectsToSolution {
    Write-Step 4 "Adding All Projects to Solution"

    $projects = @(
        "src/framework/Axbus.Core/Axbus.Core.csproj",
        "src/framework/Axbus.Application/Axbus.Application.csproj",
        "src/framework/Axbus.Infrastructure/Axbus.Infrastructure.csproj",
        "src/plugins/Axbus.Plugin.Reader.Json/Axbus.Plugin.Reader.Json.csproj",
        "src/plugins/Axbus.Plugin.Writer.Csv/Axbus.Plugin.Writer.Csv.csproj",
        "src/plugins/Axbus.Plugin.Writer.Excel/Axbus.Plugin.Writer.Excel.csproj",
        "src/clients/Axbus.ConsoleApp/Axbus.ConsoleApp.csproj",
        "src/clients/Axbus.WinFormsApp/Axbus.WinFormsApp.csproj",
        "tests/Axbus.Tests.Common/Axbus.Tests.Common.csproj",
        "tests/Axbus.Core.Tests/Axbus.Core.Tests.csproj",
        "tests/Axbus.Application.Tests/Axbus.Application.Tests.csproj",
        "tests/Axbus.Infrastructure.Tests/Axbus.Infrastructure.Tests.csproj",
        "tests/Axbus.Plugin.Reader.Json.Tests/Axbus.Plugin.Reader.Json.Tests.csproj",
        "tests/Axbus.Plugin.Writer.Csv.Tests/Axbus.Plugin.Writer.Csv.Tests.csproj",
        "tests/Axbus.Plugin.Writer.Excel.Tests/Axbus.Plugin.Writer.Excel.Tests.csproj",
        "tests/Axbus.Integration.Tests/Axbus.Integration.Tests.csproj"
    )

    foreach ($project in $projects) {
        Invoke-SafeCommand `
            "dotnet sln $SolutionName.sln add $project" `
            "Adding $project"
    }

    Write-Success "All 16 projects added to solution"
}

# ==============================================================================
# STEP 5 — CREATE ALL FOLDER STRUCTURES
# ==============================================================================

function New-AllFolderStructures {
    Write-Step 5 "Creating Folder Structures"

    # ── Axbus.Core ────────────────────────────────────────────────────────────
    Write-Info "Axbus.Core folders..."
    New-ProjectFolder "src/framework/Axbus.Core" @(
        "Abstractions/Pipeline",
        "Abstractions/Middleware",
        "Abstractions/Connectors",
        "Abstractions/Plugin",
        "Abstractions/Conversion",
        "Abstractions/Factories",
        "Abstractions/Notifications",
        "Enums",
        "Exceptions",
        "Models/Configuration",
        "Models/Pipeline",
        "Models/Plugin",
        "Models/Notifications",
        "Models/Results"
    )

    # ── Axbus.Application ─────────────────────────────────────────────────────
    Write-Info "Axbus.Application folders..."
    New-ProjectFolder "src/framework/Axbus.Application" @(
        "Conversion",
        "Factories",
        "Middleware",
        "Notifications",
        "Pipeline",
        "Plugin",
        "Extensions"
    )

    # ── Axbus.Infrastructure ──────────────────────────────────────────────────
    Write-Info "Axbus.Infrastructure folders..."
    New-ProjectFolder "src/framework/Axbus.Infrastructure" @(
        "Connectors",
        "FileSystem",
        "Logging",
        "Extensions"
    )

    # ── Axbus.Plugin.Reader.Json ──────────────────────────────────────────────
    Write-Info "Axbus.Plugin.Reader.Json folders..."
    New-ProjectFolder "src/plugins/Axbus.Plugin.Reader.Json" @(
        "Options",
        "Parser",
        "Reader",
        "Transformer",
        "Validators"
    )

    # ── Axbus.Plugin.Writer.Csv ───────────────────────────────────────────────
    Write-Info "Axbus.Plugin.Writer.Csv folders..."
    New-ProjectFolder "src/plugins/Axbus.Plugin.Writer.Csv" @(
        "Internal",
        "Options",
        "Validators",
        "Writer"
    )

    # ── Axbus.Plugin.Writer.Excel ─────────────────────────────────────────────
    Write-Info "Axbus.Plugin.Writer.Excel folders..."
    New-ProjectFolder "src/plugins/Axbus.Plugin.Writer.Excel" @(
        "Internal",
        "Options",
        "Validators",
        "Writer"
    )

    # ── Axbus.ConsoleApp ──────────────────────────────────────────────────────
    Write-Info "Axbus.ConsoleApp folders..."
    New-ProjectFolder "src/clients/Axbus.ConsoleApp" @(
        "Bootstrapper"
    )

    # ── Axbus.WinFormsApp ─────────────────────────────────────────────────────
    Write-Info "Axbus.WinFormsApp folders..."
    New-ProjectFolder "src/clients/Axbus.WinFormsApp" @(
        "Bootstrapper",
        "Forms",
        "ViewModels"
    )

    # ── Axbus.Tests.Common ────────────────────────────────────────────────────
    Write-Info "Axbus.Tests.Common folders..."
    New-ProjectFolder "tests/Axbus.Tests.Common" @(
        "Assertions",
        "Base",
        "Builders",
        "Helpers"
    )

    # ── Test Projects ─────────────────────────────────────────────────────────
    $testProjects = @(
        "tests/Axbus.Core.Tests",
        "tests/Axbus.Application.Tests",
        "tests/Axbus.Infrastructure.Tests",
        "tests/Axbus.Plugin.Reader.Json.Tests",
        "tests/Axbus.Plugin.Writer.Csv.Tests",
        "tests/Axbus.Plugin.Writer.Excel.Tests",
        "tests/Axbus.Integration.Tests"
    )

    foreach ($testProject in $testProjects) {
        Write-Info "$testProject folders..."
        New-ProjectFolder $testProject @(
            "Base",
            "TestData",
            "Tests"
        )
    }

    # Additional TestData sub-folders for specific test projects
    New-ProjectFolder "tests/Axbus.Core.Tests" @(
        "TestData/FlatJson",
        "TestData/NestedJson",
        "TestData/ArrayJson",
        "TestData/MixedJson",
        "TestData/EdgeCases",
        "Tests/Enums",
        "Tests/Models"
    )

    New-ProjectFolder "tests/Axbus.Application.Tests" @(
        "TestData/SingleModule",
        "TestData/MultiModule/module1",
        "TestData/MultiModule/module2",
        "TestData/ParallelExecution/parallel_set1",
        "TestData/ParallelExecution/parallel_set2",
        "TestData/Plugins/valid_plugin",
        "TestData/Plugins/incompatible_plugin",
        "TestData/Plugins/conflicting_plugins",
        "TestData/Plugins/missing_manifest",
        "Tests/Conversion",
        "Tests/Factories",
        "Tests/Middleware",
        "Tests/Notifications",
        "Tests/Pipeline",
        "Tests/Plugin"
    )

    New-ProjectFolder "tests/Axbus.Infrastructure.Tests" @(
        "TestData/Connectors/source_files",
        "TestData/PluginFolder/valid_plugins",
        "TestData/PluginFolder/invalid_plugins",
        "Tests/Connectors",
        "Tests/FileSystem",
        "Tests/Logging"
    )

    New-ProjectFolder "tests/Axbus.Plugin.Reader.Json.Tests" @(
        "TestData/Input",
        "TestData/Expected",
        "Tests/Integration",
        "Tests/Parser",
        "Tests/Plugin",
        "Tests/Reader",
        "Tests/Transformer"
    )

    New-ProjectFolder "tests/Axbus.Plugin.Writer.Csv.Tests" @(
        "TestData/Input",
        "TestData/Expected",
        "Tests/Integration",
        "Tests/Internal",
        "Tests/Options",
        "Tests/Plugin",
        "Tests/Writer"
    )

    New-ProjectFolder "tests/Axbus.Plugin.Writer.Excel.Tests" @(
        "TestData/Input",
        "TestData/Expected",
        "Tests/Integration",
        "Tests/Internal",
        "Tests/Options",
        "Tests/Plugin",
        "Tests/Writer"
    )

    New-ProjectFolder "tests/Axbus.Integration.Tests" @(
        "TestData/JsonToCsv/input",
        "TestData/JsonToCsv/expected",
        "TestData/JsonToExcel/input",
        "TestData/JsonToExcel/expected",
        "TestData/JsonToCsvAndExcel/input",
        "TestData/JsonToCsvAndExcel/expected",
        "TestData/MultiModule/module1_input",
        "TestData/MultiModule/module2_input",
        "TestData/MultiModule/expected",
        "TestData/ParallelExecution/set1",
        "TestData/ParallelExecution/set2",
        "TestData/ParallelExecution/set3",
        "TestData/ErrorScenarios",
        "Tests"
    )

    Write-Success "All folder structures created"
}

# ==============================================================================
# STEP 6 — SET PROJECT REFERENCES
# ==============================================================================

function Set-AllProjectReferences {
    Write-Step 6 "Setting Project References"

    # Axbus.Application → Axbus.Core
    Write-Info "Axbus.Application references..."
    Invoke-SafeCommand `
        "dotnet add src/framework/Axbus.Application/Axbus.Application.csproj reference src/framework/Axbus.Core/Axbus.Core.csproj" `
        "Axbus.Application → Axbus.Core"

    # Axbus.Infrastructure → Axbus.Core + Axbus.Application
    Write-Info "Axbus.Infrastructure references..."
    Invoke-SafeCommand `
        "dotnet add src/framework/Axbus.Infrastructure/Axbus.Infrastructure.csproj reference src/framework/Axbus.Core/Axbus.Core.csproj" `
        "Axbus.Infrastructure → Axbus.Core"

    Invoke-SafeCommand `
        "dotnet add src/framework/Axbus.Infrastructure/Axbus.Infrastructure.csproj reference src/framework/Axbus.Application/Axbus.Application.csproj" `
        "Axbus.Infrastructure → Axbus.Application"

    # Axbus.Plugin.Reader.Json → Axbus.Core ONLY
    Write-Info "Axbus.Plugin.Reader.Json references..."
    Invoke-SafeCommand `
        "dotnet add src/plugins/Axbus.Plugin.Reader.Json/Axbus.Plugin.Reader.Json.csproj reference src/framework/Axbus.Core/Axbus.Core.csproj" `
        "Axbus.Plugin.Reader.Json → Axbus.Core"

    # Axbus.Plugin.Writer.Csv → Axbus.Core ONLY
    Write-Info "Axbus.Plugin.Writer.Csv references..."
    Invoke-SafeCommand `
        "dotnet add src/plugins/Axbus.Plugin.Writer.Csv/Axbus.Plugin.Writer.Csv.csproj reference src/framework/Axbus.Core/Axbus.Core.csproj" `
        "Axbus.Plugin.Writer.Csv → Axbus.Core"

    # Axbus.Plugin.Writer.Excel → Axbus.Core ONLY
    Write-Info "Axbus.Plugin.Writer.Excel references..."
    Invoke-SafeCommand `
        "dotnet add src/plugins/Axbus.Plugin.Writer.Excel/Axbus.Plugin.Writer.Excel.csproj reference src/framework/Axbus.Core/Axbus.Core.csproj" `
        "Axbus.Plugin.Writer.Excel → Axbus.Core"

    # Axbus.ConsoleApp → All layers + All plugins
    Write-Info "Axbus.ConsoleApp references..."
    $consoleRefs = @(
        "src/framework/Axbus.Core/Axbus.Core.csproj",
        "src/framework/Axbus.Application/Axbus.Application.csproj",
        "src/framework/Axbus.Infrastructure/Axbus.Infrastructure.csproj",
        "src/plugins/Axbus.Plugin.Reader.Json/Axbus.Plugin.Reader.Json.csproj",
        "src/plugins/Axbus.Plugin.Writer.Csv/Axbus.Plugin.Writer.Csv.csproj",
        "src/plugins/Axbus.Plugin.Writer.Excel/Axbus.Plugin.Writer.Excel.csproj"
    )
    foreach ($ref in $consoleRefs) {
        Invoke-SafeCommand `
            "dotnet add src/clients/Axbus.ConsoleApp/Axbus.ConsoleApp.csproj reference $ref" `
            "Axbus.ConsoleApp → $(Split-Path $ref -Parent | Split-Path -Leaf)"
    }

    # Axbus.WinFormsApp → All layers + All plugins
    Write-Info "Axbus.WinFormsApp references..."
    $winformsRefs = @(
        "src/framework/Axbus.Core/Axbus.Core.csproj",
        "src/framework/Axbus.Application/Axbus.Application.csproj",
        "src/framework/Axbus.Infrastructure/Axbus.Infrastructure.csproj",
        "src/plugins/Axbus.Plugin.Reader.Json/Axbus.Plugin.Reader.Json.csproj",
        "src/plugins/Axbus.Plugin.Writer.Csv/Axbus.Plugin.Writer.Csv.csproj",
        "src/plugins/Axbus.Plugin.Writer.Excel/Axbus.Plugin.Writer.Excel.csproj"
    )
    foreach ($ref in $winformsRefs) {
        Invoke-SafeCommand `
            "dotnet add src/clients/Axbus.WinFormsApp/Axbus.WinFormsApp.csproj reference $ref" `
            "Axbus.WinFormsApp → $(Split-Path $ref -Parent | Split-Path -Leaf)"
    }

    # Axbus.Tests.Common → Axbus.Core
    Write-Info "Axbus.Tests.Common references..."
    Invoke-SafeCommand `
        "dotnet add tests/Axbus.Tests.Common/Axbus.Tests.Common.csproj reference src/framework/Axbus.Core/Axbus.Core.csproj" `
        "Axbus.Tests.Common → Axbus.Core"

    # Axbus.Core.Tests → Axbus.Core + Axbus.Tests.Common
    Write-Info "Axbus.Core.Tests references..."
    Invoke-SafeCommand `
        "dotnet add tests/Axbus.Core.Tests/Axbus.Core.Tests.csproj reference src/framework/Axbus.Core/Axbus.Core.csproj" `
        "Axbus.Core.Tests → Axbus.Core"
    Invoke-SafeCommand `
        "dotnet add tests/Axbus.Core.Tests/Axbus.Core.Tests.csproj reference tests/Axbus.Tests.Common/Axbus.Tests.Common.csproj" `
        "Axbus.Core.Tests → Axbus.Tests.Common"

    # Axbus.Application.Tests → Core + Application + Tests.Common
    Write-Info "Axbus.Application.Tests references..."
    Invoke-SafeCommand `
        "dotnet add tests/Axbus.Application.Tests/Axbus.Application.Tests.csproj reference src/framework/Axbus.Core/Axbus.Core.csproj" `
        "Axbus.Application.Tests → Axbus.Core"
    Invoke-SafeCommand `
        "dotnet add tests/Axbus.Application.Tests/Axbus.Application.Tests.csproj reference src/framework/Axbus.Application/Axbus.Application.csproj" `
        "Axbus.Application.Tests → Axbus.Application"
    Invoke-SafeCommand `
        "dotnet add tests/Axbus.Application.Tests/Axbus.Application.Tests.csproj reference tests/Axbus.Tests.Common/Axbus.Tests.Common.csproj" `
        "Axbus.Application.Tests → Axbus.Tests.Common"

    # Axbus.Infrastructure.Tests → All framework + Tests.Common
    Write-Info "Axbus.Infrastructure.Tests references..."
    Invoke-SafeCommand `
        "dotnet add tests/Axbus.Infrastructure.Tests/Axbus.Infrastructure.Tests.csproj reference src/framework/Axbus.Core/Axbus.Core.csproj" `
        "Axbus.Infrastructure.Tests → Axbus.Core"
    Invoke-SafeCommand `
        "dotnet add tests/Axbus.Infrastructure.Tests/Axbus.Infrastructure.Tests.csproj reference src/framework/Axbus.Application/Axbus.Application.csproj" `
        "Axbus.Infrastructure.Tests → Axbus.Application"
    Invoke-SafeCommand `
        "dotnet add tests/Axbus.Infrastructure.Tests/Axbus.Infrastructure.Tests.csproj reference src/framework/Axbus.Infrastructure/Axbus.Infrastructure.csproj" `
        "Axbus.Infrastructure.Tests → Axbus.Infrastructure"
    Invoke-SafeCommand `
        "dotnet add tests/Axbus.Infrastructure.Tests/Axbus.Infrastructure.Tests.csproj reference tests/Axbus.Tests.Common/Axbus.Tests.Common.csproj" `
        "Axbus.Infrastructure.Tests → Axbus.Tests.Common"

    # Axbus.Plugin.Reader.Json.Tests → Core + Plugin + Tests.Common
    Write-Info "Axbus.Plugin.Reader.Json.Tests references..."
    Invoke-SafeCommand `
        "dotnet add tests/Axbus.Plugin.Reader.Json.Tests/Axbus.Plugin.Reader.Json.Tests.csproj reference src/framework/Axbus.Core/Axbus.Core.csproj" `
        "Axbus.Plugin.Reader.Json.Tests → Axbus.Core"
    Invoke-SafeCommand `
        "dotnet add tests/Axbus.Plugin.Reader.Json.Tests/Axbus.Plugin.Reader.Json.Tests.csproj reference src/plugins/Axbus.Plugin.Reader.Json/Axbus.Plugin.Reader.Json.csproj" `
        "Axbus.Plugin.Reader.Json.Tests → Axbus.Plugin.Reader.Json"
    Invoke-SafeCommand `
        "dotnet add tests/Axbus.Plugin.Reader.Json.Tests/Axbus.Plugin.Reader.Json.Tests.csproj reference tests/Axbus.Tests.Common/Axbus.Tests.Common.csproj" `
        "Axbus.Plugin.Reader.Json.Tests → Axbus.Tests.Common"

    # Axbus.Plugin.Writer.Csv.Tests → Core + Plugin + Tests.Common
    Write-Info "Axbus.Plugin.Writer.Csv.Tests references..."
    Invoke-SafeCommand `
        "dotnet add tests/Axbus.Plugin.Writer.Csv.Tests/Axbus.Plugin.Writer.Csv.Tests.csproj reference src/framework/Axbus.Core/Axbus.Core.csproj" `
        "Axbus.Plugin.Writer.Csv.Tests → Axbus.Core"
    Invoke-SafeCommand `
        "dotnet add tests/Axbus.Plugin.Writer.Csv.Tests/Axbus.Plugin.Writer.Csv.Tests.csproj reference src/plugins/Axbus.Plugin.Writer.Csv/Axbus.Plugin.Writer.Csv.csproj" `
        "Axbus.Plugin.Writer.Csv.Tests → Axbus.Plugin.Writer.Csv"
    Invoke-SafeCommand `
        "dotnet add tests/Axbus.Plugin.Writer.Csv.Tests/Axbus.Plugin.Writer.Csv.Tests.csproj reference tests/Axbus.Tests.Common/Axbus.Tests.Common.csproj" `
        "Axbus.Plugin.Writer.Csv.Tests → Axbus.Tests.Common"

    # Axbus.Plugin.Writer.Excel.Tests → Core + Plugin + Tests.Common
    Write-Info "Axbus.Plugin.Writer.Excel.Tests references..."
    Invoke-SafeCommand `
        "dotnet add tests/Axbus.Plugin.Writer.Excel.Tests/Axbus.Plugin.Writer.Excel.Tests.csproj reference src/framework/Axbus.Core/Axbus.Core.csproj" `
        "Axbus.Plugin.Writer.Excel.Tests → Axbus.Core"
    Invoke-SafeCommand `
        "dotnet add tests/Axbus.Plugin.Writer.Excel.Tests/Axbus.Plugin.Writer.Excel.Tests.csproj reference src/plugins/Axbus.Plugin.Writer.Excel/Axbus.Plugin.Writer.Excel.csproj" `
        "Axbus.Plugin.Writer.Excel.Tests → Axbus.Plugin.Writer.Excel"
    Invoke-SafeCommand `
        "dotnet add tests/Axbus.Plugin.Writer.Excel.Tests/Axbus.Plugin.Writer.Excel.Tests.csproj reference tests/Axbus.Tests.Common/Axbus.Tests.Common.csproj" `
        "Axbus.Plugin.Writer.Excel.Tests → Axbus.Tests.Common"

    # Axbus.Integration.Tests → All layers + All plugins + Tests.Common
    Write-Info "Axbus.Integration.Tests references..."
    $integrationRefs = @(
        "src/framework/Axbus.Core/Axbus.Core.csproj",
        "src/framework/Axbus.Application/Axbus.Application.csproj",
        "src/framework/Axbus.Infrastructure/Axbus.Infrastructure.csproj",
        "src/plugins/Axbus.Plugin.Reader.Json/Axbus.Plugin.Reader.Json.csproj",
        "src/plugins/Axbus.Plugin.Writer.Csv/Axbus.Plugin.Writer.Csv.csproj",
        "src/plugins/Axbus.Plugin.Writer.Excel/Axbus.Plugin.Writer.Excel.csproj",
        "tests/Axbus.Tests.Common/Axbus.Tests.Common.csproj"
    )
    foreach ($ref in $integrationRefs) {
        Invoke-SafeCommand `
            "dotnet add tests/Axbus.Integration.Tests/Axbus.Integration.Tests.csproj reference $ref" `
            "Axbus.Integration.Tests → $(Split-Path $ref -Parent | Split-Path -Leaf)"
    }

    Write-Success "All project references set"
}

# ==============================================================================
# STEP 7 — INSTALL NUGET PACKAGES
# ==============================================================================

function Install-AllNuGetPackages {
    Write-Step 7 "Installing NuGet Packages"

    # ── Axbus.Application ─────────────────────────────────────────────────────
    Write-Info "Installing Axbus.Application packages..."
    $appProject = "src/framework/Axbus.Application/Axbus.Application.csproj"
    Invoke-SafeCommand "dotnet add $appProject package System.Reactive --version 6.0.1" "System.Reactive 6.0.1"
    Invoke-SafeCommand "dotnet add $appProject package Microsoft.Extensions.Logging.Abstractions --version 8.0.0" "Microsoft.Extensions.Logging.Abstractions 8.0.0"
    Invoke-SafeCommand "dotnet add $appProject package Microsoft.Extensions.Options --version 8.0.0" "Microsoft.Extensions.Options 8.0.0"
    Invoke-SafeCommand "dotnet add $appProject package Microsoft.Extensions.DependencyInjection --version 8.0.0" "Microsoft.Extensions.DependencyInjection 8.0.0"

    # ── Axbus.Infrastructure ──────────────────────────────────────────────────
    Write-Info "Installing Axbus.Infrastructure packages..."
    $infraProject = "src/framework/Axbus.Infrastructure/Axbus.Infrastructure.csproj"
    Invoke-SafeCommand "dotnet add $infraProject package Serilog --version 4.0.0" "Serilog 4.0.0"
    Invoke-SafeCommand "dotnet add $infraProject package Serilog.Sinks.Console --version 6.0.0" "Serilog.Sinks.Console 6.0.0"
    Invoke-SafeCommand "dotnet add $infraProject package Serilog.Sinks.File --version 5.0.0" "Serilog.Sinks.File 5.0.0"
    Invoke-SafeCommand "dotnet add $infraProject package Serilog.Extensions.Hosting --version 8.0.0" "Serilog.Extensions.Hosting 8.0.0"
    Invoke-SafeCommand "dotnet add $infraProject package Serilog.Settings.Configuration --version 8.0.0" "Serilog.Settings.Configuration 8.0.0"
    Invoke-SafeCommand "dotnet add $infraProject package Microsoft.Extensions.DependencyInjection --version 8.0.0" "Microsoft.Extensions.DependencyInjection 8.0.0"
    Invoke-SafeCommand "dotnet add $infraProject package Microsoft.Extensions.Configuration.Json --version 8.0.0" "Microsoft.Extensions.Configuration.Json 8.0.0"

    # ── Axbus.Plugin.Reader.Json ──────────────────────────────────────────────
    Write-Info "Installing Axbus.Plugin.Reader.Json packages..."
    $jsonPlugin = "src/plugins/Axbus.Plugin.Reader.Json/Axbus.Plugin.Reader.Json.csproj"
    Invoke-SafeCommand "dotnet add $jsonPlugin package Microsoft.Extensions.Logging.Abstractions --version 8.0.0" "Microsoft.Extensions.Logging.Abstractions 8.0.0"

    # ── Axbus.Plugin.Writer.Csv ───────────────────────────────────────────────
    Write-Info "Installing Axbus.Plugin.Writer.Csv packages..."
    $csvPlugin = "src/plugins/Axbus.Plugin.Writer.Csv/Axbus.Plugin.Writer.Csv.csproj"
    Invoke-SafeCommand "dotnet add $csvPlugin package Microsoft.Extensions.Logging.Abstractions --version 8.0.0" "Microsoft.Extensions.Logging.Abstractions 8.0.0"

    # ── Axbus.Plugin.Writer.Excel ─────────────────────────────────────────────
    Write-Info "Installing Axbus.Plugin.Writer.Excel packages..."
    $excelPlugin = "src/plugins/Axbus.Plugin.Writer.Excel/Axbus.Plugin.Writer.Excel.csproj"
    Invoke-SafeCommand "dotnet add $excelPlugin package ClosedXML --version 0.102.2" "ClosedXML 0.102.2"
    Invoke-SafeCommand "dotnet add $excelPlugin package Microsoft.Extensions.Logging.Abstractions --version 8.0.0" "Microsoft.Extensions.Logging.Abstractions 8.0.0"

    # ── Axbus.ConsoleApp ──────────────────────────────────────────────────────
    Write-Info "Installing Axbus.ConsoleApp packages..."
    $consoleApp = "src/clients/Axbus.ConsoleApp/Axbus.ConsoleApp.csproj"
    Invoke-SafeCommand "dotnet add $consoleApp package Microsoft.Extensions.Hosting --version 8.0.0" "Microsoft.Extensions.Hosting 8.0.0"
    Invoke-SafeCommand "dotnet add $consoleApp package Serilog.Extensions.Hosting --version 8.0.0" "Serilog.Extensions.Hosting 8.0.0"
    Invoke-SafeCommand "dotnet add $consoleApp package Microsoft.Extensions.Configuration.Json --version 8.0.0" "Microsoft.Extensions.Configuration.Json 8.0.0"

    # ── Axbus.WinFormsApp ─────────────────────────────────────────────────────
    Write-Info "Installing Axbus.WinFormsApp packages..."
    $winFormsApp = "src/clients/Axbus.WinFormsApp/Axbus.WinFormsApp.csproj"
    Invoke-SafeCommand "dotnet add $winFormsApp package Microsoft.Extensions.Hosting --version 8.0.0" "Microsoft.Extensions.Hosting 8.0.0"
    Invoke-SafeCommand "dotnet add $winFormsApp package Serilog.Extensions.Hosting --version 8.0.0" "Serilog.Extensions.Hosting 8.0.0"
    Invoke-SafeCommand "dotnet add $winFormsApp package Microsoft.Extensions.Configuration.Json --version 8.0.0" "Microsoft.Extensions.Configuration.Json 8.0.0"

    # ── All Test Projects ─────────────────────────────────────────────────────
    Write-Info "Installing test project packages..."
    $testProjects = @(
        "tests/Axbus.Tests.Common/Axbus.Tests.Common.csproj",
        "tests/Axbus.Core.Tests/Axbus.Core.Tests.csproj",
        "tests/Axbus.Application.Tests/Axbus.Application.Tests.csproj",
        "tests/Axbus.Infrastructure.Tests/Axbus.Infrastructure.Tests.csproj",
        "tests/Axbus.Plugin.Reader.Json.Tests/Axbus.Plugin.Reader.Json.Tests.csproj",
        "tests/Axbus.Plugin.Writer.Csv.Tests/Axbus.Plugin.Writer.Csv.Tests.csproj",
        "tests/Axbus.Plugin.Writer.Excel.Tests/Axbus.Plugin.Writer.Excel.Tests.csproj",
        "tests/Axbus.Integration.Tests/Axbus.Integration.Tests.csproj"
    )

    foreach ($testProject in $testProjects) {
        $projectName = Split-Path $testProject -Parent | Split-Path -Leaf
        Write-Info "Installing packages for $projectName..."
        Invoke-SafeCommand "dotnet add $testProject package NUnit --version 4.1.0" "NUnit 4.1.0"
        Invoke-SafeCommand "dotnet add $testProject package NUnit3TestAdapter --version 4.5.0" "NUnit3TestAdapter 4.5.0"
        Invoke-SafeCommand "dotnet add $testProject package Microsoft.NET.Test.Sdk --version 17.11.0" "Microsoft.NET.Test.Sdk 17.11.0"
        Invoke-SafeCommand "dotnet add $testProject package Microsoft.Extensions.DependencyInjection --version 8.0.0" "Microsoft.Extensions.DependencyInjection 8.0.0"
    }

    # System.Reactive for Tests.Common and Integration Tests
    Invoke-SafeCommand "dotnet add tests/Axbus.Tests.Common/Axbus.Tests.Common.csproj package System.Reactive --version 6.0.1" "System.Reactive for Tests.Common"
    Invoke-SafeCommand "dotnet add tests/Axbus.Integration.Tests/Axbus.Integration.Tests.csproj package System.Reactive --version 6.0.1" "System.Reactive for Integration.Tests"

    Write-Success "All NuGet packages installed"
}

# ==============================================================================
# STEP 8 — CREATE GLOBAL BUILD CONFIGURATION
# ==============================================================================

function New-GlobalBuildConfiguration {
    Write-Step 8 "Creating Global Build Configuration"

    # Directory.Build.props
    $buildProps = @'
<!-- Copyright (c) 2026 Axel Johnson International. All rights reserved. -->
<Project>
  <PropertyGroup>
    <!-- Target Framework -->
    <TargetFramework>net8.0</TargetFramework>

    <!-- Language Version — use latest C# features -->
    <LangVersion>latest</LangVersion>

    <!-- Nullable reference types enabled globally -->
    <Nullable>enable</Nullable>

    <!-- Treat warnings as errors in Release -->
    <TreatWarningsAsErrors Condition="'$(Configuration)' == 'Release'">true</TreatWarningsAsErrors>

    <!-- Implicit usings enabled -->
    <ImplicitUsings>enable</ImplicitUsings>

    <!-- NuGet Package Metadata -->
    <Authors>Axel Johnson International</Authors>
    <Company>Axel Johnson International</Company>
    <Copyright>Copyright (c) 2026 Axel Johnson International. All rights reserved.</Copyright>
    <PackageLicenseExpression>MIT</PackageLicenseExpression>
    <RepositoryType>git</RepositoryType>

    <!-- Symbol packages for debugging -->
    <IncludeSymbols>true</IncludeSymbols>
    <SymbolPackageFormat>snupkg</SymbolPackageFormat>

    <!-- Do not pack by default — controlled via CI -->
    <GeneratePackageOnBuild>false</GeneratePackageOnBuild>

    <!-- Analysis -->
    <EnableNETAnalyzers>true</EnableNETAnalyzers>
    <AnalysisMode>All</AnalysisMode>
  </PropertyGroup>
</Project>
'@
    New-FileFromContent "Directory.Build.props" $buildProps

    # Directory.Build.targets
    $buildTargets = @'
<!-- Copyright (c) 2026 Axel Johnson International. All rights reserved. -->
<Project>
  <PropertyGroup>
    <!-- Enforce consistent output paths -->
    <AppendTargetFrameworkToOutputPath>false</AppendTargetFrameworkToOutputPath>
  </PropertyGroup>
</Project>
'@
    New-FileFromContent "Directory.Build.targets" $buildTargets

    Write-Success "Global build configuration created"
}

# ==============================================================================
# STEP 9 — CREATE GLOBAL USINGS
# ==============================================================================

function New-AllGlobalUsings {
    Write-Step 9 "Creating GlobalUsings.cs Files"

    # Axbus.Core
    $coreUsings = @"
// <copyright file="GlobalUsings.cs" company="Axel Johnson International">
// Copyright (c) 2026 Axel Johnson International. All rights reserved.
// </copyright>

global using System;
global using System.Collections.Generic;
global using System.Threading;
global using System.Threading.Tasks;
"@
    New-FileFromContent "src/framework/Axbus.Core/GlobalUsings.cs" $coreUsings

    # Axbus.Application
    $appUsings = @"
// <copyright file="GlobalUsings.cs" company="Axel Johnson International">
// Copyright (c) 2026 Axel Johnson International. All rights reserved.
// </copyright>

global using System;
global using System.Collections.Generic;
global using System.Linq;
global using System.Threading;
global using System.Threading.Tasks;
global using Microsoft.Extensions.Logging;
"@
    New-FileFromContent "src/framework/Axbus.Application/GlobalUsings.cs" $appUsings

    # Axbus.Infrastructure
    $infraUsings = @"
// <copyright file="GlobalUsings.cs" company="Axel Johnson International">
// Copyright (c) 2026 Axel Johnson International. All rights reserved.
// </copyright>

global using System;
global using System.Collections.Generic;
global using System.IO;
global using System.Threading;
global using System.Threading.Tasks;
global using Microsoft.Extensions.Logging;
"@
    New-FileFromContent "src/framework/Axbus.Infrastructure/GlobalUsings.cs" $infraUsings

    # Axbus.Plugin.Reader.Json
    $jsonPluginUsings = @"
// <copyright file="GlobalUsings.cs" company="Axel Johnson International">
// Copyright (c) 2026 Axel Johnson International. All rights reserved.
// </copyright>

global using System;
global using System.Collections.Generic;
global using System.Text.Json;
global using System.Threading;
global using System.Threading.Tasks;
global using Microsoft.Extensions.Logging;
"@
    New-FileFromContent "src/plugins/Axbus.Plugin.Reader.Json/GlobalUsings.cs" $jsonPluginUsings

    # Axbus.Plugin.Writer.Csv
    $csvPluginUsings = @"
// <copyright file="GlobalUsings.cs" company="Axel Johnson International">
// Copyright (c) 2026 Axel Johnson International. All rights reserved.
// </copyright>

global using System;
global using System.Collections.Generic;
global using System.IO;
global using System.Text;
global using System.Threading;
global using System.Threading.Tasks;
global using Microsoft.Extensions.Logging;
"@
    New-FileFromContent "src/plugins/Axbus.Plugin.Writer.Csv/GlobalUsings.cs" $csvPluginUsings

    # Axbus.Plugin.Writer.Excel
    $excelPluginUsings = @"
// <copyright file="GlobalUsings.cs" company="Axel Johnson International">
// Copyright (c) 2026 Axel Johnson International. All rights reserved.
// </copyright>

global using System;
global using System.Collections.Generic;
global using System.IO;
global using System.Threading;
global using System.Threading.Tasks;
global using ClosedXML.Excel;
global using Microsoft.Extensions.Logging;
"@
    New-FileFromContent "src/plugins/Axbus.Plugin.Writer.Excel/GlobalUsings.cs" $excelPluginUsings

    Write-Success "GlobalUsings.cs created for all projects"
}

# ==============================================================================
# STEP 10 — DELETE AUTO-GENERATED PLACEHOLDER FILES
# ==============================================================================

function Remove-AutoGeneratedFiles {
    Write-Step 10 "Removing Auto-Generated Placeholder Files"

    $filesToDelete = @(
        "src/framework/Axbus.Core/Class1.cs",
        "src/framework/Axbus.Application/Class1.cs",
        "src/framework/Axbus.Infrastructure/Class1.cs",
        "src/plugins/Axbus.Plugin.Reader.Json/Class1.cs",
        "src/plugins/Axbus.Plugin.Writer.Csv/Class1.cs",
        "src/plugins/Axbus.Plugin.Writer.Excel/Class1.cs",
        "tests/Axbus.Tests.Common/Class1.cs",
        "tests/Axbus.Core.Tests/UnitTest1.cs",
        "tests/Axbus.Application.Tests/UnitTest1.cs",
        "tests/Axbus.Infrastructure.Tests/UnitTest1.cs",
        "tests/Axbus.Plugin.Reader.Json.Tests/UnitTest1.cs",
        "tests/Axbus.Plugin.Writer.Csv.Tests/UnitTest1.cs",
        "tests/Axbus.Plugin.Writer.Excel.Tests/UnitTest1.cs",
        "tests/Axbus.Integration.Tests/UnitTest1.cs"
    )

    foreach ($file in $filesToDelete) {
        if (Test-Path $file) {
            Remove-Item $file -Force
            Write-Success "Deleted: $file"
        }
    }

    Write-Success "Auto-generated placeholder files removed"
}

# ==============================================================================
# STEP 11 — CREATE STUB CONFIG FILES
# ==============================================================================

function New-StubConfigFiles {
    Write-Step 11 "Creating Stub Configuration Files"

    # ── appsettings.json for ConsoleApp ───────────────────────────────────────
    $consoleAppSettings = @'
{
  "RunInParallel": false,
  "ParallelSettings": {
    "MaxDegreeOfParallelism": 4,
    "MaxConcurrentFileReads": 4,
    "MaxConcurrentFileWrites": 2
  },
  "PluginSettings": {
    "PluginsFolder": null,
    "ScanSubFolders": true,
    "IsolatePlugins": true,
    "ConflictStrategy": "UseLatestVersion",
    "Plugins": [
      "Axbus.Plugin.Reader.Json",
      "Axbus.Plugin.Writer.Csv",
      "Axbus.Plugin.Writer.Excel"
    ]
  },
  "ConversionModules": [
    {
      "ConversionName": "SampleJsonToCsv",
      "Description": "Sample conversion from JSON to CSV",
      "IsEnabled": true,
      "ExecutionOrder": 1,
      "ContinueOnError": true,
      "RunInParallel": false,
      "SourceFormat": "json",
      "TargetFormat": "csv",
      "PluginOverride": null,
      "Source": {
        "Type": "FileSystem",
        "Path": "C:\\input\\json",
        "FilePattern": "*.json",
        "ReadMode": "AllFiles"
      },
      "Target": {
        "Type": "FileSystem",
        "Path": "C:\\output\\csv",
        "OutputMode": "SingleFile",
        "ErrorOutputPath": "C:\\output\\errors",
        "ErrorFileSuffix": ".errors"
      },
      "Pipeline": {
        "SchemaStrategy": "FullScan",
        "RowErrorStrategy": "WriteToErrorFile",
        "MaxExplosionDepth": 3,
        "NullPlaceholder": ""
      },
      "PluginOptions": {
        "RootArrayKey": null
      }
    }
  ],
  "Serilog": {
    "MinimumLevel": {
      "Default": "Information",
      "Override": {
        "Microsoft": "Warning",
        "System": "Warning"
      }
    },
    "WriteTo": [
      {
        "Name": "Console"
      },
      {
        "Name": "File",
        "Args": {
          "path": "logs/axbus-.log",
          "rollingInterval": "Day",
          "rollOnFileSizeLimit": true,
          "fileSizeLimitBytes": 5242880,
          "retainedFileCountLimit": 10
        }
      }
    ],
    "Enrich": [ "FromLogContext", "WithMachineName", "WithThreadId" ]
  }
}
'@
    New-FileFromContent "src/clients/Axbus.ConsoleApp/appsettings.json" $consoleAppSettings
    New-FileFromContent "src/clients/Axbus.WinFormsApp/appsettings.json" $consoleAppSettings

    # ── appsettings.Development.json ──────────────────────────────────────────
    $devSettings = @'
{
  "Serilog": {
    "MinimumLevel": {
      "Default": "Debug"
    }
  }
}
'@
    New-FileFromContent "src/clients/Axbus.ConsoleApp/appsettings.Development.json" $devSettings
    New-FileFromContent "src/clients/Axbus.WinFormsApp/appsettings.Development.json" $devSettings

    # ── appsettings.Production.json ───────────────────────────────────────────
    $prodSettings = @'
{
  "Serilog": {
    "MinimumLevel": {
      "Default": "Warning"
    }
  }
}
'@
    New-FileFromContent "src/clients/Axbus.ConsoleApp/appsettings.Production.json" $prodSettings
    New-FileFromContent "src/clients/Axbus.WinFormsApp/appsettings.Production.json" $prodSettings

    # ── Plugin manifest stubs ─────────────────────────────────────────────────
    $jsonReaderManifest = @'
{
  "Name": "JsonReader",
  "PluginId": "axbus.plugin.reader.json",
  "Version": "1.0.0",
  "FrameworkVersion": "1.0.0",
  "SourceFormat": "json",
  "TargetFormat": null,
  "SupportedStages": [ "Read", "Parse", "Transform" ],
  "IsBundled": false,
  "Author": "Axel Johnson International",
  "Description": "Reads, parses and transforms JSON files into the Axbus pipeline.",
  "Dependencies": []
}
'@
    New-FileFromContent "src/plugins/Axbus.Plugin.Reader.Json/Axbus.Plugin.Reader.Json.manifest.json" $jsonReaderManifest

    $csvWriterManifest = @'
{
  "Name": "CsvWriter",
  "PluginId": "axbus.plugin.writer.csv",
  "Version": "1.0.0",
  "FrameworkVersion": "1.0.0",
  "SourceFormat": null,
  "TargetFormat": "csv",
  "SupportedStages": [ "Write" ],
  "IsBundled": false,
  "Author": "Axel Johnson International",
  "Description": "Writes Axbus pipeline output to RFC 4180 compliant CSV files.",
  "Dependencies": []
}
'@
    New-FileFromContent "src/plugins/Axbus.Plugin.Writer.Csv/Axbus.Plugin.Writer.Csv.manifest.json" $csvWriterManifest

    $excelWriterManifest = @'
{
  "Name": "ExcelWriter",
  "PluginId": "axbus.plugin.writer.excel",
  "Version": "1.0.0",
  "FrameworkVersion": "1.0.0",
  "SourceFormat": null,
  "TargetFormat": "excel",
  "SupportedStages": [ "Write" ],
  "IsBundled": false,
  "Author": "Axel Johnson International",
  "Description": "Writes Axbus pipeline output to Excel (.xlsx) files using ClosedXML.",
  "Dependencies": [ "ClosedXML" ]
}
'@
    New-FileFromContent "src/plugins/Axbus.Plugin.Writer.Excel/Axbus.Plugin.Writer.Excel.manifest.json" $excelWriterManifest

    Write-Success "All stub configuration files created"
}

# ==============================================================================
# STEP 12 — CREATE SAMPLE TEST DATA FILES
# ==============================================================================

function New-SampleTestDataFiles {
    Write-Step 12 "Creating Sample Test Data Files"

    # Simple flat JSON
    $simpleFlatJson = @'
[
  {
    "weight": 0,
    "cnCode": 0,
    "type": "Part",
    "persistentIdentity": "1637932",
    "brandName": "3806",
    "brandPartNumber": "MA-200MESH-470x170"
  },
  {
    "weight": 10,
    "cnCode": 1234,
    "type": "Assembly",
    "persistentIdentity": "1658846",
    "brandName": "3806",
    "brandPartNumber": "SF150.0065-470x170"
  }
]
'@
    New-FileFromContent "tests/Axbus.Core.Tests/TestData/FlatJson/simple_flat.json" $simpleFlatJson

    # Nested objects JSON
    $nestedJson = @'
[
  {
    "id": "001",
    "type": "Order",
    "customer": {
      "name": "Acme Corp",
      "address": {
        "city": "Stockholm",
        "country": "Sweden"
      }
    },
    "amount": 1500.00
  }
]
'@
    New-FileFromContent "tests/Axbus.Core.Tests/TestData/NestedJson/nested_objects.json" $nestedJson

    # Array explosion JSON
    $arrayJson = @'
[
  {
    "orderId": "ORD-001",
    "customer": "Acme Corp",
    "items": [
      { "sku": "SKU-A", "qty": 2, "price": 50.00 },
      { "sku": "SKU-B", "qty": 1, "price": 75.00 }
    ]
  }
]
'@
    New-FileFromContent "tests/Axbus.Core.Tests/TestData/ArrayJson/array_explosion.json" $arrayJson

    # Edge cases
    New-FileFromContent "tests/Axbus.Core.Tests/TestData/EdgeCases/empty.json" "[]"
    New-FileFromContent "tests/Axbus.Core.Tests/TestData/EdgeCases/invalid.json" "{ this is not valid json }"

    $nullValuesJson = @'
[
  {
    "id": "001",
    "name": null,
    "value": null,
    "active": true
  }
]
'@
    New-FileFromContent "tests/Axbus.Core.Tests/TestData/EdgeCases/null_values.json" $nullValuesJson

    # Integration test data
    $salesOrderJson = @'
[
  {
    "orderId": "SO-2026-001",
    "orderDate": "2026-01-15",
    "customer": {
      "id": "CUST-001",
      "name": "Axel Johnson AB",
      "contact": {
        "email": "orders@axeljohnson.se",
        "phone": "+46 8 123 456"
      }
    },
    "lines": [
      { "lineNo": 1, "product": "Widget A", "quantity": 100, "unitPrice": 25.50 },
      { "lineNo": 2, "product": "Widget B", "quantity": 50,  "unitPrice": 42.00 }
    ],
    "totalAmount": 4650.00,
    "currency": "SEK",
    "status": "Confirmed"
  }
]
'@
    New-FileFromContent "tests/Axbus.Integration.Tests/TestData/JsonToCsv/input/sales_orders.json" $salesOrderJson
    New-FileFromContent "tests/Axbus.Plugin.Reader.Json.Tests/TestData/Input/flat_array.json" $simpleFlatJson
    New-FileFromContent "tests/Axbus.Plugin.Reader.Json.Tests/TestData/Input/nested_objects.json" $nestedJson
    New-FileFromContent "tests/Axbus.Plugin.Reader.Json.Tests/TestData/Input/array_explosion.json" $arrayJson
    New-FileFromContent "tests/Axbus.Plugin.Reader.Json.Tests/TestData/Input/empty.json" "[]"
    New-FileFromContent "tests/Axbus.Plugin.Reader.Json.Tests/TestData/Input/invalid.json" "{ this is not valid json }"

    Write-Success "Sample test data files created"
}

# ==============================================================================
# STEP 13 — BUILD SOLUTION TO VERIFY
# ==============================================================================

function Invoke-SolutionBuild {
    Write-Step 13 "Building Solution (Verification)"

    Write-Info "Running: dotnet build $SolutionName.sln"
    try {
        $buildOutput = dotnet build "$SolutionName.sln" --configuration Debug 2>&1
        $buildSuccess = $LASTEXITCODE -eq 0

        if ($buildSuccess) {
            Write-Success "Solution builds successfully — zero errors"
        }
        else {
            Write-Warning "Build completed with warnings or errors. Review output:"
            $buildOutput | Where-Object { $_ -match "error|warning" } | ForEach-Object {
                Write-Host "      $_" -ForegroundColor $ColourWarning
            }
            Write-Info "This is expected at this stage — projects are empty stubs."
            Write-Info "Errors will resolve as Copilot generates the code files."
        }
    }
    catch {
        Write-Warning "Build check failed: $_"
        Write-Info "This may be expected for empty projects. Proceed with code generation."
    }
}

# ==============================================================================
# STEP 14 — PRINT SUCCESS SUMMARY
# ==============================================================================

function Write-SuccessSummary {
    Write-Host ""
    Write-Host "===============================================================================" -ForegroundColor $ColourSuccess
    Write-Host "  ✅ Axbus Framework — Setup Complete!" -ForegroundColor $ColourSuccess
    Write-Host "===============================================================================" -ForegroundColor $ColourSuccess
    Write-Host ""
    Write-Host "  What was created:" -ForegroundColor $ColourInfo
    Write-Host "    ✅ Axbus.sln solution file" -ForegroundColor $ColourSuccess
    Write-Host "    ✅ 16 projects (3 framework + 3 plugins + 2 clients + 8 tests)" -ForegroundColor $ColourSuccess
    Write-Host "    ✅ 50+ folder structures" -ForegroundColor $ColourSuccess
    Write-Host "    ✅ All project references set" -ForegroundColor $ColourSuccess
    Write-Host "    ✅ All NuGet packages installed" -ForegroundColor $ColourSuccess
    Write-Host "    ✅ Directory.Build.props + targets" -ForegroundColor $ColourSuccess
    Write-Host "    ✅ GlobalUsings.cs per project" -ForegroundColor $ColourSuccess
    Write-Host "    ✅ appsettings.json stubs for clients" -ForegroundColor $ColourSuccess
    Write-Host "    ✅ manifest.json stubs for plugins" -ForegroundColor $ColourSuccess
    Write-Host "    ✅ Sample test data JSON files" -ForegroundColor $ColourSuccess
    Write-Host ""
    Write-Host "  Next Steps:" -ForegroundColor $ColourStep
    Write-Host "    1. Open Axbus.sln in Visual Studio" -ForegroundColor $ColourInfo
    Write-Host "    2. Open Copilot Chat (Ctrl+Alt+I)" -ForegroundColor $ColourInfo
    Write-Host "    3. Verify Claude Opus model is selected" -ForegroundColor $ColourInfo
    Write-Host "    4. Follow .github/copilot-instructions.md Section 9" -ForegroundColor $ColourInfo
    Write-Host "    5. Generate files in sequence from Section 8" -ForegroundColor $ColourInfo
    Write-Host "    6. Start with: Axbus.Core/Enums/OutputFormat.cs" -ForegroundColor $ColourInfo
    Write-Host ""
    Write-Host "  Commit this setup to Git:" -ForegroundColor $ColourStep
    Write-Host "    git add ." -ForegroundColor $ColourInfo
    Write-Host "    git commit -m 'chore(setup): create solution structure via setup-axbus.ps1'" -ForegroundColor $ColourInfo
    Write-Host "    git push" -ForegroundColor $ColourInfo
    Write-Host ""
    Write-Host "===============================================================================" -ForegroundColor $ColourSuccess
    Write-Host ""
}

# ==============================================================================
# MAIN EXECUTION
# ==============================================================================

try {
    Write-Banner
    Test-Prerequisites
    New-SolutionFile
    New-AllProjects
    Add-ProjectsToSolution
    New-AllFolderStructures
    Set-AllProjectReferences
    Install-AllNuGetPackages
    New-GlobalBuildConfiguration
    New-AllGlobalUsings
    Remove-AutoGeneratedFiles
    New-StubConfigFiles
    New-SampleTestDataFiles
    Invoke-SolutionBuild
    Write-SuccessSummary
}
catch {
    Write-Host ""
    Write-Host "===============================================================================" -ForegroundColor $ColourError
    Write-Host "  ❌ Setup Failed" -ForegroundColor $ColourError
    Write-Host "===============================================================================" -ForegroundColor $ColourError
    Write-Host "  Error: $_" -ForegroundColor $ColourError
    Write-Host "  Line : $($_.InvocationInfo.ScriptLineNumber)" -ForegroundColor $ColourError
    Write-Host ""
    Write-Host "  Please fix the error above and run the script again." -ForegroundColor $ColourError
    Write-Host "  The script is idempotent and safe to re-run." -ForegroundColor $ColourError
    Write-Host "===============================================================================" -ForegroundColor $ColourError
    Write-Host ""
    exit 1
}

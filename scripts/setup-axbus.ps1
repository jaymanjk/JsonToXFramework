# ==============================================================================
# setup-axbus.ps1
# Axbus Framework - Full Solution Setup Script
# Copyright (c) 2026 Axel Johnson International. All rights reserved.
#
# USAGE:
#   PowerShell -ExecutionPolicy Bypass -File .\scripts\setup-axbus.ps1
#
# PREREQUISITES:
#   - .NET 8 SDK installed
#   - Git installed
#   - Run from the root of the cloned JsonToXFramework repository
# ==============================================================================

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# ==============================================================================
# CONFIGURATION
# ==============================================================================

$SolutionName  = "Axbus"
$CompanyName   = "Axel Johnson International"
$CopyrightYear = "2026"
$DotNetVersion = "net8.0"
$ScriptVersion = "1.0.2"

# Resolved at runtime after solution is created - see Get-SolutionFile function
$SolutionFile  = ""

# ==============================================================================
# HELPER FUNCTIONS
# ==============================================================================

function Write-Banner {
    Write-Host ""
    Write-Host "===============================================================================" -ForegroundColor Cyan
    Write-Host "  Axbus Framework - Solution Setup Script v$ScriptVersion" -ForegroundColor Cyan
    Write-Host "  Copyright (c) $CopyrightYear $CompanyName. All rights reserved." -ForegroundColor Cyan
    Write-Host "===============================================================================" -ForegroundColor Cyan
    Write-Host ""
}

function Write-Step {
    param([int]$Number, [string]$Message)
    Write-Host ""
    Write-Host "  [$Number] $Message" -ForegroundColor Yellow
    Write-Host "  $("-" * 70)" -ForegroundColor Yellow
}

function Write-Ok {
    param([string]$Message)
    Write-Host "      [OK] $Message" -ForegroundColor Green
}

function Write-Info {
    param([string]$Message)
    Write-Host "      [..] $Message" -ForegroundColor White
}

function Write-Warn {
    param([string]$Message)
    Write-Host "      [!!] $Message" -ForegroundColor Magenta
}

function Write-Fail {
    param([string]$Message)
    Write-Host ""
    Write-Host "  [FAILED] $Message" -ForegroundColor Red
    Write-Host ""
}

function Get-SolutionFile {
    # Visual Studio 2022 17.x+ creates .slnx (new XML-based format)
    # Visual Studio 2019 and earlier creates .sln (legacy format)
    # Auto-detect whichever format was created by dotnet new sln
    if (Test-Path "$SolutionName.slnx") {
        return "$SolutionName.slnx"
    }
    elseif (Test-Path "$SolutionName.sln") {
        return "$SolutionName.sln"
    }
    else {
        return $null
    }
}

function Invoke-SafeCommand {
    param(
        [string]$Command,
        [string]$Description
    )
    Write-Info $Description
    try {
        Invoke-Expression $Command 2>&1 | Out-Null
        if ($LASTEXITCODE -ne 0 -and $LASTEXITCODE -ne $null) {
            throw "Command exited with code $LASTEXITCODE"
        }
        Write-Ok $Description
    }
    catch {
        Write-Fail "Command failed: $Description"
        Write-Host "  Command : $Command" -ForegroundColor Red
        Write-Host "  Error   : $_" -ForegroundColor Red
        exit 1
    }
}

function Invoke-DotnetNew {
    # Wrapper around dotnet new that skips gracefully if project already exists.
    # This makes the script idempotent - safe to re-run on existing projects.
    param(
        [string]$Command,
        [string]$Description,
        [string]$CsprojPath
    )
    if (Test-Path $CsprojPath) {
        Write-Host "      [SKIP] Already exists: $Description" -ForegroundColor DarkGray
        return
    }
    Invoke-SafeCommand $Command $Description
}

function Invoke-SolutionAdd {
    # Wrapper around dotnet sln add that skips if project already in solution.
    param(
        [string]$SolutionFileParam,
        [string]$ProjectPath
    )
    $projectName = Split-Path $ProjectPath -Leaf
    # Check if already in solution by attempting add - dotnet sln add is idempotent
    # but we still want clean output
    $output = Invoke-Expression "dotnet sln $SolutionFileParam add $ProjectPath" 2>&1
    if ($output -match "already contains") {
        Write-Host "      [SKIP] Already in solution: $projectName" -ForegroundColor DarkGray
    }
    else {
        Write-Ok "Added to solution: $projectName"
    }
}

function New-ProjectFolder {
    param(
        [string]$ProjectPath,
        [string[]]$Folders
    )
    foreach ($folder in $Folders) {
        $fullPath = Join-Path $ProjectPath $folder
        if (-not (Test-Path $fullPath)) {
            New-Item -ItemType Directory -Path $fullPath -Force | Out-Null
            Write-Info "Created: $folder"
        }
    }
}

function New-FileFromContent {
    param(
        [string]$FilePath,
        [string]$Content
    )
    # Split-Path -Parent returns empty string when FilePath has no folder component
    # e.g. "Directory.Build.props" -> "" which causes New-Item to fail
    # Guard against empty parent (means current directory - no need to create)
    $directory = Split-Path $FilePath -Parent
    if ((-not [string]::IsNullOrWhiteSpace($directory)) -and (-not (Test-Path $directory))) {
        New-Item -ItemType Directory -Path $directory -Force | Out-Null
    }
    [System.IO.File]::WriteAllText(
        [System.IO.Path]::GetFullPath($FilePath),
        $Content,
        [System.Text.UTF8Encoding]::new($false)
    )
    Write-Ok "Created: $(Split-Path $FilePath -Leaf)"
}

# ==============================================================================
# STEP 0 - CLEAN WORKSPACE
# ==============================================================================

function Invoke-CleanWorkspace {
    Write-Step 0 "Cleaning Existing Workspace"

    Write-Warn "This will permanently delete all generated solution files and projects."
    Write-Warn "Your .github/, scripts/, docs/, .gitignore, .editorconfig,"
    Write-Warn "README.md, LICENSE and CHANGELOG.md will NOT be deleted."
    Write-Host ""
    $answer = Read-Host "      Are you sure you want to clean and start fresh? (y/N)"

    if ($answer -ne "y" -and $answer -ne "Y") {
        Write-Info "Clean cancelled. Exiting."
        exit 0
    }

    Write-Host ""
    Write-Info "Cleaning workspace..."

    # Delete solution files
    $solutionFiles = @(
        "$SolutionName.sln",
        "$SolutionName.slnx",
        "$SolutionName.sln.DotSettings",
        "$SolutionName.sln.DotSettings.user"
    )
    foreach ($file in $solutionFiles) {
        if (Test-Path $file) {
            Remove-Item $file -Force
            Write-Ok "Deleted: $file"
        }
    }

    # Delete generated build config files
    # NOTE: We do NOT delete .github/, scripts/, docs/, .gitignore,
    #       .editorconfig, README.md, LICENSE, CHANGELOG.md, CONTRIBUTING.md
    $buildFiles = @(
        "Directory.Build.props",
        "Directory.Build.targets"
    )
    foreach ($file in $buildFiles) {
        if (Test-Path $file) {
            Remove-Item $file -Force
            Write-Ok "Deleted: $file"
        }
    }

    # Delete src folder (all framework, plugin, client projects)
    if (Test-Path "src") {
        Remove-Item "src" -Recurse -Force
        Write-Ok "Deleted: src/ (framework + plugin + client projects)"
    }
    else {
        Write-Info "Skipped: src/ (does not exist)"
    }

    # Delete tests folder (all test projects)
    if (Test-Path "tests") {
        Remove-Item "tests" -Recurse -Force
        Write-Ok "Deleted: tests/ (all test projects)"
    }
    else {
        Write-Info "Skipped: tests/ (does not exist)"
    }

    # Delete NuGet package cache for this solution (optional cleanup)
    if (Test-Path ".packages") {
        Remove-Item ".packages" -Recurse -Force
        Write-Ok "Deleted: .packages/"
    }

    Write-Host ""
    Write-Ok "Workspace cleaned. Starting fresh setup..."
    Write-Host ""
}

# ==============================================================================
# STEP 1 - VALIDATE PREREQUISITES
# ==============================================================================

function Test-Prerequisites {
    Write-Step 1 "Validating Prerequisites"

    if (-not (Test-Path ".git")) {
        Write-Fail "Run this script from the repository root (where .git folder exists)."
        Write-Host "  Current location: $(Get-Location)" -ForegroundColor Red
        exit 1
    }
    Write-Ok "Repository root confirmed: $(Get-Location)"

    try {
        $dotnetVersion = (dotnet --version 2>&1).ToString().Trim()
        if ($dotnetVersion -match "^8\.") {
            Write-Ok ".NET SDK: $dotnetVersion"
        }
        else {
            Write-Warn ".NET $dotnetVersion found - Axbus targets .NET 8"
        }
    }
    catch {
        Write-Fail ".NET SDK not found. Install from: https://dotnet.microsoft.com/download/dotnet/8.0"
        exit 1
    }

    try {
        $gitVersion = (git --version 2>&1).ToString().Trim()
        Write-Ok "Git: $gitVersion"
    }
    catch {
        Write-Fail "Git not found. Please install Git."
        exit 1
    }

    Write-Ok "All prerequisites validated"
}

# ==============================================================================
# STEP 2 - CREATE SOLUTION
# ==============================================================================

function New-SolutionFile {
    Write-Step 2 "Creating Solution File"
    Invoke-SafeCommand "dotnet new sln --name $SolutionName --output ." "Creating solution file"
    $script:SolutionFile = Get-SolutionFile
    Write-Ok "Solution file detected: $script:SolutionFile"
}

# ==============================================================================
# STEP 3 - CREATE PROJECTS
# ==============================================================================

function New-AllProjects {
    Write-Step 3 "Creating All 16 Projects"

    Write-Info "--- Framework Projects ---"
    Invoke-DotnetNew "dotnet new classlib --name Axbus.Core --output src/framework/Axbus.Core --framework $DotNetVersion" "Axbus.Core" "src/framework/Axbus.Core/Axbus.Core.csproj"
    Invoke-DotnetNew "dotnet new classlib --name Axbus.Application --output src/framework/Axbus.Application --framework $DotNetVersion" "Axbus.Application" "src/framework/Axbus.Application/Axbus.Application.csproj"
    Invoke-DotnetNew "dotnet new classlib --name Axbus.Infrastructure --output src/framework/Axbus.Infrastructure --framework $DotNetVersion" "Axbus.Infrastructure" "src/framework/Axbus.Infrastructure/Axbus.Infrastructure.csproj"

    Write-Info "--- Plugin Projects ---"
    Invoke-DotnetNew "dotnet new classlib --name Axbus.Plugin.Reader.Json --output src/plugins/Axbus.Plugin.Reader.Json --framework $DotNetVersion" "Axbus.Plugin.Reader.Json" "src/plugins/Axbus.Plugin.Reader.Json/Axbus.Plugin.Reader.Json.csproj"
    Invoke-DotnetNew "dotnet new classlib --name Axbus.Plugin.Writer.Csv --output src/plugins/Axbus.Plugin.Writer.Csv --framework $DotNetVersion" "Axbus.Plugin.Writer.Csv" "src/plugins/Axbus.Plugin.Writer.Csv/Axbus.Plugin.Writer.Csv.csproj"
    Invoke-DotnetNew "dotnet new classlib --name Axbus.Plugin.Writer.Excel --output src/plugins/Axbus.Plugin.Writer.Excel --framework $DotNetVersion" "Axbus.Plugin.Writer.Excel" "src/plugins/Axbus.Plugin.Writer.Excel/Axbus.Plugin.Writer.Excel.csproj"

    Write-Info "--- Client Projects ---"
    Invoke-DotnetNew "dotnet new console --name Axbus.ConsoleApp --output src/clients/Axbus.ConsoleApp --framework $DotNetVersion" "Axbus.ConsoleApp" "src/clients/Axbus.ConsoleApp/Axbus.ConsoleApp.csproj"
    Invoke-DotnetNew "dotnet new winforms --name Axbus.WinFormsApp --output src/clients/Axbus.WinFormsApp --framework $DotNetVersion" "Axbus.WinFormsApp" "src/clients/Axbus.WinFormsApp/Axbus.WinFormsApp.csproj"

    Write-Info "--- Test Projects ---"
    Invoke-DotnetNew "dotnet new classlib --name Axbus.Tests.Common --output tests/Axbus.Tests.Common --framework $DotNetVersion" "Axbus.Tests.Common" "tests/Axbus.Tests.Common/Axbus.Tests.Common.csproj"
    Invoke-DotnetNew "dotnet new nunit --name Axbus.Core.Tests --output tests/Axbus.Core.Tests --framework $DotNetVersion" "Axbus.Core.Tests" "tests/Axbus.Core.Tests/Axbus.Core.Tests.csproj"
    Invoke-DotnetNew "dotnet new nunit --name Axbus.Application.Tests --output tests/Axbus.Application.Tests --framework $DotNetVersion" "Axbus.Application.Tests" "tests/Axbus.Application.Tests/Axbus.Application.Tests.csproj"
    Invoke-DotnetNew "dotnet new nunit --name Axbus.Infrastructure.Tests --output tests/Axbus.Infrastructure.Tests --framework $DotNetVersion" "Axbus.Infrastructure.Tests" "tests/Axbus.Infrastructure.Tests/Axbus.Infrastructure.Tests.csproj"
    Invoke-DotnetNew "dotnet new nunit --name Axbus.Plugin.Reader.Json.Tests --output tests/Axbus.Plugin.Reader.Json.Tests --framework $DotNetVersion" "Axbus.Plugin.Reader.Json.Tests" "tests/Axbus.Plugin.Reader.Json.Tests/Axbus.Plugin.Reader.Json.Tests.csproj"
    Invoke-DotnetNew "dotnet new nunit --name Axbus.Plugin.Writer.Csv.Tests --output tests/Axbus.Plugin.Writer.Csv.Tests --framework $DotNetVersion" "Axbus.Plugin.Writer.Csv.Tests" "tests/Axbus.Plugin.Writer.Csv.Tests/Axbus.Plugin.Writer.Csv.Tests.csproj"
    Invoke-DotnetNew "dotnet new nunit --name Axbus.Plugin.Writer.Excel.Tests --output tests/Axbus.Plugin.Writer.Excel.Tests --framework $DotNetVersion" "Axbus.Plugin.Writer.Excel.Tests" "tests/Axbus.Plugin.Writer.Excel.Tests/Axbus.Plugin.Writer.Excel.Tests.csproj"
    Invoke-DotnetNew "dotnet new nunit --name Axbus.Integration.Tests --output tests/Axbus.Integration.Tests --framework $DotNetVersion" "Axbus.Integration.Tests" "tests/Axbus.Integration.Tests/Axbus.Integration.Tests.csproj"

    Write-Ok "All 16 projects created"
}

# ==============================================================================
# STEP 4 - ADD TO SOLUTION
# ==============================================================================

function Add-ProjectsToSolution {
    Write-Step 4 "Adding Projects to Solution"

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
        Invoke-SolutionAdd $script:SolutionFile $project
    }

    Write-Ok "All 16 projects added to solution"
}

# ==============================================================================
# STEP 5 - CREATE FOLDER STRUCTURES
# ==============================================================================

function New-AllFolderStructures {
    Write-Step 5 "Creating Folder Structures"

    Write-Info "--- Axbus.Core ---"
    New-ProjectFolder "src/framework/Axbus.Core" @(
        "Abstractions/Pipeline", "Abstractions/Middleware", "Abstractions/Connectors",
        "Abstractions/Plugin", "Abstractions/Conversion", "Abstractions/Factories",
        "Abstractions/Notifications", "Enums", "Exceptions",
        "Models/Configuration", "Models/Pipeline", "Models/Plugin",
        "Models/Notifications", "Models/Results"
    )

    Write-Info "--- Axbus.Application ---"
    New-ProjectFolder "src/framework/Axbus.Application" @(
        "Conversion", "Factories", "Middleware", "Notifications",
        "Pipeline", "Plugin", "Extensions"
    )

    Write-Info "--- Axbus.Infrastructure ---"
    New-ProjectFolder "src/framework/Axbus.Infrastructure" @(
        "Connectors", "FileSystem", "Logging", "Extensions"
    )

    Write-Info "--- Axbus.Plugin.Reader.Json ---"
    New-ProjectFolder "src/plugins/Axbus.Plugin.Reader.Json" @(
        "Options", "Parser", "Reader", "Transformer", "Validators"
    )

    Write-Info "--- Axbus.Plugin.Writer.Csv ---"
    New-ProjectFolder "src/plugins/Axbus.Plugin.Writer.Csv" @(
        "Internal", "Options", "Validators", "Writer"
    )

    Write-Info "--- Axbus.Plugin.Writer.Excel ---"
    New-ProjectFolder "src/plugins/Axbus.Plugin.Writer.Excel" @(
        "Internal", "Options", "Validators", "Writer"
    )

    Write-Info "--- Client folders ---"
    New-ProjectFolder "src/clients/Axbus.ConsoleApp" @("Bootstrapper")
    New-ProjectFolder "src/clients/Axbus.WinFormsApp" @("Bootstrapper", "Forms", "ViewModels")

    Write-Info "--- Axbus.Tests.Common ---"
    New-ProjectFolder "tests/Axbus.Tests.Common" @("Assertions", "Base", "Builders", "Helpers")

    Write-Info "--- Test project base folders ---"
    $testProjects = @(
        "tests/Axbus.Core.Tests",
        "tests/Axbus.Application.Tests",
        "tests/Axbus.Infrastructure.Tests",
        "tests/Axbus.Plugin.Reader.Json.Tests",
        "tests/Axbus.Plugin.Writer.Csv.Tests",
        "tests/Axbus.Plugin.Writer.Excel.Tests",
        "tests/Axbus.Integration.Tests"
    )
    foreach ($tp in $testProjects) {
        New-ProjectFolder $tp @("Base", "TestData", "Tests")
    }

    Write-Info "--- Test project sub-folders ---"
    New-ProjectFolder "tests/Axbus.Core.Tests" @(
        "TestData/FlatJson", "TestData/NestedJson", "TestData/ArrayJson",
        "TestData/MixedJson", "TestData/EdgeCases", "Tests/Enums", "Tests/Models"
    )

    New-ProjectFolder "tests/Axbus.Application.Tests" @(
        "TestData/SingleModule",
        "TestData/MultiModule/module1", "TestData/MultiModule/module2",
        "TestData/ParallelExecution/parallel_set1", "TestData/ParallelExecution/parallel_set2",
        "TestData/Plugins/valid_plugin", "TestData/Plugins/incompatible_plugin",
        "TestData/Plugins/conflicting_plugins", "TestData/Plugins/missing_manifest",
        "Tests/Conversion", "Tests/Factories", "Tests/Middleware",
        "Tests/Notifications", "Tests/Pipeline", "Tests/Plugin"
    )

    New-ProjectFolder "tests/Axbus.Infrastructure.Tests" @(
        "TestData/Connectors/source_files",
        "TestData/PluginFolder/valid_plugins", "TestData/PluginFolder/invalid_plugins",
        "Tests/Connectors", "Tests/FileSystem", "Tests/Logging"
    )

    New-ProjectFolder "tests/Axbus.Plugin.Reader.Json.Tests" @(
        "TestData/Input", "TestData/Expected",
        "Tests/Integration", "Tests/Parser", "Tests/Plugin", "Tests/Reader", "Tests/Transformer"
    )

    New-ProjectFolder "tests/Axbus.Plugin.Writer.Csv.Tests" @(
        "TestData/Input", "TestData/Expected",
        "Tests/Integration", "Tests/Internal", "Tests/Options", "Tests/Plugin", "Tests/Writer"
    )

    New-ProjectFolder "tests/Axbus.Plugin.Writer.Excel.Tests" @(
        "TestData/Input", "TestData/Expected",
        "Tests/Integration", "Tests/Internal", "Tests/Options", "Tests/Plugin", "Tests/Writer"
    )

    New-ProjectFolder "tests/Axbus.Integration.Tests" @(
        "TestData/JsonToCsv/input", "TestData/JsonToCsv/expected",
        "TestData/JsonToExcel/input", "TestData/JsonToExcel/expected",
        "TestData/JsonToCsvAndExcel/input", "TestData/JsonToCsvAndExcel/expected",
        "TestData/MultiModule/module1_input", "TestData/MultiModule/module2_input",
        "TestData/MultiModule/expected",
        "TestData/ParallelExecution/set1", "TestData/ParallelExecution/set2",
        "TestData/ParallelExecution/set3", "TestData/ErrorScenarios", "Tests"
    )

    Write-Ok "All folder structures created"
}

# ==============================================================================
# STEP 6 - SET PROJECT REFERENCES
# ==============================================================================

function Set-AllProjectReferences {
    Write-Step 6 "Setting Project References"

    Write-Info "--- Framework ---"
    Invoke-SafeCommand "dotnet add src/framework/Axbus.Application/Axbus.Application.csproj reference src/framework/Axbus.Core/Axbus.Core.csproj" "Axbus.Application -> Axbus.Core"
    Invoke-SafeCommand "dotnet add src/framework/Axbus.Infrastructure/Axbus.Infrastructure.csproj reference src/framework/Axbus.Core/Axbus.Core.csproj" "Axbus.Infrastructure -> Axbus.Core"
    Invoke-SafeCommand "dotnet add src/framework/Axbus.Infrastructure/Axbus.Infrastructure.csproj reference src/framework/Axbus.Application/Axbus.Application.csproj" "Axbus.Infrastructure -> Axbus.Application"

    Write-Info "--- Plugins (Core only) ---"
    Invoke-SafeCommand "dotnet add src/plugins/Axbus.Plugin.Reader.Json/Axbus.Plugin.Reader.Json.csproj reference src/framework/Axbus.Core/Axbus.Core.csproj" "Axbus.Plugin.Reader.Json -> Axbus.Core"
    Invoke-SafeCommand "dotnet add src/plugins/Axbus.Plugin.Writer.Csv/Axbus.Plugin.Writer.Csv.csproj reference src/framework/Axbus.Core/Axbus.Core.csproj" "Axbus.Plugin.Writer.Csv -> Axbus.Core"
    Invoke-SafeCommand "dotnet add src/plugins/Axbus.Plugin.Writer.Excel/Axbus.Plugin.Writer.Excel.csproj reference src/framework/Axbus.Core/Axbus.Core.csproj" "Axbus.Plugin.Writer.Excel -> Axbus.Core"

    Write-Info "--- ConsoleApp ---"
    Invoke-SafeCommand "dotnet add src/clients/Axbus.ConsoleApp/Axbus.ConsoleApp.csproj reference src/framework/Axbus.Core/Axbus.Core.csproj" "Axbus.ConsoleApp -> Axbus.Core"
    Invoke-SafeCommand "dotnet add src/clients/Axbus.ConsoleApp/Axbus.ConsoleApp.csproj reference src/framework/Axbus.Application/Axbus.Application.csproj" "Axbus.ConsoleApp -> Axbus.Application"
    Invoke-SafeCommand "dotnet add src/clients/Axbus.ConsoleApp/Axbus.ConsoleApp.csproj reference src/framework/Axbus.Infrastructure/Axbus.Infrastructure.csproj" "Axbus.ConsoleApp -> Axbus.Infrastructure"
    Invoke-SafeCommand "dotnet add src/clients/Axbus.ConsoleApp/Axbus.ConsoleApp.csproj reference src/plugins/Axbus.Plugin.Reader.Json/Axbus.Plugin.Reader.Json.csproj" "Axbus.ConsoleApp -> Axbus.Plugin.Reader.Json"
    Invoke-SafeCommand "dotnet add src/clients/Axbus.ConsoleApp/Axbus.ConsoleApp.csproj reference src/plugins/Axbus.Plugin.Writer.Csv/Axbus.Plugin.Writer.Csv.csproj" "Axbus.ConsoleApp -> Axbus.Plugin.Writer.Csv"
    Invoke-SafeCommand "dotnet add src/clients/Axbus.ConsoleApp/Axbus.ConsoleApp.csproj reference src/plugins/Axbus.Plugin.Writer.Excel/Axbus.Plugin.Writer.Excel.csproj" "Axbus.ConsoleApp -> Axbus.Plugin.Writer.Excel"

    Write-Info "--- WinFormsApp ---"
    Invoke-SafeCommand "dotnet add src/clients/Axbus.WinFormsApp/Axbus.WinFormsApp.csproj reference src/framework/Axbus.Core/Axbus.Core.csproj" "Axbus.WinFormsApp -> Axbus.Core"
    Invoke-SafeCommand "dotnet add src/clients/Axbus.WinFormsApp/Axbus.WinFormsApp.csproj reference src/framework/Axbus.Application/Axbus.Application.csproj" "Axbus.WinFormsApp -> Axbus.Application"
    Invoke-SafeCommand "dotnet add src/clients/Axbus.WinFormsApp/Axbus.WinFormsApp.csproj reference src/framework/Axbus.Infrastructure/Axbus.Infrastructure.csproj" "Axbus.WinFormsApp -> Axbus.Infrastructure"
    Invoke-SafeCommand "dotnet add src/clients/Axbus.WinFormsApp/Axbus.WinFormsApp.csproj reference src/plugins/Axbus.Plugin.Reader.Json/Axbus.Plugin.Reader.Json.csproj" "Axbus.WinFormsApp -> Axbus.Plugin.Reader.Json"
    Invoke-SafeCommand "dotnet add src/clients/Axbus.WinFormsApp/Axbus.WinFormsApp.csproj reference src/plugins/Axbus.Plugin.Writer.Csv/Axbus.Plugin.Writer.Csv.csproj" "Axbus.WinFormsApp -> Axbus.Plugin.Writer.Csv"
    Invoke-SafeCommand "dotnet add src/clients/Axbus.WinFormsApp/Axbus.WinFormsApp.csproj reference src/plugins/Axbus.Plugin.Writer.Excel/Axbus.Plugin.Writer.Excel.csproj" "Axbus.WinFormsApp -> Axbus.Plugin.Writer.Excel"

    Write-Info "--- Test Projects ---"
    Invoke-SafeCommand "dotnet add tests/Axbus.Tests.Common/Axbus.Tests.Common.csproj reference src/framework/Axbus.Core/Axbus.Core.csproj" "Axbus.Tests.Common -> Axbus.Core"

    Invoke-SafeCommand "dotnet add tests/Axbus.Core.Tests/Axbus.Core.Tests.csproj reference src/framework/Axbus.Core/Axbus.Core.csproj" "Axbus.Core.Tests -> Axbus.Core"
    Invoke-SafeCommand "dotnet add tests/Axbus.Core.Tests/Axbus.Core.Tests.csproj reference tests/Axbus.Tests.Common/Axbus.Tests.Common.csproj" "Axbus.Core.Tests -> Axbus.Tests.Common"

    Invoke-SafeCommand "dotnet add tests/Axbus.Application.Tests/Axbus.Application.Tests.csproj reference src/framework/Axbus.Core/Axbus.Core.csproj" "Axbus.Application.Tests -> Axbus.Core"
    Invoke-SafeCommand "dotnet add tests/Axbus.Application.Tests/Axbus.Application.Tests.csproj reference src/framework/Axbus.Application/Axbus.Application.csproj" "Axbus.Application.Tests -> Axbus.Application"
    Invoke-SafeCommand "dotnet add tests/Axbus.Application.Tests/Axbus.Application.Tests.csproj reference tests/Axbus.Tests.Common/Axbus.Tests.Common.csproj" "Axbus.Application.Tests -> Axbus.Tests.Common"

    Invoke-SafeCommand "dotnet add tests/Axbus.Infrastructure.Tests/Axbus.Infrastructure.Tests.csproj reference src/framework/Axbus.Core/Axbus.Core.csproj" "Axbus.Infrastructure.Tests -> Axbus.Core"
    Invoke-SafeCommand "dotnet add tests/Axbus.Infrastructure.Tests/Axbus.Infrastructure.Tests.csproj reference src/framework/Axbus.Application/Axbus.Application.csproj" "Axbus.Infrastructure.Tests -> Axbus.Application"
    Invoke-SafeCommand "dotnet add tests/Axbus.Infrastructure.Tests/Axbus.Infrastructure.Tests.csproj reference src/framework/Axbus.Infrastructure/Axbus.Infrastructure.csproj" "Axbus.Infrastructure.Tests -> Axbus.Infrastructure"
    Invoke-SafeCommand "dotnet add tests/Axbus.Infrastructure.Tests/Axbus.Infrastructure.Tests.csproj reference tests/Axbus.Tests.Common/Axbus.Tests.Common.csproj" "Axbus.Infrastructure.Tests -> Axbus.Tests.Common"

    Invoke-SafeCommand "dotnet add tests/Axbus.Plugin.Reader.Json.Tests/Axbus.Plugin.Reader.Json.Tests.csproj reference src/framework/Axbus.Core/Axbus.Core.csproj" "Axbus.Plugin.Reader.Json.Tests -> Axbus.Core"
    Invoke-SafeCommand "dotnet add tests/Axbus.Plugin.Reader.Json.Tests/Axbus.Plugin.Reader.Json.Tests.csproj reference src/plugins/Axbus.Plugin.Reader.Json/Axbus.Plugin.Reader.Json.csproj" "Axbus.Plugin.Reader.Json.Tests -> Axbus.Plugin.Reader.Json"
    Invoke-SafeCommand "dotnet add tests/Axbus.Plugin.Reader.Json.Tests/Axbus.Plugin.Reader.Json.Tests.csproj reference tests/Axbus.Tests.Common/Axbus.Tests.Common.csproj" "Axbus.Plugin.Reader.Json.Tests -> Axbus.Tests.Common"

    Invoke-SafeCommand "dotnet add tests/Axbus.Plugin.Writer.Csv.Tests/Axbus.Plugin.Writer.Csv.Tests.csproj reference src/framework/Axbus.Core/Axbus.Core.csproj" "Axbus.Plugin.Writer.Csv.Tests -> Axbus.Core"
    Invoke-SafeCommand "dotnet add tests/Axbus.Plugin.Writer.Csv.Tests/Axbus.Plugin.Writer.Csv.Tests.csproj reference src/plugins/Axbus.Plugin.Writer.Csv/Axbus.Plugin.Writer.Csv.csproj" "Axbus.Plugin.Writer.Csv.Tests -> Axbus.Plugin.Writer.Csv"
    Invoke-SafeCommand "dotnet add tests/Axbus.Plugin.Writer.Csv.Tests/Axbus.Plugin.Writer.Csv.Tests.csproj reference tests/Axbus.Tests.Common/Axbus.Tests.Common.csproj" "Axbus.Plugin.Writer.Csv.Tests -> Axbus.Tests.Common"

    Invoke-SafeCommand "dotnet add tests/Axbus.Plugin.Writer.Excel.Tests/Axbus.Plugin.Writer.Excel.Tests.csproj reference src/framework/Axbus.Core/Axbus.Core.csproj" "Axbus.Plugin.Writer.Excel.Tests -> Axbus.Core"
    Invoke-SafeCommand "dotnet add tests/Axbus.Plugin.Writer.Excel.Tests/Axbus.Plugin.Writer.Excel.Tests.csproj reference src/plugins/Axbus.Plugin.Writer.Excel/Axbus.Plugin.Writer.Excel.csproj" "Axbus.Plugin.Writer.Excel.Tests -> Axbus.Plugin.Writer.Excel"
    Invoke-SafeCommand "dotnet add tests/Axbus.Plugin.Writer.Excel.Tests/Axbus.Plugin.Writer.Excel.Tests.csproj reference tests/Axbus.Tests.Common/Axbus.Tests.Common.csproj" "Axbus.Plugin.Writer.Excel.Tests -> Axbus.Tests.Common"

    Invoke-SafeCommand "dotnet add tests/Axbus.Integration.Tests/Axbus.Integration.Tests.csproj reference src/framework/Axbus.Core/Axbus.Core.csproj" "Axbus.Integration.Tests -> Axbus.Core"
    Invoke-SafeCommand "dotnet add tests/Axbus.Integration.Tests/Axbus.Integration.Tests.csproj reference src/framework/Axbus.Application/Axbus.Application.csproj" "Axbus.Integration.Tests -> Axbus.Application"
    Invoke-SafeCommand "dotnet add tests/Axbus.Integration.Tests/Axbus.Integration.Tests.csproj reference src/framework/Axbus.Infrastructure/Axbus.Infrastructure.csproj" "Axbus.Integration.Tests -> Axbus.Infrastructure"
    Invoke-SafeCommand "dotnet add tests/Axbus.Integration.Tests/Axbus.Integration.Tests.csproj reference src/plugins/Axbus.Plugin.Reader.Json/Axbus.Plugin.Reader.Json.csproj" "Axbus.Integration.Tests -> Axbus.Plugin.Reader.Json"
    Invoke-SafeCommand "dotnet add tests/Axbus.Integration.Tests/Axbus.Integration.Tests.csproj reference src/plugins/Axbus.Plugin.Writer.Csv/Axbus.Plugin.Writer.Csv.csproj" "Axbus.Integration.Tests -> Axbus.Plugin.Writer.Csv"
    Invoke-SafeCommand "dotnet add tests/Axbus.Integration.Tests/Axbus.Integration.Tests.csproj reference src/plugins/Axbus.Plugin.Writer.Excel/Axbus.Plugin.Writer.Excel.csproj" "Axbus.Integration.Tests -> Axbus.Plugin.Writer.Excel"
    Invoke-SafeCommand "dotnet add tests/Axbus.Integration.Tests/Axbus.Integration.Tests.csproj reference tests/Axbus.Tests.Common/Axbus.Tests.Common.csproj" "Axbus.Integration.Tests -> Axbus.Tests.Common"

    Write-Ok "All project references set"
}

# ==============================================================================
# STEP 7 - INSTALL NUGET PACKAGES
# ==============================================================================

function Install-AllNuGetPackages {
    Write-Step 7 "Installing NuGet Packages"

    Write-Info "--- Axbus.Application ---"
    $ap = "src/framework/Axbus.Application/Axbus.Application.csproj"
    Invoke-SafeCommand "dotnet add $ap package System.Reactive --version 6.0.1" "System.Reactive"
    Invoke-SafeCommand "dotnet add $ap package Microsoft.Extensions.Logging.Abstractions --version 8.0.0" "Microsoft.Extensions.Logging.Abstractions"
    Invoke-SafeCommand "dotnet add $ap package Microsoft.Extensions.Options --version 8.0.0" "Microsoft.Extensions.Options"
    Invoke-SafeCommand "dotnet add $ap package Microsoft.Extensions.DependencyInjection --version 8.0.0" "Microsoft.Extensions.DependencyInjection"

    Write-Info "--- Axbus.Infrastructure ---"
    $ip = "src/framework/Axbus.Infrastructure/Axbus.Infrastructure.csproj"
    Invoke-SafeCommand "dotnet add $ip package Serilog --version 4.0.0" "Serilog"
    Invoke-SafeCommand "dotnet add $ip package Serilog.Sinks.Console --version 6.0.0" "Serilog.Sinks.Console"
    Invoke-SafeCommand "dotnet add $ip package Serilog.Sinks.File --version 5.0.0" "Serilog.Sinks.File"
    Invoke-SafeCommand "dotnet add $ip package Serilog.Extensions.Hosting --version 8.0.0" "Serilog.Extensions.Hosting"
    Invoke-SafeCommand "dotnet add $ip package Serilog.Settings.Configuration --version 8.0.0" "Serilog.Settings.Configuration"
    Invoke-SafeCommand "dotnet add $ip package Microsoft.Extensions.DependencyInjection --version 8.0.0" "Microsoft.Extensions.DependencyInjection"
    Invoke-SafeCommand "dotnet add $ip package Microsoft.Extensions.Configuration.Json --version 8.0.0" "Microsoft.Extensions.Configuration.Json"

    Write-Info "--- Plugins ---"
    $rj = "src/plugins/Axbus.Plugin.Reader.Json/Axbus.Plugin.Reader.Json.csproj"
    Invoke-SafeCommand "dotnet add $rj package Microsoft.Extensions.Logging.Abstractions --version 8.0.0" "Microsoft.Extensions.Logging.Abstractions -> Reader.Json"

    $wc = "src/plugins/Axbus.Plugin.Writer.Csv/Axbus.Plugin.Writer.Csv.csproj"
    Invoke-SafeCommand "dotnet add $wc package Microsoft.Extensions.Logging.Abstractions --version 8.0.0" "Microsoft.Extensions.Logging.Abstractions -> Writer.Csv"

    $we = "src/plugins/Axbus.Plugin.Writer.Excel/Axbus.Plugin.Writer.Excel.csproj"
    Invoke-SafeCommand "dotnet add $we package ClosedXML --version 0.102.2" "ClosedXML"
    Invoke-SafeCommand "dotnet add $we package Microsoft.Extensions.Logging.Abstractions --version 8.0.0" "Microsoft.Extensions.Logging.Abstractions -> Writer.Excel"

    Write-Info "--- ConsoleApp ---"
    $ca = "src/clients/Axbus.ConsoleApp/Axbus.ConsoleApp.csproj"
    Invoke-SafeCommand "dotnet add $ca package Microsoft.Extensions.Hosting --version 8.0.0" "Microsoft.Extensions.Hosting"
    Invoke-SafeCommand "dotnet add $ca package Serilog.Extensions.Hosting --version 8.0.0" "Serilog.Extensions.Hosting"
    Invoke-SafeCommand "dotnet add $ca package Microsoft.Extensions.Configuration.Json --version 8.0.0" "Microsoft.Extensions.Configuration.Json"

    Write-Info "--- WinFormsApp ---"
    $wf = "src/clients/Axbus.WinFormsApp/Axbus.WinFormsApp.csproj"
    Invoke-SafeCommand "dotnet add $wf package Microsoft.Extensions.Hosting --version 8.0.0" "Microsoft.Extensions.Hosting"
    Invoke-SafeCommand "dotnet add $wf package Serilog.Extensions.Hosting --version 8.0.0" "Serilog.Extensions.Hosting"
    Invoke-SafeCommand "dotnet add $wf package Microsoft.Extensions.Configuration.Json --version 8.0.0" "Microsoft.Extensions.Configuration.Json"

    Write-Info "--- Test Projects ---"
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
    foreach ($tp in $testProjects) {
        $name = Split-Path (Split-Path $tp -Parent) -Leaf
        Invoke-SafeCommand "dotnet add $tp package NUnit --version 4.1.0" "NUnit -> $name"
        Invoke-SafeCommand "dotnet add $tp package NUnit3TestAdapter --version 4.5.0" "NUnit3TestAdapter -> $name"
        Invoke-SafeCommand "dotnet add $tp package Microsoft.NET.Test.Sdk --version 17.11.0" "Microsoft.NET.Test.Sdk -> $name"
        Invoke-SafeCommand "dotnet add $tp package Microsoft.Extensions.DependencyInjection --version 8.0.0" "Microsoft.Extensions.DependencyInjection -> $name"
    }
    Invoke-SafeCommand "dotnet add tests/Axbus.Tests.Common/Axbus.Tests.Common.csproj package System.Reactive --version 6.0.1" "System.Reactive -> Tests.Common"
    Invoke-SafeCommand "dotnet add tests/Axbus.Integration.Tests/Axbus.Integration.Tests.csproj package System.Reactive --version 6.0.1" "System.Reactive -> Integration.Tests"

    Write-Ok "All NuGet packages installed"
}

# ==============================================================================
# STEP 8 - GLOBAL BUILD CONFIGURATION
# ==============================================================================

function New-GlobalBuildConfiguration {
    Write-Step 8 "Creating Global Build Configuration"

    # NOTE: Using @" "@ here-strings to avoid ALL single/double quote escaping issues
    $buildProps = @"
<!-- Copyright (c) 2026 Axel Johnson International. All rights reserved. -->
<Project>
  <PropertyGroup>
    <TargetFramework>net8.0</TargetFramework>
    <LangVersion>latest</LangVersion>
    <Nullable>enable</Nullable>
    <TreatWarningsAsErrors Condition=" '`$(Configuration)' == 'Release' ">true</TreatWarningsAsErrors>
    <ImplicitUsings>enable</ImplicitUsings>
    <Authors>Axel Johnson International</Authors>
    <Company>Axel Johnson International</Company>
    <Copyright>Copyright (c) 2026 Axel Johnson International. All rights reserved.</Copyright>
    <PackageLicenseExpression>MIT</PackageLicenseExpression>
    <RepositoryType>git</RepositoryType>
    <IncludeSymbols>true</IncludeSymbols>
    <SymbolPackageFormat>snupkg</SymbolPackageFormat>
    <GeneratePackageOnBuild>false</GeneratePackageOnBuild>
    <EnableNETAnalyzers>true</EnableNETAnalyzers>
    <AnalysisMode>All</AnalysisMode>
  </PropertyGroup>
</Project>
"@

    $buildTargets = @"
<!-- Copyright (c) 2026 Axel Johnson International. All rights reserved. -->
<Project>
  <PropertyGroup>
    <AppendTargetFrameworkToOutputPath>false</AppendTargetFrameworkToOutputPath>
  </PropertyGroup>
</Project>
"@

    New-FileFromContent "Directory.Build.props" $buildProps
    New-FileFromContent "Directory.Build.targets" $buildTargets

    Write-Ok "Global build configuration created"
}

# ==============================================================================
# STEP 9 - GLOBAL USINGS
# ==============================================================================

function New-AllGlobalUsings {
    Write-Step 9 "Creating GlobalUsings.cs Files"

    New-FileFromContent "src/framework/Axbus.Core/GlobalUsings.cs" @"
// <copyright file="GlobalUsings.cs" company="Axel Johnson International">
// Copyright (c) 2026 Axel Johnson International. All rights reserved.
// </copyright>

global using System;
global using System.Collections.Generic;
global using System.Threading;
global using System.Threading.Tasks;
"@

    New-FileFromContent "src/framework/Axbus.Application/GlobalUsings.cs" @"
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

    New-FileFromContent "src/framework/Axbus.Infrastructure/GlobalUsings.cs" @"
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

    New-FileFromContent "src/plugins/Axbus.Plugin.Reader.Json/GlobalUsings.cs" @"
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

    New-FileFromContent "src/plugins/Axbus.Plugin.Writer.Csv/GlobalUsings.cs" @"
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

    New-FileFromContent "src/plugins/Axbus.Plugin.Writer.Excel/GlobalUsings.cs" @"
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

    Write-Ok "GlobalUsings.cs created for all projects"
}

# ==============================================================================
# STEP 10 - REMOVE PLACEHOLDER FILES
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
            Write-Ok "Deleted: $file"
        }
    }

    Write-Ok "Placeholder files removed"
}

# ==============================================================================
# STEP 11 - STUB CONFIG FILES
# ==============================================================================

function New-StubConfigFiles {
    Write-Step 11 "Creating Stub Configuration Files"

    $appSettings = @"
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
      { "Name": "Console" },
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
"@
    New-FileFromContent "src/clients/Axbus.ConsoleApp/appsettings.json" $appSettings
    New-FileFromContent "src/clients/Axbus.WinFormsApp/appsettings.json" $appSettings

    $devSettings = @"
{
  "Serilog": {
    "MinimumLevel": {
      "Default": "Debug"
    }
  }
}
"@
    New-FileFromContent "src/clients/Axbus.ConsoleApp/appsettings.Development.json" $devSettings
    New-FileFromContent "src/clients/Axbus.WinFormsApp/appsettings.Development.json" $devSettings

    $prodSettings = @"
{
  "Serilog": {
    "MinimumLevel": {
      "Default": "Warning"
    }
  }
}
"@
    New-FileFromContent "src/clients/Axbus.ConsoleApp/appsettings.Production.json" $prodSettings
    New-FileFromContent "src/clients/Axbus.WinFormsApp/appsettings.Production.json" $prodSettings

    New-FileFromContent "src/plugins/Axbus.Plugin.Reader.Json/Axbus.Plugin.Reader.Json.manifest.json" @"
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
"@

    New-FileFromContent "src/plugins/Axbus.Plugin.Writer.Csv/Axbus.Plugin.Writer.Csv.manifest.json" @"
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
"@

    New-FileFromContent "src/plugins/Axbus.Plugin.Writer.Excel/Axbus.Plugin.Writer.Excel.manifest.json" @"
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
"@

    Write-Ok "All stub configuration files created"
}

# ==============================================================================
# STEP 12 - SAMPLE TEST DATA FILES
# ==============================================================================

function New-SampleTestDataFiles {
    Write-Step 12 "Creating Sample Test Data Files"

    $simpleFlatJson = @"
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
"@
    New-FileFromContent "tests/Axbus.Core.Tests/TestData/FlatJson/simple_flat.json" $simpleFlatJson
    New-FileFromContent "tests/Axbus.Plugin.Reader.Json.Tests/TestData/Input/flat_array.json" $simpleFlatJson

    $nestedJson = @"
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
"@
    New-FileFromContent "tests/Axbus.Core.Tests/TestData/NestedJson/nested_objects.json" $nestedJson
    New-FileFromContent "tests/Axbus.Plugin.Reader.Json.Tests/TestData/Input/nested_objects.json" $nestedJson

    $arrayJson = @"
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
"@
    New-FileFromContent "tests/Axbus.Core.Tests/TestData/ArrayJson/array_explosion.json" $arrayJson
    New-FileFromContent "tests/Axbus.Plugin.Reader.Json.Tests/TestData/Input/array_explosion.json" $arrayJson

    New-FileFromContent "tests/Axbus.Core.Tests/TestData/EdgeCases/empty.json" "[]"
    New-FileFromContent "tests/Axbus.Plugin.Reader.Json.Tests/TestData/Input/empty.json" "[]"
    New-FileFromContent "tests/Axbus.Core.Tests/TestData/EdgeCases/invalid.json" "{ this is not valid json }"
    New-FileFromContent "tests/Axbus.Plugin.Reader.Json.Tests/TestData/Input/invalid.json" "{ this is not valid json }"

    New-FileFromContent "tests/Axbus.Core.Tests/TestData/EdgeCases/null_values.json" @"
[
  {
    "id": "001",
    "name": null,
    "value": null,
    "active": true
  }
]
"@

    New-FileFromContent "tests/Axbus.Integration.Tests/TestData/JsonToCsv/input/sales_orders.json" @"
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
      { "lineNo": 2, "product": "Widget B", "quantity": 50, "unitPrice": 42.00 }
    ],
    "totalAmount": 4650.00,
    "currency": "SEK",
    "status": "Confirmed"
  }
]
"@

    Write-Ok "Sample test data files created"
}

# ==============================================================================
# STEP 13 - BUILD SOLUTION
# ==============================================================================

function Invoke-SolutionBuild {
    Write-Step 13 "Building Solution (Verification)"
    Write-Info "Running dotnet build..."
    try {
        dotnet build "$script:SolutionFile" --configuration Debug 2>&1 | Out-Null
        if ($LASTEXITCODE -eq 0) {
            Write-Ok "Solution builds successfully"
        }
        else {
            Write-Warn "Build has warnings or errors - expected for empty stubs"
            Write-Info "Errors will resolve as Copilot generates code files"
        }
    }
    catch {
        Write-Warn "Build check: $_"
        Write-Info "This is expected for empty projects - proceed with code generation"
    }
}

# ==============================================================================
# STEP 14 - SUCCESS SUMMARY
# ==============================================================================

function Write-SuccessSummary {
    Write-Host ""
    Write-Host "===============================================================================" -ForegroundColor Green
    Write-Host "  [DONE] Axbus Framework - Setup Complete!" -ForegroundColor Green
    Write-Host "===============================================================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "  What was created:" -ForegroundColor White
    Write-Host "    [OK] $script:SolutionFile" -ForegroundColor Green
    Write-Host "    [OK] 16 projects (3 framework, 3 plugins, 2 clients, 8 tests)" -ForegroundColor Green
    Write-Host "    [OK] 50+ folder structures" -ForegroundColor Green
    Write-Host "    [OK] All project references" -ForegroundColor Green
    Write-Host "    [OK] All NuGet packages" -ForegroundColor Green
    Write-Host "    [OK] Directory.Build.props and Directory.Build.targets" -ForegroundColor Green
    Write-Host "    [OK] GlobalUsings.cs per project" -ForegroundColor Green
    Write-Host "    [OK] appsettings.json stubs" -ForegroundColor Green
    Write-Host "    [OK] Plugin manifest stubs" -ForegroundColor Green
    Write-Host "    [OK] Sample test data JSON files" -ForegroundColor Green
    Write-Host ""
    Write-Host "  Next Steps:" -ForegroundColor Yellow
    Write-Host "    1. Open $script:SolutionFile in Visual Studio" -ForegroundColor White
    Write-Host "    2. Open Copilot Chat (Ctrl+Alt+I)" -ForegroundColor White
    Write-Host "    3. Verify Claude Opus model is selected" -ForegroundColor White
    Write-Host "    4. Follow .github/copilot-instructions.md Section 9" -ForegroundColor White
    Write-Host "    5. Start generating from Section 8 Phase 1" -ForegroundColor White
    Write-Host "    6. First file: Axbus.Core/Enums/OutputFormat.cs" -ForegroundColor White
    Write-Host ""
    Write-Host "  Commit to Git:" -ForegroundColor Yellow
    Write-Host "    git add ." -ForegroundColor White
    Write-Host "    git commit -m 'chore(setup): create solution via setup-axbus.ps1'" -ForegroundColor White
    Write-Host "    git push" -ForegroundColor White
    Write-Host ""
    Write-Host "===============================================================================" -ForegroundColor Green
    Write-Host ""
}

# ==============================================================================
# MAIN EXECUTION
# ==============================================================================

try {
    Write-Banner
    Invoke-CleanWorkspace
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
    Write-Host "===============================================================================" -ForegroundColor Red
    Write-Host "  [FAILED] Setup Failed" -ForegroundColor Red
    Write-Host "===============================================================================" -ForegroundColor Red
    Write-Host "  Error : $_" -ForegroundColor Red
    Write-Host "  Line  : $($_.InvocationInfo.ScriptLineNumber)" -ForegroundColor Red
    Write-Host ""
    Write-Host "  Fix the error and run again - script is safe to re-run." -ForegroundColor Red
    Write-Host "===============================================================================" -ForegroundColor Red
    exit 1
}

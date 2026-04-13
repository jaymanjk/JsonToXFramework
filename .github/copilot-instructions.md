# Axbus Framework — GitHub Copilot Master Instructions
<!-- Copyright (c) 2026 Axel Johnson International. All rights reserved. -->

> **This file is automatically read by GitHub Copilot for every file in this repository.**
> Every instruction in this document MUST be followed for ALL code generation unless
> explicitly stated otherwise. These instructions represent the authoritative coding
> standards, architecture rules, and generation guidelines for the Axbus framework.

---

## Table of Contents

1. [Framework Overview](#1-framework-overview)
2. [Solution Setup — Visual Studio From Scratch](#2-solution-setup--visual-studio-from-scratch)
3. [Project References](#3-project-references)
4. [NuGet Package References](#4-nuget-package-references)
5. [Global Build Configuration](#5-global-build-configuration)
6. [Code Generation Rules](#6-code-generation-rules)
7. [Architecture Rules](#7-architecture-rules)
8. [File Generation Sequence](#8-file-generation-sequence)
9. [Per-Layer Generation Prompts](#9-per-layer-generation-prompts)
10. [Per-File Generation Prompts](#10-per-file-generation-prompts)
11. [Validation Checklist](#11-validation-checklist)
12. [Common Mistakes To Avoid](#12-common-mistakes-to-avoid)

---

## 1. Framework Overview

### What Is Axbus?

Axbus is an **enterprise-grade, plugin-based, extensible data transformation framework**
built on .NET 8. It provides a generic pipeline architecture that converts any file format
to any other file format via a discoverable, isolated plugin system. The framework itself
never knows about specific file formats — all format knowledge lives in plugins.

### Core Concept
```
Source File(s) → [Reader Plugin] → [Parser Plugin] → [Transformer Plugin] → [Writer Plugin] → Output File(s)
```

### Key Architectural Principles
- **Framework = contracts only** — Core has zero external dependencies
- **Plugins = format knowledge** — All format-specific code lives in plugins
- **Pipeline = typed stage chain** — Each stage takes previous output, returns next typed output
- **Infrastructure = generic I/O** — Infrastructure never knows about file formats
- **Clients = thin wrappers** — ConsoleApp and WinFormsApp wire DI and delegate to framework

### Solution Namespace Root
```
Axbus.*
```

### Target Framework
```xml
<TargetFramework>net8.0</TargetFramework>
```

### Projects In Solution
```
src/framework/
    Axbus.Core                      ← Pure abstractions, models, enums. ZERO dependencies.
    Axbus.Application               ← Pipeline engine, orchestration. Depends on Core only.
    Axbus.Infrastructure            ← Generic I/O, Serilog, connectors. Format-agnostic always.

src/plugins/
    Axbus.Plugin.Reader.Json        ← JSON reader/parser/transformer plugin.
    Axbus.Plugin.Writer.Csv         ← CSV schema builder + writer plugin.
    Axbus.Plugin.Writer.Excel       ← Excel schema builder + writer plugin.

src/clients/
    Axbus.ConsoleApp                ← Console client. DI wiring + demo.
    Axbus.WinFormsApp               ← WinForms client. DI wiring + UI.

tests/
    Axbus.Tests.Common              ← Shared test utilities, builders, assertions.
    Axbus.Core.Tests                ← Tests for Core models and abstractions.
    Axbus.Application.Tests         ← Tests for pipeline and orchestration.
    Axbus.Infrastructure.Tests      ← Tests for connectors and file system.
    Axbus.Plugin.Reader.Json.Tests  ← Tests for JSON reader plugin.
    Axbus.Plugin.Writer.Csv.Tests   ← Tests for CSV writer plugin.
    Axbus.Plugin.Writer.Excel.Tests ← Tests for Excel writer plugin.
    Axbus.Integration.Tests         ← Full end-to-end cross-plugin tests.
```

---

## 2. Solution Setup — Visual Studio From Scratch

Follow these steps **in exact order** before generating any code.

### Step 1 — Create Blank Solution
```
Visual Studio → File → New → Project
→ Search: "Blank Solution"
→ Solution name: Axbus
→ Location: [your preferred path]
→ Click Create
```

### Step 2 — Create Solution Folders
```
Right-click Solution 'Axbus' → Add → New Solution Folder

Create these folders in order:
├── src
│   ├── framework
│   ├── plugins
│   └── clients
├── tests
├── build
└── docs
```

### Step 3 — Create Framework Projects
```
Right-click 'framework' folder → Add → New Project

Project 1:
  Template : Class Library
  Name     : Axbus.Core
  Location : src/framework/Axbus.Core
  Framework: .NET 8.0

Project 2:
  Template : Class Library
  Name     : Axbus.Application
  Location : src/framework/Axbus.Application
  Framework: .NET 8.0

Project 3:
  Template : Class Library
  Name     : Axbus.Infrastructure
  Location : src/framework/Axbus.Infrastructure
  Framework: .NET 8.0
```

### Step 4 — Create Plugin Projects
```
Right-click 'plugins' folder → Add → New Project

Project 4:
  Template : Class Library
  Name     : Axbus.Plugin.Reader.Json
  Location : src/plugins/Axbus.Plugin.Reader.Json
  Framework: .NET 8.0

Project 5:
  Template : Class Library
  Name     : Axbus.Plugin.Writer.Csv
  Location : src/plugins/Axbus.Plugin.Writer.Csv
  Framework: .NET 8.0

Project 6:
  Template : Class Library
  Name     : Axbus.Plugin.Writer.Excel
  Location : src/plugins/Axbus.Plugin.Writer.Excel
  Framework: .NET 8.0
```

### Step 5 — Create Client Projects
```
Right-click 'clients' folder → Add → New Project

Project 7:
  Template : Console App
  Name     : Axbus.ConsoleApp
  Location : src/clients/Axbus.ConsoleApp
  Framework: .NET 8.0

Project 8:
  Template : Windows Forms App
  Name     : Axbus.WinFormsApp
  Location : src/clients/Axbus.WinFormsApp
  Framework: .NET 8.0
```

### Step 6 — Create Test Projects
```
Right-click 'tests' folder → Add → New Project
Template for ALL test projects: NUnit Test Project

Project 9  : Axbus.Tests.Common              (Class Library — NOT NUnit, shared utilities)
Project 10 : Axbus.Core.Tests
Project 11 : Axbus.Application.Tests
Project 12 : Axbus.Infrastructure.Tests
Project 13 : Axbus.Plugin.Reader.Json.Tests
Project 14 : Axbus.Plugin.Writer.Csv.Tests
Project 15 : Axbus.Plugin.Writer.Excel.Tests
Project 16 : Axbus.Integration.Tests
```

### Step 7 — Delete Auto-Generated Files
```
Delete from every project:
- Class1.cs
- UnitTest1.cs (in test projects)
Keep:
- Nothing — start clean
```

### Step 8 — Create Folder Structure Per Project
```
After creating projects, create these folders inside each project in Solution Explorer:

Axbus.Core/
  Abstractions/Pipeline/
  Abstractions/Middleware/
  Abstractions/Connectors/
  Abstractions/Plugin/
  Abstractions/Conversion/
  Abstractions/Factories/
  Abstractions/Notifications/
  Models/Configuration/
  Models/Pipeline/
  Models/Plugin/
  Models/Notifications/
  Models/Results/
  Enums/

Axbus.Application/
  Pipeline/
  Middleware/
  Conversion/
  Plugin/
  Factories/
  Notifications/
  Extensions/

Axbus.Infrastructure/
  Connectors/
  FileSystem/
  Logging/
  Extensions/

Axbus.Plugin.Reader.Json/
  Reader/
  Parser/
  Transformer/
  Options/
  Validators/

Axbus.Plugin.Writer.Csv/
  Internal/
  Writer/
  Options/
  Validators/

Axbus.Plugin.Writer.Excel/
  Internal/
  Writer/
  Options/
  Validators/

Axbus.ConsoleApp/
  Bootstrapper/

Axbus.WinFormsApp/
  Bootstrapper/
  Forms/
  ViewModels/

Axbus.Tests.Common/
  Base/
  Builders/
  Assertions/
  Helpers/

Each test project (Axbus.*.Tests)/
  TestData/     ← real JSON files go here
  Base/
  Tests/        ← test classes go here
```

---

## 3. Project References

Set these references **exactly** in Visual Studio:
```
Right-click Project → Add → Project Reference

Axbus.Application
  → Axbus.Core

Axbus.Infrastructure
  → Axbus.Core
  → Axbus.Application

Axbus.Plugin.Reader.Json
  → Axbus.Core  (ONLY — never Application or Infrastructure)

Axbus.Plugin.Writer.Csv
  → Axbus.Core  (ONLY — never Application or Infrastructure)

Axbus.Plugin.Writer.Excel
  → Axbus.Core  (ONLY — never Application or Infrastructure)

Axbus.ConsoleApp
  → Axbus.Core
  → Axbus.Application
  → Axbus.Infrastructure
  → Axbus.Plugin.Reader.Json
  → Axbus.Plugin.Writer.Csv
  → Axbus.Plugin.Writer.Excel

Axbus.WinFormsApp
  → Axbus.Core
  → Axbus.Application
  → Axbus.Infrastructure
  → Axbus.Plugin.Reader.Json
  → Axbus.Plugin.Writer.Csv
  → Axbus.Plugin.Writer.Excel

Axbus.Tests.Common
  → Axbus.Core

Axbus.Core.Tests
  → Axbus.Core
  → Axbus.Tests.Common

Axbus.Application.Tests
  → Axbus.Core
  → Axbus.Application
  → Axbus.Tests.Common

Axbus.Infrastructure.Tests
  → Axbus.Core
  → Axbus.Application
  → Axbus.Infrastructure
  → Axbus.Tests.Common

Axbus.Plugin.Reader.Json.Tests
  → Axbus.Core
  → Axbus.Plugin.Reader.Json
  → Axbus.Tests.Common

Axbus.Plugin.Writer.Csv.Tests
  → Axbus.Core
  → Axbus.Plugin.Writer.Csv
  → Axbus.Tests.Common

Axbus.Plugin.Writer.Excel.Tests
  → Axbus.Core
  → Axbus.Plugin.Writer.Excel
  → Axbus.Tests.Common

Axbus.Integration.Tests
  → Axbus.Core
  → Axbus.Application
  → Axbus.Infrastructure
  → Axbus.Plugin.Reader.Json
  → Axbus.Plugin.Writer.Csv
  → Axbus.Plugin.Writer.Excel
  → Axbus.Tests.Common
```

---

## 4. NuGet Package References

Install via NuGet Package Manager or Package Manager Console.
**All packages are MIT or Apache 2.0 licensed — zero commercial licensing costs.**

### Axbus.Core
```
NO NuGet packages — zero external dependencies by design
```

### Axbus.Application
```
Install-Package System.Reactive                              --version 6.0.1
Install-Package Microsoft.Extensions.Logging.Abstractions   --version 8.0.0
Install-Package Microsoft.Extensions.Options                 --version 8.0.0
Install-Package Microsoft.Extensions.DependencyInjection    --version 8.0.0
```

### Axbus.Infrastructure
```
Install-Package Serilog                                      --version 4.0.0
Install-Package Serilog.Sinks.Console                        --version 6.0.0
Install-Package Serilog.Sinks.File                           --version 5.0.0
Install-Package Serilog.Extensions.Hosting                   --version 8.0.0
Install-Package Serilog.Settings.Configuration               --version 8.0.0
Install-Package Microsoft.Extensions.DependencyInjection     --version 8.0.0
Install-Package Microsoft.Extensions.Configuration.Json      --version 8.0.0
```

### Axbus.Plugin.Reader.Json
```
Install-Package Microsoft.Extensions.Logging.Abstractions   --version 8.0.0
(System.Text.Json is built into .NET 8 — no separate package needed)
```

### Axbus.Plugin.Writer.Csv
```
Install-Package Microsoft.Extensions.Logging.Abstractions   --version 8.0.0
```

### Axbus.Plugin.Writer.Excel
```
Install-Package ClosedXML                                    --version 0.102.2
Install-Package Microsoft.Extensions.Logging.Abstractions   --version 8.0.0
```

### Axbus.ConsoleApp
```
Install-Package Microsoft.Extensions.Hosting                 --version 8.0.0
Install-Package Serilog.Extensions.Hosting                   --version 8.0.0
Install-Package Microsoft.Extensions.Configuration.Json      --version 8.0.0
```

### Axbus.WinFormsApp
```
Install-Package Microsoft.Extensions.Hosting                 --version 8.0.0
Install-Package Serilog.Extensions.Hosting                   --version 8.0.0
Install-Package Microsoft.Extensions.Configuration.Json      --version 8.0.0
```

### All Test Projects
```
Install-Package NUnit                                        --version 4.1.0
Install-Package NUnit3TestAdapter                            --version 4.5.0
Install-Package Microsoft.NET.Test.Sdk                       --version 17.11.0
Install-Package System.Reactive                              --version 6.0.1
Install-Package Microsoft.Extensions.DependencyInjection     --version 8.0.0
```

---

## 5. Global Build Configuration

### Create `build/Directory.Build.props`
```xml
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
```

### Create `build/Directory.Build.targets`
```xml
<Project>
  <PropertyGroup>
    <!-- Enforce consistent output paths -->
    <AppendTargetFrameworkToOutputPath>false</AppendTargetFrameworkToOutputPath>
  </PropertyGroup>
</Project>
```

### Create Global Usings Per Project

**Axbus.Core** — `GlobalUsings.cs`
```csharp
global using System;
global using System.Collections.Generic;
global using System.Threading;
global using System.Threading.Tasks;
```

**Axbus.Application** — `GlobalUsings.cs`
```csharp
global using System;
global using System.Collections.Generic;
global using System.Linq;
global using System.Threading;
global using System.Threading.Tasks;
global using Axbus.Core.Abstractions.Conversion;
global using Axbus.Core.Abstractions.Pipeline;
global using Axbus.Core.Models.Configuration;
global using Axbus.Core.Models.Results;
global using Microsoft.Extensions.Logging;
```

**Axbus.Infrastructure** — `GlobalUsings.cs`
```csharp
global using System;
global using System.Collections.Generic;
global using System.IO;
global using System.Threading;
global using System.Threading.Tasks;
global using Microsoft.Extensions.Logging;
global using Serilog;
```

---

## 6. Code Generation Rules

> These rules apply to ALL `.cs` files generated in this solution.
> **Exceptions are explicitly stated per rule.**
> Rules do NOT apply to: `.csproj`, `.xml`, `AssemblyInfo.cs`, `.json`, `.yml`, `.yaml`,
> `Directory.Build.props`, `Directory.Build.targets`.

---

### RULE 1 — XML Documentation Comments

**Applies to:** All `.cs` files EXCEPT test projects (test projects: XML comments on
class/method/property/namespace only, no inline comments required).

Every **class**, **interface**, **enum**, **property**, **method**, and **namespace**
MUST have full XML documentation using `///` triple-slash comments.

**Format:**
```csharp
/// <summary>
/// [One sentence describing what this does, not how.]
/// </summary>
/// <remarks>
/// [Optional: Additional context, usage notes, or important behaviour.]
/// </remarks>
/// <param name="paramName">[What this parameter represents and valid values.]</param>
/// <returns>
/// [What is returned and under what conditions.]
/// </returns>
/// <exception cref="ExceptionType">
/// [When this exception is thrown.]
/// </exception>
```

**Local variables and function logic use inline `//` comments:**
```csharp
public async Task<ModuleResult> RunAsync(CancellationToken cancellationToken)
{
    // Retrieve only enabled modules sorted by execution order
    var enabledModules = modules.Where(m => m.IsEnabled).OrderBy(m => m.ExecutionOrder);

    // Track cumulative rows written across all modules
    var totalRowsWritten = 0;

    // Execute each module and accumulate results
    foreach (var module in enabledModules)
    {
        var result = await ExecuteModuleAsync(module, cancellationToken);
        totalRowsWritten += result.RowsWritten;
    }

    return new ModuleResult { RowsWritten = totalRowsWritten };
}
```

**Anti-patterns — NEVER do these:**
```csharp
// WRONG — no XML docs
public class ConversionRunner { }

// WRONG — incomplete XML docs
/// <summary></summary>
public void Run() { }

// WRONG — XML on local variable (compiler ignores it)
/// <summary>The result</summary>
var result = await RunAsync();
```

---

### RULE 2 — Exception and Logging Best Practices

**Applies to:** All `.cs` files EXCEPT test projects.

#### 2a — Logging Standards

Always use **structured logging** with named placeholders. Never use string interpolation
or string concatenation in log messages.

```csharp
// CORRECT — structured logging
logger.LogInformation(
    "Pipeline started for module {ModuleName} with {FileCount} files",
    module.ConversionName,
    fileCount);

logger.LogError(
    ex,
    "Pipeline failed for module {ModuleName} at stage {Stage}",
    module.ConversionName,
    stage);

// WRONG — string interpolation (not searchable, allocates memory)
logger.LogError($"Pipeline failed for {module.ConversionName}");

// WRONG — exception not passed to LogError
logger.LogError("Error: " + ex.Message);
```

**Log level guidelines:**
```
LogTrace       → Extremely detailed, loop iterations, hot paths
LogDebug       → Diagnostic info useful during development
LogInformation → Normal operational events (start, complete, skip)
LogWarning     → Unexpected but recoverable (depth truncated, file skipped)
LogError       → Failures that affect output but execution continues
LogCritical    → Unrecoverable failures that stop the application
```

#### 2b — Exception Handling Standards

```csharp
/// <summary>Executes the conversion pipeline for a single module.</summary>
public async Task<ModuleResult> ExecuteAsync(
    ConversionModule module,
    CancellationToken cancellationToken)
{
    // Validate inputs before processing
    ArgumentNullException.ThrowIfNull(module);

    try
    {
        logger.LogInformation(
            "Starting conversion for module {ModuleName}",
            module.ConversionName);

        var result = await pipeline.ExecuteAsync(module, cancellationToken)
            .ConfigureAwait(false);

        logger.LogInformation(
            "Completed conversion for module {ModuleName}. Rows: {RowsWritten}",
            module.ConversionName,
            result.RowsWritten);

        return result;
    }
    catch (OperationCanceledException ex)
    {
        // Always handle cancellation separately and re-throw
        logger.LogWarning(
            ex,
            "Conversion cancelled for module {ModuleName}",
            module.ConversionName);
        throw;
    }
    catch (AxbusPipelineException ex)
    {
        // Domain exceptions: log and re-throw without wrapping
        logger.LogError(
            ex,
            "Pipeline error in module {ModuleName} at stage {Stage}",
            module.ConversionName,
            ex.Stage);
        throw;
    }
    catch (Exception ex)
    {
        // Unexpected exceptions: log, wrap in domain exception, re-throw
        logger.LogError(
            ex,
            "Unexpected error in {MethodName} for module {ModuleName}",
            nameof(ExecuteAsync),
            module.ConversionName);
        throw new AxbusPipelineException(
            $"Unexpected failure executing module '{module.ConversionName}'",
            ex);
    }
}
```

**Exception rules:**
- NEVER swallow exceptions with empty catch blocks
- ALWAYS pass exception object to `LogError` as first argument
- ALWAYS handle `OperationCanceledException` separately before generic `Exception`
- ALWAYS use `ArgumentNullException.ThrowIfNull()` for null guard checks
- NEVER use `throw ex` — always use `throw` to preserve stack trace
- Use custom domain exceptions (`AxbusPipelineException`, `AxbusPluginException`) for
  domain failures

---

### RULE 3 — Database Operations (CONDITIONAL — DORMANT FOR AXBUS)

> **This rule is DORMANT for the Axbus framework.**
> Axbus has no database operations. Rule 3 activates ONLY when a solution built on
> top of Axbus requires database connectivity (e.g. Azure Functions using Axbus).
> Do NOT apply Rule 3 to any file in the Axbus solution.

When activated in a DB-connected solution, Rule 3 covers:
- Model classes (with `[JsonPropertyName]`) in `*.Models` project
- Entity classes (with `[Table]` and `[Column]`) in `*.Entities` project
- Mapster for Model ↔ Entity mapping
- Entity Framework Core best practices
- Separate `*.Models` and `*.Entities` NuGet packages for Azure Function reuse

---

### RULE 4 — .NET Naming and Coding Standards

**Applies to:** All `.cs` files.

#### Naming Conventions
```
Classes           → PascalCase          → ConversionRunner, PluginRegistry
Interfaces        → I + PascalCase      → IConversionRunner, IPluginRegistry
Abstract classes  → PascalCase          → PipelineStageBase
Enums             → PascalCase          → ConversionStatus, OutputFormat
Enum values       → PascalCase          → ConversionStatus.Completed
Methods           → PascalCase          → ExecuteAsync, BuildSchema
Async methods     → PascalCase + Async  → RunAsync, LoadPluginAsync
Properties        → PascalCase          → ModuleName, IsEnabled
Private fields    → camelCase (NO _)    → logger, conversionRunner
Local variables   → camelCase           → moduleCount, pipelineResult
Parameters        → camelCase           → cancellationToken, pluginOptions
Constants         → PascalCase          → DefaultExplosionDepth, MaxRetryCount
Namespaces        → Pascal.Dot.Notation → Axbus.Core.Abstractions.Pipeline
```

#### Code Style Standards
```csharp
// Primary constructors — USE for simple injection
public class ConversionRunner(
    IConversionPipeline pipeline,
    ILogger<ConversionRunner> logger)
{
    // Assign to fields with this. to avoid name collision (no underscore)
    private readonly IConversionPipeline pipeline = pipeline;
    private readonly ILogger<ConversionRunner> logger = logger;
}

// File-scoped namespaces — ALWAYS USE
namespace Axbus.Application.Conversion;  // ← semicolon, not braces

// Records for immutable data — USE for pipeline stage outputs
public record SourceData(Stream RawData, string SourcePath, string Format);

// var for local variables — ALWAYS USE for locals
var result = await pipeline.ExecuteAsync(cancellationToken);

// Explicit types for fields and properties — ALWAYS
private readonly ILogger<ConversionRunner> logger;
public ConversionStatus Status { get; private set; }

// Pattern matching — USE modern C# syntax
var message = status switch
{
    ConversionStatus.Completed => "Conversion completed successfully",
    ConversionStatus.Failed    => "Conversion failed",
    ConversionStatus.Skipped   => "Conversion skipped",
    _                          => "Unknown status"
};

// Braces — ALWAYS use braces even for single-line if
if (module.IsEnabled)
{
    await ExecuteAsync(module, cancellationToken);
}

// Guard clauses — ALWAYS at top of method
public async Task<ModuleResult> RunAsync(
    ConversionModule module,
    CancellationToken cancellationToken)
{
    ArgumentNullException.ThrowIfNull(module);
    ArgumentException.ThrowIfNullOrWhiteSpace(module.ConversionName);

    // ... rest of method
}
```

---

### RULE 5 — Clean Code Architecture

**Applies to:** All `.cs` files.

#### Layer Dependency Rules — NEVER VIOLATE
```
Axbus.Core           → ZERO external dependencies. No NuGet. No project references.
Axbus.Application    → Depends on Axbus.Core ONLY.
Axbus.Infrastructure → Depends on Axbus.Core + Axbus.Application.
Axbus.Plugin.*       → Depends on Axbus.Core ONLY. Never Application or Infrastructure.
Axbus.ConsoleApp     → May depend on all layers.
Axbus.WinFormsApp    → May depend on all layers.
```

#### What Belongs Where
```
Axbus.Core
  ✅ Interfaces (IPlugin, ISourceReader, IOutputWriter etc)
  ✅ Immutable record models (SourceData, ParsedData, WriteResult)
  ✅ Configuration models (ConversionModule, SourceOptions)
  ✅ Enums (OutputFormat, ConversionStatus)
  ✅ Custom exceptions (AxbusPipelineException, AxbusPluginException)
  ❌ NEVER implementations
  ❌ NEVER NuGet package references
  ❌ NEVER file I/O, logging, or framework-specific code

Axbus.Application
  ✅ Pipeline orchestration (ConversionPipeline, ConversionRunner)
  ✅ Middleware implementations (LoggingMiddleware, RetryMiddleware)
  ✅ Plugin loading and registry (PluginLoader, PluginRegistry)
  ✅ Factories (PipelineFactory, MiddlewareFactory)
  ✅ DI extensions (ApplicationServiceExtensions)
  ❌ NEVER file system access
  ❌ NEVER format-specific code
  ❌ NEVER direct Serilog references (use ILogger abstraction)

Axbus.Infrastructure
  ✅ Connectors (LocalFileSourceConnector, LocalFileTargetConnector)
  ✅ File system utilities (FileSystemScanner, PluginFolderScanner)
  ✅ Serilog configuration (SerilogConfiguration)
  ✅ DI extensions (InfrastructureServiceExtensions)
  ❌ NEVER format-specific code (no JSON, CSV, Excel knowledge)
  ❌ NEVER business logic

Axbus.Plugin.*
  ✅ Format-specific reading, parsing, transforming, writing
  ✅ Plugin options (JsonReaderPluginOptions, CsvWriterPluginOptions)
  ✅ Options validators
  ❌ NEVER reference Application or Infrastructure
  ❌ NEVER self-register into host DI container
```

---

### RULE 6 — SOLID Principles

**Applies to:** All `.cs` files EXCEPT test projects.

Before completing any class, verify it satisfies all five principles:

#### S — Single Responsibility
```
Each class has ONE reason to change.

✅ ConversionRunner → only runs conversion modules
✅ PluginLoader     → only loads plugin assemblies
✅ CsvOutputWriter  → only writes CSV output

❌ WRONG: ConversionRunner that also logs AND reads files AND writes output
```

#### O — Open/Closed
```
Open for extension, closed for modification.

✅ New output format = new plugin class, zero changes to framework
✅ New middleware = new class implementing IPipelineMiddleware
✅ New connector = new class implementing ISourceConnector

❌ WRONG: Adding if/switch in ConversionPipeline for each new format
```

#### L — Liskov Substitution
```
All implementations must be fully substitutable for their interface.

✅ Any IPlugin implementation works in PluginRegistry
✅ Any IOutputWriter implementation works in PipelineFactory
✅ Any ISourceConnector works in ConnectorFactory

❌ WRONG: CsvOutputWriter that throws NotImplementedException on WriteAsync
```

#### I — Interface Segregation
```
Interfaces are focused and minimal.

✅ IOutputWriter → only WriteAsync
✅ ISchemaAwareWriter → extends IOutputWriter, adds BuildSchemaAsync
✅ ISourceReader → only ReadAsync

❌ WRONG: One giant IPlugin interface with 20 methods when most return null
```

#### D — Dependency Inversion
```
Depend on abstractions, never concretions.

✅ ConversionRunner depends on IConversionPipeline (not ConversionPipeline)
✅ PipelineFactory depends on IPluginRegistry (not PluginRegistry)
✅ All dependencies injected via constructor

❌ WRONG: new ConversionPipeline() inside ConversionRunner
❌ WRONG: static class dependencies
❌ WRONG: ServiceLocator pattern
```

---

### RULE 7 — Optimization Techniques

**Applies to:** All `.cs` files EXCEPT test projects.

```csharp
// 1. IAsyncEnumerable for streaming — ALWAYS for large data
public async IAsyncEnumerable<FlattenedRow> TransformAsync(
    ParsedData data,
    [EnumeratorCancellation] CancellationToken cancellationToken)
{
    await foreach (var element in data.Elements.WithCancellation(cancellationToken))
    {
        yield return FlattenElement(element);
    }
}

// 2. ConfigureAwait(false) in ALL library code (not in clients)
var result = await pipeline.ExecuteAsync(cancellationToken).ConfigureAwait(false);

// 3. CancellationToken in every async method
public async Task<WriteResult> WriteAsync(
    TransformedData data,
    TargetOptions options,
    CancellationToken cancellationToken = default)

// 4. SemaphoreSlim for throttling parallel operations
var semaphore = new SemaphoreSlim(maxDegreeOfParallelism); // Controls parallel execution count
await semaphore.WaitAsync(cancellationToken).ConfigureAwait(false);
try { await ExecuteAsync(module, cancellationToken); }
finally { semaphore.Release(); }

// 5. StringBuilder for string building in loops
var builder = new StringBuilder(capacity: 256); // Pre-allocated for expected CSV row size
foreach (var column in schema.Columns)
{
    builder.Append(EscapeCsvValue(row[column]));
    builder.Append(delimiter);
}

// 6. Span<T> for buffer operations where applicable
ReadOnlySpan<char> valueSpan = value.AsSpan().Trim();

// 7. Avoid LINQ in hot paths — use for-loops for performance-critical code
// ACCEPTABLE in setup/config code
var enabled = modules.Where(m => m.IsEnabled).OrderBy(m => m.ExecutionOrder);

// PREFER in hot path (inside pipeline loop processing millions of rows)
for (var i = 0; i < columns.Count; i++)
{
    // direct index access — no LINQ overhead
}

// 8. string.Empty over "" for empty string constants
public string NullPlaceholder { get; set; } = string.Empty;

// 9. Utf8JsonReader for streaming JSON — NEVER JsonDocument for large files
var reader = new Utf8JsonReader(buffer.Span);
while (reader.Read()) { /* process token */ }
```

---

### RULE 8 — Try/Catch and Production Logging

**Applies to:** All `.cs` files EXCEPT test projects.

**Wrap all I/O operations, plugin operations, and pipeline stages in try/catch.**

```csharp
// File I/O operations
try
{
    await using var stream = File.OpenRead(filePath); // Open file for reading
    var data = await reader.ReadAsync(stream, options, cancellationToken)
        .ConfigureAwait(false);
    return data;
}
catch (FileNotFoundException ex)
{
    logger.LogError(
        ex,
        "Source file not found: {FilePath}",
        filePath);
    throw new AxbusConnectorException($"Source file not found: {filePath}", ex);
}
catch (UnauthorizedAccessException ex)
{
    logger.LogError(
        ex,
        "Access denied reading file: {FilePath}",
        filePath);
    throw new AxbusConnectorException($"Access denied: {filePath}", ex);
}
catch (IOException ex)
{
    logger.LogError(
        ex,
        "I/O error reading file: {FilePath}",
        filePath);
    throw new AxbusConnectorException($"I/O failure reading: {filePath}", ex);
}

// Plugin operations
try
{
    await plugin.InitializeAsync(context, cancellationToken).ConfigureAwait(false);
    logger.LogDebug(
        "Plugin {PluginId} initialized successfully",
        plugin.PluginId);
}
catch (Exception ex) when (ex is not OperationCanceledException)
{
    logger.LogError(
        ex,
        "Failed to initialize plugin {PluginId}",
        plugin.PluginId);
    throw new AxbusPluginException($"Plugin '{plugin.PluginId}' failed to initialize", ex);
}
```

---

### RULE 9 — StyleCop Copyright Header

**Applies to:** ALL `.cs` files EXCEPT test projects and generated files.

Every `.cs` file MUST start with this exact copyright header:

```csharp
// <copyright file="{FILENAME}.cs" company="Axel Johnson International">
// Copyright (c) 2026 Axel Johnson International. All rights reserved.
// </copyright>
```

Replace `{FILENAME}` with the actual file name without path.

**Example for `ConversionRunner.cs`:**
```csharp
// <copyright file="ConversionRunner.cs" company="Axel Johnson International">
// Copyright (c) 2026 Axel Johnson International. All rights reserved.
// </copyright>

namespace Axbus.Application.Conversion;

using System;
using System.Threading;
```

---

### RULE 10 — Using Statements Below Namespace

**Applies to:** All `.cs` files.

Using statements MUST appear **after** the namespace declaration, never before.

```csharp
// <copyright file="ConversionPipeline.cs" company="Axel Johnson International">
// Copyright (c) 2026 Axel Johnson International. All rights reserved.
// </copyright>

namespace Axbus.Application.Pipeline;

// System namespaces first (alphabetical)
using System;
using System.Collections.Generic;
using System.Runtime.CompilerServices;
using System.Threading;
using System.Threading.Tasks;

// Microsoft namespaces second (alphabetical)
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;

// Third-party namespaces third (alphabetical)
using System.Reactive.Subjects;

// Internal Axbus namespaces last (alphabetical)
using Axbus.Core.Abstractions.Conversion;
using Axbus.Core.Abstractions.Pipeline;
using Axbus.Core.Models.Configuration;
using Axbus.Core.Models.Pipeline;
using Axbus.Core.Models.Results;
```

**NEVER do this:**
```csharp
// WRONG — using before namespace
using System;
using Axbus.Core.Abstractions;

namespace Axbus.Application.Pipeline;
```

---

### RULE 11 — No Underscore Prefix on Fields

**Applies to:** All `.cs` files EXCEPT test projects.

Private fields use `camelCase` with NO underscore prefix.
Use `this.` to disambiguate field from parameter in constructors.

```csharp
// CORRECT
public class ConversionRunner
{
    /// <summary>Logger instance for structured diagnostic output.</summary>
    private readonly ILogger<ConversionRunner> logger;

    /// <summary>Pipeline instance for executing conversion stages.</summary>
    private readonly IConversionPipeline pipeline;

    /// <summary>Initializes a new instance of <see cref="ConversionRunner"/>.</summary>
    public ConversionRunner(
        IConversionPipeline pipeline,
        ILogger<ConversionRunner> logger)
    {
        this.pipeline = pipeline; // Disambiguate from parameter using this.
        this.logger = logger;     // Disambiguate from parameter using this.
    }
}

// WRONG — underscore prefix
private readonly ILogger<ConversionRunner> _logger;
private readonly IConversionPipeline _pipeline;
```

---

### RULE 12 — Excluded Files

**Rules DO NOT apply to:**
- `*.csproj` files
- `*.xml` files
- `AssemblyInfo.cs`
- `*.json` config files
- `*.yml` / `*.yaml` files
- `Directory.Build.props`
- `Directory.Build.targets`
- `GlobalUsings.cs` (just using statements, no docs needed)
- Auto-generated files (`*.g.cs`, `*.Designer.cs` for WinForms)

---

### RULE 13 — Test Projects

**Test projects follow SIMPLIFIED rules ONLY:**

```
✅ APPLY  Rule 1  — XML comments on class, property, method, namespace
✅ APPLY  BDD naming convention (see below)
❌ SKIP   Rule 2  — Exception handling (tests can use Assert.Throws)
❌ SKIP   Rule 4  — Strict naming (underscore in fields is acceptable in tests)
❌ SKIP   Rule 8  — Try/Catch (NUnit handles exceptions)
❌ SKIP   Rule 9  — Copyright header
❌ SKIP   Rule 11 — No underscore (relaxed in tests)
```

**BDD Test Naming Convention:**
```csharp
/// <summary>Tests for the JSON data transformer flattening behaviour.</summary>
[TestFixture]
public class JsonDataTransformerTests
{
    /// <summary>
    /// Verifies that nested objects are flattened using dot notation
    /// when the input JSON contains two levels of nesting.
    /// </summary>
    [Test]
    public async Task Should_FlattenWithDotNotation_When_JsonHasTwoLevelNesting()

    /// <summary>
    /// Verifies that arrays are exploded into multiple rows
    /// when the array depth is within the configured maximum.
    /// </summary>
    [Test]
    public async Task Should_ExplodeArrayIntoRows_When_DepthIsWithinMaxLimit()

    /// <summary>
    /// Verifies that arrays beyond the maximum depth are serialised as
    /// a JSON string rather than being exploded into rows.
    /// </summary>
    [Test]
    public async Task Should_SerialiseAsJsonString_When_ArrayDepthExceedsMaxExplosionDepth()
}
```

**Test Structure — AAA Pattern:**
```csharp
[Test]
public async Task Should_ReturnRowsWritten_When_PipelineCompletesSuccessfully()
{
    // Arrange
    var inputFile = testDataLoader.GetPath("FlatJson/simple_flat.json"); // Path to test input
    var outputPath = tempFolder.GetOutputPath("result.csv");             // Temp output path
    var module = new ConversionModuleBuilder()
        .WithName("TestModule")
        .WithSourcePath(inputFile)
        .WithTargetPath(outputPath)
        .Build();

    // Act
    var result = await conversionRunner.RunAsync(module, CancellationToken.None);

    // Assert
    Assert.That(result.RowsWritten, Is.GreaterThan(0));
    Assert.That(result.Status, Is.EqualTo(ConversionStatus.Completed));
    CsvAssertions.AssertFileExists(outputPath);
}
```

---

## 7. Architecture Rules

### Plugin System Rules

```
1. Plugins NEVER self-register into host DI container.
   Framework (PluginRegistry) controls ALL plugin registration.

2. Plugins ONLY depend on Axbus.Core.
   Never reference Axbus.Application or Axbus.Infrastructure.

3. Every plugin MUST implement IPlugin fully.
   Null-returning Create*() methods are acceptable for unsupported stages.

4. Plugin manifest file MUST exist alongside plugin DLL.
   Format: {PluginAssemblyName}.manifest.json

5. Plugins run in isolated AssemblyLoadContext by default.
   Opt-out via IsolatePlugins=false in PluginSettings.

6. Schema building is INTERNAL to writer plugins.
   CsvSchemaBuilder and ExcelSchemaBuilder are in Internal/ folder.
   They are NOT public pipeline stages.
   Writers that need schema implement ISchemaAwareWriter.
```

### Pipeline Rules

```
1. Each stage takes the previous stage's typed output as input.
   ISourceReader    → ReadAsync()    → SourceData
   IFormatParser    → ParseAsync()   → ParsedData
   IDataTransformer → TransformAsync → TransformedData
   IOutputWriter    → WriteAsync()   → WriteResult

2. No PipelineContextBuilder. Context = accumulated stage outputs.

3. Every stage MUST accept CancellationToken.

4. ConfigureAwait(false) on every await in library code.

5. Middleware wraps every stage execution.
   Default middleware: Logging → Timing → ErrorHandling
   Optional middleware: Retry (if configured)
```

### Custom Exception Types

Generate these exception classes in `Axbus.Core`:
```csharp
// Axbus.Core/Exceptions/AxbusPipelineException.cs
public class AxbusPipelineException : Exception
{
    public PipelineStage Stage { get; }
    public AxbusPipelineException(string message) : base(message) { }
    public AxbusPipelineException(string message, Exception inner) : base(message, inner) { }
    public AxbusPipelineException(string message, PipelineStage stage, Exception? inner = null)
        : base(message, inner) { Stage = stage; }
}

// Axbus.Core/Exceptions/AxbusPluginException.cs
public class AxbusPluginException : Exception { ... }

// Axbus.Core/Exceptions/AxbusConnectorException.cs
public class AxbusConnectorException : Exception { ... }

// Axbus.Core/Exceptions/AxbusConfigurationException.cs
public class AxbusConfigurationException : Exception { ... }
```

---

## 8. File Generation Sequence

Generate files in **this exact order**. Each file depends on files generated before it.

### Phase 1 — Core Enums (no dependencies)
```
01. Axbus.Core/Enums/OutputFormat.cs
02. Axbus.Core/Enums/OutputMode.cs
03. Axbus.Core/Enums/ConversionStatus.cs
04. Axbus.Core/Enums/PipelineStage.cs
05. Axbus.Core/Enums/PluginCapabilities.cs
06. Axbus.Core/Enums/SchemaStrategy.cs
07. Axbus.Core/Enums/RowErrorStrategy.cs
08. Axbus.Core/Enums/PluginConflictStrategy.cs
09. Axbus.Core/Enums/PluginIsolationMode.cs
10. Axbus.Core/Enums/ConversionEventType.cs
```

### Phase 2 — Core Models (depend on enums)
```
11. Axbus.Core/Models/Configuration/ParallelSettings.cs
12. Axbus.Core/Models/Configuration/SourceOptions.cs
13. Axbus.Core/Models/Configuration/TargetOptions.cs
14. Axbus.Core/Models/Configuration/PipelineOptions.cs
15. Axbus.Core/Models/Configuration/PluginSettings.cs
16. Axbus.Core/Models/Configuration/ConversionModule.cs
17. Axbus.Core/Models/Configuration/AxbusRootSettings.cs
18. Axbus.Core/Models/Pipeline/FlattenedRow.cs
19. Axbus.Core/Models/Pipeline/ErrorRow.cs
20. Axbus.Core/Models/Pipeline/SourceData.cs
21. Axbus.Core/Models/Pipeline/ParsedData.cs
22. Axbus.Core/Models/Pipeline/TransformedData.cs
23. Axbus.Core/Models/Pipeline/WriteResult.cs
24. Axbus.Core/Models/Pipeline/ValidationResult.cs
25. Axbus.Core/Models/Pipeline/PipelineStageResult.cs
26. Axbus.Core/Models/Plugin/PluginFileSet.cs
27. Axbus.Core/Models/Plugin/PluginManifest.cs
28. Axbus.Core/Models/Plugin/PluginDescriptor.cs
29. Axbus.Core/Models/Plugin/PluginCompatibility.cs
30. Axbus.Core/Models/Plugin/FrameworkInfo.cs
31. Axbus.Core/Models/Notifications/ConversionProgress.cs
32. Axbus.Core/Models/Notifications/ConversionEvent.cs
33. Axbus.Core/Models/Results/ModuleResult.cs
34. Axbus.Core/Models/Results/ConversionSummary.cs
```

### Phase 3 — Core Exceptions
```
35. Axbus.Core/Exceptions/AxbusPipelineException.cs
36. Axbus.Core/Exceptions/AxbusPluginException.cs
37. Axbus.Core/Exceptions/AxbusConnectorException.cs
38. Axbus.Core/Exceptions/AxbusConfigurationException.cs
```

### Phase 4 — Core Abstractions (depend on models + enums)
```
39. Axbus.Core/Abstractions/Pipeline/ISourceReader.cs
40. Axbus.Core/Abstractions/Pipeline/IFormatParser.cs
41. Axbus.Core/Abstractions/Pipeline/IDataTransformer.cs
42. Axbus.Core/Abstractions/Pipeline/IOutputWriter.cs
43. Axbus.Core/Abstractions/Pipeline/ISchemaAwareWriter.cs
44. Axbus.Core/Abstractions/Pipeline/IDataValidator.cs
45. Axbus.Core/Abstractions/Pipeline/IDataFilter.cs
46. Axbus.Core/Abstractions/Middleware/IPipelineMiddleware.cs
47. Axbus.Core/Abstractions/Middleware/IPipelineMiddlewareContext.cs
48. Axbus.Core/Abstractions/Middleware/PipelineStageDelegate.cs
49. Axbus.Core/Abstractions/Connectors/ISourceConnector.cs
50. Axbus.Core/Abstractions/Connectors/ITargetConnector.cs
51. Axbus.Core/Abstractions/Connectors/IConnectorFactory.cs
52. Axbus.Core/Abstractions/Plugin/IPluginOptions.cs
53. Axbus.Core/Abstractions/Plugin/IPluginOptionsValidator.cs
54. Axbus.Core/Abstractions/Plugin/IPluginManifest.cs
55. Axbus.Core/Abstractions/Plugin/IPluginContext.cs
56. Axbus.Core/Abstractions/Plugin/IPlugin.cs
57. Axbus.Core/Abstractions/Plugin/IPluginLoader.cs
58. Axbus.Core/Abstractions/Plugin/IPluginRegistry.cs
59. Axbus.Core/Abstractions/Plugin/IPluginManifestReader.cs
60. Axbus.Core/Abstractions/Conversion/IConversionContext.cs
61. Axbus.Core/Abstractions/Conversion/IConversionPipeline.cs
62. Axbus.Core/Abstractions/Conversion/IConversionRunner.cs
63. Axbus.Core/Abstractions/Factories/IPipelineFactory.cs
64. Axbus.Core/Abstractions/Factories/IPluginOptionsFactory.cs
65. Axbus.Core/Abstractions/Factories/IMiddlewareFactory.cs
66. Axbus.Core/Abstractions/Notifications/IProgressReporter.cs
67. Axbus.Core/Abstractions/Notifications/IEventPublisher.cs
```

### Phase 5 — Application Layer
```
68. Axbus.Application/Pipeline/PipelineStageExecutor.cs
69. Axbus.Application/Pipeline/ConversionPipeline.cs
70. Axbus.Application/Middleware/PipelineMiddlewareContext.cs
71. Axbus.Application/Middleware/MiddlewarePipelineBuilder.cs
72. Axbus.Application/Middleware/LoggingMiddleware.cs
73. Axbus.Application/Middleware/TimingMiddleware.cs
74. Axbus.Application/Middleware/RetryMiddleware.cs
75. Axbus.Application/Middleware/ErrorHandlingMiddleware.cs
76. Axbus.Application/Conversion/ConversionContext.cs
77. Axbus.Application/Conversion/ConversionRunner.cs
78. Axbus.Application/Plugin/PluginIsolationContext.cs
79. Axbus.Application/Plugin/PluginCompatibilityChecker.cs
80. Axbus.Application/Plugin/PluginManifestReader.cs
81. Axbus.Application/Plugin/PluginLoader.cs
82. Axbus.Application/Plugin/PluginOptionsFactory.cs
83. Axbus.Application/Plugin/PluginContextFactory.cs
84. Axbus.Application/Plugin/PluginRegistry.cs
85. Axbus.Application/Factories/MiddlewareFactory.cs
86. Axbus.Application/Factories/PipelineFactory.cs
87. Axbus.Application/Notifications/ProgressReporter.cs
88. Axbus.Application/Notifications/EventPublisher.cs
89. Axbus.Application/Extensions/ApplicationServiceExtensions.cs
```

### Phase 6 — Infrastructure Layer
```
90. Axbus.Infrastructure/Connectors/LocalFileSourceConnector.cs
91. Axbus.Infrastructure/Connectors/LocalFileTargetConnector.cs
92. Axbus.Infrastructure/Connectors/ConnectorFactory.cs
93. Axbus.Infrastructure/FileSystem/FileSystemScanner.cs
94. Axbus.Infrastructure/FileSystem/FileSystemWatcher.cs
95. Axbus.Infrastructure/FileSystem/PluginFolderScanner.cs
96. Axbus.Infrastructure/Logging/SerilogConfiguration.cs
97. Axbus.Infrastructure/Logging/ConversionLogContext.cs
98. Axbus.Infrastructure/Extensions/InfrastructureServiceExtensions.cs
```

### Phase 7 — JSON Reader Plugin
```
99.  Axbus.Plugin.Reader.Json/Options/JsonReaderPluginOptions.cs
100. Axbus.Plugin.Reader.Json/Validators/JsonReaderOptionsValidator.cs
101. Axbus.Plugin.Reader.Json/Reader/JsonSourceReader.cs
102. Axbus.Plugin.Reader.Json/Parser/JsonFormatParser.cs
103. Axbus.Plugin.Reader.Json/Transformer/JsonArrayExploder.cs
104. Axbus.Plugin.Reader.Json/Transformer/JsonDataTransformer.cs
105. Axbus.Plugin.Reader.Json/JsonReaderPlugin.cs
106. Axbus.Plugin.Reader.Json/Axbus.Plugin.Reader.Json.manifest.json
```

### Phase 8 — CSV Writer Plugin
```
107. Axbus.Plugin.Writer.Csv/Options/CsvWriterPluginOptions.cs
108. Axbus.Plugin.Writer.Csv/Validators/CsvWriterOptionsValidator.cs
109. Axbus.Plugin.Writer.Csv/Internal/CsvSchemaBuilder.cs
110. Axbus.Plugin.Writer.Csv/Writer/CsvOutputWriter.cs
111. Axbus.Plugin.Writer.Csv/CsvWriterPlugin.cs
112. Axbus.Plugin.Writer.Csv/Axbus.Plugin.Writer.Csv.manifest.json
```

### Phase 9 — Excel Writer Plugin
```
113. Axbus.Plugin.Writer.Excel/Options/ExcelWriterPluginOptions.cs
114. Axbus.Plugin.Writer.Excel/Validators/ExcelWriterOptionsValidator.cs
115. Axbus.Plugin.Writer.Excel/Internal/ExcelSchemaBuilder.cs
116. Axbus.Plugin.Writer.Excel/Writer/ExcelOutputWriter.cs
117. Axbus.Plugin.Writer.Excel/ExcelWriterPlugin.cs
118. Axbus.Plugin.Writer.Excel/Axbus.Plugin.Writer.Excel.manifest.json
```

### Phase 10 — Console Client
```
119. Axbus.ConsoleApp/Bootstrapper/AppBootstrapper.cs
120. Axbus.ConsoleApp/appsettings.json
121. Axbus.ConsoleApp/appsettings.Development.json
122. Axbus.ConsoleApp/appsettings.Production.json
123. Axbus.ConsoleApp/Program.cs
```

### Phase 11 — WinForms Client
```
124. Axbus.WinFormsApp/Bootstrapper/FormFactory.cs
125. Axbus.WinFormsApp/Bootstrapper/AppBootstrapper.cs
126. Axbus.WinFormsApp/ViewModels/ConversionModuleViewModel.cs
127. Axbus.WinFormsApp/ViewModels/ProgressViewModel.cs
128. Axbus.WinFormsApp/ViewModels/ModuleResultViewModel.cs
129. Axbus.WinFormsApp/ViewModels/ConversionSummaryViewModel.cs
130. Axbus.WinFormsApp/ViewModels/PluginInfoViewModel.cs
131. Axbus.WinFormsApp/ViewModels/ErrorViewModel.cs
132. Axbus.WinFormsApp/Forms/ProgressForm.cs
133. Axbus.WinFormsApp/Forms/SummaryForm.cs
134. Axbus.WinFormsApp/Forms/MainForm.cs
135. Axbus.WinFormsApp/appsettings.json
136. Axbus.WinFormsApp/Program.cs
```

### Phase 12 — Test Infrastructure
```
137. Axbus.Tests.Common/Helpers/TestDataLoader.cs
138. Axbus.Tests.Common/Helpers/OutputCapture.cs
139. Axbus.Tests.Common/Base/TempFolderFixture.cs
140. Axbus.Tests.Common/Base/AxbusTestBase.cs
141. Axbus.Tests.Common/Builders/PipelineOptionsBuilder.cs
142. Axbus.Tests.Common/Builders/PluginOptionsBuilder.cs
143. Axbus.Tests.Common/Builders/ConversionModuleBuilder.cs
144. Axbus.Tests.Common/Assertions/PipelineAssertions.cs
145. Axbus.Tests.Common/Assertions/ExcelAssertions.cs
146. Axbus.Tests.Common/Assertions/CsvAssertions.cs
```

### Phase 13 — Core Tests
```
147. Axbus.Core.Tests/TestData/ ← add real JSON files
148. Axbus.Core.Tests/Base/CoreTestBase.cs
149. Axbus.Core.Tests/Tests/Enums/OutputFormatFlagsTests.cs
150. Axbus.Core.Tests/Tests/Enums/PluginCapabilitiesTests.cs
151. Axbus.Core.Tests/Tests/Models/ConversionModuleTests.cs
152. Axbus.Core.Tests/Tests/Models/PluginManifestTests.cs
153. Axbus.Core.Tests/Tests/Models/PipelineStageDataTests.cs
154. Axbus.Core.Tests/Tests/Models/ParallelSettingsTests.cs
```

### Phase 14 — Application Tests
```
155. Axbus.Application.Tests/Base/ApplicationTestBase.cs
156. Axbus.Application.Tests/Tests/Pipeline/ConversionPipelineTests.cs
157. Axbus.Application.Tests/Tests/Pipeline/PipelineStageExecutorTests.cs
158. Axbus.Application.Tests/Tests/Middleware/MiddlewarePipelineBuilderTests.cs
159. Axbus.Application.Tests/Tests/Middleware/LoggingMiddlewareTests.cs
160. Axbus.Application.Tests/Tests/Middleware/TimingMiddlewareTests.cs
161. Axbus.Application.Tests/Tests/Middleware/RetryMiddlewareTests.cs
162. Axbus.Application.Tests/Tests/Middleware/ErrorHandlingMiddlewareTests.cs
163. Axbus.Application.Tests/Tests/Conversion/ConversionRunnerTests.cs
164. Axbus.Application.Tests/Tests/Conversion/ConversionContextTests.cs
165. Axbus.Application.Tests/Tests/Plugin/PluginLoaderTests.cs
166. Axbus.Application.Tests/Tests/Plugin/PluginManifestReaderTests.cs
167. Axbus.Application.Tests/Tests/Plugin/PluginRegistryTests.cs
168. Axbus.Application.Tests/Tests/Plugin/PluginCompatibilityTests.cs
169. Axbus.Application.Tests/Tests/Plugin/PluginContextFactoryTests.cs
170. Axbus.Application.Tests/Tests/Factories/PipelineFactoryTests.cs
171. Axbus.Application.Tests/Tests/Factories/MiddlewareFactoryTests.cs
172. Axbus.Application.Tests/Tests/Notifications/ProgressReporterTests.cs
173. Axbus.Application.Tests/Tests/Notifications/EventPublisherTests.cs
```

### Phase 15 — Infrastructure Tests
```
174. Axbus.Infrastructure.Tests/Base/InfrastructureTestBase.cs
175. Axbus.Infrastructure.Tests/Tests/Connectors/LocalFileSourceConnectorTests.cs
176. Axbus.Infrastructure.Tests/Tests/Connectors/LocalFileTargetConnectorTests.cs
177. Axbus.Infrastructure.Tests/Tests/FileSystem/FileSystemScannerTests.cs
178. Axbus.Infrastructure.Tests/Tests/FileSystem/PluginFolderScannerTests.cs
179. Axbus.Infrastructure.Tests/Tests/Logging/ConversionLogContextTests.cs
```

### Phase 16 — Plugin Tests
```
180. Axbus.Plugin.Reader.Json.Tests/Base/JsonReaderTestBase.cs
181. Axbus.Plugin.Reader.Json.Tests/Tests/Plugin/JsonReaderPluginTests.cs
182. Axbus.Plugin.Reader.Json.Tests/Tests/Reader/JsonSourceReaderTests.cs
183. Axbus.Plugin.Reader.Json.Tests/Tests/Parser/JsonFormatParserTests.cs
184. Axbus.Plugin.Reader.Json.Tests/Tests/Transformer/JsonDataTransformerTests.cs
185. Axbus.Plugin.Reader.Json.Tests/Tests/Transformer/JsonArrayExploderTests.cs
186. Axbus.Plugin.Reader.Json.Tests/Tests/Integration/JsonReaderEndToEndTests.cs

187. Axbus.Plugin.Writer.Csv.Tests/Base/CsvWriterTestBase.cs
188. Axbus.Plugin.Writer.Csv.Tests/Tests/Plugin/CsvWriterPluginTests.cs
189. Axbus.Plugin.Writer.Csv.Tests/Tests/Internal/CsvSchemaBuilderTests.cs
190. Axbus.Plugin.Writer.Csv.Tests/Tests/Writer/CsvOutputWriterTests.cs
191. Axbus.Plugin.Writer.Csv.Tests/Tests/Integration/CsvWriterEndToEndTests.cs

192. Axbus.Plugin.Writer.Excel.Tests/Base/ExcelWriterTestBase.cs
193. Axbus.Plugin.Writer.Excel.Tests/Tests/Plugin/ExcelWriterPluginTests.cs
194. Axbus.Plugin.Writer.Excel.Tests/Tests/Internal/ExcelSchemaBuilderTests.cs
195. Axbus.Plugin.Writer.Excel.Tests/Tests/Writer/ExcelOutputWriterTests.cs
196. Axbus.Plugin.Writer.Excel.Tests/Tests/Integration/ExcelWriterEndToEndTests.cs
```

### Phase 17 — Integration Tests
```
197. Axbus.Integration.Tests/Base/IntegrationTestBase.cs
198. Axbus.Integration.Tests/Tests/JsonToCsvTests.cs
199. Axbus.Integration.Tests/Tests/JsonToExcelTests.cs
200. Axbus.Integration.Tests/Tests/JsonToCsvAndExcelTests.cs
201. Axbus.Integration.Tests/Tests/MultiModuleTests.cs
202. Axbus.Integration.Tests/Tests/ParallelExecutionTests.cs
203. Axbus.Integration.Tests/Tests/CancellationTests.cs
204. Axbus.Integration.Tests/Tests/ProgressReportingTests.cs
205. Axbus.Integration.Tests/Tests/ErrorStrategyTests.cs
206. Axbus.Integration.Tests/Tests/PluginResolutionTests.cs
```

---

## 9. Per-Layer Generation Prompts

Use these prompts in **GitHub Copilot Chat** (`Ctrl+Alt+I` in Visual Studio).
Open the relevant file first, then paste the prompt.

### Prompt: Generate Entire Core Layer
```
Generate all files for the Axbus.Core project following the copilot-instructions.md rules.

The Core layer has ZERO external dependencies. It contains only:
- Enums (OutputFormat, OutputMode, ConversionStatus, PipelineStage, PluginCapabilities,
  SchemaStrategy, RowErrorStrategy, PluginConflictStrategy, PluginIsolationMode,
  ConversionEventType)
- Immutable record models for pipeline stages (SourceData, ParsedData, TransformedData,
  WriteResult, FlattenedRow, ErrorRow, ValidationResult, PipelineStageResult)
- Configuration models (AxbusRootSettings, ConversionModule, SourceOptions, TargetOptions,
  PipelineOptions, PluginSettings, ParallelSettings)
- Plugin models (PluginManifest, PluginDescriptor, PluginCompatibility, PluginFileSet,
  FrameworkInfo)
- Notification models (ConversionProgress, ConversionEvent)
- Result models (ModuleResult, ConversionSummary)
- Custom exceptions (AxbusPipelineException, AxbusPluginException,
  AxbusConnectorException, AxbusConfigurationException)
- All interfaces for pipeline stages, middleware, connectors, plugins,
  conversion, factories and notifications

Follow all rules in copilot-instructions.md:
- Full XML documentation on everything
- Inline comments on local variables
- StyleCop copyright header: "Axel Johnson International" 2026
- File-scoped namespaces
- Using statements below namespace
- No underscore on fields
- Nullable reference types enabled
- Records for all immutable pipeline stage outputs
```

### Prompt: Generate Entire Application Layer
```
Generate all files for the Axbus.Application project following the copilot-instructions.md rules.

The Application layer depends on Axbus.Core ONLY. It contains:
- ConversionPipeline: executes typed stage chain Read→Parse→Transform→Write
- PipelineStageExecutor: executes a single stage wrapped in middleware
- ConversionRunner: runs all enabled modules, sequential or parallel with
  SemaphoreSlim throttling using MaxDegreeOfParallelism
- ConversionContext: IConversionContext implementation accumulating stage outputs
- Middleware: MiddlewarePipelineBuilder, LoggingMiddleware, TimingMiddleware,
  RetryMiddleware, ErrorHandlingMiddleware, PipelineMiddlewareContext
- Plugin: PluginLoader (loads assembly into AssemblyLoadContext),
  PluginManifestReader (deserializes manifest JSON),
  PluginRegistry (registers + resolves, applies ConflictStrategy),
  PluginIsolationContext (AssemblyLoadContext per plugin),
  PluginOptionsFactory (deserializes Dictionary<string,JsonElement> to typed options),
  PluginContextFactory (creates IPluginContext per plugin),
  PluginCompatibilityChecker (SemVer validation)
- Factories: PipelineFactory, MiddlewareFactory
- Notifications: ProgressReporter, EventPublisher
- Extensions: ApplicationServiceExtensions

Key behaviours:
- ConfigureAwait(false) on all awaits
- CancellationToken in every async method
- Parallel execution uses SemaphoreSlim not Task.WhenAll
- Root RunInParallel=false overrides all module flags
```

### Prompt: Generate Entire Infrastructure Layer
```
Generate all files for the Axbus.Infrastructure project following copilot-instructions.md.

CRITICAL: Infrastructure is FORMAT-AGNOSTIC. It NEVER knows about JSON, CSV, or Excel.
It provides generic file system access returning raw streams.

Contains:
- LocalFileSourceConnector: ISourceConnector returning raw Stream per file
- LocalFileTargetConnector: ITargetConnector accepting Stream, writes to disk
- ConnectorFactory: resolves connectors by SourceOptions.Type
- FileSystemScanner: scans folders by pattern, supports recursive scan
- FileSystemWatcher: watches folders for new files, format-agnostic
- PluginFolderScanner: finds DLL+manifest pairs, returns PluginFileSet, does NOT load
- SerilogConfiguration: Console + File sinks, 5MB rollover, 10 retained files
- ConversionLogContext: enriches Serilog events with ConversionName, PluginId, Stage
- InfrastructureServiceExtensions: DI registration
```

---

## 10. Per-File Generation Prompts

Use these prompts when generating individual files in Copilot Chat.
**Open the target file first, then paste the prompt.**

### IPlugin.cs
```
Generate the IPlugin interface in Axbus.Core/Abstractions/Plugin/IPlugin.cs

This is the BASE CONTRACT every Axbus plugin must implement. Include:
- string PluginId { get; }
- string Name { get; }
- Version Version { get; }
- Version MinFrameworkVersion { get; }
- PluginCapabilities Capabilities { get; }
- ISourceReader? CreateReader(IServiceProvider services)     ← null if not supported
- IFormatParser? CreateParser(IServiceProvider services)     ← null if not supported
- IDataTransformer? CreateTransformer(IServiceProvider services) ← null if not supported
- IOutputWriter? CreateWriter(IServiceProvider services)     ← null if not supported
- Task InitializeAsync(IPluginContext context, CancellationToken cancellationToken)
- Task ShutdownAsync(CancellationToken cancellationToken)

Full XML docs on every member. Copyright header. File-scoped namespace.
Nullable reference types. Using below namespace.
```

### ConversionRunner.cs
```
Generate ConversionRunner in Axbus.Application/Conversion/ConversionRunner.cs

Implements IConversionRunner. Injected dependencies:
- IConversionPipeline pipeline
- IPluginRegistry pluginRegistry
- IProgressReporter progressReporter
- IEventPublisher eventPublisher
- ILogger<ConversionRunner> logger
- IOptions<AxbusRootSettings> settings

Key behaviours:
1. RunAsync(IProgress<ConversionProgress>, CancellationToken) → ConversionSummary
2. Parallel execution: use SemaphoreSlim(settings.ParallelSettings.MaxDegreeOfParallelism)
3. Root RunInParallel=false OVERRIDES all individual module RunInParallel flags
4. Root RunInParallel=true respects each module's own RunInParallel flag
5. Sequential: execute in ExecutionOrder ascending
6. Skip disabled modules (IsEnabled=false) with LogInformation + Skipped event
7. ContinueOnError=true: catch exception, log, continue to next module
8. ContinueOnError=false: re-throw on first failure
9. Publish ConversionEvent for every state change
10. Report IProgress<ConversionProgress> per file processed
11. Return ConversionSummary with all ModuleResult entries

Full XML docs. Inline comments on locals. Copyright header. ConfigureAwait(false).
```

### JsonReaderPlugin.cs
```
Generate JsonReaderPlugin in Axbus.Plugin.Reader.Json/JsonReaderPlugin.cs

Implements IPlugin. Capabilities = PluginCapabilities.Reader | Parser | Transformer.

- PluginId = "axbus.plugin.reader.json"
- Name = "JsonReader"
- MinFrameworkVersion = new Version(1, 0, 0)

CreateReader() → new JsonSourceReader(services)
CreateParser() → new JsonFormatParser(services)
CreateTransformer() → new JsonDataTransformer(services)
CreateWriter() → null (this plugin has no write capability)

InitializeAsync: validate options using JsonReaderOptionsValidator, log initialization
ShutdownAsync: log shutdown

Full XML docs. Copyright header. No underscore. ConfigureAwait(false).
Depends on Axbus.Core ONLY.
```

### CsvOutputWriter.cs
```
Generate CsvOutputWriter in Axbus.Plugin.Writer.Csv/Writer/CsvOutputWriter.cs

Implements IOutputWriter AND ISchemaAwareWriter.

WriteAsync behaviour:
1. Receive TransformedData (IAsyncEnumerable<FlattenedRow>)
2. If ISchemaAwareWriter.BuildSchemaAsync was called: use that schema
3. If not: build schema from first pass (FullScan strategy) or first file
4. Write header row using schema column order
5. For each row: write values in schema order, NullPlaceholder for missing columns
6. RFC 4180 compliant: quote values containing delimiter/newline/quote
7. On RowErrorStrategy.WriteToErrorFile: write bad rows to ErrorOutputPath
8. Use StringBuilder for row building (pre-allocate 256 chars)
9. Use StreamWriter with UTF-8 encoding, no BOM

Full XML docs. Inline comments. Copyright header. ConfigureAwait(false).
Depends on Axbus.Core ONLY.
```

### AppBootstrapper.cs (ConsoleApp)
```
Generate AppBootstrapper in Axbus.ConsoleApp/Bootstrapper/AppBootstrapper.cs

Static class with Build(string[] args) → IHost method.

Registers:
1. All framework layers via extension methods:
   services.AddAxbusApplication()
   services.AddAxbusInfrastructure(config)
2. All plugins manually (framework controls registration, not plugins):
   services.AddSingleton<IPlugin, JsonReaderPlugin>()
   services.AddSingleton<IPlugin, CsvWriterPlugin>()
   services.AddSingleton<IPlugin, ExcelWriterPlugin>()
3. Serilog via UseSerilog()
4. AxbusRootSettings from configuration
5. IProgress<ConversionProgress> reporting to Console
6. Ctrl+C cancellation via CancellationTokenSource

Program.cs should be max 15 lines calling AppBootstrapper.Build(args).Run()

Full XML docs. Copyright header. Using below namespace.
```

---

## 11. Validation Checklist

After generating each file, verify:

### Every `.cs` File
```
☐ StyleCop copyright header present (except test projects)
☐ File-scoped namespace used (namespace Axbus.X.Y; not namespace Axbus.X.Y { })
☐ Using statements BELOW namespace declaration
☐ Full XML documentation on class/interface
☐ Full XML documentation on all public methods (summary + param + returns + exception)
☐ Full XML documentation on all public properties (summary)
☐ Inline // comments on local variables and logic blocks
☐ No underscore prefix on any field (except test projects)
☐ this. used for field assignment in constructors to disambiguate
☐ Nullable reference types respected (string? for nullable, string for non-nullable)
☐ Braces on all if/else/for/foreach even single-line
☐ ConfigureAwait(false) on all awaits in library projects
☐ CancellationToken parameter on all async methods
☐ ArgumentNullException.ThrowIfNull() guard at top of public methods
```

### Interface Files (Core)
```
☐ Resides in Axbus.Core — zero project references
☐ No implementation code
☐ All methods have CancellationToken parameter
☐ Nullable return types where method can return null
```

### Plugin Files
```
☐ Only references Axbus.Core (no Application or Infrastructure)
☐ No self-registration code (no IServiceCollection extensions)
☐ IPlugin.CreateWriter() returns null if plugin is reader-only
☐ IPlugin.CreateReader() returns null if plugin is writer-only
☐ manifest.json file exists alongside plugin class
```

### Test Files
```
☐ NUnit [TestFixture] attribute on test class
☐ NUnit [Test] attribute on every test method
☐ BDD naming: Should_X_When_Y
☐ AAA pattern: Arrange / Act / Assert with comments
☐ XML docs on class and all test methods
☐ Real test data files used (no mock objects)
☐ TempFolderFixture used for output files
☐ [SetUp] and [TearDown] inherited from AxbusTestBase
```

---

## 12. Common Mistakes To Avoid

### Copilot Will Try To Do These — REJECT Them

```csharp
// ❌ REJECT — using statements above namespace
using System;
namespace Axbus.Core;

// ❌ REJECT — underscore prefix
private readonly ILogger _logger;

// ❌ REJECT — missing ConfigureAwait in library code
var result = await pipeline.ExecuteAsync(ct); // missing .ConfigureAwait(false)

// ❌ REJECT — string interpolation in logging
logger.LogError($"Failed for {module.ConversionName}");

// ❌ REJECT — swallowed exception
catch (Exception) { }

// ❌ REJECT — throw ex (loses stack trace)
catch (Exception ex) { throw ex; }

// ❌ REJECT — new inside service class (violates DI)
var pipeline = new ConversionPipeline();

// ❌ REJECT — plugin referencing Application layer
using Axbus.Application.Pipeline; // inside a plugin project

// ❌ REJECT — Infrastructure knowing about file formats
// Inside LocalFileSourceConnector.cs:
var json = JsonSerializer.Deserialize<...>(stream); // format knowledge in infrastructure

// ❌ REJECT — missing null guard
public async Task RunAsync(ConversionModule module, CancellationToken ct)
{
    // Missing: ArgumentNullException.ThrowIfNull(module);
    var result = await pipeline.ExecuteAsync(module, ct);
}

// ❌ REJECT — XML docs missing on public member
public class ConversionRunner
{
    public async Task<ConversionSummary> RunAsync(...) // no /// docs
    { }
}

// ❌ REJECT — plugin self-registering into DI
// Inside CsvWriterPlugin.cs:
public static IServiceCollection AddCsvWriter(this IServiceCollection services)
{
    services.AddSingleton<IOutputWriter, CsvOutputWriter>(); // ← WRONG
    return services;
}
```

### Architecture Violations — NEVER ALLOW
```
❌ Axbus.Core referencing any NuGet package
❌ Axbus.Plugin.* referencing Axbus.Application or Axbus.Infrastructure
❌ Axbus.Infrastructure containing format-specific code
❌ Any class using new() to create service dependencies
❌ Any static service classes (except AppBootstrapper)
❌ Any use of #region blocks
❌ ServiceLocator pattern (IServiceProvider.GetService() outside factories)
```

---

*Generated for Axbus Framework v1.0.0*
*Copyright (c) 2026 Axel Johnson International. All rights reserved.*
*Last updated: 2026*

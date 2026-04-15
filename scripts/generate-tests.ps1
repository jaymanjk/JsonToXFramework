# ==============================================================================
# generate-tests.ps1
# Axbus Framework - All Test Projects Code Generation Script
# Copyright (c) 2026 Axel Johnson International. All rights reserved.
#
# USAGE:
#   PowerShell -ExecutionPolicy Bypass -File .\scripts\generate-tests.ps1
#
# GENERATES:
#   36 .cs source files across 8 test projects
#   Patches all 8 .csproj files with explicit Compile Include entries
#   Runs dotnet build to verify - zero manual steps required
# ==============================================================================

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$ScriptVersion = "1.0.1"
$CompanyName   = "Axel Johnson International"
$CopyrightYear = "2026"

function Write-Banner {
    Write-Host ""
    Write-Host "===============================================================================" -ForegroundColor Cyan
    Write-Host "  Axbus Tests - Code Generation Script v$ScriptVersion" -ForegroundColor Cyan
    Write-Host "  Copyright (c) $CopyrightYear $CompanyName. All rights reserved." -ForegroundColor Cyan
    Write-Host "===============================================================================" -ForegroundColor Cyan
    Write-Host ""
}

function Write-Phase {
    param([string]$Message)
    Write-Host ""
    Write-Host "  >> $Message" -ForegroundColor Yellow
    Write-Host "  $("-" * 70)" -ForegroundColor Yellow
}

function Write-Ok   { param([string]$m) Write-Host "      [OK] $m" -ForegroundColor Green }
function Write-Warn { param([string]$m) Write-Host "      [!!] $m" -ForegroundColor Magenta }
function Write-Info { param([string]$m) Write-Host "      [..] $m" -ForegroundColor White }

# ------------------------------------------------------------------------------
# New-SourceFile
# Writes a .cs file to disk using Windows CRLF line endings.
# Creates the parent directory if it does not exist.
# ------------------------------------------------------------------------------
function New-SourceFile {
    param([string]$RootPath, [string]$RelativePath, [string]$Content)
    $fullPath  = Join-Path $RootPath $RelativePath
    $directory = Split-Path $fullPath -Parent
    if (-not [string]::IsNullOrWhiteSpace($directory) -and -not (Test-Path $directory)) {
        New-Item -ItemType Directory -Path $directory -Force | Out-Null
    }
    # Normalise to CRLF so PowerShell here-strings work correctly on Windows
    $crlfContent = $Content -replace "(?<!\r)\n", "`r`n"
    [System.IO.File]::WriteAllText(
        [System.IO.Path]::GetFullPath($fullPath),
        $crlfContent,
        [System.Text.UTF8Encoding]::new($false)
    )
    Write-Ok $RelativePath
}

# ------------------------------------------------------------------------------
# Add-CompileIncludes
# Patches a .csproj file by inserting an explicit <ItemGroup> with
# <Compile Include="folder\**\*.cs" /> entries just before </Project>.
# This makes VS show all generated files without a manual project reload.
# ------------------------------------------------------------------------------
function Add-CompileIncludes {
    param(
        [string]$CsprojPath,
        [string[]]$Folders
    )

    if (-not (Test-Path $CsprojPath)) {
        Write-Warn "Cannot patch (not found): $CsprojPath"
        return
    }

    $content = [System.IO.File]::ReadAllText(
        [System.IO.Path]::GetFullPath($CsprojPath),
        [System.Text.Encoding]::UTF8)

    # Skip if already patched
    if ($content -match "Axbus-Generated-Compile-Includes") {
        Write-Info "Already patched: $(Split-Path $CsprojPath -Leaf)"
        return
    }

    # Build the ItemGroup XML block
    $lines = @("", "  <!-- Axbus-Generated-Compile-Includes: makes files visible in VS immediately -->")
    $lines += "  <ItemGroup>"
    foreach ($folder in $Folders) {
        $lines += "    <Compile Include=`"$folder\**\*.cs`" />"
    }
    $lines += "  </ItemGroup>"
    $lines += ""

    $insertBlock = $lines -join "`r`n"

    # Insert before </Project>
    $patched = $content -replace "</Project>", "$insertBlock</Project>"

    [System.IO.File]::WriteAllText(
        [System.IO.Path]::GetFullPath($CsprojPath),
        $patched,
        [System.Text.UTF8Encoding]::new($false)
    )

    Write-Ok "Patched: $(Split-Path $CsprojPath -Leaf)"
}

# ==============================================================================
# GUARDS
# ==============================================================================

if (-not (Test-Path ".git")) {
    Write-Host "  [FAILED] Run from repository root." -ForegroundColor Red; exit 1
}
if (-not (Test-Path "src/framework/Axbus.Core/Axbus.Core.csproj")) {
    Write-Host "  [FAILED] Axbus.Core not found. Run previous generate scripts first." -ForegroundColor Red; exit 1
}

Write-Banner

# ==============================================================================
# TEST PROJECT 1 - AXBUS.TESTS.COMMON
# ==============================================================================

$CommonRoot = "tests/Axbus.Tests.Common"
Write-Phase "Test Project 1 - Axbus.Tests.Common (4 files)"

New-SourceFile $CommonRoot "Base/AxbusTestBase.cs" @'
// <copyright file="AxbusTestBase.cs" company="Axel Johnson International">
// Copyright (c) 2026 Axel Johnson International. All rights reserved.
// </copyright>

namespace Axbus.Tests.Common.Base;

using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Logging;
using NUnit.Framework;

/// <summary>
/// Base class for all Axbus unit and integration tests.
/// Provides a pre-configured DI service provider with logging,
/// a NullLogger factory for tests that do not need log output,
/// and helper properties for common test setup patterns.
/// All test classes in the Axbus test suite should inherit from this class.
/// </summary>
public abstract class AxbusTestBase
{
    /// <summary>
    /// Gets the DI service provider configured in <see cref="SetUp"/>.
    /// Rebuilt before each test to ensure test isolation.
    /// </summary>
    protected IServiceProvider Services { get; private set; } = null!;

    /// <summary>
    /// Gets a null logger factory that discards all log output.
    /// Use when a logger is required but log assertions are not needed.
    /// </summary>
    protected ILoggerFactory NullLoggerFactory { get; } =
        Microsoft.Extensions.Logging.Abstractions.NullLoggerFactory.Instance;

    /// <summary>
    /// Configures the DI service collection before each test.
    /// Override <see cref="ConfigureServices"/> to register additional services.
    /// </summary>
    [SetUp]
    public virtual void SetUp()
    {
        var services = new ServiceCollection();
        services.AddLogging(b => b.AddConsole().SetMinimumLevel(LogLevel.Debug));
        ConfigureServices(services);
        Services = services.BuildServiceProvider();
    }

    /// <summary>
    /// Tears down the service provider after each test.
    /// </summary>
    [TearDown]
    public virtual void TearDown()
    {
        if (Services is IDisposable disposable)
        {
            disposable.Dispose();
        }
    }

    /// <summary>
    /// Override to register additional services required by a test class.
    /// Called during <see cref="SetUp"/> before the provider is built.
    /// </summary>
    /// <param name="services">The service collection to register into.</param>
    protected virtual void ConfigureServices(IServiceCollection services)
    {
    }

    /// <summary>
    /// Creates a typed NullLogger for use in tests that need a logger
    /// but do not assert on log output.
    /// </summary>
    /// <typeparam name="T">The logger category type.</typeparam>
    /// <returns>A <see cref="ILogger{T}"/> that discards all output.</returns>
    protected static ILogger<T> NullLogger<T>() =>
        Microsoft.Extensions.Logging.Abstractions.NullLogger<T>.Instance;
}
'@

New-SourceFile $CommonRoot "Builders/ConversionModuleBuilder.cs" @'
// <copyright file="ConversionModuleBuilder.cs" company="Axel Johnson International">
// Copyright (c) 2026 Axel Johnson International. All rights reserved.
// </copyright>

namespace Axbus.Tests.Common.Builders;

using Axbus.Core.Enums;
using Axbus.Core.Models.Configuration;

/// <summary>
/// Fluent test data builder for <see cref="ConversionModule"/>.
/// Provides pre-configured defaults suitable for unit tests and allows
/// selective overrides via a fluent API.
/// </summary>
public sealed class ConversionModuleBuilder
{
    private string conversionName  = "TestModule";
    private string description     = "Test conversion module";
    private bool isEnabled         = true;
    private int executionOrder     = 1;
    private bool continueOnError   = true;
    private bool runInParallel     = false;
    private string sourceFormat    = "json";
    private string targetFormat    = "csv";
    private string? pluginOverride;
    private SourceOptions source   = new() { Path = "C:/test/input", FilePattern = "*.json" };
    private TargetOptions target   = new() { Path = "C:/test/output" };
    private PipelineOptions pipeline = new();

    /// <summary>Sets the conversion name.</summary>
    public ConversionModuleBuilder WithName(string name)
    { conversionName = name; return this; }

    /// <summary>Marks the module as disabled.</summary>
    public ConversionModuleBuilder Disabled()
    { isEnabled = false; return this; }

    /// <summary>Sets the source format.</summary>
    public ConversionModuleBuilder WithSourceFormat(string format)
    { sourceFormat = format; return this; }

    /// <summary>Sets the target format.</summary>
    public ConversionModuleBuilder WithTargetFormat(string format)
    { targetFormat = format; return this; }

    /// <summary>Sets the source path.</summary>
    public ConversionModuleBuilder WithSourcePath(string path)
    { source = new SourceOptions { Path = path, FilePattern = source.FilePattern }; return this; }

    /// <summary>Sets the target path.</summary>
    public ConversionModuleBuilder WithTargetPath(string path)
    { target = new TargetOptions { Path = path }; return this; }

    /// <summary>Sets the pipeline options.</summary>
    public ConversionModuleBuilder WithPipeline(PipelineOptions options)
    { pipeline = options; return this; }

    /// <summary>Sets ContinueOnError to false.</summary>
    public ConversionModuleBuilder StopOnError()
    { continueOnError = false; return this; }

    /// <summary>Sets the explicit plugin override identifier.</summary>
    public ConversionModuleBuilder WithPluginOverride(string pluginId)
    { pluginOverride = pluginId; return this; }

    /// <summary>Enables parallel execution for this module.</summary>
    public ConversionModuleBuilder RunningInParallel()
    { runInParallel = true; return this; }

    /// <summary>Builds and returns the configured <see cref="ConversionModule"/>.</summary>
    public ConversionModule Build() => new()
    {
        ConversionName  = conversionName,
        Description     = description,
        IsEnabled       = isEnabled,
        ExecutionOrder  = executionOrder,
        ContinueOnError = continueOnError,
        RunInParallel   = runInParallel,
        SourceFormat    = sourceFormat,
        TargetFormat    = targetFormat,
        PluginOverride  = pluginOverride,
        Source          = source,
        Target          = target,
        Pipeline        = pipeline,
    };

    /// <summary>Creates a new builder instance with default settings.</summary>
    public static ConversionModuleBuilder Default() => new();

    /// <summary>Creates a builder pre-configured for JSON-to-CSV conversion.</summary>
    public static ConversionModuleBuilder JsonToCsv() =>
        new ConversionModuleBuilder()
            .WithName("TestJsonToCsv")
            .WithSourceFormat("json")
            .WithTargetFormat("csv");

    /// <summary>Creates a builder pre-configured for JSON-to-Excel conversion.</summary>
    public static ConversionModuleBuilder JsonToExcel() =>
        new ConversionModuleBuilder()
            .WithName("TestJsonToExcel")
            .WithSourceFormat("json")
            .WithTargetFormat("excel");
}
'@

New-SourceFile $CommonRoot "Helpers/JsonTestDataHelper.cs" @'
// <copyright file="JsonTestDataHelper.cs" company="Axel Johnson International">
// Copyright (c) 2026 Axel Johnson International. All rights reserved.
// </copyright>

namespace Axbus.Tests.Common.Helpers;

using System.Text;
using System.Text.Json;

/// <summary>
/// Provides helper methods for creating in-memory JSON test data streams.
/// Eliminates the need for physical test data files for simple unit test scenarios.
/// </summary>
public static class JsonTestDataHelper
{
    /// <summary>
    /// Converts a JSON string to a readable <see cref="MemoryStream"/> positioned at the start.
    /// </summary>
    /// <param name="json">The JSON string to convert.</param>
    /// <returns>A <see cref="MemoryStream"/> containing the UTF-8 encoded JSON bytes.</returns>
    public static MemoryStream ToStream(string json)
    {
        var bytes = Encoding.UTF8.GetBytes(json);
        return new MemoryStream(bytes);
    }

    /// <summary>
    /// Creates a stream containing a flat JSON array with the specified number of objects.
    /// Each object has <c>id</c>, <c>name</c> and <c>value</c> fields.
    /// </summary>
    /// <param name="count">Number of objects in the array. Defaults to 3.</param>
    /// <returns>A <see cref="MemoryStream"/> containing the JSON array.</returns>
    public static MemoryStream FlatArray(int count = 3)
    {
        var items = Enumerable.Range(1, count).Select(i => new
        {
            id    = i.ToString(),
            name  = $"Item {i}",
            value = i * 10,
        });

        return ToStream(JsonSerializer.Serialize(items));
    }

    /// <summary>
    /// Creates a stream containing a JSON array with nested customer/address objects.
    /// </summary>
    /// <param name="count">Number of objects. Defaults to 2.</param>
    /// <returns>A <see cref="MemoryStream"/> containing the nested JSON array.</returns>
    public static MemoryStream NestedArray(int count = 2)
    {
        var items = Enumerable.Range(1, count).Select(i => new
        {
            id   = i.ToString(),
            type = "Order",
            customer = new
            {
                name    = $"Customer {i}",
                address = new { city = "Stockholm", country = "Sweden" },
            },
        });

        return ToStream(JsonSerializer.Serialize(items));
    }

    /// <summary>
    /// Creates a stream with a JSON array containing a nested array field
    /// suitable for testing array explosion behaviour.
    /// </summary>
    /// <param name="itemsPerArray">Items in the nested array. Defaults to 2.</param>
    /// <returns>A <see cref="MemoryStream"/> with explosion test JSON.</returns>
    public static MemoryStream ArrayForExplosion(int itemsPerArray = 2)
    {
        var items = new[]
        {
            new
            {
                orderId  = "ORD-001",
                customer = "Acme Corp",
                lines    = Enumerable.Range(1, itemsPerArray).Select(i => new
                {
                    lineNo = i,
                    sku    = $"SKU-{i:D3}",
                    qty    = i * 2,
                }).ToArray(),
            },
        };

        return ToStream(JsonSerializer.Serialize(items));
    }

    /// <summary>Creates a stream containing an empty JSON array <c>[]</c>.</summary>
    public static MemoryStream EmptyArray() => ToStream("[]");

    /// <summary>Creates a stream containing invalid JSON for error handling tests.</summary>
    public static MemoryStream InvalidJson() => ToStream("{ this is not valid json }");
}
'@

New-SourceFile $CommonRoot "Assertions/FlattenedRowAssertions.cs" @'
// <copyright file="FlattenedRowAssertions.cs" company="Axel Johnson International">
// Copyright (c) 2026 Axel Johnson International. All rights reserved.
// </copyright>

namespace Axbus.Tests.Common.Assertions;

using Axbus.Core.Models.Pipeline;
using NUnit.Framework;

/// <summary>
/// Provides custom NUnit assertion helpers for <see cref="FlattenedRow"/>
/// and collections thereof. Produces clear failure messages that include
/// row number and column names.
/// </summary>
public static class FlattenedRowAssertions
{
    /// <summary>
    /// Asserts that <paramref name="row"/> contains <paramref name="columnName"/>
    /// with the expected <paramref name="value"/>.
    /// </summary>
    /// <param name="row">The row to check.</param>
    /// <param name="columnName">The column name to look up.</param>
    /// <param name="value">The expected value.</param>
    public static void HasValue(FlattenedRow row, string columnName, string value)
    {
        Assert.That(
            row.Values.ContainsKey(columnName),
            Is.True,
            $"Row {row.RowNumber} does not contain column '{columnName}'. " +
            $"Present: {string.Join(", ", row.Values.Keys)}");

        Assert.That(
            row.Values[columnName],
            Is.EqualTo(value),
            $"Row {row.RowNumber} column '{columnName}' expected '{value}' " +
            $"but was '{row.Values[columnName]}'.");
    }

    /// <summary>
    /// Asserts that <paramref name="rows"/> contains exactly <paramref name="expectedCount"/> rows.
    /// </summary>
    /// <param name="rows">The row collection to check.</param>
    /// <param name="expectedCount">The expected row count.</param>
    public static void HasCount(IReadOnlyList<FlattenedRow> rows, int expectedCount)
    {
        Assert.That(rows.Count, Is.EqualTo(expectedCount),
            $"Expected {expectedCount} rows but got {rows.Count}.");
    }

    /// <summary>
    /// Asserts that every row in <paramref name="rows"/> contains <paramref name="columnName"/>.
    /// </summary>
    /// <param name="rows">The rows to check.</param>
    /// <param name="columnName">The column that must exist in every row.</param>
    public static void AllHaveColumn(IReadOnlyList<FlattenedRow> rows, string columnName)
    {
        foreach (var row in rows)
        {
            Assert.That(row.Values.ContainsKey(columnName), Is.True,
                $"Row {row.RowNumber} is missing column '{columnName}'.");
        }
    }

    /// <summary>
    /// Collects all rows from an <see cref="IAsyncEnumerable{T}"/> into a list
    /// for use in synchronous NUnit assertions.
    /// </summary>
    /// <param name="rows">The async row stream to collect.</param>
    /// <param name="cancellationToken">A token to cancel collection.</param>
    /// <returns>A list of all rows from the stream.</returns>
    public static async Task<List<FlattenedRow>> CollectAsync(
        IAsyncEnumerable<FlattenedRow> rows,
        CancellationToken cancellationToken = default)
    {
        var result = new List<FlattenedRow>();
        await foreach (var row in rows.WithCancellation(cancellationToken).ConfigureAwait(false))
        {
            result.Add(row);
        }

        return result;
    }
}
'@

# ==============================================================================
# TEST PROJECT 2 - AXBUS.CORE.TESTS
# ==============================================================================

$CoreTestsRoot = "tests/Axbus.Core.Tests"
Write-Phase "Test Project 2 - Axbus.Core.Tests (6 files)"

New-SourceFile $CoreTestsRoot "Tests/Enums/OutputFormatTests.cs" @'
// <copyright file="OutputFormatTests.cs" company="Axel Johnson International">
// Copyright (c) 2026 Axel Johnson International. All rights reserved.
// </copyright>

namespace Axbus.Core.Tests.Tests.Enums;

using Axbus.Core.Enums;
using Axbus.Tests.Common.Base;
using NUnit.Framework;

/// <summary>
/// Unit tests for the <see cref="OutputFormat"/> flags enumeration.
/// </summary>
[TestFixture]
public sealed class OutputFormatTests : AxbusTestBase
{
    /// <summary>Should_HaveNoneAsZeroValue_When_EnumIsInspected.</summary>
    [Test]
    public void Should_HaveNoneAsZeroValue_When_EnumIsInspected()
    {
        Assert.That((int)OutputFormat.None, Is.EqualTo(0));
    }

    /// <summary>Should_SupportFlagCombination_When_MultipleFormatsSelected.</summary>
    [Test]
    public void Should_SupportFlagCombination_When_MultipleFormatsSelected()
    {
        var combined = OutputFormat.Csv | OutputFormat.Excel;

        Assert.That(combined.HasFlag(OutputFormat.Csv),   Is.True);
        Assert.That(combined.HasFlag(OutputFormat.Excel), Is.True);
        Assert.That(combined.HasFlag(OutputFormat.Text),  Is.False);
    }

    /// <summary>Should_ReturnDistinctBitValues_When_EnumValuesCompared.</summary>
    [Test]
    public void Should_ReturnDistinctBitValues_When_EnumValuesCompared()
    {
        Assert.That((int)OutputFormat.Csv,   Is.EqualTo(1));
        Assert.That((int)OutputFormat.Excel, Is.EqualTo(2));
        Assert.That((int)OutputFormat.Text,  Is.EqualTo(4));
    }
}
'@

New-SourceFile $CoreTestsRoot "Tests/Enums/PluginCapabilitiesTests.cs" @'
// <copyright file="PluginCapabilitiesTests.cs" company="Axel Johnson International">
// Copyright (c) 2026 Axel Johnson International. All rights reserved.
// </copyright>

namespace Axbus.Core.Tests.Tests.Enums;

using Axbus.Core.Enums;
using Axbus.Tests.Common.Base;
using NUnit.Framework;

/// <summary>
/// Unit tests for the <see cref="PluginCapabilities"/> flags enumeration.
/// </summary>
[TestFixture]
public sealed class PluginCapabilitiesTests : AxbusTestBase
{
    /// <summary>Should_ContainAllCoreStages_When_BundledValueInspected.</summary>
    [Test]
    public void Should_ContainAllCoreStages_When_BundledValueInspected()
    {
        var bundled = PluginCapabilities.Bundled;

        Assert.That(bundled.HasFlag(PluginCapabilities.Reader),      Is.True);
        Assert.That(bundled.HasFlag(PluginCapabilities.Parser),      Is.True);
        Assert.That(bundled.HasFlag(PluginCapabilities.Transformer), Is.True);
        Assert.That(bundled.HasFlag(PluginCapabilities.Writer),      Is.True);
    }

    /// <summary>Should_NotContainValidatorOrFilter_When_BundledValueInspected.</summary>
    [Test]
    public void Should_NotContainValidatorOrFilter_When_BundledValueInspected()
    {
        var bundled = PluginCapabilities.Bundled;

        Assert.That(bundled.HasFlag(PluginCapabilities.Validator), Is.False);
        Assert.That(bundled.HasFlag(PluginCapabilities.Filter),    Is.False);
    }

    /// <summary>Should_AllowWriterOnlyPlugin_When_OnlyWriterCapabilitySet.</summary>
    [Test]
    public void Should_AllowWriterOnlyPlugin_When_OnlyWriterCapabilitySet()
    {
        var writerOnly = PluginCapabilities.Writer;

        Assert.That(writerOnly.HasFlag(PluginCapabilities.Writer), Is.True);
        Assert.That(writerOnly.HasFlag(PluginCapabilities.Reader), Is.False);
    }
}
'@

New-SourceFile $CoreTestsRoot "Tests/Models/ValidationResultTests.cs" @'
// <copyright file="ValidationResultTests.cs" company="Axel Johnson International">
// Copyright (c) 2026 Axel Johnson International. All rights reserved.
// </copyright>

namespace Axbus.Core.Tests.Tests.Models;

using Axbus.Core.Models.Pipeline;
using Axbus.Tests.Common.Base;
using NUnit.Framework;

/// <summary>
/// Unit tests for <see cref="ValidationResult"/>.
/// </summary>
[TestFixture]
public sealed class ValidationResultTests : AxbusTestBase
{
    /// <summary>Should_HaveIsValidTrue_When_SuccessFactoryUsed.</summary>
    [Test]
    public void Should_HaveIsValidTrue_When_SuccessFactoryUsed()
    {
        var result = ValidationResult.Success;

        Assert.That(result.IsValid,      Is.True);
        Assert.That(result.Errors.Count, Is.EqualTo(0));
    }

    /// <summary>Should_HaveIsValidFalse_When_FailFactoryUsedWithMessages.</summary>
    [Test]
    public void Should_HaveIsValidFalse_When_FailFactoryUsedWithMessages()
    {
        var result = ValidationResult.Fail("Field is required.", "Value out of range.");

        Assert.That(result.IsValid,      Is.False);
        Assert.That(result.Errors.Count, Is.EqualTo(2));
        Assert.That(result.Errors[0],    Is.EqualTo("Field is required."));
    }

    /// <summary>Should_ReturnSameInstance_When_SuccessPropertyAccessedTwice.</summary>
    [Test]
    public void Should_ReturnSameInstance_When_SuccessPropertyAccessedTwice()
    {
        Assert.That(ReferenceEquals(ValidationResult.Success, ValidationResult.Success), Is.True);
    }
}
'@

New-SourceFile $CoreTestsRoot "Tests/Models/SchemaDefinitionTests.cs" @'
// <copyright file="SchemaDefinitionTests.cs" company="Axel Johnson International">
// Copyright (c) 2026 Axel Johnson International. All rights reserved.
// </copyright>

namespace Axbus.Core.Tests.Tests.Models;

using Axbus.Core.Models.Pipeline;
using Axbus.Tests.Common.Base;
using NUnit.Framework;

/// <summary>
/// Unit tests for <see cref="SchemaDefinition"/>.
/// </summary>
[TestFixture]
public sealed class SchemaDefinitionTests : AxbusTestBase
{
    /// <summary>Should_PreserveColumnOrder_When_SchemaCreated.</summary>
    [Test]
    public void Should_PreserveColumnOrder_When_SchemaCreated()
    {
        var columns = new[] { "id", "name", "customer.city", "amount" };
        var schema  = new SchemaDefinition(columns, "csv", sourceFileCount: 2);

        Assert.That(schema.Columns.Count, Is.EqualTo(4));
        Assert.That(schema.Columns[0],    Is.EqualTo("id"));
        Assert.That(schema.Columns[2],    Is.EqualTo("customer.city"));
    }

    /// <summary>Should_StoreFormat_When_SchemaCreated.</summary>
    [Test]
    public void Should_StoreFormat_When_SchemaCreated()
    {
        var schema = new SchemaDefinition(new[] { "col1" }, "excel");
        Assert.That(schema.Format, Is.EqualTo("excel"));
    }

    /// <summary>Should_StoreSourceFileCount_When_SchemaCreated.</summary>
    [Test]
    public void Should_StoreSourceFileCount_When_SchemaCreated()
    {
        var schema = new SchemaDefinition(new[] { "col1" }, "csv", sourceFileCount: 5);
        Assert.That(schema.SourceFileCount, Is.EqualTo(5));
    }
}
'@

New-SourceFile $CoreTestsRoot "Tests/Models/FlattenedRowTests.cs" @'
// <copyright file="FlattenedRowTests.cs" company="Axel Johnson International">
// Copyright (c) 2026 Axel Johnson International. All rights reserved.
// </copyright>

namespace Axbus.Core.Tests.Tests.Models;

using Axbus.Core.Models.Pipeline;
using Axbus.Tests.Common.Base;
using NUnit.Framework;

/// <summary>
/// Unit tests for <see cref="FlattenedRow"/>.
/// </summary>
[TestFixture]
public sealed class FlattenedRowTests : AxbusTestBase
{
    /// <summary>Should_AllowCaseInsensitiveKeyLookup_When_ValuesAccessed.</summary>
    [Test]
    public void Should_AllowCaseInsensitiveKeyLookup_When_ValuesAccessed()
    {
        var row = new FlattenedRow();
        row.Values["CustomerId"] = "C001";

        Assert.That(row.Values.ContainsKey("customerid"), Is.True);
        Assert.That(row.Values["customerId"],              Is.EqualTo("C001"));
    }

    /// <summary>Should_DefaultIsExplodedToFalse_When_RowCreated.</summary>
    [Test]
    public void Should_DefaultIsExplodedToFalse_When_RowCreated()
    {
        Assert.That(new FlattenedRow().IsExploded, Is.False);
    }

    /// <summary>Should_StoreExplosionIndex_When_RowIsExploded.</summary>
    [Test]
    public void Should_StoreExplosionIndex_When_RowIsExploded()
    {
        var row = new FlattenedRow { IsExploded = true, ExplosionIndex = 3 };

        Assert.That(row.IsExploded,     Is.True);
        Assert.That(row.ExplosionIndex, Is.EqualTo(3));
    }

    /// <summary>Should_StoreMetadata_When_RowNumberAndPathSet.</summary>
    [Test]
    public void Should_StoreMetadata_When_RowNumberAndPathSet()
    {
        var row = new FlattenedRow { RowNumber = 42, SourceFilePath = @"C:\input\orders.json" };

        Assert.That(row.RowNumber,      Is.EqualTo(42));
        Assert.That(row.SourceFilePath, Is.EqualTo(@"C:\input\orders.json"));
    }
}
'@

New-SourceFile $CoreTestsRoot "Tests/Models/PluginCompatibilityTests.cs" @'
// <copyright file="PluginCompatibilityTests.cs" company="Axel Johnson International">
// Copyright (c) 2026 Axel Johnson International. All rights reserved.
// </copyright>

namespace Axbus.Core.Tests.Tests.Models;

using Axbus.Core.Models.Plugin;
using Axbus.Tests.Common.Base;
using NUnit.Framework;

/// <summary>
/// Unit tests for <see cref="PluginCompatibility"/>.
/// </summary>
[TestFixture]
public sealed class PluginCompatibilityTests : AxbusTestBase
{
    /// <summary>Should_BeCompatible_When_CompatibleFactoryUsed.</summary>
    [Test]
    public void Should_BeCompatible_When_CompatibleFactoryUsed()
    {
        var result = PluginCompatibility.Compatible;

        Assert.That(result.IsCompatible, Is.True);
        Assert.That(result.Reason,       Is.Null);
    }

    /// <summary>Should_BeIncompatible_When_IncompatibleFactoryUsedWithReason.</summary>
    [Test]
    public void Should_BeIncompatible_When_IncompatibleFactoryUsedWithReason()
    {
        var reason = "Requires framework v2.0 but current is v1.0.";
        var result = PluginCompatibility.Incompatible(reason);

        Assert.That(result.IsCompatible, Is.False);
        Assert.That(result.Reason,       Is.EqualTo(reason));
    }
}
'@

# ==============================================================================
# TEST PROJECT 3 - AXBUS.APPLICATION.TESTS
# ==============================================================================

$AppTestsRoot = "tests/Axbus.Application.Tests"
Write-Phase "Test Project 3 - Axbus.Application.Tests (5 files)"

New-SourceFile $AppTestsRoot "Tests/Middleware/TimingMiddlewareTests.cs" @'
// <copyright file="TimingMiddlewareTests.cs" company="Axel Johnson International">
// Copyright (c) 2026 Axel Johnson International. All rights reserved.
// </copyright>

namespace Axbus.Application.Tests.Tests.Middleware;

using Axbus.Application.Middleware;
using Axbus.Core.Enums;
using Axbus.Core.Models.Pipeline;
using Axbus.Tests.Common.Base;
using NUnit.Framework;

/// <summary>
/// Unit tests for <see cref="TimingMiddleware"/>.
/// </summary>
[TestFixture]
public sealed class TimingMiddlewareTests : AxbusTestBase
{
    private TimingMiddleware sut = null!;

    /// <inheritdoc/>
    public override void SetUp()
    {
        base.SetUp();
        sut = new TimingMiddleware();
    }

    /// <summary>Should_SetDurationOnResult_When_StageCompletes.</summary>
    [Test]
    public async Task Should_SetDurationOnResult_When_StageCompletes()
    {
        var context = new PipelineMiddlewareContext("M", "p", PipelineStage.Read);
        var result  = await sut.InvokeAsync(context, () => Task.FromResult(
            new PipelineStageResult { Success = true, Stage = PipelineStage.Read }));

        Assert.That(result.Duration, Is.GreaterThanOrEqualTo(TimeSpan.Zero));
    }

    /// <summary>Should_InvokeNextDelegate_When_MiddlewareExecuted.</summary>
    [Test]
    public async Task Should_InvokeNextDelegate_When_MiddlewareExecuted()
    {
        var nextInvoked = false;
        var context     = new PipelineMiddlewareContext("M", "p", PipelineStage.Parse);

        await sut.InvokeAsync(context, () =>
        {
            nextInvoked = true;
            return Task.FromResult(new PipelineStageResult { Success = true });
        });

        Assert.That(nextInvoked, Is.True);
    }

    /// <summary>Should_PassThroughFailedResult_When_NextFails.</summary>
    [Test]
    public async Task Should_PassThroughFailedResult_When_NextFails()
    {
        var context = new PipelineMiddlewareContext("M", "p", PipelineStage.Write);
        var result  = await sut.InvokeAsync(context, () => Task.FromResult(
            new PipelineStageResult { Success = false, Exception = new Exception("fail") }));

        Assert.That(result.Success, Is.False);
    }
}
'@

New-SourceFile $AppTestsRoot "Tests/Middleware/MiddlewarePipelineBuilderTests.cs" @'
// <copyright file="MiddlewarePipelineBuilderTests.cs" company="Axel Johnson International">
// Copyright (c) 2026 Axel Johnson International. All rights reserved.
// </copyright>

namespace Axbus.Application.Tests.Tests.Middleware;

using Axbus.Application.Middleware;
using Axbus.Core.Abstractions.Middleware;
using Axbus.Core.Enums;
using Axbus.Core.Models.Pipeline;
using Axbus.Tests.Common.Base;
using NUnit.Framework;

/// <summary>
/// Unit tests for <see cref="MiddlewarePipelineBuilder"/>.
/// </summary>
[TestFixture]
public sealed class MiddlewarePipelineBuilderTests : AxbusTestBase
{
    /// <summary>Should_InvokeStageAction_When_NoMiddlewareRegistered.</summary>
    [Test]
    public async Task Should_InvokeStageAction_When_NoMiddlewareRegistered()
    {
        var builder      = new MiddlewarePipelineBuilder(new List<IPipelineMiddleware>());
        var context      = new PipelineMiddlewareContext("M", "p", PipelineStage.Read);
        var actionCalled = false;

        await builder.ExecuteAsync(context, () =>
        {
            actionCalled = true;
            return Task.FromResult(new PipelineStageResult { Success = true });
        });

        Assert.That(actionCalled, Is.True);
    }

    /// <summary>Should_InvokeMiddlewareOutermostFirst_When_MultipleRegistered.</summary>
    [Test]
    public async Task Should_InvokeMiddlewareOutermostFirst_When_MultipleRegistered()
    {
        var order   = new List<int>();
        var builder = new MiddlewarePipelineBuilder(new[]
        {
            new OrderRecordingMiddleware(1, order),
            new OrderRecordingMiddleware(2, order),
        });

        await builder.ExecuteAsync(
            new PipelineMiddlewareContext("M", "p", PipelineStage.Transform),
            () => Task.FromResult(new PipelineStageResult { Success = true }));

        Assert.That(order[0], Is.EqualTo(1));
        Assert.That(order[1], Is.EqualTo(2));
    }

    private sealed class OrderRecordingMiddleware : IPipelineMiddleware
    {
        private readonly int id;
        private readonly List<int> order;

        public OrderRecordingMiddleware(int id, List<int> order)
        { this.id = id; this.order = order; }

        public async Task<PipelineStageResult> InvokeAsync(
            IPipelineMiddlewareContext context, PipelineStageDelegate next)
        {
            order.Add(id);
            return await next();
        }
    }
}
'@

New-SourceFile $AppTestsRoot "Tests/Plugin/PluginRegistryTests.cs" @'
// <copyright file="PluginRegistryTests.cs" company="Axel Johnson International">
// Copyright (c) 2026 Axel Johnson International. All rights reserved.
// </copyright>

namespace Axbus.Application.Tests.Tests.Plugin;

using Axbus.Application.Plugin;
using Axbus.Core.Abstractions.Pipeline;
using Axbus.Core.Abstractions.Plugin;
using Axbus.Core.Enums;
using Axbus.Core.Exceptions;
using Axbus.Core.Models.Configuration;
using Axbus.Core.Models.Plugin;
using Axbus.Tests.Common.Base;
using Microsoft.Extensions.Options;
using NUnit.Framework;

/// <summary>
/// Unit tests for <see cref="PluginRegistry"/>.
/// </summary>
[TestFixture]
public sealed class PluginRegistryTests : AxbusTestBase
{
    private PluginRegistry sut = null!;

    /// <inheritdoc/>
    public override void SetUp()
    {
        base.SetUp();
        var settings = new AxbusRootSettings
        {
            PluginSettings = new PluginSettings
            {
                ConflictStrategy = PluginConflictStrategy.UseLatestVersion,
            },
        };
        sut = new PluginRegistry(NullLogger<PluginRegistry>(), Options.Create(settings));
    }

    /// <summary>Should_ResolvePlugin_When_PluginRegisteredForFormatPair.</summary>
    [Test]
    public void Should_ResolvePlugin_When_PluginRegisteredForFormatPair()
    {
        sut.Register(BuildDescriptor("test.reader.json", "json", null));
        var plugin = sut.Resolve("json", string.Empty);
        Assert.That(plugin.PluginId, Is.EqualTo("test.reader.json"));
    }

    /// <summary>Should_ResolvePluginById_When_ExplicitIdProvided.</summary>
    [Test]
    public void Should_ResolvePluginById_When_ExplicitIdProvided()
    {
        sut.Register(BuildDescriptor("axbus.plugin.writer.csv", null, "csv"));
        var plugin = sut.ResolveById("axbus.plugin.writer.csv");
        Assert.That(plugin.PluginId, Is.EqualTo("axbus.plugin.writer.csv"));
    }

    /// <summary>Should_ThrowPluginException_When_NoPluginForFormat.</summary>
    [Test]
    public void Should_ThrowPluginException_When_NoPluginForFormat()
    {
        Assert.Throws<AxbusPluginException>(() => sut.Resolve("xml", "csv"));
    }

    /// <summary>Should_ThrowPluginException_When_PluginIdNotRegistered.</summary>
    [Test]
    public void Should_ThrowPluginException_When_PluginIdNotRegistered()
    {
        Assert.Throws<AxbusPluginException>(() => sut.ResolveById("non.existent"));
    }

    /// <summary>Should_ReturnAllDescriptors_When_GetAllCalled.</summary>
    [Test]
    public void Should_ReturnAllDescriptors_When_GetAllCalled()
    {
        sut.Register(BuildDescriptor("plugin.a", "json", null));
        sut.Register(BuildDescriptor("plugin.b", null, "csv"));
        Assert.That(sut.GetAll().Count, Is.EqualTo(2));
    }

    private static PluginDescriptor BuildDescriptor(string pluginId, string? source, string? target) =>
        new()
        {
            Instance = new StubPlugin(pluginId),
            Manifest = new PluginManifest
            {
                PluginId = pluginId, SourceFormat = source,
                TargetFormat = target, Version = "1.0.0", FrameworkVersion = "1.0.0",
            },
            Assembly  = typeof(PluginRegistryTests).Assembly,
            IsIsolated = false,
        };

    private sealed class StubPlugin : IPlugin
    {
        public string PluginId { get; }
        public string Name => PluginId;
        public Version Version => new(1, 0, 0);
        public Version MinFrameworkVersion => new(1, 0, 0);
        public PluginCapabilities Capabilities => PluginCapabilities.Reader;

        public StubPlugin(string id) => PluginId = id;

        public ISourceReader?    CreateReader(IServiceProvider s)      => null;
        public IFormatParser?    CreateParser(IServiceProvider s)      => null;
        public IDataTransformer? CreateTransformer(IServiceProvider s) => null;
        public IOutputWriter?    CreateWriter(IServiceProvider s)      => null;
        public Task InitializeAsync(IPluginContext ctx, CancellationToken ct) => Task.CompletedTask;
        public Task ShutdownAsync(CancellationToken ct) => Task.CompletedTask;
    }
}
'@

New-SourceFile $AppTestsRoot "Tests/Notifications/ProgressReporterTests.cs" @'
// <copyright file="ProgressReporterTests.cs" company="Axel Johnson International">
// Copyright (c) 2026 Axel Johnson International. All rights reserved.
// </copyright>

namespace Axbus.Application.Tests.Tests.Notifications;

using Axbus.Application.Notifications;
using Axbus.Core.Enums;
using Axbus.Core.Models.Notifications;
using Axbus.Tests.Common.Base;
using NUnit.Framework;

/// <summary>
/// Unit tests for <see cref="ProgressReporter"/>.
/// </summary>
[TestFixture]
public sealed class ProgressReporterTests : AxbusTestBase
{
    private ProgressReporter sut = null!;

    /// <inheritdoc/>
    public override void SetUp() { base.SetUp(); sut = new ProgressReporter(); }

    /// <summary>Should_DeliverProgress_When_ConsumerRegistered.</summary>
    [Test]
    public void Should_DeliverProgress_When_ConsumerRegistered()
    {
        ConversionProgress? received = null;
        sut.Register(new Progress<ConversionProgress>(p => received = p));
        sut.Report(new ConversionProgress { ModuleName = "M", PercentComplete = 50 });

        Assert.That(received,                 Is.Not.Null);
        Assert.That(received!.ModuleName,     Is.EqualTo("M"));
        Assert.That(received.PercentComplete, Is.EqualTo(50));
    }

    /// <summary>Should_DeliverToAll_When_MultipleConsumersRegistered.</summary>
    [Test]
    public void Should_DeliverToAll_When_MultipleConsumersRegistered()
    {
        var count = 0;
        sut.Register(new Progress<ConversionProgress>(_ => count++));
        sut.Register(new Progress<ConversionProgress>(_ => count++));
        sut.Report(new ConversionProgress { ModuleName = "M" });

        Assert.That(count, Is.EqualTo(2));
    }

    /// <summary>Should_NotThrow_When_NoConsumersRegistered.</summary>
    [Test]
    public void Should_NotThrow_When_NoConsumersRegistered()
    {
        Assert.DoesNotThrow(() => sut.Report(new ConversionProgress { ModuleName = "M" }));
    }
}
'@

New-SourceFile $AppTestsRoot "Tests/Plugin/PluginManifestReaderTests.cs" @'
// <copyright file="PluginManifestReaderTests.cs" company="Axel Johnson International">
// Copyright (c) 2026 Axel Johnson International. All rights reserved.
// </copyright>

namespace Axbus.Application.Tests.Tests.Plugin;

using System.Text;
using Axbus.Application.Plugin;
using Axbus.Core.Exceptions;
using Axbus.Tests.Common.Base;
using NUnit.Framework;

/// <summary>
/// Unit tests for <see cref="PluginManifestReader"/>.
/// </summary>
[TestFixture]
public sealed class PluginManifestReaderTests : AxbusTestBase
{
    private PluginManifestReader sut     = null!;
    private string               tempDir = null!;

    /// <inheritdoc/>
    public override void SetUp()
    {
        base.SetUp();
        sut     = new PluginManifestReader(NullLogger<PluginManifestReader>());
        tempDir = Path.Combine(Path.GetTempPath(), Path.GetRandomFileName());
        Directory.CreateDirectory(tempDir);
    }

    /// <inheritdoc/>
    public override void TearDown()
    {
        base.TearDown();
        if (Directory.Exists(tempDir)) Directory.Delete(tempDir, recursive: true);
    }

    /// <summary>Should_DeserialiseManifest_When_ValidJsonProvided.</summary>
    [Test]
    public async Task Should_DeserialiseManifest_When_ValidJsonProvided()
    {
        var path = Path.Combine(tempDir, "test.manifest.json");
        var json = """
            {
                "Name": "TestPlugin", "PluginId": "test.plugin",
                "Version": "1.0.0", "FrameworkVersion": "1.0.0",
                "SourceFormat": "json", "TargetFormat": null,
                "SupportedStages": ["Read","Parse"],
                "IsBundled": false, "Author": "AJI",
                "Description": "Test", "Dependencies": []
            }
            """;

        await File.WriteAllTextAsync(path, json, Encoding.UTF8);
        var manifest = await sut.ReadAsync(path, CancellationToken.None);

        Assert.That(manifest.Name,     Is.EqualTo("TestPlugin"));
        Assert.That(manifest.PluginId, Is.EqualTo("test.plugin"));
        Assert.That(manifest.SupportedStages.Count, Is.EqualTo(2));
    }

    /// <summary>Should_ThrowPluginException_When_FileNotFound.</summary>
    [Test]
    public void Should_ThrowPluginException_When_FileNotFound()
    {
        Assert.ThrowsAsync<AxbusPluginException>(async () =>
            await sut.ReadAsync(Path.Combine(tempDir, "missing.json"), CancellationToken.None));
    }

    /// <summary>Should_ThrowPluginException_When_InvalidJsonInManifest.</summary>
    [Test]
    public async Task Should_ThrowPluginException_When_InvalidJsonInManifest()
    {
        var path = Path.Combine(tempDir, "bad.manifest.json");
        await File.WriteAllTextAsync(path, "{ invalid }", Encoding.UTF8);

        Assert.ThrowsAsync<AxbusPluginException>(async () =>
            await sut.ReadAsync(path, CancellationToken.None));
    }
}
'@

# ==============================================================================
# TEST PROJECT 4 - AXBUS.INFRASTRUCTURE.TESTS
# ==============================================================================

$InfraTestsRoot = "tests/Axbus.Infrastructure.Tests"
Write-Phase "Test Project 4 - Axbus.Infrastructure.Tests (4 files)"

New-SourceFile $InfraTestsRoot "Tests/FileSystem/FileSystemScannerTests.cs" @'
// <copyright file="FileSystemScannerTests.cs" company="Axel Johnson International">
// Copyright (c) 2026 Axel Johnson International. All rights reserved.
// </copyright>

namespace Axbus.Infrastructure.Tests.Tests.FileSystem;

using Axbus.Infrastructure.FileSystem;
using Axbus.Tests.Common.Base;
using NUnit.Framework;

/// <summary>
/// Unit tests for <see cref="FileSystemScanner"/>.
/// </summary>
[TestFixture]
public sealed class FileSystemScannerTests : AxbusTestBase
{
    private FileSystemScanner sut     = null!;
    private string            tempDir = null!;

    /// <inheritdoc/>
    public override void SetUp()
    {
        base.SetUp();
        sut     = new FileSystemScanner(NullLogger<FileSystemScanner>());
        tempDir = Path.Combine(Path.GetTempPath(), Path.GetRandomFileName());
        Directory.CreateDirectory(tempDir);
    }

    /// <inheritdoc/>
    public override void TearDown()
    {
        base.TearDown();
        if (Directory.Exists(tempDir)) Directory.Delete(tempDir, recursive: true);
    }

    /// <summary>Should_ReturnMatchingFiles_When_PatternMatches.</summary>
    [Test]
    public void Should_ReturnMatchingFiles_When_PatternMatches()
    {
        File.WriteAllText(Path.Combine(tempDir, "a.json"), "[]");
        File.WriteAllText(Path.Combine(tempDir, "b.json"), "[]");
        File.WriteAllText(Path.Combine(tempDir, "c.txt"),  "text");

        var results = sut.Scan(tempDir, "*.json").ToList();

        Assert.That(results.Count,                         Is.EqualTo(2));
        Assert.That(results.All(f => f.EndsWith(".json")), Is.True);
    }

    /// <summary>Should_ReturnEmpty_When_FolderDoesNotExist.</summary>
    [Test]
    public void Should_ReturnEmpty_When_FolderDoesNotExist()
    {
        Assert.That(sut.Scan(Path.Combine(tempDir, "missing"), "*.json"), Is.Empty);
    }

    /// <summary>Should_ReturnFilesInAlphaOrder_When_MultipleFilesPresent.</summary>
    [Test]
    public void Should_ReturnFilesInAlphaOrder_When_MultipleFilesPresent()
    {
        File.WriteAllText(Path.Combine(tempDir, "c.json"), "[]");
        File.WriteAllText(Path.Combine(tempDir, "a.json"), "[]");
        File.WriteAllText(Path.Combine(tempDir, "b.json"), "[]");

        var results = sut.Scan(tempDir, "*.json").ToList();

        Assert.That(Path.GetFileName(results[0]), Is.EqualTo("a.json"));
        Assert.That(Path.GetFileName(results[2]), Is.EqualTo("c.json"));
    }

    /// <summary>Should_ReturnEmpty_When_NoFilesMatchPattern.</summary>
    [Test]
    public void Should_ReturnEmpty_When_NoFilesMatchPattern()
    {
        File.WriteAllText(Path.Combine(tempDir, "a.csv"), "data");
        Assert.That(sut.Scan(tempDir, "*.json"), Is.Empty);
    }
}
'@

New-SourceFile $InfraTestsRoot "Tests/FileSystem/PluginFolderScannerTests.cs" @'
// <copyright file="PluginFolderScannerTests.cs" company="Axel Johnson International">
// Copyright (c) 2026 Axel Johnson International. All rights reserved.
// </copyright>

namespace Axbus.Infrastructure.Tests.Tests.FileSystem;

using Axbus.Infrastructure.FileSystem;
using Axbus.Tests.Common.Base;
using NUnit.Framework;

/// <summary>
/// Unit tests for <see cref="PluginFolderScanner"/>.
/// </summary>
[TestFixture]
public sealed class PluginFolderScannerTests : AxbusTestBase
{
    private PluginFolderScanner sut     = null!;
    private string              tempDir = null!;

    /// <inheritdoc/>
    public override void SetUp()
    {
        base.SetUp();
        sut     = new PluginFolderScanner(NullLogger<PluginFolderScanner>());
        tempDir = Path.Combine(Path.GetTempPath(), Path.GetRandomFileName());
        Directory.CreateDirectory(tempDir);
    }

    /// <inheritdoc/>
    public override void TearDown()
    {
        base.TearDown();
        if (Directory.Exists(tempDir)) Directory.Delete(tempDir, recursive: true);
    }

    /// <summary>Should_ReturnFileSet_When_DllAndManifestPresent.</summary>
    [Test]
    public void Should_ReturnFileSet_When_DllAndManifestPresent()
    {
        File.WriteAllText(Path.Combine(tempDir, "MyPlugin.dll"),           "fake");
        File.WriteAllText(Path.Combine(tempDir, "MyPlugin.manifest.json"), "{}");

        var results = sut.Scan(tempDir, scanSubFolders: false).ToList();

        Assert.That(results.Count,                                     Is.EqualTo(1));
        Assert.That(Path.GetFileName(results[0].AssemblyPath),         Is.EqualTo("MyPlugin.dll"));
        Assert.That(File.Exists(results[0].ManifestPath),              Is.True);
    }

    /// <summary>Should_SkipDll_When_ManifestMissing.</summary>
    [Test]
    public void Should_SkipDll_When_ManifestMissing()
    {
        File.WriteAllText(Path.Combine(tempDir, "OrphanPlugin.dll"), "fake");
        Assert.That(sut.Scan(tempDir, scanSubFolders: false), Is.Empty);
    }

    /// <summary>Should_ReturnEmpty_When_FolderNotFound.</summary>
    [Test]
    public void Should_ReturnEmpty_When_FolderNotFound()
    {
        Assert.That(sut.Scan(Path.Combine(tempDir, "missing"), scanSubFolders: false), Is.Empty);
    }
}
'@

New-SourceFile $InfraTestsRoot "Tests/Connectors/LocalFileTargetConnectorTests.cs" @'
// <copyright file="LocalFileTargetConnectorTests.cs" company="Axel Johnson International">
// Copyright (c) 2026 Axel Johnson International. All rights reserved.
// </copyright>

namespace Axbus.Infrastructure.Tests.Tests.Connectors;

using System.Text;
using Axbus.Core.Models.Configuration;
using Axbus.Infrastructure.Connectors;
using Axbus.Tests.Common.Base;
using NUnit.Framework;

/// <summary>
/// Unit tests for <see cref="LocalFileTargetConnector"/>.
/// </summary>
[TestFixture]
public sealed class LocalFileTargetConnectorTests : AxbusTestBase
{
    private LocalFileTargetConnector sut     = null!;
    private string                   tempDir = null!;

    /// <inheritdoc/>
    public override void SetUp()
    {
        base.SetUp();
        sut     = new LocalFileTargetConnector(NullLogger<LocalFileTargetConnector>());
        tempDir = Path.Combine(Path.GetTempPath(), Path.GetRandomFileName());
        Directory.CreateDirectory(tempDir);
    }

    /// <inheritdoc/>
    public override void TearDown()
    {
        base.TearDown();
        if (Directory.Exists(tempDir)) Directory.Delete(tempDir, recursive: true);
    }

    /// <summary>Should_WriteFile_When_ValidStreamProvided.</summary>
    [Test]
    public async Task Should_WriteFile_When_ValidStreamProvided()
    {
        var content = "id,name\n1,Test";
        var data    = new MemoryStream(Encoding.UTF8.GetBytes(content));
        var options = new TargetOptions { Path = tempDir };

        var outputPath = await sut.WriteAsync(data, "output.csv", options, CancellationToken.None);

        Assert.That(File.Exists(outputPath), Is.True);
        Assert.That(await File.ReadAllTextAsync(outputPath), Is.EqualTo(content));
    }

    /// <summary>Should_CreateDirectory_When_TargetFolderMissing.</summary>
    [Test]
    public async Task Should_CreateDirectory_When_TargetFolderMissing()
    {
        var newFolder = Path.Combine(tempDir, "new_sub");
        var data      = new MemoryStream(Encoding.UTF8.GetBytes("data"));
        var options   = new TargetOptions { Path = newFolder };

        await sut.WriteAsync(data, "file.csv", options, CancellationToken.None);

        Assert.That(Directory.Exists(newFolder), Is.True);
    }

    /// <summary>Should_ReturnFullOutputPath_When_WriteSucceeds.</summary>
    [Test]
    public async Task Should_ReturnFullOutputPath_When_WriteSucceeds()
    {
        var data    = new MemoryStream(Encoding.UTF8.GetBytes("test"));
        var options = new TargetOptions { Path = tempDir };

        var result = await sut.WriteAsync(data, "result.csv", options, CancellationToken.None);

        Assert.That(result, Is.EqualTo(Path.Combine(tempDir, "result.csv")));
    }
}
'@

New-SourceFile $InfraTestsRoot "Tests/Connectors/LocalFileSourceConnectorTests.cs" @'
// <copyright file="LocalFileSourceConnectorTests.cs" company="Axel Johnson International">
// Copyright (c) 2026 Axel Johnson International. All rights reserved.
// </copyright>

namespace Axbus.Infrastructure.Tests.Tests.Connectors;

using Axbus.Core.Exceptions;
using Axbus.Core.Models.Configuration;
using Axbus.Infrastructure.Connectors;
using Axbus.Tests.Common.Base;
using NUnit.Framework;

/// <summary>
/// Unit tests for <see cref="LocalFileSourceConnector"/>.
/// </summary>
[TestFixture]
public sealed class LocalFileSourceConnectorTests : AxbusTestBase
{
    private LocalFileSourceConnector sut     = null!;
    private string                   tempDir = null!;

    /// <inheritdoc/>
    public override void SetUp()
    {
        base.SetUp();
        sut     = new LocalFileSourceConnector(NullLogger<LocalFileSourceConnector>());
        tempDir = Path.Combine(Path.GetTempPath(), Path.GetRandomFileName());
        Directory.CreateDirectory(tempDir);
    }

    /// <inheritdoc/>
    public override void TearDown()
    {
        base.TearDown();
        if (Directory.Exists(tempDir)) Directory.Delete(tempDir, recursive: true);
    }

    /// <summary>Should_ReturnOneStreamPerFile_When_AllFilesMode.</summary>
    [Test]
    public async Task Should_ReturnOneStreamPerFile_When_AllFilesMode()
    {
        File.WriteAllText(Path.Combine(tempDir, "a.json"), "[{}]");
        File.WriteAllText(Path.Combine(tempDir, "b.json"), "[{}]");

        var options = new SourceOptions { Path = tempDir, FilePattern = "*.json", ReadMode = "AllFiles" };
        var streams = new List<Stream>();

        await foreach (var s in sut.GetSourceStreamsAsync(options, CancellationToken.None))
            streams.Add(s);

        foreach (var s in streams) s.Dispose();

        Assert.That(streams.Count, Is.EqualTo(2));
    }

    /// <summary>Should_ThrowConnectorException_When_FolderMissing.</summary>
    [Test]
    public void Should_ThrowConnectorException_When_FolderMissing()
    {
        var options = new SourceOptions
        {
            Path     = Path.Combine(tempDir, "nonexistent"),
            ReadMode = "AllFiles",
        };

        Assert.ThrowsAsync<AxbusConnectorException>(async () =>
        {
            await foreach (var _ in sut.GetSourceStreamsAsync(options, CancellationToken.None)) { }
        });
    }
}
'@

# ==============================================================================
# TEST PROJECT 5 - AXBUS.PLUGIN.READER.JSON.TESTS
# ==============================================================================

$JsonTestsRoot = "tests/Axbus.Plugin.Reader.Json.Tests"
Write-Phase "Test Project 5 - Axbus.Plugin.Reader.Json.Tests (5 files)"

New-SourceFile $JsonTestsRoot "Tests/Reader/JsonSourceReaderTests.cs" @'
// <copyright file="JsonSourceReaderTests.cs" company="Axel Johnson International">
// Copyright (c) 2026 Axel Johnson International. All rights reserved.
// </copyright>

namespace Axbus.Plugin.Reader.Json.Tests.Tests.Reader;

using Axbus.Core.Exceptions;
using Axbus.Core.Models.Configuration;
using Axbus.Plugin.Reader.Json.Reader;
using Axbus.Tests.Common.Base;
using NUnit.Framework;

/// <summary>
/// Unit tests for <see cref="JsonSourceReader"/>.
/// </summary>
[TestFixture]
public sealed class JsonSourceReaderTests : AxbusTestBase
{
    private JsonSourceReader sut     = null!;
    private string           tempDir = null!;

    /// <inheritdoc/>
    public override void SetUp()
    {
        base.SetUp();
        sut     = new JsonSourceReader(NullLogger<JsonSourceReader>());
        tempDir = Path.Combine(Path.GetTempPath(), Path.GetRandomFileName());
        Directory.CreateDirectory(tempDir);
    }

    /// <inheritdoc/>
    public override void TearDown()
    {
        base.TearDown();
        if (Directory.Exists(tempDir)) Directory.Delete(tempDir, recursive: true);
    }

    /// <summary>Should_ReturnSourceData_When_JsonFileExists.</summary>
    [Test]
    public async Task Should_ReturnSourceData_When_JsonFileExists()
    {
        var filePath = Path.Combine(tempDir, "test.json");
        await File.WriteAllTextAsync(filePath, "[{\"id\":1}]");

        var sourceData = await sut.ReadAsync(new SourceOptions { Path = filePath }, CancellationToken.None);

        Assert.That(sourceData.Format,        Is.EqualTo("json"));
        Assert.That(sourceData.SourcePath,    Is.EqualTo(filePath));
        Assert.That(sourceData.ContentLength, Is.GreaterThan(0));

        await sourceData.RawData.DisposeAsync();
    }

    /// <summary>Should_ThrowConnectorException_When_FileNotFound.</summary>
    [Test]
    public void Should_ThrowConnectorException_When_FileNotFound()
    {
        Assert.ThrowsAsync<AxbusConnectorException>(async () =>
            await sut.ReadAsync(
                new SourceOptions { Path = Path.Combine(tempDir, "missing.json") },
                CancellationToken.None));
    }
}
'@

New-SourceFile $JsonTestsRoot "Tests/Parser/JsonFormatParserTests.cs" @'
// <copyright file="JsonFormatParserTests.cs" company="Axel Johnson International">
// Copyright (c) 2026 Axel Johnson International. All rights reserved.
// </copyright>

namespace Axbus.Plugin.Reader.Json.Tests.Tests.Parser;

using System.Text.Json;
using Axbus.Core.Exceptions;
using Axbus.Core.Models.Pipeline;
using Axbus.Plugin.Reader.Json.Options;
using Axbus.Plugin.Reader.Json.Parser;
using Axbus.Tests.Common.Base;
using Axbus.Tests.Common.Helpers;
using NUnit.Framework;

/// <summary>
/// Unit tests for <see cref="JsonFormatParser"/>.
/// </summary>
[TestFixture]
public sealed class JsonFormatParserTests : AxbusTestBase
{
    private JsonFormatParser CreateSut(string? rootArrayKey = null) =>
        new(NullLogger<JsonFormatParser>(), new JsonReaderPluginOptions { RootArrayKey = rootArrayKey });

    /// <summary>Should_StreamAllElements_When_FlatArrayParsed.</summary>
    [Test]
    public async Task Should_StreamAllElements_When_FlatArrayParsed()
    {
        var sourceData = new SourceData(JsonTestDataHelper.FlatArray(3), "test.json", "json");
        var parsed     = await CreateSut().ParseAsync(sourceData, CancellationToken.None);
        var elements   = new List<JsonElement>();

        await foreach (var el in parsed.Elements) elements.Add(el);

        Assert.That(elements.Count, Is.EqualTo(3));
    }

    /// <summary>Should_ReturnEmptyStream_When_EmptyArray.</summary>
    [Test]
    public async Task Should_ReturnEmptyStream_When_EmptyArray()
    {
        var sourceData = new SourceData(JsonTestDataHelper.EmptyArray(), "empty.json", "json");
        var parsed     = await CreateSut().ParseAsync(sourceData, CancellationToken.None);
        var elements   = new List<JsonElement>();

        await foreach (var el in parsed.Elements) elements.Add(el);

        Assert.That(elements, Is.Empty);
    }

    /// <summary>Should_ThrowPipelineException_When_InvalidJson.</summary>
    [Test]
    public async Task Should_ThrowPipelineException_When_InvalidJson()
    {
        var sourceData = new SourceData(JsonTestDataHelper.InvalidJson(), "bad.json", "json");
        var parsed     = await CreateSut().ParseAsync(sourceData, CancellationToken.None);

        Assert.ThrowsAsync<AxbusPipelineException>(async () =>
        {
            await foreach (var _ in parsed.Elements) { }
        });
    }

    /// <summary>Should_DrillIntoKey_When_RootArrayKeyConfigured.</summary>
    [Test]
    public async Task Should_DrillIntoKey_When_RootArrayKeyConfigured()
    {
        var json       = "{\"items\":[{\"id\":1},{\"id\":2}]}";
        var sourceData = new SourceData(JsonTestDataHelper.ToStream(json), "test.json", "json");
        var parsed     = await CreateSut(rootArrayKey: "items").ParseAsync(sourceData, CancellationToken.None);
        var elements   = new List<JsonElement>();

        await foreach (var el in parsed.Elements) elements.Add(el);

        Assert.That(elements.Count, Is.EqualTo(2));
    }
}
'@

New-SourceFile $JsonTestsRoot "Tests/Transformer/JsonDataTransformerTests.cs" @'
// <copyright file="JsonDataTransformerTests.cs" company="Axel Johnson International">
// Copyright (c) 2026 Axel Johnson International. All rights reserved.
// </copyright>

namespace Axbus.Plugin.Reader.Json.Tests.Tests.Transformer;

using Axbus.Core.Models.Configuration;
using Axbus.Core.Models.Pipeline;
using Axbus.Plugin.Reader.Json.Options;
using Axbus.Plugin.Reader.Json.Parser;
using Axbus.Plugin.Reader.Json.Transformer;
using Axbus.Tests.Common.Assertions;
using Axbus.Tests.Common.Base;
using Axbus.Tests.Common.Helpers;
using NUnit.Framework;

/// <summary>
/// Unit tests for <see cref="JsonDataTransformer"/>.
/// </summary>
[TestFixture]
public sealed class JsonDataTransformerTests : AxbusTestBase
{
    private JsonFormatParser    parser      = null!;
    private JsonDataTransformer transformer = null!;

    /// <inheritdoc/>
    public override void SetUp()
    {
        base.SetUp();
        var opts    = new JsonReaderPluginOptions { MaxExplosionDepth = 3 };
        parser      = new JsonFormatParser(NullLogger<JsonFormatParser>(), opts);
        transformer = new JsonDataTransformer(NullLogger<JsonDataTransformer>(), opts);
    }

    /// <summary>Should_ProduceFlatRows_When_JsonIsFlatArray.</summary>
    [Test]
    public async Task Should_ProduceFlatRows_When_JsonIsFlatArray()
    {
        var sd   = new SourceData(JsonTestDataHelper.FlatArray(3), "flat.json", "json");
        var pd   = await parser.ParseAsync(sd, CancellationToken.None);
        var td   = await transformer.TransformAsync(pd, new PipelineOptions(), CancellationToken.None);
        var rows = await FlattenedRowAssertions.CollectAsync(td.Rows);

        FlattenedRowAssertions.HasCount(rows, 3);
        FlattenedRowAssertions.AllHaveColumn(rows, "id");
    }

    /// <summary>Should_UseDotNotation_When_JsonHasNestedObjects.</summary>
    [Test]
    public async Task Should_UseDotNotation_When_JsonHasNestedObjects()
    {
        var sd   = new SourceData(JsonTestDataHelper.NestedArray(1), "nested.json", "json");
        var pd   = await parser.ParseAsync(sd, CancellationToken.None);
        var td   = await transformer.TransformAsync(pd, new PipelineOptions(), CancellationToken.None);
        var rows = await FlattenedRowAssertions.CollectAsync(td.Rows);

        FlattenedRowAssertions.HasCount(rows, 1);
        FlattenedRowAssertions.AllHaveColumn(rows, "customer.address.city");
    }

    /// <summary>Should_ExplodeArray_When_NestedArrayPresent.</summary>
    [Test]
    public async Task Should_ExplodeArray_When_NestedArrayPresent()
    {
        var sd   = new SourceData(JsonTestDataHelper.ArrayForExplosion(3), "arr.json", "json");
        var pd   = await parser.ParseAsync(sd, CancellationToken.None);
        var td   = await transformer.TransformAsync(pd, new PipelineOptions(), CancellationToken.None);
        var rows = await FlattenedRowAssertions.CollectAsync(td.Rows);

        Assert.That(rows.Count,                Is.EqualTo(3));
        Assert.That(rows.All(r => r.IsExploded), Is.True);
    }

    /// <summary>Should_ProduceNoRows_When_EmptyArray.</summary>
    [Test]
    public async Task Should_ProduceNoRows_When_EmptyArray()
    {
        var sd   = new SourceData(JsonTestDataHelper.EmptyArray(), "empty.json", "json");
        var pd   = await parser.ParseAsync(sd, CancellationToken.None);
        var td   = await transformer.TransformAsync(pd, new PipelineOptions(), CancellationToken.None);
        var rows = await FlattenedRowAssertions.CollectAsync(td.Rows);

        Assert.That(rows, Is.Empty);
    }
}
'@

New-SourceFile $JsonTestsRoot "Tests/Plugin/JsonReaderPluginTests.cs" @'
// <copyright file="JsonReaderPluginTests.cs" company="Axel Johnson International">
// Copyright (c) 2026 Axel Johnson International. All rights reserved.
// </copyright>

namespace Axbus.Plugin.Reader.Json.Tests.Tests.Plugin;

using Axbus.Core.Enums;
using Axbus.Tests.Common.Base;
using NUnit.Framework;

/// <summary>
/// Unit tests for <see cref="JsonReaderPlugin"/>.
/// </summary>
[TestFixture]
public sealed class JsonReaderPluginTests : AxbusTestBase
{
    private JsonReaderPlugin sut = null!;

    /// <inheritdoc/>
    public override void SetUp() { base.SetUp(); sut = new JsonReaderPlugin(); }

    /// <summary>Should_HaveCorrectPluginId.</summary>
    [Test]
    public void Should_HaveCorrectPluginId()
    {
        Assert.That(sut.PluginId, Is.EqualTo("axbus.plugin.reader.json"));
    }

    /// <summary>Should_DeclareReaderParserTransformer_When_CapabilitiesInspected.</summary>
    [Test]
    public void Should_DeclareReaderParserTransformer_When_CapabilitiesInspected()
    {
        Assert.That(sut.Capabilities.HasFlag(PluginCapabilities.Reader),      Is.True);
        Assert.That(sut.Capabilities.HasFlag(PluginCapabilities.Parser),      Is.True);
        Assert.That(sut.Capabilities.HasFlag(PluginCapabilities.Transformer), Is.True);
        Assert.That(sut.Capabilities.HasFlag(PluginCapabilities.Writer),      Is.False);
    }

    /// <summary>Should_ReturnNullWriter_When_CreateWriterCalled.</summary>
    [Test]
    public void Should_ReturnNullWriter_When_CreateWriterCalled()
    {
        Assert.That(sut.CreateWriter(Services), Is.Null);
    }

    /// <summary>Should_ReturnNonNullStages_When_SupportedFactoriesCalled.</summary>
    [Test]
    public void Should_ReturnNonNullStages_When_SupportedFactoriesCalled()
    {
        Assert.That(sut.CreateReader(Services),      Is.Not.Null);
        Assert.That(sut.CreateParser(Services),      Is.Not.Null);
        Assert.That(sut.CreateTransformer(Services), Is.Not.Null);
    }
}
'@

New-SourceFile $JsonTestsRoot "Tests/Transformer/JsonArrayExploderTests.cs" @'
// <copyright file="JsonArrayExploderTests.cs" company="Axel Johnson International">
// Copyright (c) 2026 Axel Johnson International. All rights reserved.
// </copyright>

namespace Axbus.Plugin.Reader.Json.Tests.Tests.Transformer;

using System.Text.Json;
using Axbus.Tests.Common.Assertions;
using Axbus.Tests.Common.Base;
using NUnit.Framework;

/// <summary>
/// Unit tests for <see cref="Axbus.Plugin.Reader.Json.Transformer.JsonArrayExploder"/>.
/// </summary>
[TestFixture]
public sealed class JsonArrayExploderTests : AxbusTestBase
{
    /// <summary>Should_ProduceSingleRow_When_NoArraysPresent.</summary>
    [Test]
    public void Should_ProduceSingleRow_When_NoArraysPresent()
    {
        var element = JsonDocument.Parse("{\"id\":\"1\",\"name\":\"Test\"}").RootElement;
        var rows    = Axbus.Plugin.Reader.Json.Transformer.JsonArrayExploder.Explode(
            element, new Dictionary<string, string>(), string.Empty, 3, 0, "t.json", 1, string.Empty).ToList();

        Assert.That(rows.Count, Is.EqualTo(1));
        FlattenedRowAssertions.HasValue(rows[0], "id",   "1");
        FlattenedRowAssertions.HasValue(rows[0], "name", "Test");
    }

    /// <summary>Should_FlattenNestedObject_When_DotNotationApplied.</summary>
    [Test]
    public void Should_FlattenNestedObject_When_DotNotationApplied()
    {
        var element = JsonDocument.Parse("{\"customer\":{\"name\":\"Acme\",\"city\":\"Stockholm\"}}").RootElement;
        var rows    = Axbus.Plugin.Reader.Json.Transformer.JsonArrayExploder.Explode(
            element, new Dictionary<string, string>(), string.Empty, 3, 0, "t.json", 1, string.Empty).ToList();

        Assert.That(rows.Count, Is.EqualTo(1));
        FlattenedRowAssertions.HasValue(rows[0], "customer.name", "Acme");
        FlattenedRowAssertions.HasValue(rows[0], "customer.city", "Stockholm");
    }

    /// <summary>Should_ExplodeArray_When_NestedArrayPresent.</summary>
    [Test]
    public void Should_ExplodeArray_When_NestedArrayPresent()
    {
        var element = JsonDocument.Parse("{\"id\":\"O1\",\"lines\":[{\"sku\":\"A\"},{\"sku\":\"B\"}]}").RootElement;
        var rows    = Axbus.Plugin.Reader.Json.Transformer.JsonArrayExploder.Explode(
            element, new Dictionary<string, string>(), string.Empty, 3, 0, "t.json", 1, string.Empty).ToList();

        Assert.That(rows.Count,              Is.EqualTo(2));
        Assert.That(rows.All(r => r.IsExploded), Is.True);
    }
}
'@

# ==============================================================================
# TEST PROJECT 6 - AXBUS.PLUGIN.WRITER.CSV.TESTS
# ==============================================================================

$CsvTestsRoot = "tests/Axbus.Plugin.Writer.Csv.Tests"
Write-Phase "Test Project 6 - Axbus.Plugin.Writer.Csv.Tests (4 files)"

New-SourceFile $CsvTestsRoot "Tests/Options/CsvWriterOptionsValidatorTests.cs" @'
// <copyright file="CsvWriterOptionsValidatorTests.cs" company="Axel Johnson International">
// Copyright (c) 2026 Axel Johnson International. All rights reserved.
// </copyright>

namespace Axbus.Plugin.Writer.Csv.Tests.Tests.Options;

using Axbus.Plugin.Writer.Csv.Options;
using Axbus.Plugin.Writer.Csv.Validators;
using Axbus.Tests.Common.Base;
using NUnit.Framework;

/// <summary>
/// Unit tests for <see cref="CsvWriterOptionsValidator"/>.
/// </summary>
[TestFixture]
public sealed class CsvWriterOptionsValidatorTests : AxbusTestBase
{
    private CsvWriterOptionsValidator sut = null!;

    /// <inheritdoc/>
    public override void SetUp() { base.SetUp(); sut = new CsvWriterOptionsValidator(); }

    /// <summary>Should_ReturnNoErrors_When_DefaultOptions.</summary>
    [Test]
    public void Should_ReturnNoErrors_When_DefaultOptions()
    {
        Assert.That(sut.Validate(new CsvWriterPluginOptions()).ToList(), Is.Empty);
    }

    /// <summary>Should_ReturnError_When_DelimiterIsNullChar.</summary>
    [Test]
    public void Should_ReturnError_When_DelimiterIsNullChar()
    {
        Assert.That(sut.Validate(new CsvWriterPluginOptions { Delimiter = '\0' }).ToList(), Is.Not.Empty);
    }

    /// <summary>Should_ReturnError_When_EncodingInvalid.</summary>
    [Test]
    public void Should_ReturnError_When_EncodingInvalid()
    {
        Assert.That(sut.Validate(new CsvWriterPluginOptions { Encoding = "NOT-VALID" }).ToList(), Is.Not.Empty);
    }
}
'@

New-SourceFile $CsvTestsRoot "Tests/Writer/CsvOutputWriterTests.cs" @'
// <copyright file="CsvOutputWriterTests.cs" company="Axel Johnson International">
// Copyright (c) 2026 Axel Johnson International. All rights reserved.
// </copyright>

namespace Axbus.Plugin.Writer.Csv.Tests.Tests.Writer;

using Axbus.Core.Models.Configuration;
using Axbus.Core.Models.Pipeline;
using Axbus.Plugin.Writer.Csv.Internal;
using Axbus.Plugin.Writer.Csv.Options;
using Axbus.Plugin.Writer.Csv.Writer;
using Axbus.Tests.Common.Base;
using NUnit.Framework;

/// <summary>
/// Unit tests for <see cref="CsvOutputWriter"/>.
/// </summary>
[TestFixture]
public sealed class CsvOutputWriterTests : AxbusTestBase
{
    private string tempDir = null!;

    /// <inheritdoc/>
    public override void SetUp()
    {
        base.SetUp();
        tempDir = Path.Combine(Path.GetTempPath(), Path.GetRandomFileName());
        Directory.CreateDirectory(tempDir);
    }

    /// <inheritdoc/>
    public override void TearDown()
    {
        base.TearDown();
        if (Directory.Exists(tempDir)) Directory.Delete(tempDir, recursive: true);
    }

    private CsvOutputWriter CreateWriter(char delimiter = ',') =>
        new(NullLogger<CsvOutputWriter>(),
            new CsvWriterPluginOptions { Delimiter = delimiter, IncludeHeader = true },
            new CsvSchemaBuilder(NullLogger<CsvSchemaBuilder>()));

    private static TransformedData MakeData(int rowCount) =>
        new(Rows: MakeRows(rowCount), SourcePath: "test.json");

    private static async IAsyncEnumerable<FlattenedRow> MakeRows(int count)
    {
        for (var i = 1; i <= count; i++)
        {
            var row = new FlattenedRow { RowNumber = i };
            row.Values["id"]   = i.ToString();
            row.Values["name"] = $"Item {i}";
            yield return row;
            await Task.Yield();
        }
    }

    /// <summary>Should_CreateOutputFile_When_RowsWritten.</summary>
    [Test]
    public async Task Should_CreateOutputFile_When_RowsWritten()
    {
        var result = await CreateWriter().WriteAsync(
            MakeData(3), new TargetOptions { Path = tempDir }, new PipelineOptions(), CancellationToken.None);

        Assert.That(File.Exists(result.OutputPath), Is.True);
        Assert.That(result.RowsWritten,             Is.EqualTo(3));
    }

    /// <summary>Should_WriteHeaderRow_When_IncludeHeaderTrue.</summary>
    [Test]
    public async Task Should_WriteHeaderRow_When_IncludeHeaderTrue()
    {
        var result = await CreateWriter().WriteAsync(
            MakeData(2), new TargetOptions { Path = tempDir }, new PipelineOptions(), CancellationToken.None);

        var lines = await File.ReadAllLinesAsync(result.OutputPath);

        Assert.That(lines.Length, Is.GreaterThanOrEqualTo(3));
        Assert.That(lines[0], Does.Contain("id"));
        Assert.That(lines[0], Does.Contain("name"));
    }

    /// <summary>Should_UseSemicolon_When_DelimiterConfigured.</summary>
    [Test]
    public async Task Should_UseSemicolon_When_DelimiterConfigured()
    {
        var result  = await CreateWriter(delimiter: ';').WriteAsync(
            MakeData(1), new TargetOptions { Path = tempDir }, new PipelineOptions(), CancellationToken.None);
        var content = await File.ReadAllTextAsync(result.OutputPath);

        Assert.That(content, Does.Contain(";"));
        Assert.That(content, Does.Not.Contain(","));
    }
}
'@

New-SourceFile $CsvTestsRoot "Tests/Plugin/CsvWriterPluginTests.cs" @'
// <copyright file="CsvWriterPluginTests.cs" company="Axel Johnson International">
// Copyright (c) 2026 Axel Johnson International. All rights reserved.
// </copyright>

namespace Axbus.Plugin.Writer.Csv.Tests.Tests.Plugin;

using Axbus.Core.Enums;
using Axbus.Tests.Common.Base;
using NUnit.Framework;

/// <summary>
/// Unit tests for <see cref="CsvWriterPlugin"/>.
/// </summary>
[TestFixture]
public sealed class CsvWriterPluginTests : AxbusTestBase
{
    private CsvWriterPlugin sut = null!;

    /// <inheritdoc/>
    public override void SetUp() { base.SetUp(); sut = new CsvWriterPlugin(); }

    /// <summary>Should_HaveCorrectPluginId.</summary>
    [Test]
    public void Should_HaveCorrectPluginId()
    {
        Assert.That(sut.PluginId, Is.EqualTo("axbus.plugin.writer.csv"));
    }

    /// <summary>Should_DeclareWriterOnly_When_CapabilitiesInspected.</summary>
    [Test]
    public void Should_DeclareWriterOnly_When_CapabilitiesInspected()
    {
        Assert.That(sut.Capabilities.HasFlag(PluginCapabilities.Writer), Is.True);
        Assert.That(sut.Capabilities.HasFlag(PluginCapabilities.Reader), Is.False);
    }

    /// <summary>Should_ReturnNullForNonWriterStages.</summary>
    [Test]
    public void Should_ReturnNullForNonWriterStages()
    {
        Assert.That(sut.CreateReader(Services),      Is.Null);
        Assert.That(sut.CreateParser(Services),      Is.Null);
        Assert.That(sut.CreateTransformer(Services), Is.Null);
    }

    /// <summary>Should_ReturnNonNullWriter.</summary>
    [Test]
    public void Should_ReturnNonNullWriter()
    {
        Assert.That(sut.CreateWriter(Services), Is.Not.Null);
    }
}
'@

New-SourceFile $CsvTestsRoot "Tests/Internal/CsvSchemaBuilderTests.cs" @'
// <copyright file="CsvSchemaBuilderTests.cs" company="Axel Johnson International">
// Copyright (c) 2026 Axel Johnson International. All rights reserved.
// </copyright>

namespace Axbus.Plugin.Writer.Csv.Tests.Tests.Internal;

using Axbus.Core.Models.Pipeline;
using Axbus.Plugin.Writer.Csv.Internal;
using Axbus.Tests.Common.Base;
using NUnit.Framework;

/// <summary>
/// Unit tests for <see cref="CsvSchemaBuilder"/>.
/// </summary>
[TestFixture]
public sealed class CsvSchemaBuilderTests : AxbusTestBase
{
    private CsvSchemaBuilder sut = null!;

    /// <inheritdoc/>
    public override void SetUp() { base.SetUp(); sut = new CsvSchemaBuilder(NullLogger<CsvSchemaBuilder>()); }

    private static async IAsyncEnumerable<FlattenedRow> MakeRows(IEnumerable<Dictionary<string, string>> vals)
    {
        var rn = 1;
        foreach (var v in vals)
        {
            var row = new FlattenedRow { RowNumber = rn++ };
            foreach (var kvp in v) row.Values[kvp.Key] = kvp.Value;
            yield return row;
            await Task.Yield();
        }
    }

    /// <summary>Should_DiscoverColumnsInFirstSeenOrder.</summary>
    [Test]
    public async Task Should_DiscoverColumnsInFirstSeenOrder()
    {
        var rows   = MakeRows(new[] { new Dictionary<string, string> { ["id"] = "1", ["name"] = "A" } });
        var schema = await sut.BuildAsync(rows, CancellationToken.None);

        Assert.That(schema.Columns[0], Is.EqualTo("id"));
        Assert.That(schema.Columns[1], Is.EqualTo("name"));
    }

    /// <summary>Should_UnionColumns_When_RowsHaveDifferentKeys.</summary>
    [Test]
    public async Task Should_UnionColumns_When_RowsHaveDifferentKeys()
    {
        var rows = MakeRows(new[]
        {
            new Dictionary<string, string> { ["id"] = "1" },
            new Dictionary<string, string> { ["id"] = "2", ["extra"] = "X" },
        });
        var schema = await sut.BuildAsync(rows, CancellationToken.None);

        Assert.That(schema.Columns.Count,           Is.EqualTo(2));
        Assert.That(schema.Columns.Contains("extra"), Is.True);
    }

    /// <summary>Should_ReturnEmptySchema_When_NoRows.</summary>
    [Test]
    public async Task Should_ReturnEmptySchema_When_NoRows()
    {
        var schema = await sut.BuildAsync(
            MakeRows(Array.Empty<Dictionary<string, string>>()),
            CancellationToken.None);
        Assert.That(schema.Columns, Is.Empty);
    }
}
'@

# ==============================================================================
# TEST PROJECT 7 - AXBUS.PLUGIN.WRITER.EXCEL.TESTS
# ==============================================================================

$ExcelTestsRoot = "tests/Axbus.Plugin.Writer.Excel.Tests"
Write-Phase "Test Project 7 - Axbus.Plugin.Writer.Excel.Tests (4 files)"

New-SourceFile $ExcelTestsRoot "Tests/Options/ExcelWriterOptionsValidatorTests.cs" @'
// <copyright file="ExcelWriterOptionsValidatorTests.cs" company="Axel Johnson International">
// Copyright (c) 2026 Axel Johnson International. All rights reserved.
// </copyright>

namespace Axbus.Plugin.Writer.Excel.Tests.Tests.Options;

using Axbus.Plugin.Writer.Excel.Options;
using Axbus.Plugin.Writer.Excel.Validators;
using Axbus.Tests.Common.Base;
using NUnit.Framework;

/// <summary>
/// Unit tests for <see cref="ExcelWriterOptionsValidator"/>.
/// </summary>
[TestFixture]
public sealed class ExcelWriterOptionsValidatorTests : AxbusTestBase
{
    private ExcelWriterOptionsValidator sut = null!;

    /// <inheritdoc/>
    public override void SetUp() { base.SetUp(); sut = new ExcelWriterOptionsValidator(); }

    /// <summary>Should_ReturnNoErrors_When_DefaultOptions.</summary>
    [Test]
    public void Should_ReturnNoErrors_When_DefaultOptions()
    {
        Assert.That(sut.Validate(new ExcelWriterPluginOptions()).ToList(), Is.Empty);
    }

    /// <summary>Should_ReturnError_When_SheetNameTooLong.</summary>
    [Test]
    public void Should_ReturnError_When_SheetNameTooLong()
    {
        Assert.That(sut.Validate(new ExcelWriterPluginOptions { SheetName = new string('A', 32) }).ToList(), Is.Not.Empty);
    }

    /// <summary>Should_ReturnError_When_SheetNameContainsForbiddenChar.</summary>
    [TestCase(":")] [TestCase("\\")] [TestCase("/")] [TestCase("?")]
    [TestCase("*")] [TestCase("[")] [TestCase("]")]
    public void Should_ReturnError_When_SheetNameContainsForbiddenChar(string ch)
    {
        Assert.That(sut.Validate(new ExcelWriterPluginOptions { SheetName = $"Sheet{ch}Name" }).ToList(), Is.Not.Empty);
    }

    /// <summary>Should_ReturnError_When_SheetNameEmpty.</summary>
    [Test]
    public void Should_ReturnError_When_SheetNameEmpty()
    {
        Assert.That(sut.Validate(new ExcelWriterPluginOptions { SheetName = "" }).ToList(), Is.Not.Empty);
    }
}
'@

New-SourceFile $ExcelTestsRoot "Tests/Writer/ExcelOutputWriterTests.cs" @'
// <copyright file="ExcelOutputWriterTests.cs" company="Axel Johnson International">
// Copyright (c) 2026 Axel Johnson International. All rights reserved.
// </copyright>

namespace Axbus.Plugin.Writer.Excel.Tests.Tests.Writer;

using Axbus.Core.Models.Configuration;
using Axbus.Core.Models.Pipeline;
using Axbus.Plugin.Writer.Excel.Internal;
using Axbus.Plugin.Writer.Excel.Options;
using Axbus.Plugin.Writer.Excel.Writer;
using Axbus.Tests.Common.Base;
using ClosedXML.Excel;
using NUnit.Framework;

/// <summary>
/// Unit tests for <see cref="ExcelOutputWriter"/>.
/// </summary>
[TestFixture]
public sealed class ExcelOutputWriterTests : AxbusTestBase
{
    private string tempDir = null!;

    /// <inheritdoc/>
    public override void SetUp()
    {
        base.SetUp();
        tempDir = Path.Combine(Path.GetTempPath(), Path.GetRandomFileName());
        Directory.CreateDirectory(tempDir);
    }

    /// <inheritdoc/>
    public override void TearDown()
    {
        base.TearDown();
        if (Directory.Exists(tempDir)) Directory.Delete(tempDir, recursive: true);
    }

    private ExcelOutputWriter CreateWriter(string sheet = "Sheet1") =>
        new(NullLogger<ExcelOutputWriter>(),
            new ExcelWriterPluginOptions { SheetName = sheet, AutoFit = false, BoldHeaders = true },
            new ExcelSchemaBuilder(NullLogger<ExcelSchemaBuilder>()));

    private static TransformedData MakeData(int count) =>
        new(Rows: MakeRows(count), SourcePath: "test.json");

    private static async IAsyncEnumerable<FlattenedRow> MakeRows(int count)
    {
        for (var i = 1; i <= count; i++)
        {
            var row = new FlattenedRow { RowNumber = i };
            row.Values["id"]   = i.ToString();
            row.Values["name"] = $"Product {i}";
            yield return row;
            await Task.Yield();
        }
    }

    /// <summary>Should_CreateXlsxFile_When_RowsWritten.</summary>
    [Test]
    public async Task Should_CreateXlsxFile_When_RowsWritten()
    {
        var result = await CreateWriter().WriteAsync(
            MakeData(3), new TargetOptions { Path = tempDir }, new PipelineOptions(), CancellationToken.None);

        Assert.That(File.Exists(result.OutputPath), Is.True);
        Assert.That(result.RowsWritten,             Is.EqualTo(3));
        Assert.That(result.OutputPath,              Does.EndWith(".xlsx"));
    }

    /// <summary>Should_UseConfiguredSheetName_When_Opened.</summary>
    [Test]
    public async Task Should_UseConfiguredSheetName_When_Opened()
    {
        var result = await CreateWriter(sheet: "MyData").WriteAsync(
            MakeData(1), new TargetOptions { Path = tempDir }, new PipelineOptions(), CancellationToken.None);

        using var wb = new XLWorkbook(result.OutputPath);
        Assert.That(wb.Worksheets.Any(ws => ws.Name == "MyData"), Is.True);
    }

    /// <summary>Should_WriteHeaderRowWithColumnNames.</summary>
    [Test]
    public async Task Should_WriteHeaderRowWithColumnNames()
    {
        var result = await CreateWriter().WriteAsync(
            MakeData(2), new TargetOptions { Path = tempDir }, new PipelineOptions(), CancellationToken.None);

        using var wb = new XLWorkbook(result.OutputPath);
        var ws = wb.Worksheets.First();

        Assert.That(ws.Cell(1, 1).GetString(), Is.EqualTo("id"));
        Assert.That(ws.Cell(1, 2).GetString(), Is.EqualTo("name"));
    }
}
'@

New-SourceFile $ExcelTestsRoot "Tests/Plugin/ExcelWriterPluginTests.cs" @'
// <copyright file="ExcelWriterPluginTests.cs" company="Axel Johnson International">
// Copyright (c) 2026 Axel Johnson International. All rights reserved.
// </copyright>

namespace Axbus.Plugin.Writer.Excel.Tests.Tests.Plugin;

using Axbus.Core.Enums;
using Axbus.Tests.Common.Base;
using NUnit.Framework;

/// <summary>
/// Unit tests for <see cref="ExcelWriterPlugin"/>.
/// </summary>
[TestFixture]
public sealed class ExcelWriterPluginTests : AxbusTestBase
{
    private ExcelWriterPlugin sut = null!;

    /// <inheritdoc/>
    public override void SetUp() { base.SetUp(); sut = new ExcelWriterPlugin(); }

    /// <summary>Should_HaveCorrectPluginId.</summary>
    [Test]
    public void Should_HaveCorrectPluginId()
    {
        Assert.That(sut.PluginId, Is.EqualTo("axbus.plugin.writer.excel"));
    }

    /// <summary>Should_DeclareWriterOnly_When_CapabilitiesInspected.</summary>
    [Test]
    public void Should_DeclareWriterOnly_When_CapabilitiesInspected()
    {
        Assert.That(sut.Capabilities.HasFlag(PluginCapabilities.Writer), Is.True);
        Assert.That(sut.Capabilities.HasFlag(PluginCapabilities.Reader), Is.False);
    }

    /// <summary>Should_ReturnNullForNonWriterStages.</summary>
    [Test]
    public void Should_ReturnNullForNonWriterStages()
    {
        Assert.That(sut.CreateReader(Services),      Is.Null);
        Assert.That(sut.CreateParser(Services),      Is.Null);
        Assert.That(sut.CreateTransformer(Services), Is.Null);
    }

    /// <summary>Should_ReturnNonNullWriter.</summary>
    [Test]
    public void Should_ReturnNonNullWriter()
    {
        Assert.That(sut.CreateWriter(Services), Is.Not.Null);
    }
}
'@

New-SourceFile $ExcelTestsRoot "Tests/Internal/ExcelSchemaBuilderTests.cs" @'
// <copyright file="ExcelSchemaBuilderTests.cs" company="Axel Johnson International">
// Copyright (c) 2026 Axel Johnson International. All rights reserved.
// </copyright>

namespace Axbus.Plugin.Writer.Excel.Tests.Tests.Internal;

using Axbus.Core.Models.Pipeline;
using Axbus.Plugin.Writer.Excel.Internal;
using Axbus.Tests.Common.Base;
using NUnit.Framework;

/// <summary>
/// Unit tests for <see cref="ExcelSchemaBuilder"/>.
/// </summary>
[TestFixture]
public sealed class ExcelSchemaBuilderTests : AxbusTestBase
{
    private ExcelSchemaBuilder sut = null!;

    /// <inheritdoc/>
    public override void SetUp() { base.SetUp(); sut = new ExcelSchemaBuilder(NullLogger<ExcelSchemaBuilder>()); }

    private static async IAsyncEnumerable<FlattenedRow> MakeRows(IEnumerable<string[]> cols)
    {
        var rn = 1;
        foreach (var c in cols)
        {
            var row = new FlattenedRow { RowNumber = rn++ };
            foreach (var col in c) row.Values[col] = "val";
            yield return row;
            await Task.Yield();
        }
    }

    /// <summary>Should_ReturnExcelFormat_When_SchemaBuilt.</summary>
    [Test]
    public async Task Should_ReturnExcelFormat_When_SchemaBuilt()
    {
        var schema = await sut.BuildAsync(MakeRows(new[] { new[] { "id" } }), CancellationToken.None);
        Assert.That(schema.Format, Is.EqualTo("excel"));
    }

    /// <summary>Should_CollectAllColumns_When_RowsHaveDifferentFields.</summary>
    [Test]
    public async Task Should_CollectAllColumns_When_RowsHaveDifferentFields()
    {
        var schema = await sut.BuildAsync(
            MakeRows(new[] { new[] { "id", "name" }, new[] { "id", "name", "amount" } }),
            CancellationToken.None);

        Assert.That(schema.Columns.Count,             Is.EqualTo(3));
        Assert.That(schema.Columns.Contains("amount"), Is.True);
    }
}
'@

# ==============================================================================
# TEST PROJECT 8 - AXBUS.INTEGRATION.TESTS
# ==============================================================================

$IntegTestsRoot = "tests/Axbus.Integration.Tests"
Write-Phase "Test Project 8 - Axbus.Integration.Tests (4 files)"

New-SourceFile $IntegTestsRoot "Tests/JsonToCsvIntegrationTests.cs" @'
// <copyright file="JsonToCsvIntegrationTests.cs" company="Axel Johnson International">
// Copyright (c) 2026 Axel Johnson International. All rights reserved.
// </copyright>

namespace Axbus.Integration.Tests.Tests;

using Axbus.Core.Models.Configuration;
using Axbus.Plugin.Reader.Json.Options;
using Axbus.Plugin.Reader.Json.Parser;
using Axbus.Plugin.Reader.Json.Reader;
using Axbus.Plugin.Reader.Json.Transformer;
using Axbus.Plugin.Writer.Csv.Internal;
using Axbus.Plugin.Writer.Csv.Options;
using Axbus.Plugin.Writer.Csv.Writer;
using Axbus.Tests.Common.Base;
using NUnit.Framework;

/// <summary>
/// End-to-end integration tests for the JSON-to-CSV pipeline.
/// </summary>
[TestFixture]
public sealed class JsonToCsvIntegrationTests : AxbusTestBase
{
    private string tempIn  = null!;
    private string tempOut = null!;

    /// <inheritdoc/>
    public override void SetUp()
    {
        base.SetUp();
        tempIn  = Path.Combine(Path.GetTempPath(), Path.GetRandomFileName());
        tempOut = Path.Combine(Path.GetTempPath(), Path.GetRandomFileName());
        Directory.CreateDirectory(tempIn);
        Directory.CreateDirectory(tempOut);
    }

    /// <inheritdoc/>
    public override void TearDown()
    {
        base.TearDown();
        foreach (var d in new[] { tempIn, tempOut })
            if (Directory.Exists(d)) Directory.Delete(d, recursive: true);
    }

    /// <summary>Should_ProduceValidCsv_When_FlatJsonProcessed.</summary>
    [Test]
    public async Task Should_ProduceValidCsv_When_FlatJsonProcessed()
    {
        var inputPath = Path.Combine(tempIn, "orders.json");
        await File.WriteAllTextAsync(inputPath, """
            [
              {"orderId":"ORD-001","customer":"Acme Corp","amount":1500.00},
              {"orderId":"ORD-002","customer":"Globex Ltd","amount":2750.50}
            ]
            """);

        var opts    = new JsonReaderPluginOptions();
        var reader  = new JsonSourceReader(NullLogger<JsonSourceReader>());
        var parser  = new JsonFormatParser(NullLogger<JsonFormatParser>(), opts);
        var xformer = new JsonDataTransformer(NullLogger<JsonDataTransformer>(), opts);
        var writer  = new CsvOutputWriter(NullLogger<CsvOutputWriter>(),
            new CsvWriterPluginOptions { Delimiter = ',', IncludeHeader = true },
            new CsvSchemaBuilder(NullLogger<CsvSchemaBuilder>()));

        var sd = await reader.ReadAsync(new SourceOptions { Path = inputPath }, CancellationToken.None);
        var pd = await parser.ParseAsync(sd, CancellationToken.None);
        var td = await xformer.TransformAsync(pd, new PipelineOptions(), CancellationToken.None);
        var result = await writer.WriteAsync(td, new TargetOptions { Path = tempOut }, new PipelineOptions(), CancellationToken.None);

        Assert.That(File.Exists(result.OutputPath), Is.True);
        Assert.That(result.RowsWritten,             Is.EqualTo(2));
        Assert.That(result.ErrorRowsWritten,        Is.EqualTo(0));

        var lines = await File.ReadAllLinesAsync(result.OutputPath);
        Assert.That(lines.Length,  Is.EqualTo(3));
        Assert.That(lines[0],      Does.Contain("orderId"));
        Assert.That(lines[1],      Does.Contain("ORD-001"));
    }

    /// <summary>Should_ExplodeNestedArrays_When_JsonContainsArrayFields.</summary>
    [Test]
    public async Task Should_ExplodeNestedArrays_When_JsonContainsArrayFields()
    {
        var inputPath = Path.Combine(tempIn, "sales.json");
        await File.WriteAllTextAsync(inputPath, """
            [{"orderId":"SO-001","lines":[{"lineNo":1,"product":"A"},{"lineNo":2,"product":"B"}]}]
            """);

        var opts    = new JsonReaderPluginOptions { MaxExplosionDepth = 3 };
        var reader  = new JsonSourceReader(NullLogger<JsonSourceReader>());
        var parser  = new JsonFormatParser(NullLogger<JsonFormatParser>(), opts);
        var xformer = new JsonDataTransformer(NullLogger<JsonDataTransformer>(), opts);
        var writer  = new CsvOutputWriter(NullLogger<CsvOutputWriter>(),
            new CsvWriterPluginOptions(), new CsvSchemaBuilder(NullLogger<CsvSchemaBuilder>()));

        var sd = await reader.ReadAsync(new SourceOptions { Path = inputPath }, CancellationToken.None);
        var pd = await parser.ParseAsync(sd, CancellationToken.None);
        var td = await xformer.TransformAsync(pd, new PipelineOptions(), CancellationToken.None);
        var result = await writer.WriteAsync(td, new TargetOptions { Path = tempOut }, new PipelineOptions(), CancellationToken.None);

        Assert.That(result.RowsWritten, Is.EqualTo(2));
    }

    /// <summary>Should_ProduceEmptyCsv_When_JsonArrayIsEmpty.</summary>
    [Test]
    public async Task Should_ProduceEmptyCsv_When_JsonArrayIsEmpty()
    {
        var inputPath = Path.Combine(tempIn, "empty.json");
        await File.WriteAllTextAsync(inputPath, "[]");

        var opts    = new JsonReaderPluginOptions();
        var reader  = new JsonSourceReader(NullLogger<JsonSourceReader>());
        var parser  = new JsonFormatParser(NullLogger<JsonFormatParser>(), opts);
        var xformer = new JsonDataTransformer(NullLogger<JsonDataTransformer>(), opts);
        var writer  = new CsvOutputWriter(NullLogger<CsvOutputWriter>(),
            new CsvWriterPluginOptions(), new CsvSchemaBuilder(NullLogger<CsvSchemaBuilder>()));

        var sd = await reader.ReadAsync(new SourceOptions { Path = inputPath }, CancellationToken.None);
        var pd = await parser.ParseAsync(sd, CancellationToken.None);
        var td = await xformer.TransformAsync(pd, new PipelineOptions(), CancellationToken.None);
        var result = await writer.WriteAsync(td, new TargetOptions { Path = tempOut }, new PipelineOptions(), CancellationToken.None);

        Assert.That(result.RowsWritten, Is.EqualTo(0));
        Assert.That(File.Exists(result.OutputPath), Is.True);
    }
}
'@

New-SourceFile $IntegTestsRoot "Tests/JsonToExcelIntegrationTests.cs" @'
// <copyright file="JsonToExcelIntegrationTests.cs" company="Axel Johnson International">
// Copyright (c) 2026 Axel Johnson International. All rights reserved.
// </copyright>

namespace Axbus.Integration.Tests.Tests;

using Axbus.Core.Models.Configuration;
using Axbus.Plugin.Reader.Json.Options;
using Axbus.Plugin.Reader.Json.Parser;
using Axbus.Plugin.Reader.Json.Reader;
using Axbus.Plugin.Reader.Json.Transformer;
using Axbus.Plugin.Writer.Excel.Internal;
using Axbus.Plugin.Writer.Excel.Options;
using Axbus.Plugin.Writer.Excel.Writer;
using Axbus.Tests.Common.Base;
using ClosedXML.Excel;
using NUnit.Framework;

/// <summary>
/// End-to-end integration tests for the JSON-to-Excel pipeline.
/// </summary>
[TestFixture]
public sealed class JsonToExcelIntegrationTests : AxbusTestBase
{
    private string tempIn  = null!;
    private string tempOut = null!;

    /// <inheritdoc/>
    public override void SetUp()
    {
        base.SetUp();
        tempIn  = Path.Combine(Path.GetTempPath(), Path.GetRandomFileName());
        tempOut = Path.Combine(Path.GetTempPath(), Path.GetRandomFileName());
        Directory.CreateDirectory(tempIn);
        Directory.CreateDirectory(tempOut);
    }

    /// <inheritdoc/>
    public override void TearDown()
    {
        base.TearDown();
        foreach (var d in new[] { tempIn, tempOut })
            if (Directory.Exists(d)) Directory.Delete(d, recursive: true);
    }

    /// <summary>Should_ProduceValidXlsx_When_FlatJsonProcessed.</summary>
    [Test]
    public async Task Should_ProduceValidXlsx_When_FlatJsonProcessed()
    {
        var inputPath = Path.Combine(tempIn, "products.json");
        await File.WriteAllTextAsync(inputPath, """
            [
              {"productId":"P001","name":"Widget A","price":25.50},
              {"productId":"P002","name":"Widget B","price":42.00},
              {"productId":"P003","name":"Widget C","price":15.75}
            ]
            """);

        var opts    = new JsonReaderPluginOptions();
        var reader  = new JsonSourceReader(NullLogger<JsonSourceReader>());
        var parser  = new JsonFormatParser(NullLogger<JsonFormatParser>(), opts);
        var xformer = new JsonDataTransformer(NullLogger<JsonDataTransformer>(), opts);
        var writer  = new ExcelOutputWriter(NullLogger<ExcelOutputWriter>(),
            new ExcelWriterPluginOptions { SheetName = "Products", AutoFit = false, BoldHeaders = true },
            new ExcelSchemaBuilder(NullLogger<ExcelSchemaBuilder>()));

        var sd = await reader.ReadAsync(new SourceOptions { Path = inputPath }, CancellationToken.None);
        var pd = await parser.ParseAsync(sd, CancellationToken.None);
        var td = await xformer.TransformAsync(pd, new PipelineOptions(), CancellationToken.None);
        var result = await writer.WriteAsync(td, new TargetOptions { Path = tempOut }, new PipelineOptions(), CancellationToken.None);

        Assert.That(File.Exists(result.OutputPath), Is.True);
        Assert.That(result.RowsWritten,             Is.EqualTo(3));

        using var wb = new XLWorkbook(result.OutputPath);
        var ws = wb.Worksheet("Products");
        Assert.That(ws,                          Is.Not.Null);
        Assert.That(ws.Cell(1, 1).GetString(),   Is.EqualTo("productId"));
        Assert.That(ws.Cell(2, 1).GetString(),   Is.EqualTo("P001"));
    }

    /// <summary>Should_ApplyBoldHeaders_When_BoldHeadersEnabled.</summary>
    [Test]
    public async Task Should_ApplyBoldHeaders_When_BoldHeadersEnabled()
    {
        var inputPath = Path.Combine(tempIn, "data.json");
        await File.WriteAllTextAsync(inputPath, "[{\"id\":\"1\",\"value\":\"X\"}]");

        var opts    = new JsonReaderPluginOptions();
        var reader  = new JsonSourceReader(NullLogger<JsonSourceReader>());
        var parser  = new JsonFormatParser(NullLogger<JsonFormatParser>(), opts);
        var xformer = new JsonDataTransformer(NullLogger<JsonDataTransformer>(), opts);
        var writer  = new ExcelOutputWriter(NullLogger<ExcelOutputWriter>(),
            new ExcelWriterPluginOptions { BoldHeaders = true, AutoFit = false },
            new ExcelSchemaBuilder(NullLogger<ExcelSchemaBuilder>()));

        var sd = await reader.ReadAsync(new SourceOptions { Path = inputPath }, CancellationToken.None);
        var pd = await parser.ParseAsync(sd, CancellationToken.None);
        var td = await xformer.TransformAsync(pd, new PipelineOptions(), CancellationToken.None);
        var result = await writer.WriteAsync(td, new TargetOptions { Path = tempOut }, new PipelineOptions(), CancellationToken.None);

        using var wb = new XLWorkbook(result.OutputPath);
        Assert.That(wb.Worksheets.First().Cell(1, 1).Style.Font.Bold, Is.True);
    }
}
'@

New-SourceFile $IntegTestsRoot "Tests/ErrorHandlingIntegrationTests.cs" @'
// <copyright file="ErrorHandlingIntegrationTests.cs" company="Axel Johnson International">
// Copyright (c) 2026 Axel Johnson International. All rights reserved.
// </copyright>

namespace Axbus.Integration.Tests.Tests;

using Axbus.Core.Exceptions;
using Axbus.Core.Models.Configuration;
using Axbus.Plugin.Reader.Json.Options;
using Axbus.Plugin.Reader.Json.Parser;
using Axbus.Plugin.Reader.Json.Reader;
using Axbus.Tests.Common.Base;
using NUnit.Framework;

/// <summary>
/// Integration tests for pipeline error handling.
/// </summary>
[TestFixture]
public sealed class ErrorHandlingIntegrationTests : AxbusTestBase
{
    private string tempDir = null!;

    /// <inheritdoc/>
    public override void SetUp()
    {
        base.SetUp();
        tempDir = Path.Combine(Path.GetTempPath(), Path.GetRandomFileName());
        Directory.CreateDirectory(tempDir);
    }

    /// <inheritdoc/>
    public override void TearDown()
    {
        base.TearDown();
        if (Directory.Exists(tempDir)) Directory.Delete(tempDir, recursive: true);
    }

    /// <summary>Should_ThrowConnectorException_When_FileDoesNotExist.</summary>
    [Test]
    public void Should_ThrowConnectorException_When_FileDoesNotExist()
    {
        var reader = new JsonSourceReader(NullLogger<JsonSourceReader>());
        Assert.ThrowsAsync<AxbusConnectorException>(async () =>
            await reader.ReadAsync(
                new SourceOptions { Path = Path.Combine(tempDir, "missing.json") },
                CancellationToken.None));
    }

    /// <summary>Should_ThrowPipelineException_When_InvalidJsonParsed.</summary>
    [Test]
    public async Task Should_ThrowPipelineException_When_InvalidJsonParsed()
    {
        var badFile = Path.Combine(tempDir, "bad.json");
        await File.WriteAllTextAsync(badFile, "{ this is not valid json }");

        var reader = new JsonSourceReader(NullLogger<JsonSourceReader>());
        var parser = new JsonFormatParser(NullLogger<JsonFormatParser>(), new JsonReaderPluginOptions());
        var sd     = await reader.ReadAsync(new SourceOptions { Path = badFile }, CancellationToken.None);
        var pd     = await parser.ParseAsync(sd, CancellationToken.None);

        Assert.ThrowsAsync<AxbusPipelineException>(async () =>
        {
            await foreach (var _ in pd.Elements) { }
        });
    }

    /// <summary>Should_ThrowPipelineException_When_RootKeyNotFound.</summary>
    [Test]
    public async Task Should_ThrowPipelineException_When_RootKeyNotFound()
    {
        var inputPath = Path.Combine(tempDir, "data.json");
        await File.WriteAllTextAsync(inputPath, "{\"orders\":[{\"id\":\"1\"}]}");

        var reader = new JsonSourceReader(NullLogger<JsonSourceReader>());
        var parser = new JsonFormatParser(NullLogger<JsonFormatParser>(),
            new JsonReaderPluginOptions { RootArrayKey = "items" });

        var sd = await reader.ReadAsync(new SourceOptions { Path = inputPath }, CancellationToken.None);
        var pd = await parser.ParseAsync(sd, CancellationToken.None);

        Assert.ThrowsAsync<AxbusPipelineException>(async () =>
        {
            await foreach (var _ in pd.Elements) { }
        });
    }
}
'@

New-SourceFile $IntegTestsRoot "Tests/MultiFormatIntegrationTests.cs" @'
// <copyright file="MultiFormatIntegrationTests.cs" company="Axel Johnson International">
// Copyright (c) 2026 Axel Johnson International. All rights reserved.
// </copyright>

namespace Axbus.Integration.Tests.Tests;

using Axbus.Core.Models.Configuration;
using Axbus.Plugin.Reader.Json.Options;
using Axbus.Plugin.Reader.Json.Parser;
using Axbus.Plugin.Reader.Json.Reader;
using Axbus.Plugin.Reader.Json.Transformer;
using Axbus.Plugin.Writer.Csv.Internal;
using Axbus.Plugin.Writer.Csv.Options;
using Axbus.Plugin.Writer.Csv.Writer;
using Axbus.Plugin.Writer.Excel.Internal;
using Axbus.Plugin.Writer.Excel.Options;
using Axbus.Plugin.Writer.Excel.Writer;
using Axbus.Tests.Common.Base;
using ClosedXML.Excel;
using NUnit.Framework;

/// <summary>
/// Integration tests verifying consistent output across CSV and Excel formats.
/// </summary>
[TestFixture]
public sealed class MultiFormatIntegrationTests : AxbusTestBase
{
    private string tempIn  = null!;
    private string tempOut = null!;

    /// <inheritdoc/>
    public override void SetUp()
    {
        base.SetUp();
        tempIn  = Path.Combine(Path.GetTempPath(), Path.GetRandomFileName());
        tempOut = Path.Combine(Path.GetTempPath(), Path.GetRandomFileName());
        Directory.CreateDirectory(tempIn);
        Directory.CreateDirectory(tempOut);
    }

    /// <inheritdoc/>
    public override void TearDown()
    {
        base.TearDown();
        foreach (var d in new[] { tempIn, tempOut })
            if (Directory.Exists(d)) Directory.Delete(d, recursive: true);
    }

    /// <summary>Should_ProduceSameRowCount_When_SameJsonWrittenToCsvAndExcel.</summary>
    [Test]
    public async Task Should_ProduceSameRowCount_When_SameJsonWrittenToCsvAndExcel()
    {
        var inputPath = Path.Combine(tempIn, "inventory.json");
        await File.WriteAllTextAsync(inputPath, """
            [
              {"sku":"SKU-001","description":"Bolt M8","qty":500},
              {"sku":"SKU-002","description":"Nut M8","qty":500},
              {"sku":"SKU-003","description":"Washer M8","qty":1000}
            ]
            """);

        var opts    = new JsonReaderPluginOptions();
        var pipeline = new PipelineOptions();
        var target   = new TargetOptions { Path = tempOut };
        var reader  = new JsonSourceReader(NullLogger<JsonSourceReader>());
        var parser  = new JsonFormatParser(NullLogger<JsonFormatParser>(), opts);
        var xformer = new JsonDataTransformer(NullLogger<JsonDataTransformer>(), opts);

        // CSV pass
        var sd1 = await reader.ReadAsync(new SourceOptions { Path = inputPath }, CancellationToken.None);
        var pd1 = await parser.ParseAsync(sd1, CancellationToken.None);
        var td1 = await xformer.TransformAsync(pd1, pipeline, CancellationToken.None);
        var csvResult = await new CsvOutputWriter(NullLogger<CsvOutputWriter>(),
            new CsvWriterPluginOptions(), new CsvSchemaBuilder(NullLogger<CsvSchemaBuilder>()))
            .WriteAsync(td1, target, pipeline, CancellationToken.None);

        // Excel pass
        var sd2 = await reader.ReadAsync(new SourceOptions { Path = inputPath }, CancellationToken.None);
        var pd2 = await parser.ParseAsync(sd2, CancellationToken.None);
        var td2 = await xformer.TransformAsync(pd2, pipeline, CancellationToken.None);
        var xlResult = await new ExcelOutputWriter(NullLogger<ExcelOutputWriter>(),
            new ExcelWriterPluginOptions { AutoFit = false }, new ExcelSchemaBuilder(NullLogger<ExcelSchemaBuilder>()))
            .WriteAsync(td2, target, pipeline, CancellationToken.None);

        Assert.That(csvResult.RowsWritten, Is.EqualTo(3));
        Assert.That(xlResult.RowsWritten,  Is.EqualTo(3));

        var csvLines = await File.ReadAllLinesAsync(csvResult.OutputPath);
        Assert.That(csvLines.Length, Is.EqualTo(4), "1 header + 3 data rows");

        using var wb = new XLWorkbook(xlResult.OutputPath);
        Assert.That(wb.Worksheets.First().LastRowUsed()!.RowNumber(), Is.EqualTo(4));

        var csvCols  = csvLines[0].Split(',').Length;
        var xlCols   = wb.Worksheets.First().LastColumnUsed()!.ColumnNumber();
        Assert.That(csvCols, Is.EqualTo(xlCols), "Same column count in both formats");
    }
}
'@

# ==============================================================================
# PATCH ALL .CSPROJ FILES
# ==============================================================================

Write-Phase "Patching .csproj Files (adds explicit Compile Include entries)"

Add-CompileIncludes `
    "tests/Axbus.Tests.Common/Axbus.Tests.Common.csproj" `
    @("Base", "Builders", "Helpers", "Assertions")

Add-CompileIncludes `
    "tests/Axbus.Core.Tests/Axbus.Core.Tests.csproj" `
    @("Tests\Enums", "Tests\Models")

Add-CompileIncludes `
    "tests/Axbus.Application.Tests/Axbus.Application.Tests.csproj" `
    @("Tests\Middleware", "Tests\Plugin", "Tests\Notifications", "Tests\Conversion", "Tests\Factories", "Tests\Pipeline")

Add-CompileIncludes `
    "tests/Axbus.Infrastructure.Tests/Axbus.Infrastructure.Tests.csproj" `
    @("Tests\Connectors", "Tests\FileSystem", "Tests\Logging")

Add-CompileIncludes `
    "tests/Axbus.Plugin.Reader.Json.Tests/Axbus.Plugin.Reader.Json.Tests.csproj" `
    @("Tests\Reader", "Tests\Parser", "Tests\Transformer", "Tests\Plugin", "Tests\Integration")

Add-CompileIncludes `
    "tests/Axbus.Plugin.Writer.Csv.Tests/Axbus.Plugin.Writer.Csv.Tests.csproj" `
    @("Tests\Writer", "Tests\Internal", "Tests\Options", "Tests\Plugin", "Tests\Integration")

Add-CompileIncludes `
    "tests/Axbus.Plugin.Writer.Excel.Tests/Axbus.Plugin.Writer.Excel.Tests.csproj" `
    @("Tests\Writer", "Tests\Internal", "Tests\Options", "Tests\Plugin", "Tests\Integration")

Add-CompileIncludes `
    "tests/Axbus.Integration.Tests/Axbus.Integration.Tests.csproj" `
    @("Tests")

# ==============================================================================
# VERIFY AND BUILD
# ==============================================================================

Write-Phase "Verifying File Counts"

$expected = @{
    "tests/Axbus.Tests.Common"              = 4
    "tests/Axbus.Core.Tests"                = 6
    "tests/Axbus.Application.Tests"         = 5
    "tests/Axbus.Infrastructure.Tests"      = 4
    "tests/Axbus.Plugin.Reader.Json.Tests"  = 5
    "tests/Axbus.Plugin.Writer.Csv.Tests"   = 4
    "tests/Axbus.Plugin.Writer.Excel.Tests" = 4
    "tests/Axbus.Integration.Tests"         = 4
}

$allOk = $true
foreach ($entry in $expected.GetEnumerator()) {
    $path   = $entry.Key
    $count  = (Get-ChildItem -Path $path -Filter "*.cs" -Recurse |
               Where-Object { $_.FullName -notmatch "\\(bin|obj)\\" }).Count
    $name   = Split-Path $path -Leaf
    if ($count -ge $entry.Value) {
        Write-Ok "$name : $count .cs files"
    } else {
        Write-Warn "$name : $count .cs files (expected $($entry.Value))"
        $allOk = $false
    }
}

Write-Host ""
Write-Info "Running dotnet restore..."
try {
    $slnFile = if (Test-Path "Axbus.slnx") { "Axbus.slnx" } else { "Axbus.sln" }
    dotnet restore $slnFile --nologo 2>&1 | Out-Null
    Write-Ok "NuGet restore complete"
} catch {
    Write-Warn "Restore warning: $_"
}

Write-Host ""
Write-Info "Running dotnet build to verify zero errors..."
try {
    dotnet build $slnFile --configuration Debug --nologo 2>&1 | Out-Null
    if ($LASTEXITCODE -eq 0) {
        Write-Ok "Full solution builds with 0 errors"
    } else {
        Write-Warn "Build completed with errors - run: dotnet build $slnFile"
    }
} catch {
    Write-Warn "Build check: $_"
}

# ==============================================================================
# SUMMARY
# ==============================================================================

Write-Host ""
Write-Host "===============================================================================" -ForegroundColor Green
Write-Host "  [DONE] All Test Projects Generated!" -ForegroundColor Green
Write-Host "===============================================================================" -ForegroundColor Green
Write-Host ""
Write-Host "  Test Project 1 - Axbus.Tests.Common             :  4 files" -ForegroundColor White
Write-Host "  Test Project 2 - Axbus.Core.Tests               :  6 files" -ForegroundColor White
Write-Host "  Test Project 3 - Axbus.Application.Tests        :  5 files" -ForegroundColor White
Write-Host "  Test Project 4 - Axbus.Infrastructure.Tests     :  4 files" -ForegroundColor White
Write-Host "  Test Project 5 - Axbus.Plugin.Reader.Json.Tests :  5 files" -ForegroundColor White
Write-Host "  Test Project 6 - Axbus.Plugin.Writer.Csv.Tests  :  4 files" -ForegroundColor White
Write-Host "  Test Project 7 - Axbus.Plugin.Writer.Excel.Tests:  4 files" -ForegroundColor White
Write-Host "  Test Project 8 - Axbus.Integration.Tests        :  4 files" -ForegroundColor White
Write-Host ""
Write-Host "  All 8 .csproj files patched with explicit Compile Include entries." -ForegroundColor Green
Write-Host "  Files will appear in Visual Studio immediately - no manual reload." -ForegroundColor Green
Write-Host ""
Write-Host "  Next Steps:" -ForegroundColor Yellow
Write-Host "    dotnet test $slnFile  -- run all tests" -ForegroundColor White
Write-Host "    git add . && git commit -m 'test: add all test projects'" -ForegroundColor White
Write-Host ""
Write-Host "===============================================================================" -ForegroundColor Green
Write-Host ""

# ==============================================================================
# generate-tests.ps1
# Axbus Framework - All Test Projects Code Generation Script
# Copyright (c) 2026 Axel Johnson International. All rights reserved.
#
# USAGE:
#   PowerShell -ExecutionPolicy Bypass -File .\scripts\generate-tests.ps1
#
# GENERATES:
#   Axbus.Tests.Common              (shared test infrastructure)
#   Axbus.Core.Tests                (enum + model unit tests)
#   Axbus.Application.Tests         (pipeline + middleware + plugin tests)
#   Axbus.Infrastructure.Tests      (connector + file system tests)
#   Axbus.Plugin.Reader.Json.Tests  (JSON reader/parser/transformer tests)
#   Axbus.Plugin.Writer.Csv.Tests   (CSV writer + schema tests)
#   Axbus.Plugin.Writer.Excel.Tests (Excel writer + schema tests)
#   Axbus.Integration.Tests         (end-to-end JSON->CSV and JSON->Excel)
#
# PREREQUISITES:
#   - All previous generate-*.ps1 scripts must have been run first
#   - Run from the repository root
# ==============================================================================

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$ScriptVersion = "1.0.0"
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
function Write-Info { param([string]$m) Write-Host "      [..] $m" -ForegroundColor White }

function New-SourceFile {
    param([string]$RootPath, [string]$RelativePath, [string]$Content)
    $fullPath  = Join-Path $RootPath $RelativePath
    $directory = Split-Path $fullPath -Parent
    if (-not [string]::IsNullOrWhiteSpace($directory) -and -not (Test-Path $directory)) {
        New-Item -ItemType Directory -Path $directory -Force | Out-Null
    }
    [System.IO.File]::WriteAllText(
        [System.IO.Path]::GetFullPath($fullPath),
        $Content,
        [System.Text.UTF8Encoding]::new($false)
    )
    Write-Ok $RelativePath
}

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
/// a NullLogger factory for tests that do not require log output,
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
    /// Use when a test needs a logger but does not need to assert on log output.
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
    /// Disposes the container if it implements <see cref="IDisposable"/>.
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
    /// Override this method to register additional services required by the test class.
    /// Called during <see cref="SetUp"/> before the service provider is built.
    /// </summary>
    /// <param name="services">The service collection to register services into.</param>
    protected virtual void ConfigureServices(IServiceCollection services)
    {
    }

    /// <summary>
    /// Creates a typed NullLogger instance for use in tests that require
    /// a concrete logger but do not need to assert on log output.
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
/// selective overrides via a fluent API. Use this builder in test setup
/// instead of constructing modules directly to keep tests readable
/// and resilient to model changes.
/// </summary>
public sealed class ConversionModuleBuilder
{
    private string conversionName = "TestModule";
    private string description    = "Test conversion module";
    private bool isEnabled        = true;
    private int executionOrder    = 1;
    private bool continueOnError  = true;
    private bool runInParallel    = false;
    private string sourceFormat   = "json";
    private string targetFormat   = "csv";
    private string? pluginOverride;
    private SourceOptions source  = new() { Path = "C:/test/input", FilePattern = "*.json" };
    private TargetOptions target  = new() { Path = "C:/test/output" };
    private PipelineOptions pipeline = new();

    /// <summary>Sets the conversion name.</summary>
    public ConversionModuleBuilder WithName(string name)
    { conversionName = name; return this; }

    /// <summary>Sets the module as disabled.</summary>
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

    /// <summary>Sets the explicit plugin override.</summary>
    public ConversionModuleBuilder WithPluginOverride(string pluginId)
    { pluginOverride = pluginId; return this; }

    /// <summary>Sets parallel execution.</summary>
    public ConversionModuleBuilder RunningInParallel()
    { runInParallel = true; return this; }

    /// <summary>
    /// Builds and returns the configured <see cref="ConversionModule"/>.
    /// </summary>
    /// <returns>A new <see cref="ConversionModule"/> with the configured properties.</returns>
    public ConversionModule Build() => new()
    {
        ConversionName = conversionName,
        Description    = description,
        IsEnabled      = isEnabled,
        ExecutionOrder = executionOrder,
        ContinueOnError = continueOnError,
        RunInParallel  = runInParallel,
        SourceFormat   = sourceFormat,
        TargetFormat   = targetFormat,
        PluginOverride = pluginOverride,
        Source         = source,
        Target         = target,
        Pipeline       = pipeline,
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
/// Eliminates the need for test data files for simple unit test scenarios.
/// Use <see cref="ToStream"/> to convert JSON strings to streams suitable
/// for passing to parsers and readers under test.
/// </summary>
public static class JsonTestDataHelper
{
    /// <summary>
    /// Converts a JSON string to a readable <see cref="MemoryStream"/>.
    /// The stream is positioned at the beginning and ready to read.
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
    /// <param name="count">The number of objects to include in the array.</param>
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
    /// Creates a stream containing a JSON array with nested objects.
    /// Each object has <c>id</c>, <c>type</c> and a nested <c>address</c> object.
    /// </summary>
    /// <param name="count">The number of objects to include.</param>
    /// <returns>A <see cref="MemoryStream"/> containing the nested JSON array.</returns>
    public static MemoryStream NestedArray(int count = 2)
    {
        var items = Enumerable.Range(1, count).Select(i => new
        {
            id   = i.ToString(),
            type = "Order",
            customer = new
            {
                name = $"Customer {i}",
                address = new { city = "Stockholm", country = "Sweden" },
            },
        });

        return ToStream(JsonSerializer.Serialize(items));
    }

    /// <summary>
    /// Creates a stream containing a JSON array where each object has a nested array field.
    /// Used for testing array explosion behaviour.
    /// </summary>
    /// <param name="itemsPerArray">Number of items in each nested array.</param>
    /// <returns>A <see cref="MemoryStream"/> containing the explosion test JSON.</returns>
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
/// and collections of flattened rows. Reduces boilerplate in test assertions
/// and produces clear failure messages that include row number and values.
/// </summary>
public static class FlattenedRowAssertions
{
    /// <summary>
    /// Asserts that <paramref name="row"/> contains the expected
    /// <paramref name="columnName"/> with the expected <paramref name="value"/>.
    /// </summary>
    /// <param name="row">The row to check.</param>
    /// <param name="columnName">The column name to look up.</param>
    /// <param name="value">The expected value for the column.</param>
    public static void HasValue(FlattenedRow row, string columnName, string value)
    {
        Assert.That(
            row.Values.ContainsKey(columnName),
            Is.True,
            $"Row {row.RowNumber} does not contain column '{columnName}'. " +
            $"Columns present: {string.Join(", ", row.Values.Keys)}");

        Assert.That(
            row.Values[columnName],
            Is.EqualTo(value),
            $"Row {row.RowNumber} column '{columnName}' expected '{value}' " +
            $"but was '{row.Values[columnName]}'.");
    }

    /// <summary>
    /// Asserts that <paramref name="rows"/> contains exactly
    /// <paramref name="expectedCount"/> rows.
    /// </summary>
    /// <param name="rows">The row collection to check.</param>
    /// <param name="expectedCount">The expected number of rows.</param>
    public static void HasCount(IReadOnlyList<FlattenedRow> rows, int expectedCount)
    {
        Assert.That(
            rows.Count,
            Is.EqualTo(expectedCount),
            $"Expected {expectedCount} rows but got {rows.Count}.");
    }

    /// <summary>
    /// Asserts that all rows in <paramref name="rows"/> contain the
    /// specified <paramref name="columnName"/>.
    /// </summary>
    /// <param name="rows">The rows to check.</param>
    /// <param name="columnName">The column name that must be present in every row.</param>
    public static void AllHaveColumn(IReadOnlyList<FlattenedRow> rows, string columnName)
    {
        foreach (var row in rows)
        {
            Assert.That(
                row.Values.ContainsKey(columnName),
                Is.True,
                $"Row {row.RowNumber} is missing expected column '{columnName}'.");
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
/// Verifies that flag combination, containment checks and zero values
/// behave correctly for downstream plugin resolution logic.
/// </summary>
[TestFixture]
public sealed class OutputFormatTests : AxbusTestBase
{
    /// <summary>
    /// Should_HaveNoneAsZeroValue_When_EnumIsInspected.
    /// </summary>
    [Test]
    public void Should_HaveNoneAsZeroValue_When_EnumIsInspected()
    {
        Assert.That((int)OutputFormat.None, Is.EqualTo(0));
    }

    /// <summary>
    /// Should_SupportFlagCombination_When_MultipleFormatsSelected.
    /// </summary>
    [Test]
    public void Should_SupportFlagCombination_When_MultipleFormatsSelected()
    {
        var combined = OutputFormat.Csv | OutputFormat.Excel;

        Assert.That(combined.HasFlag(OutputFormat.Csv),   Is.True);
        Assert.That(combined.HasFlag(OutputFormat.Excel), Is.True);
        Assert.That(combined.HasFlag(OutputFormat.Text),  Is.False);
    }

    /// <summary>
    /// Should_NotContainNone_When_FlagsAreSet.
    /// </summary>
    [Test]
    public void Should_NotContainNone_When_FlagsAreSet()
    {
        var format = OutputFormat.Csv;
        Assert.That(format, Is.Not.EqualTo(OutputFormat.None));
    }

    /// <summary>
    /// Should_ReturnDistinctBitValues_When_EnumValuesCompared.
    /// </summary>
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
/// Verifies the Bundled convenience value and individual capability flag behaviour.
/// </summary>
[TestFixture]
public sealed class PluginCapabilitiesTests : AxbusTestBase
{
    /// <summary>
    /// Should_ContainAllCoreStageCaps_When_BundledValueInspected.
    /// </summary>
    [Test]
    public void Should_ContainAllCoreStageCaps_When_BundledValueInspected()
    {
        var bundled = PluginCapabilities.Bundled;

        Assert.That(bundled.HasFlag(PluginCapabilities.Reader),      Is.True);
        Assert.That(bundled.HasFlag(PluginCapabilities.Parser),      Is.True);
        Assert.That(bundled.HasFlag(PluginCapabilities.Transformer),  Is.True);
        Assert.That(bundled.HasFlag(PluginCapabilities.Writer),      Is.True);
    }

    /// <summary>
    /// Should_NotContainValidatorOrFilter_When_BundledValueInspected.
    /// </summary>
    [Test]
    public void Should_NotContainValidatorOrFilter_When_BundledValueInspected()
    {
        var bundled = PluginCapabilities.Bundled;

        Assert.That(bundled.HasFlag(PluginCapabilities.Validator), Is.False);
        Assert.That(bundled.HasFlag(PluginCapabilities.Filter),    Is.False);
    }

    /// <summary>
    /// Should_AllowWriterOnlyPlugin_When_OnlyWriterCapabilitySet.
    /// </summary>
    [Test]
    public void Should_AllowWriterOnlyPlugin_When_OnlyWriterCapabilitySet()
    {
        var writerOnly = PluginCapabilities.Writer;

        Assert.That(writerOnly.HasFlag(PluginCapabilities.Writer),  Is.True);
        Assert.That(writerOnly.HasFlag(PluginCapabilities.Reader),  Is.False);
        Assert.That(writerOnly.HasFlag(PluginCapabilities.Parser),  Is.False);
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
/// Verifies factory methods, error collection and the static Success instance.
/// </summary>
[TestFixture]
public sealed class ValidationResultTests : AxbusTestBase
{
    /// <summary>
    /// Should_HaveIsValidTrue_When_SuccessFactoryUsed.
    /// </summary>
    [Test]
    public void Should_HaveIsValidTrue_When_SuccessFactoryUsed()
    {
        var result = ValidationResult.Success;

        Assert.That(result.IsValid,       Is.True);
        Assert.That(result.Errors.Count,  Is.EqualTo(0));
    }

    /// <summary>
    /// Should_HaveIsValidFalse_When_FailFactoryUsed.
    /// </summary>
    [Test]
    public void Should_HaveIsValidFalse_When_FailFactoryUsed()
    {
        var result = ValidationResult.Fail("Field is required.", "Value out of range.");

        Assert.That(result.IsValid,       Is.False);
        Assert.That(result.Errors.Count,  Is.EqualTo(2));
        Assert.That(result.Errors[0],     Is.EqualTo("Field is required."));
        Assert.That(result.Errors[1],     Is.EqualTo("Value out of range."));
    }

    /// <summary>
    /// Should_ReturnSameInstance_When_SuccessPropertyAccessedMultipleTimes.
    /// </summary>
    [Test]
    public void Should_ReturnSameInstance_When_SuccessPropertyAccessedMultipleTimes()
    {
        var first  = ValidationResult.Success;
        var second = ValidationResult.Success;

        Assert.That(ReferenceEquals(first, second), Is.True);
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
/// Verifies column ordering, format metadata and source file count.
/// </summary>
[TestFixture]
public sealed class SchemaDefinitionTests : AxbusTestBase
{
    /// <summary>
    /// Should_PreserveColumnOrder_When_SchemaCreatedWithOrderedList.
    /// </summary>
    [Test]
    public void Should_PreserveColumnOrder_When_SchemaCreatedWithOrderedList()
    {
        var columns = new[] { "id", "name", "customer.city", "amount" };
        var schema  = new SchemaDefinition(columns, "csv", sourceFileCount: 2);

        Assert.That(schema.Columns.Count, Is.EqualTo(4));
        Assert.That(schema.Columns[0],    Is.EqualTo("id"));
        Assert.That(schema.Columns[1],    Is.EqualTo("name"));
        Assert.That(schema.Columns[2],    Is.EqualTo("customer.city"));
        Assert.That(schema.Columns[3],    Is.EqualTo("amount"));
    }

    /// <summary>
    /// Should_StoreFormat_When_SchemaCreated.
    /// </summary>
    [Test]
    public void Should_StoreFormat_When_SchemaCreated()
    {
        var schema = new SchemaDefinition(new[] { "col1" }, "excel");
        Assert.That(schema.Format, Is.EqualTo("excel"));
    }

    /// <summary>
    /// Should_StoreSourceFileCount_When_SchemaCreated.
    /// </summary>
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
/// Verifies case-insensitive key lookup, metadata properties
/// and explosion flag behaviour.
/// </summary>
[TestFixture]
public sealed class FlattenedRowTests : AxbusTestBase
{
    /// <summary>
    /// Should_AllowCaseInsensitiveKeyLookup_When_ValuesAccessed.
    /// </summary>
    [Test]
    public void Should_AllowCaseInsensitiveKeyLookup_When_ValuesAccessed()
    {
        var row = new FlattenedRow();
        row.Values["CustomerId"] = "C001";

        Assert.That(row.Values.ContainsKey("customerid"), Is.True);
        Assert.That(row.Values.ContainsKey("CUSTOMERID"), Is.True);
        Assert.That(row.Values["customerId"],              Is.EqualTo("C001"));
    }

    /// <summary>
    /// Should_DefaultIsExplodedToFalse_When_RowCreated.
    /// </summary>
    [Test]
    public void Should_DefaultIsExplodedToFalse_When_RowCreated()
    {
        var row = new FlattenedRow();
        Assert.That(row.IsExploded, Is.False);
    }

    /// <summary>
    /// Should_StoreExplosionIndex_When_RowIsExploded.
    /// </summary>
    [Test]
    public void Should_StoreExplosionIndex_When_RowIsExploded()
    {
        var row = new FlattenedRow { IsExploded = true, ExplosionIndex = 3 };

        Assert.That(row.IsExploded,      Is.True);
        Assert.That(row.ExplosionIndex,  Is.EqualTo(3));
    }

    /// <summary>
    /// Should_StoreSourcePathAndRowNumber_When_MetadataSet.
    /// </summary>
    [Test]
    public void Should_StoreSourcePathAndRowNumber_When_MetadataSet()
    {
        var row = new FlattenedRow
        {
            RowNumber      = 42,
            SourceFilePath = @"C:\input\orders.json",
        };

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
/// Verifies the static factory methods and property values.
/// </summary>
[TestFixture]
public sealed class PluginCompatibilityTests : AxbusTestBase
{
    /// <summary>
    /// Should_BeCompatible_When_CompatibleFactoryUsed.
    /// </summary>
    [Test]
    public void Should_BeCompatible_When_CompatibleFactoryUsed()
    {
        var result = PluginCompatibility.Compatible;

        Assert.That(result.IsCompatible, Is.True);
        Assert.That(result.Reason,       Is.Null);
    }

    /// <summary>
    /// Should_BeIncompatible_When_IncompatibleFactoryUsedWithReason.
    /// </summary>
    [Test]
    public void Should_BeIncompatible_When_IncompatibleFactoryUsedWithReason()
    {
        var reason = "Plugin requires framework v2.0 but current version is v1.0.";
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
/// Verifies that Duration is set on the result and that the next delegate is invoked.
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

    /// <summary>
    /// Should_SetDurationOnResult_When_StageCompletes.
    /// </summary>
    [Test]
    public async Task Should_SetDurationOnResult_When_StageCompletes()
    {
        var context = new PipelineMiddlewareContext("TestModule", "test.plugin", PipelineStage.Read);
        var result  = await sut.InvokeAsync(context, () => Task.FromResult(
            new PipelineStageResult { Success = true, Stage = PipelineStage.Read }));

        Assert.That(result.Duration, Is.GreaterThanOrEqualTo(TimeSpan.Zero));
    }

    /// <summary>
    /// Should_InvokeNextDelegate_When_MiddlewareExecuted.
    /// </summary>
    [Test]
    public async Task Should_InvokeNextDelegate_When_MiddlewareExecuted()
    {
        var nextInvoked = false;
        var context     = new PipelineMiddlewareContext("TestModule", "test.plugin", PipelineStage.Parse);

        await sut.InvokeAsync(context, () =>
        {
            nextInvoked = true;
            return Task.FromResult(new PipelineStageResult { Success = true });
        });

        Assert.That(nextInvoked, Is.True);
    }

    /// <summary>
    /// Should_PassThroughFailedResult_When_NextReturnsFailure.
    /// </summary>
    [Test]
    public async Task Should_PassThroughFailedResult_When_NextReturnsFailure()
    {
        var context = new PipelineMiddlewareContext("TestModule", "test.plugin", PipelineStage.Write);
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
/// Verifies that middleware is applied in correct order and that the
/// innermost stage action is always invoked.
/// </summary>
[TestFixture]
public sealed class MiddlewarePipelineBuilderTests : AxbusTestBase
{
    /// <summary>
    /// Should_InvokeStageAction_When_NoMiddlewareRegistered.
    /// </summary>
    [Test]
    public async Task Should_InvokeStageAction_When_NoMiddlewareRegistered()
    {
        var builder     = new MiddlewarePipelineBuilder(new List<IPipelineMiddleware>());
        var context     = new PipelineMiddlewareContext("M", "p", PipelineStage.Read);
        var actionCalled = false;

        await builder.ExecuteAsync(context, () =>
        {
            actionCalled = true;
            return Task.FromResult(new PipelineStageResult { Success = true });
        });

        Assert.That(actionCalled, Is.True);
    }

    /// <summary>
    /// Should_InvokeMiddlewareOutermostFirst_When_MultipleMiddlewareRegistered.
    /// </summary>
    [Test]
    public async Task Should_InvokeMiddlewareOutermostFirst_When_MultipleMiddlewareRegistered()
    {
        var order   = new List<int>();
        var middle1 = new OrderRecordingMiddleware(1, order);
        var middle2 = new OrderRecordingMiddleware(2, order);
        var builder = new MiddlewarePipelineBuilder(new[] { middle1, middle2 });
        var context = new PipelineMiddlewareContext("M", "p", PipelineStage.Transform);

        await builder.ExecuteAsync(context, () =>
            Task.FromResult(new PipelineStageResult { Success = true }));

        // middle1 (outermost) should execute before middle2
        Assert.That(order[0], Is.EqualTo(1));
        Assert.That(order[1], Is.EqualTo(2));
    }

    /// <summary>
    /// A test middleware that records its execution order into a shared list.
    /// </summary>
    private sealed class OrderRecordingMiddleware : IPipelineMiddleware
    {
        private readonly int id;
        private readonly List<int> order;

        public OrderRecordingMiddleware(int id, List<int> order)
        { this.id = id; this.order = order; }

        public async Task<PipelineStageResult> InvokeAsync(
            IPipelineMiddlewareContext context,
            PipelineStageDelegate next)
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
/// Verifies plugin registration, resolution by format pair and by ID,
/// and conflict strategy behaviour.
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

        sut = new PluginRegistry(
            NullLogger<PluginRegistry>(),
            Options.Create(settings));
    }

    /// <summary>
    /// Should_ResolvePlugin_When_PluginRegisteredForFormatPair.
    /// </summary>
    [Test]
    public void Should_ResolvePlugin_When_PluginRegisteredForFormatPair()
    {
        var descriptor = BuildDescriptor("test.reader.json", "json", null);
        sut.Register(descriptor);

        var plugin = sut.Resolve("json", string.Empty);
        Assert.That(plugin.PluginId, Is.EqualTo("test.reader.json"));
    }

    /// <summary>
    /// Should_ResolvePluginById_When_ExplicitOverrideProvided.
    /// </summary>
    [Test]
    public void Should_ResolvePluginById_When_ExplicitOverrideProvided()
    {
        var descriptor = BuildDescriptor("axbus.plugin.writer.csv", null, "csv");
        sut.Register(descriptor);

        var plugin = sut.ResolveById("axbus.plugin.writer.csv");
        Assert.That(plugin.PluginId, Is.EqualTo("axbus.plugin.writer.csv"));
    }

    /// <summary>
    /// Should_ThrowPluginException_When_NoPluginRegisteredForFormat.
    /// </summary>
    [Test]
    public void Should_ThrowPluginException_When_NoPluginRegisteredForFormat()
    {
        Assert.Throws<AxbusPluginException>(() => sut.Resolve("xml", "csv"));
    }

    /// <summary>
    /// Should_ThrowPluginException_When_PluginIdNotRegistered.
    /// </summary>
    [Test]
    public void Should_ThrowPluginException_When_PluginIdNotRegistered()
    {
        Assert.Throws<AxbusPluginException>(() => sut.ResolveById("non.existent.plugin"));
    }

    /// <summary>
    /// Should_ReturnAllDescriptors_When_GetAllCalled.
    /// </summary>
    [Test]
    public void Should_ReturnAllDescriptors_When_GetAllCalled()
    {
        sut.Register(BuildDescriptor("plugin.a", "json", null));
        sut.Register(BuildDescriptor("plugin.b", null, "csv"));

        Assert.That(sut.GetAll().Count, Is.EqualTo(2));
    }

    private static PluginDescriptor BuildDescriptor(
        string pluginId,
        string? sourceFormat,
        string? targetFormat)
    {
        return new PluginDescriptor
        {
            Instance = new StubPlugin(pluginId),
            Manifest = new PluginManifest
            {
                PluginId      = pluginId,
                SourceFormat  = sourceFormat,
                TargetFormat  = targetFormat,
                Version       = "1.0.0",
                FrameworkVersion = "1.0.0",
            },
            Assembly  = typeof(PluginRegistryTests).Assembly,
            IsIsolated = false,
        };
    }

    private sealed class StubPlugin : IPlugin
    {
        public string PluginId { get; }
        public string Name               => PluginId;
        public Version Version           => new(1, 0, 0);
        public Version MinFrameworkVersion => new(1, 0, 0);
        public PluginCapabilities Capabilities => PluginCapabilities.Reader;

        public StubPlugin(string pluginId) => PluginId = pluginId;

        public ISourceReader?    CreateReader(IServiceProvider services)     => null;
        public IFormatParser?    CreateParser(IServiceProvider services)     => null;
        public IDataTransformer? CreateTransformer(IServiceProvider services) => null;
        public IOutputWriter?    CreateWriter(IServiceProvider services)     => null;
        public Task InitializeAsync(IPluginContext context, CancellationToken ct) => Task.CompletedTask;
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
/// Verifies that registered consumers receive progress updates
/// and that multiple consumers all receive the same update.
/// </summary>
[TestFixture]
public sealed class ProgressReporterTests : AxbusTestBase
{
    private ProgressReporter sut = null!;

    /// <inheritdoc/>
    public override void SetUp()
    {
        base.SetUp();
        sut = new ProgressReporter();
    }

    /// <summary>
    /// Should_DeliverProgressToConsumer_When_ConsumerRegistered.
    /// </summary>
    [Test]
    public void Should_DeliverProgressToConsumer_When_ConsumerRegistered()
    {
        ConversionProgress? received = null;
        sut.Register(new Progress<ConversionProgress>(p => received = p));

        sut.Report(new ConversionProgress
        {
            ModuleName      = "TestModule",
            PercentComplete = 50,
            Status          = ConversionStatus.Converting,
        });

        Assert.That(received,                     Is.Not.Null);
        Assert.That(received!.ModuleName,         Is.EqualTo("TestModule"));
        Assert.That(received.PercentComplete,     Is.EqualTo(50));
    }

    /// <summary>
    /// Should_DeliverToAllConsumers_When_MultipleConsumersRegistered.
    /// </summary>
    [Test]
    public void Should_DeliverToAllConsumers_When_MultipleConsumersRegistered()
    {
        var count = 0;
        sut.Register(new Progress<ConversionProgress>(_ => count++));
        sut.Register(new Progress<ConversionProgress>(_ => count++));

        sut.Report(new ConversionProgress { ModuleName = "M" });

        Assert.That(count, Is.EqualTo(2));
    }

    /// <summary>
    /// Should_NotThrow_When_NoConsumersRegistered.
    /// </summary>
    [Test]
    public void Should_NotThrow_When_NoConsumersRegistered()
    {
        Assert.DoesNotThrow(() =>
            sut.Report(new ConversionProgress { ModuleName = "M" }));
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
/// Verifies correct deserialisation of valid manifests and appropriate
/// exceptions for missing or malformed manifest files.
/// </summary>
[TestFixture]
public sealed class PluginManifestReaderTests : AxbusTestBase
{
    private PluginManifestReader sut = null!;
    private string tempDir = null!;

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
        if (Directory.Exists(tempDir))
        {
            Directory.Delete(tempDir, recursive: true);
        }
    }

    /// <summary>
    /// Should_DeserialiseManifest_When_ValidJsonFileProvided.
    /// </summary>
    [Test]
    public async Task Should_DeserialiseManifest_When_ValidJsonFileProvided()
    {
        var path = Path.Combine(tempDir, "test.manifest.json");
        var json = @"{
            ""Name"": ""TestPlugin"",
            ""PluginId"": ""test.plugin"",
            ""Version"": ""1.0.0"",
            ""FrameworkVersion"": ""1.0.0"",
            ""SourceFormat"": ""json"",
            ""TargetFormat"": null,
            ""SupportedStages"": [""Read"", ""Parse""],
            ""IsBundled"": false,
            ""Author"": ""Axel Johnson"",
            ""Description"": ""Test plugin"",
            ""Dependencies"": []
        }";

        await File.WriteAllTextAsync(path, json, Encoding.UTF8);

        var manifest = await sut.ReadAsync(path, CancellationToken.None);

        Assert.That(manifest.Name,             Is.EqualTo("TestPlugin"));
        Assert.That(manifest.PluginId,         Is.EqualTo("test.plugin"));
        Assert.That(manifest.Version,          Is.EqualTo("1.0.0"));
        Assert.That(manifest.SourceFormat,     Is.EqualTo("json"));
        Assert.That(manifest.SupportedStages.Count, Is.EqualTo(2));
    }

    /// <summary>
    /// Should_ThrowPluginException_When_ManifestFileNotFound.
    /// </summary>
    [Test]
    public void Should_ThrowPluginException_When_ManifestFileNotFound()
    {
        Assert.ThrowsAsync<AxbusPluginException>(async () =>
            await sut.ReadAsync(
                Path.Combine(tempDir, "missing.manifest.json"),
                CancellationToken.None));
    }

    /// <summary>
    /// Should_ThrowPluginException_When_ManifestContainsInvalidJson.
    /// </summary>
    [Test]
    public async Task Should_ThrowPluginException_When_ManifestContainsInvalidJson()
    {
        var path = Path.Combine(tempDir, "bad.manifest.json");
        await File.WriteAllTextAsync(path, "{ invalid json }", Encoding.UTF8);

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
/// Uses a temporary directory with real files to verify scan behaviour.
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
        if (Directory.Exists(tempDir))
            Directory.Delete(tempDir, recursive: true);
    }

    /// <summary>
    /// Should_ReturnMatchingFiles_When_PatternMatches.
    /// </summary>
    [Test]
    public void Should_ReturnMatchingFiles_When_PatternMatches()
    {
        File.WriteAllText(Path.Combine(tempDir, "a.json"), "[]");
        File.WriteAllText(Path.Combine(tempDir, "b.json"), "[]");
        File.WriteAllText(Path.Combine(tempDir, "c.txt"),  "text");

        var results = sut.Scan(tempDir, "*.json").ToList();

        Assert.That(results.Count, Is.EqualTo(2));
        Assert.That(results.All(f => f.EndsWith(".json")), Is.True);
    }

    /// <summary>
    /// Should_ReturnEmpty_When_FolderDoesNotExist.
    /// </summary>
    [Test]
    public void Should_ReturnEmpty_When_FolderDoesNotExist()
    {
        var results = sut.Scan(Path.Combine(tempDir, "nonexistent"), "*.json");
        Assert.That(results, Is.Empty);
    }

    /// <summary>
    /// Should_ReturnEmpty_When_NoFilesMatchPattern.
    /// </summary>
    [Test]
    public void Should_ReturnEmpty_When_NoFilesMatchPattern()
    {
        File.WriteAllText(Path.Combine(tempDir, "a.csv"), "data");
        var results = sut.Scan(tempDir, "*.json");
        Assert.That(results, Is.Empty);
    }

    /// <summary>
    /// Should_ReturnFilesInAlphaOrder_When_MultipleFilesPresent.
    /// </summary>
    [Test]
    public void Should_ReturnFilesInAlphaOrder_When_MultipleFilesPresent()
    {
        File.WriteAllText(Path.Combine(tempDir, "c.json"), "[]");
        File.WriteAllText(Path.Combine(tempDir, "a.json"), "[]");
        File.WriteAllText(Path.Combine(tempDir, "b.json"), "[]");

        var results = sut.Scan(tempDir, "*.json").ToList();

        Assert.That(Path.GetFileName(results[0]), Is.EqualTo("a.json"));
        Assert.That(Path.GetFileName(results[1]), Is.EqualTo("b.json"));
        Assert.That(Path.GetFileName(results[2]), Is.EqualTo("c.json"));
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
/// Verifies that DLL + manifest pairs are detected correctly
/// and that orphaned DLLs without manifests are skipped.
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
        if (Directory.Exists(tempDir))
            Directory.Delete(tempDir, recursive: true);
    }

    /// <summary>
    /// Should_ReturnFileSet_When_DllAndManifestBothPresent.
    /// </summary>
    [Test]
    public void Should_ReturnFileSet_When_DllAndManifestBothPresent()
    {
        File.WriteAllText(Path.Combine(tempDir, "MyPlugin.dll"),           "fake dll");
        File.WriteAllText(Path.Combine(tempDir, "MyPlugin.manifest.json"), "{}");

        var results = sut.Scan(tempDir, scanSubFolders: false).ToList();

        Assert.That(results.Count, Is.EqualTo(1));
        Assert.That(Path.GetFileName(results[0].AssemblyPath), Is.EqualTo("MyPlugin.dll"));
        Assert.That(File.Exists(results[0].ManifestPath),      Is.True);
    }

    /// <summary>
    /// Should_SkipDll_When_ManifestFileMissing.
    /// </summary>
    [Test]
    public void Should_SkipDll_When_ManifestFileMissing()
    {
        File.WriteAllText(Path.Combine(tempDir, "OrphanPlugin.dll"), "fake dll");

        var results = sut.Scan(tempDir, scanSubFolders: false).ToList();

        Assert.That(results, Is.Empty);
    }

    /// <summary>
    /// Should_ReturnEmpty_When_PluginFolderDoesNotExist.
    /// </summary>
    [Test]
    public void Should_ReturnEmpty_When_PluginFolderDoesNotExist()
    {
        var results = sut.Scan(Path.Combine(tempDir, "missing"), scanSubFolders: false);
        Assert.That(results, Is.Empty);
    }
}
'@

New-SourceFile $InfraTestsRoot "Tests/Connectors/LocalFileTargetConnectorTests.cs" @'
// <copyright file="LocalFileTargetConnectorTests.cs" company="Axel Johnson International">
// Copyright (c) 2026 Axel Johnson International. All rights reserved.
// </copyright>

namespace Axbus.Infrastructure.Tests.Tests.Connectors;

using System.Text;
using Axbus.Core.Exceptions;
using Axbus.Core.Models.Configuration;
using Axbus.Infrastructure.Connectors;
using Axbus.Tests.Common.Base;
using NUnit.Framework;

/// <summary>
/// Unit tests for <see cref="LocalFileTargetConnector"/>.
/// Uses a temporary directory to verify file creation and error handling.
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
        if (Directory.Exists(tempDir))
            Directory.Delete(tempDir, recursive: true);
    }

    /// <summary>
    /// Should_WriteFile_When_ValidStreamAndOptionsProvided.
    /// </summary>
    [Test]
    public async Task Should_WriteFile_When_ValidStreamAndOptionsProvided()
    {
        var content  = "id,name\n1,Test";
        var data     = new MemoryStream(Encoding.UTF8.GetBytes(content));
        var options  = new TargetOptions { Path = tempDir };

        var outputPath = await sut.WriteAsync(data, "output.csv", options, CancellationToken.None);

        Assert.That(File.Exists(outputPath), Is.True);
        var written = await File.ReadAllTextAsync(outputPath);
        Assert.That(written, Is.EqualTo(content));
    }

    /// <summary>
    /// Should_CreateDirectory_When_TargetFolderDoesNotExist.
    /// </summary>
    [Test]
    public async Task Should_CreateDirectory_When_TargetFolderDoesNotExist()
    {
        var newFolder = Path.Combine(tempDir, "new_subfolder");
        var data      = new MemoryStream(Encoding.UTF8.GetBytes("data"));
        var options   = new TargetOptions { Path = newFolder };

        var outputPath = await sut.WriteAsync(data, "file.csv", options, CancellationToken.None);

        Assert.That(Directory.Exists(newFolder), Is.True);
        Assert.That(File.Exists(outputPath),     Is.True);
    }

    /// <summary>
    /// Should_ReturnFullPath_When_WriteSucceeds.
    /// </summary>
    [Test]
    public async Task Should_ReturnFullPath_When_WriteSucceeds()
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
/// Verifies AllFiles and SingleFile read modes and missing path handling.
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
        if (Directory.Exists(tempDir))
            Directory.Delete(tempDir, recursive: true);
    }

    /// <summary>
    /// Should_ReturnOneStreamPerFile_When_AllFilesModeAndMultipleFilesPresent.
    /// </summary>
    [Test]
    public async Task Should_ReturnOneStreamPerFile_When_AllFilesModeAndMultipleFilesPresent()
    {
        File.WriteAllText(Path.Combine(tempDir, "a.json"), "[{}]");
        File.WriteAllText(Path.Combine(tempDir, "b.json"), "[{}]");

        var options = new SourceOptions
        {
            Path        = tempDir,
            FilePattern = "*.json",
            ReadMode    = "AllFiles",
        };

        var streams = new List<Stream>();
        await foreach (var s in sut.GetSourceStreamsAsync(options, CancellationToken.None))
        {
            streams.Add(s);
        }

        foreach (var stream in streams) stream.Dispose();

        Assert.That(streams.Count, Is.EqualTo(2));
    }

    /// <summary>
    /// Should_ThrowConnectorException_When_FolderDoesNotExist.
    /// </summary>
    [Test]
    public void Should_ThrowConnectorException_When_FolderDoesNotExist()
    {
        var options = new SourceOptions
        {
            Path     = Path.Combine(tempDir, "nonexistent"),
            ReadMode = "AllFiles",
        };

        Assert.ThrowsAsync<AxbusConnectorException>(async () =>
        {
            await foreach (var _ in sut.GetSourceStreamsAsync(options, CancellationToken.None))
            { }
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
/// Verifies stream opening, metadata and error handling for missing files.
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
        if (Directory.Exists(tempDir))
            Directory.Delete(tempDir, recursive: true);
    }

    /// <summary>
    /// Should_ReturnSourceData_When_JsonFileExists.
    /// </summary>
    [Test]
    public async Task Should_ReturnSourceData_When_JsonFileExists()
    {
        var filePath = Path.Combine(tempDir, "test.json");
        await File.WriteAllTextAsync(filePath, "[{\"id\":1}]");

        var options    = new SourceOptions { Path = filePath };
        var sourceData = await sut.ReadAsync(options, CancellationToken.None);

        Assert.That(sourceData,            Is.Not.Null);
        Assert.That(sourceData.Format,     Is.EqualTo("json"));
        Assert.That(sourceData.SourcePath, Is.EqualTo(filePath));
        Assert.That(sourceData.RawData,    Is.Not.Null);
        Assert.That(sourceData.ContentLength, Is.GreaterThan(0));

        await sourceData.RawData.DisposeAsync();
    }

    /// <summary>
    /// Should_ThrowConnectorException_When_FileNotFound.
    /// </summary>
    [Test]
    public void Should_ThrowConnectorException_When_FileNotFound()
    {
        var options = new SourceOptions { Path = Path.Combine(tempDir, "missing.json") };

        Assert.ThrowsAsync<AxbusConnectorException>(async () =>
            await sut.ReadAsync(options, CancellationToken.None));
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
/// Verifies element streaming for flat arrays, nested objects,
/// empty arrays and invalid JSON.
/// </summary>
[TestFixture]
public sealed class JsonFormatParserTests : AxbusTestBase
{
    private JsonFormatParser CreateSut(string? rootArrayKey = null) =>
        new(NullLogger<JsonFormatParser>(),
            new JsonReaderPluginOptions { RootArrayKey = rootArrayKey });

    /// <summary>
    /// Should_StreamAllElements_When_JsonContainsFlatArray.
    /// </summary>
    [Test]
    public async Task Should_StreamAllElements_When_JsonContainsFlatArray()
    {
        var stream     = JsonTestDataHelper.FlatArray(count: 3);
        var sourceData = new SourceData(stream, "test.json", "json");
        var sut        = CreateSut();

        var parsed   = await sut.ParseAsync(sourceData, CancellationToken.None);
        var elements = new List<JsonElement>();

        await foreach (var el in parsed.Elements)
            elements.Add(el);

        Assert.That(elements.Count, Is.EqualTo(3));
    }

    /// <summary>
    /// Should_ReturnEmptyStream_When_JsonArrayIsEmpty.
    /// </summary>
    [Test]
    public async Task Should_ReturnEmptyStream_When_JsonArrayIsEmpty()
    {
        var stream     = JsonTestDataHelper.EmptyArray();
        var sourceData = new SourceData(stream, "empty.json", "json");
        var sut        = CreateSut();

        var parsed   = await sut.ParseAsync(sourceData, CancellationToken.None);
        var elements = new List<JsonElement>();

        await foreach (var el in parsed.Elements)
            elements.Add(el);

        Assert.That(elements, Is.Empty);
    }

    /// <summary>
    /// Should_ThrowPipelineException_When_JsonIsInvalid.
    /// </summary>
    [Test]
    public async Task Should_ThrowPipelineException_When_JsonIsInvalid()
    {
        var stream     = JsonTestDataHelper.InvalidJson();
        var sourceData = new SourceData(stream, "bad.json", "json");
        var sut        = CreateSut();

        var parsed = await sut.ParseAsync(sourceData, CancellationToken.None);

        Assert.ThrowsAsync<AxbusPipelineException>(async () =>
        {
            await foreach (var _ in parsed.Elements) { }
        });
    }

    /// <summary>
    /// Should_DrillIntoNamedKey_When_RootArrayKeyConfigured.
    /// </summary>
    [Test]
    public async Task Should_DrillIntoNamedKey_When_RootArrayKeyConfigured()
    {
        var json       = "{\"items\":[{\"id\":1},{\"id\":2}]}";
        var stream     = JsonTestDataHelper.ToStream(json);
        var sourceData = new SourceData(stream, "test.json", "json");
        var sut        = CreateSut(rootArrayKey: "items");

        var parsed   = await sut.ParseAsync(sourceData, CancellationToken.None);
        var elements = new List<JsonElement>();

        await foreach (var el in parsed.Elements)
            elements.Add(el);

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
/// Verifies flat row production, dot-notation field naming,
/// array explosion and empty input handling.
/// </summary>
[TestFixture]
public sealed class JsonDataTransformerTests : AxbusTestBase
{
    private JsonFormatParser   parser      = null!;
    private JsonDataTransformer transformer = null!;

    /// <inheritdoc/>
    public override void SetUp()
    {
        base.SetUp();
        var opts    = new JsonReaderPluginOptions { MaxExplosionDepth = 3 };
        parser      = new JsonFormatParser(NullLogger<JsonFormatParser>(), opts);
        transformer = new JsonDataTransformer(NullLogger<JsonDataTransformer>(), opts);
    }

    /// <summary>
    /// Should_ProduceFlatRows_When_JsonIsFlatArray.
    /// </summary>
    [Test]
    public async Task Should_ProduceFlatRows_When_JsonIsFlatArray()
    {
        var sourceData    = new SourceData(JsonTestDataHelper.FlatArray(3), "flat.json", "json");
        var parsedData    = await parser.ParseAsync(sourceData, CancellationToken.None);
        var transformed   = await transformer.TransformAsync(parsedData, new PipelineOptions(), CancellationToken.None);
        var rows          = await FlattenedRowAssertions.CollectAsync(transformed.Rows);

        FlattenedRowAssertions.HasCount(rows, 3);
        FlattenedRowAssertions.AllHaveColumn(rows, "id");
        FlattenedRowAssertions.AllHaveColumn(rows, "name");
    }

    /// <summary>
    /// Should_UseDotNotation_When_JsonHasNestedObjects.
    /// </summary>
    [Test]
    public async Task Should_UseDotNotation_When_JsonHasNestedObjects()
    {
        var sourceData  = new SourceData(JsonTestDataHelper.NestedArray(1), "nested.json", "json");
        var parsedData  = await parser.ParseAsync(sourceData, CancellationToken.None);
        var transformed = await transformer.TransformAsync(parsedData, new PipelineOptions(), CancellationToken.None);
        var rows        = await FlattenedRowAssertions.CollectAsync(transformed.Rows);

        FlattenedRowAssertions.HasCount(rows, 1);
        FlattenedRowAssertions.AllHaveColumn(rows, "customer.address.city");
    }

    /// <summary>
    /// Should_ExplodeArrayIntoMultipleRows_When_NestedArrayPresent.
    /// </summary>
    [Test]
    public async Task Should_ExplodeArrayIntoMultipleRows_When_NestedArrayPresent()
    {
        var sourceData  = new SourceData(JsonTestDataHelper.ArrayForExplosion(3), "array.json", "json");
        var parsedData  = await parser.ParseAsync(sourceData, CancellationToken.None);
        var transformed = await transformer.TransformAsync(parsedData, new PipelineOptions(), CancellationToken.None);
        var rows        = await FlattenedRowAssertions.CollectAsync(transformed.Rows);

        // One parent object with 3 array items = 3 exploded rows
        Assert.That(rows.Count, Is.EqualTo(3));
        Assert.That(rows.All(r => r.IsExploded), Is.True);
    }

    /// <summary>
    /// Should_ProduceNoRows_When_JsonArrayIsEmpty.
    /// </summary>
    [Test]
    public async Task Should_ProduceNoRows_When_JsonArrayIsEmpty()
    {
        var sourceData  = new SourceData(JsonTestDataHelper.EmptyArray(), "empty.json", "json");
        var parsedData  = await parser.ParseAsync(sourceData, CancellationToken.None);
        var transformed = await transformer.TransformAsync(parsedData, new PipelineOptions(), CancellationToken.None);
        var rows        = await FlattenedRowAssertions.CollectAsync(transformed.Rows);

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
/// Verifies plugin metadata, capabilities and stage factory method contracts.
/// </summary>
[TestFixture]
public sealed class JsonReaderPluginTests : AxbusTestBase
{
    private JsonReaderPlugin sut = null!;

    /// <inheritdoc/>
    public override void SetUp()
    {
        base.SetUp();
        sut = new JsonReaderPlugin();
    }

    /// <summary>
    /// Should_HaveCorrectPluginId_When_Inspected.
    /// </summary>
    [Test]
    public void Should_HaveCorrectPluginId_When_Inspected()
    {
        Assert.That(sut.PluginId, Is.EqualTo("axbus.plugin.reader.json"));
    }

    /// <summary>
    /// Should_DeclareReaderParserTransformerCapabilities_When_Inspected.
    /// </summary>
    [Test]
    public void Should_DeclareReaderParserTransformerCapabilities_When_Inspected()
    {
        Assert.That(sut.Capabilities.HasFlag(PluginCapabilities.Reader),      Is.True);
        Assert.That(sut.Capabilities.HasFlag(PluginCapabilities.Parser),      Is.True);
        Assert.That(sut.Capabilities.HasFlag(PluginCapabilities.Transformer), Is.True);
        Assert.That(sut.Capabilities.HasFlag(PluginCapabilities.Writer),      Is.False);
    }

    /// <summary>
    /// Should_ReturnNullWriter_When_CreateWriterCalled.
    /// </summary>
    [Test]
    public void Should_ReturnNullWriter_When_CreateWriterCalled()
    {
        Assert.That(sut.CreateWriter(Services), Is.Null);
    }

    /// <summary>
    /// Should_ReturnNonNullReader_When_CreateReaderCalled.
    /// </summary>
    [Test]
    public void Should_ReturnNonNullReader_When_CreateReaderCalled()
    {
        Assert.That(sut.CreateReader(Services), Is.Not.Null);
    }

    /// <summary>
    /// Should_ReturnNonNullParser_When_CreateParserCalled.
    /// </summary>
    [Test]
    public void Should_ReturnNonNullParser_When_CreateParserCalled()
    {
        Assert.That(sut.CreateParser(Services), Is.Not.Null);
    }

    /// <summary>
    /// Should_ReturnNonNullTransformer_When_CreateTransformerCalled.
    /// </summary>
    [Test]
    public void Should_ReturnNonNullTransformer_When_CreateTransformerCalled()
    {
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
/// Unit tests for the internal JSON array explosion logic accessed
/// through <see cref="Axbus.Plugin.Reader.Json.Transformer.JsonDataTransformer"/>.
/// Verifies that scalar values, nested objects and nested arrays all
/// produce the correct number of rows with the correct column names.
/// </summary>
[TestFixture]
public sealed class JsonArrayExploderTests : AxbusTestBase
{
    /// <summary>
    /// Should_ProduceSingleRow_When_ObjectHasNoArrays.
    /// </summary>
    [Test]
    public void Should_ProduceSingleRow_When_ObjectHasNoArrays()
    {
        var json    = "{\"id\":\"1\",\"name\":\"Test\"}";
        var element = JsonDocument.Parse(json).RootElement;

        var rows = Axbus.Plugin.Reader.Json.Transformer.JsonArrayExploder.Explode(
            element,
            new Dictionary<string, string>(),
            prefix: string.Empty,
            maxDepth: 3,
            currentDepth: 0,
            sourcePath: "test.json",
            rowNumber: 1,
            nullPlaceholder: string.Empty).ToList();

        Assert.That(rows.Count, Is.EqualTo(1));
        FlattenedRowAssertions.HasValue(rows[0], "id",   "1");
        FlattenedRowAssertions.HasValue(rows[0], "name", "Test");
    }

    /// <summary>
    /// Should_FlattenNestedObject_When_DotNotationApplied.
    /// </summary>
    [Test]
    public void Should_FlattenNestedObject_When_DotNotationApplied()
    {
        var json    = "{\"customer\":{\"name\":\"Acme\",\"city\":\"Stockholm\"}}";
        var element = JsonDocument.Parse(json).RootElement;

        var rows = Axbus.Plugin.Reader.Json.Transformer.JsonArrayExploder.Explode(
            element,
            new Dictionary<string, string>(),
            prefix: string.Empty,
            maxDepth: 3,
            currentDepth: 0,
            sourcePath: "test.json",
            rowNumber: 1,
            nullPlaceholder: string.Empty).ToList();

        Assert.That(rows.Count, Is.EqualTo(1));
        FlattenedRowAssertions.HasValue(rows[0], "customer.name", "Acme");
        FlattenedRowAssertions.HasValue(rows[0], "customer.city", "Stockholm");
    }

    /// <summary>
    /// Should_ExplodeArray_When_NestedArrayPresent.
    /// </summary>
    [Test]
    public void Should_ExplodeArray_When_NestedArrayPresent()
    {
        var json    = "{\"orderId\":\"O1\",\"lines\":[{\"sku\":\"A\"},{\"sku\":\"B\"}]}";
        var element = JsonDocument.Parse(json).RootElement;

        var rows = Axbus.Plugin.Reader.Json.Transformer.JsonArrayExploder.Explode(
            element,
            new Dictionary<string, string>(),
            prefix: string.Empty,
            maxDepth: 3,
            currentDepth: 0,
            sourcePath: "test.json",
            rowNumber: 1,
            nullPlaceholder: string.Empty).ToList();

        // 1 parent * 2 array items = 2 rows
        Assert.That(rows.Count, Is.EqualTo(2));
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
/// Verifies that valid options pass and invalid options produce
/// meaningful error messages.
/// </summary>
[TestFixture]
public sealed class CsvWriterOptionsValidatorTests : AxbusTestBase
{
    private CsvWriterOptionsValidator sut = null!;

    /// <inheritdoc/>
    public override void SetUp()
    {
        base.SetUp();
        sut = new CsvWriterOptionsValidator();
    }

    /// <summary>
    /// Should_ReturnNoErrors_When_DefaultOptionsProvided.
    /// </summary>
    [Test]
    public void Should_ReturnNoErrors_When_DefaultOptionsProvided()
    {
        var errors = sut.Validate(new CsvWriterPluginOptions()).ToList();
        Assert.That(errors, Is.Empty);
    }

    /// <summary>
    /// Should_ReturnError_When_DelimiterIsNullChar.
    /// </summary>
    [Test]
    public void Should_ReturnError_When_DelimiterIsNullChar()
    {
        var errors = sut.Validate(new CsvWriterPluginOptions { Delimiter = '\0' }).ToList();
        Assert.That(errors.Count, Is.GreaterThan(0));
    }

    /// <summary>
    /// Should_ReturnError_When_EncodingIsInvalid.
    /// </summary>
    [Test]
    public void Should_ReturnError_When_EncodingIsInvalid()
    {
        var errors = sut.Validate(new CsvWriterPluginOptions { Encoding = "NOT-A-VALID-ENCODING" }).ToList();
        Assert.That(errors.Count, Is.GreaterThan(0));
    }

    /// <summary>
    /// Should_ReturnError_When_WrongOptionsTypeProvided.
    /// </summary>
    [Test]
    public void Should_ReturnError_When_WrongOptionsTypeProvided()
    {
        var errors = sut.Validate(new Axbus.Plugin.Writer.Excel.Options.ExcelWriterPluginOptions()).ToList();
        Assert.That(errors.Count, Is.GreaterThan(0));
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
/// Verifies CSV file creation, header row, delimiter usage
/// and row count in the returned WriteResult.
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
        if (Directory.Exists(tempDir))
            Directory.Delete(tempDir, recursive: true);
    }

    private CsvOutputWriter CreateWriter(char delimiter = ',') =>
        new(
            NullLogger<CsvOutputWriter>(),
            new CsvWriterPluginOptions { Delimiter = delimiter, IncludeHeader = true },
            new CsvSchemaBuilder(NullLogger<CsvSchemaBuilder>()));

    private static TransformedData CreateTransformedData(int rowCount) =>
        new(
            Rows: CreateRows(rowCount),
            SourcePath: "test.json");

    private static async IAsyncEnumerable<FlattenedRow> CreateRows(int count)
    {
        for (var i = 1; i <= count; i++)
        {
            var row = new FlattenedRow { RowNumber = i, SourceFilePath = "test.json" };
            row.Values["id"]   = i.ToString();
            row.Values["name"] = $"Item {i}";
            yield return row;
            await Task.Yield();
        }
    }

    /// <summary>
    /// Should_CreateOutputFile_When_RowsWritten.
    /// </summary>
    [Test]
    public async Task Should_CreateOutputFile_When_RowsWritten()
    {
        var writer  = CreateWriter();
        var data    = CreateTransformedData(3);
        var target  = new TargetOptions { Path = tempDir };
        var pipeline = new PipelineOptions();

        var result = await writer.WriteAsync(data, target, pipeline, CancellationToken.None);

        Assert.That(File.Exists(result.OutputPath), Is.True);
        Assert.That(result.RowsWritten,             Is.EqualTo(3));
    }

    /// <summary>
    /// Should_WriteHeaderRow_When_IncludeHeaderIsTrue.
    /// </summary>
    [Test]
    public async Task Should_WriteHeaderRow_When_IncludeHeaderIsTrue()
    {
        var writer  = CreateWriter();
        var data    = CreateTransformedData(2);
        var target  = new TargetOptions { Path = tempDir };
        var pipeline = new PipelineOptions();

        var result  = await writer.WriteAsync(data, target, pipeline, CancellationToken.None);
        var lines   = await File.ReadAllLinesAsync(result.OutputPath);

        // Line 0 = header, lines 1+ = data rows
        Assert.That(lines.Length, Is.GreaterThanOrEqualTo(3));
        Assert.That(lines[0], Does.Contain("id"));
        Assert.That(lines[0], Does.Contain("name"));
    }

    /// <summary>
    /// Should_UseSemicolonDelimiter_When_OptionConfigured.
    /// </summary>
    [Test]
    public async Task Should_UseSemicolonDelimiter_When_OptionConfigured()
    {
        var writer  = CreateWriter(delimiter: ';');
        var data    = CreateTransformedData(1);
        var target  = new TargetOptions { Path = tempDir };
        var pipeline = new PipelineOptions();

        var result  = await writer.WriteAsync(data, target, pipeline, CancellationToken.None);
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
/// Verifies plugin metadata, capabilities and stage factory contracts.
/// </summary>
[TestFixture]
public sealed class CsvWriterPluginTests : AxbusTestBase
{
    private CsvWriterPlugin sut = null!;

    /// <inheritdoc/>
    public override void SetUp()
    {
        base.SetUp();
        sut = new CsvWriterPlugin();
    }

    /// <summary>
    /// Should_HaveCorrectPluginId_When_Inspected.
    /// </summary>
    [Test]
    public void Should_HaveCorrectPluginId_When_Inspected()
    {
        Assert.That(sut.PluginId, Is.EqualTo("axbus.plugin.writer.csv"));
    }

    /// <summary>
    /// Should_DeclareOnlyWriterCapability_When_Inspected.
    /// </summary>
    [Test]
    public void Should_DeclareOnlyWriterCapability_When_Inspected()
    {
        Assert.That(sut.Capabilities.HasFlag(PluginCapabilities.Writer),      Is.True);
        Assert.That(sut.Capabilities.HasFlag(PluginCapabilities.Reader),      Is.False);
        Assert.That(sut.Capabilities.HasFlag(PluginCapabilities.Parser),      Is.False);
        Assert.That(sut.Capabilities.HasFlag(PluginCapabilities.Transformer), Is.False);
    }

    /// <summary>
    /// Should_ReturnNullForNonWriterStages_When_FactoriesInvoked.
    /// </summary>
    [Test]
    public void Should_ReturnNullForNonWriterStages_When_FactoriesInvoked()
    {
        Assert.That(sut.CreateReader(Services),      Is.Null);
        Assert.That(sut.CreateParser(Services),      Is.Null);
        Assert.That(sut.CreateTransformer(Services), Is.Null);
    }

    /// <summary>
    /// Should_ReturnNonNullWriter_When_CreateWriterCalled.
    /// </summary>
    [Test]
    public void Should_ReturnNonNullWriter_When_CreateWriterCalled()
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
/// Verifies first-seen column ordering and union of columns across multiple rows.
/// </summary>
[TestFixture]
public sealed class CsvSchemaBuilderTests : AxbusTestBase
{
    private CsvSchemaBuilder sut = null!;

    /// <inheritdoc/>
    public override void SetUp()
    {
        base.SetUp();
        sut = new CsvSchemaBuilder(NullLogger<CsvSchemaBuilder>());
    }

    private static async IAsyncEnumerable<FlattenedRow> MakeRows(
        IEnumerable<Dictionary<string, string>> values)
    {
        var rn = 1;
        foreach (var vals in values)
        {
            var row = new FlattenedRow { RowNumber = rn++ };
            foreach (var kvp in vals) row.Values[kvp.Key] = kvp.Value;
            yield return row;
            await Task.Yield();
        }
    }

    /// <summary>
    /// Should_DiscoverColumnsInFirstSeenOrder_When_RowsScanned.
    /// </summary>
    [Test]
    public async Task Should_DiscoverColumnsInFirstSeenOrder_When_RowsScanned()
    {
        var rows   = MakeRows(new[] { new Dictionary<string, string> { ["id"] = "1", ["name"] = "A" } });
        var schema = await sut.BuildAsync(rows, CancellationToken.None);

        Assert.That(schema.Columns[0], Is.EqualTo("id"));
        Assert.That(schema.Columns[1], Is.EqualTo("name"));
    }

    /// <summary>
    /// Should_UnionColumns_When_DifferentRowsHaveDifferentColumns.
    /// </summary>
    [Test]
    public async Task Should_UnionColumns_When_DifferentRowsHaveDifferentColumns()
    {
        var rows = MakeRows(new[]
        {
            new Dictionary<string, string> { ["id"] = "1" },
            new Dictionary<string, string> { ["id"] = "2", ["extra"] = "X" },
        });

        var schema = await sut.BuildAsync(rows, CancellationToken.None);

        Assert.That(schema.Columns.Count,      Is.EqualTo(2));
        Assert.That(schema.Columns.Contains("id"),    Is.True);
        Assert.That(schema.Columns.Contains("extra"), Is.True);
    }

    /// <summary>
    /// Should_ReturnEmptySchema_When_NoRowsProvided.
    /// </summary>
    [Test]
    public async Task Should_ReturnEmptySchema_When_NoRowsProvided()
    {
        var rows   = MakeRows(Array.Empty<Dictionary<string, string>>());
        var schema = await sut.BuildAsync(rows, CancellationToken.None);

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
/// Verifies valid default options and enforcement of Excel sheet name rules.
/// </summary>
[TestFixture]
public sealed class ExcelWriterOptionsValidatorTests : AxbusTestBase
{
    private ExcelWriterOptionsValidator sut = null!;

    /// <inheritdoc/>
    public override void SetUp()
    {
        base.SetUp();
        sut = new ExcelWriterOptionsValidator();
    }

    /// <summary>
    /// Should_ReturnNoErrors_When_DefaultOptionsProvided.
    /// </summary>
    [Test]
    public void Should_ReturnNoErrors_When_DefaultOptionsProvided()
    {
        var errors = sut.Validate(new ExcelWriterPluginOptions()).ToList();
        Assert.That(errors, Is.Empty);
    }

    /// <summary>
    /// Should_ReturnError_When_SheetNameExceeds31Chars.
    /// </summary>
    [Test]
    public void Should_ReturnError_When_SheetNameExceeds31Chars()
    {
        var errors = sut.Validate(new ExcelWriterPluginOptions
        {
            SheetName = new string('A', 32),
        }).ToList();

        Assert.That(errors.Count, Is.GreaterThan(0));
    }

    /// <summary>
    /// Should_ReturnError_When_SheetNameContainsForbiddenChar.
    /// </summary>
    [TestCase(":")]
    [TestCase("\\")]
    [TestCase("/")]
    [TestCase("?")]
    [TestCase("*")]
    [TestCase("[")]
    [TestCase("]")]
    public void Should_ReturnError_When_SheetNameContainsForbiddenChar(string forbidden)
    {
        var errors = sut.Validate(new ExcelWriterPluginOptions
        {
            SheetName = $"Sheet{forbidden}Name",
        }).ToList();

        Assert.That(errors.Count, Is.GreaterThan(0));
    }

    /// <summary>
    /// Should_ReturnError_When_SheetNameIsEmpty.
    /// </summary>
    [Test]
    public void Should_ReturnError_When_SheetNameIsEmpty()
    {
        var errors = sut.Validate(new ExcelWriterPluginOptions { SheetName = "" }).ToList();
        Assert.That(errors.Count, Is.GreaterThan(0));
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
/// Verifies xlsx file creation, sheet name, header formatting,
/// row count and the WriteResult return value.
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
        if (Directory.Exists(tempDir))
            Directory.Delete(tempDir, recursive: true);
    }

    private ExcelOutputWriter CreateWriter(string sheetName = "Sheet1") =>
        new(
            NullLogger<ExcelOutputWriter>(),
            new ExcelWriterPluginOptions
            {
                SheetName   = sheetName,
                AutoFit     = false,
                BoldHeaders = true,
                FreezeHeader = true,
            },
            new ExcelSchemaBuilder(NullLogger<ExcelSchemaBuilder>()));

    private static TransformedData CreateTransformedData(int rowCount) =>
        new(Rows: CreateRows(rowCount), SourcePath: "test.json");

    private static async IAsyncEnumerable<FlattenedRow> CreateRows(int count)
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

    /// <summary>
    /// Should_CreateXlsxFile_When_RowsWritten.
    /// </summary>
    [Test]
    public async Task Should_CreateXlsxFile_When_RowsWritten()
    {
        var writer  = CreateWriter();
        var result  = await writer.WriteAsync(
            CreateTransformedData(3),
            new TargetOptions { Path = tempDir },
            new PipelineOptions(),
            CancellationToken.None);

        Assert.That(File.Exists(result.OutputPath), Is.True);
        Assert.That(result.RowsWritten,             Is.EqualTo(3));
        Assert.That(result.OutputPath,              Does.EndWith(".xlsx"));
    }

    /// <summary>
    /// Should_UseConfiguredSheetName_When_WorkbookOpened.
    /// </summary>
    [Test]
    public async Task Should_UseConfiguredSheetName_When_WorkbookOpened()
    {
        var writer = CreateWriter(sheetName: "MyData");
        var result = await writer.WriteAsync(
            CreateTransformedData(1),
            new TargetOptions { Path = tempDir },
            new PipelineOptions(),
            CancellationToken.None);

        using var workbook   = new XLWorkbook(result.OutputPath);
        var worksheetExists  = workbook.Worksheets.Any(ws =>
            ws.Name.Equals("MyData", StringComparison.OrdinalIgnoreCase));

        Assert.That(worksheetExists, Is.True);
    }

    /// <summary>
    /// Should_WriteHeaderRowWithColumnNames_When_RowsWritten.
    /// </summary>
    [Test]
    public async Task Should_WriteHeaderRowWithColumnNames_When_RowsWritten()
    {
        var writer = CreateWriter();
        var result = await writer.WriteAsync(
            CreateTransformedData(2),
            new TargetOptions { Path = tempDir },
            new PipelineOptions(),
            CancellationToken.None);

        using var workbook = new XLWorkbook(result.OutputPath);
        var ws             = workbook.Worksheets.First();

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
/// Verifies plugin metadata, capabilities and stage factory contracts.
/// </summary>
[TestFixture]
public sealed class ExcelWriterPluginTests : AxbusTestBase
{
    private ExcelWriterPlugin sut = null!;

    /// <inheritdoc/>
    public override void SetUp()
    {
        base.SetUp();
        sut = new ExcelWriterPlugin();
    }

    /// <summary>
    /// Should_HaveCorrectPluginId_When_Inspected.
    /// </summary>
    [Test]
    public void Should_HaveCorrectPluginId_When_Inspected()
    {
        Assert.That(sut.PluginId, Is.EqualTo("axbus.plugin.writer.excel"));
    }

    /// <summary>
    /// Should_DeclareOnlyWriterCapability_When_Inspected.
    /// </summary>
    [Test]
    public void Should_DeclareOnlyWriterCapability_When_Inspected()
    {
        Assert.That(sut.Capabilities.HasFlag(PluginCapabilities.Writer),      Is.True);
        Assert.That(sut.Capabilities.HasFlag(PluginCapabilities.Reader),      Is.False);
        Assert.That(sut.Capabilities.HasFlag(PluginCapabilities.Parser),      Is.False);
        Assert.That(sut.Capabilities.HasFlag(PluginCapabilities.Transformer), Is.False);
    }

    /// <summary>
    /// Should_ReturnNullForNonWriterStages_When_FactoriesInvoked.
    /// </summary>
    [Test]
    public void Should_ReturnNullForNonWriterStages_When_FactoriesInvoked()
    {
        Assert.That(sut.CreateReader(Services),      Is.Null);
        Assert.That(sut.CreateParser(Services),      Is.Null);
        Assert.That(sut.CreateTransformer(Services), Is.Null);
    }

    /// <summary>
    /// Should_ReturnNonNullWriter_When_CreateWriterCalled.
    /// </summary>
    [Test]
    public void Should_ReturnNonNullWriter_When_CreateWriterCalled()
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
/// Verifies column discovery, ordering and format metadata.
/// </summary>
[TestFixture]
public sealed class ExcelSchemaBuilderTests : AxbusTestBase
{
    private ExcelSchemaBuilder sut = null!;

    /// <inheritdoc/>
    public override void SetUp()
    {
        base.SetUp();
        sut = new ExcelSchemaBuilder(NullLogger<ExcelSchemaBuilder>());
    }

    private static async IAsyncEnumerable<FlattenedRow> MakeRows(
        IEnumerable<string[]> columnSets)
    {
        var rn = 1;
        foreach (var cols in columnSets)
        {
            var row = new FlattenedRow { RowNumber = rn++ };
            foreach (var col in cols) row.Values[col] = "val";
            yield return row;
            await Task.Yield();
        }
    }

    /// <summary>
    /// Should_ReturnExcelFormat_When_SchemaBuilt.
    /// </summary>
    [Test]
    public async Task Should_ReturnExcelFormat_When_SchemaBuilt()
    {
        var rows   = MakeRows(new[] { new[] { "id", "name" } });
        var schema = await sut.BuildAsync(rows, CancellationToken.None);
        Assert.That(schema.Format, Is.EqualTo("excel"));
    }

    /// <summary>
    /// Should_CollectAllColumns_When_MultipleRowsHaveDifferentFields.
    /// </summary>
    [Test]
    public async Task Should_CollectAllColumns_When_MultipleRowsHaveDifferentFields()
    {
        var rows = MakeRows(new[]
        {
            new[] { "id", "name" },
            new[] { "id", "name", "amount" },
        });

        var schema = await sut.BuildAsync(rows, CancellationToken.None);

        Assert.That(schema.Columns.Count, Is.EqualTo(3));
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
using Axbus.Core.Models.Pipeline;
using Axbus.Plugin.Reader.Json.Options;
using Axbus.Plugin.Reader.Json.Parser;
using Axbus.Plugin.Reader.Json.Reader;
using Axbus.Plugin.Reader.Json.Transformer;
using Axbus.Plugin.Writer.Csv.Internal;
using Axbus.Plugin.Writer.Csv.Options;
using Axbus.Plugin.Writer.Csv.Writer;
using Axbus.Tests.Common.Base;
using Axbus.Tests.Common.Helpers;
using NUnit.Framework;

/// <summary>
/// End-to-end integration tests for the JSON-to-CSV conversion path.
/// Assembles the full Read -> Parse -> Transform -> Write pipeline
/// using real plugin implementations and a temporary file system.
/// These tests verify that the entire stack works together correctly.
/// </summary>
[TestFixture]
public sealed class JsonToCsvIntegrationTests : AxbusTestBase
{
    private string tempInputDir  = null!;
    private string tempOutputDir = null!;

    /// <inheritdoc/>
    public override void SetUp()
    {
        base.SetUp();
        tempInputDir  = Path.Combine(Path.GetTempPath(), Path.GetRandomFileName());
        tempOutputDir = Path.Combine(Path.GetTempPath(), Path.GetRandomFileName());
        Directory.CreateDirectory(tempInputDir);
        Directory.CreateDirectory(tempOutputDir);
    }

    /// <inheritdoc/>
    public override void TearDown()
    {
        base.TearDown();
        foreach (var dir in new[] { tempInputDir, tempOutputDir })
        {
            if (Directory.Exists(dir)) Directory.Delete(dir, recursive: true);
        }
    }

    /// <summary>
    /// Should_ProduceValidCsvFile_When_FlatJsonProcessed.
    /// </summary>
    [Test]
    public async Task Should_ProduceValidCsvFile_When_FlatJsonProcessed()
    {
        // Arrange - write test JSON to disk
        var inputPath = Path.Combine(tempInputDir, "orders.json");
        var json = """
            [
              {"orderId":"ORD-001","customer":"Acme Corp","amount":1500.00},
              {"orderId":"ORD-002","customer":"Globex Ltd","amount":2750.50}
            ]
            """;
        await File.WriteAllTextAsync(inputPath, json);

        // Act - run full pipeline
        var opts        = new JsonReaderPluginOptions();
        var reader      = new JsonSourceReader(NullLogger<JsonSourceReader>());
        var parser      = new JsonFormatParser(NullLogger<JsonFormatParser>(), opts);
        var transformer = new JsonDataTransformer(NullLogger<JsonDataTransformer>(), opts);
        var writer      = new CsvOutputWriter(
            NullLogger<CsvOutputWriter>(),
            new CsvWriterPluginOptions { Delimiter = ',', IncludeHeader = true },
            new CsvSchemaBuilder(NullLogger<CsvSchemaBuilder>()));

        var sourceData  = await reader.ReadAsync(
            new SourceOptions { Path = inputPath }, CancellationToken.None);

        var parsedData  = await parser.ParseAsync(sourceData, CancellationToken.None);
        var transformed = await transformer.TransformAsync(
            parsedData, new PipelineOptions(), CancellationToken.None);

        var result = await writer.WriteAsync(
            transformed,
            new TargetOptions { Path = tempOutputDir },
            new PipelineOptions(),
            CancellationToken.None);

        // Assert
        Assert.That(File.Exists(result.OutputPath), Is.True,  "Output CSV file should exist.");
        Assert.That(result.RowsWritten,             Is.EqualTo(2), "Should have written 2 rows.");
        Assert.That(result.ErrorRowsWritten,        Is.EqualTo(0), "Should have no error rows.");

        var lines = await File.ReadAllLinesAsync(result.OutputPath);
        Assert.That(lines.Length,    Is.EqualTo(3), "3 lines: header + 2 data rows.");
        Assert.That(lines[0],        Does.Contain("orderId"));
        Assert.That(lines[0],        Does.Contain("customer"));
        Assert.That(lines[0],        Does.Contain("amount"));
        Assert.That(lines[1],        Does.Contain("ORD-001"));
        Assert.That(lines[2],        Does.Contain("ORD-002"));
    }

    /// <summary>
    /// Should_ExplodeNestedArraysIntoCsvRows_When_JsonContainsArrayFields.
    /// </summary>
    [Test]
    public async Task Should_ExplodeNestedArraysIntoCsvRows_When_JsonContainsArrayFields()
    {
        // Arrange
        var inputPath = Path.Combine(tempInputDir, "sales.json");
        var json = """
            [
              {
                "orderId": "SO-001",
                "lines": [
                  {"lineNo":1,"product":"Widget A","qty":10},
                  {"lineNo":2,"product":"Widget B","qty":5}
                ]
              }
            ]
            """;
        await File.WriteAllTextAsync(inputPath, json);

        // Act
        var opts        = new JsonReaderPluginOptions { MaxExplosionDepth = 3 };
        var reader      = new JsonSourceReader(NullLogger<JsonSourceReader>());
        var parser      = new JsonFormatParser(NullLogger<JsonFormatParser>(), opts);
        var transformer = new JsonDataTransformer(NullLogger<JsonDataTransformer>(), opts);
        var writer      = new CsvOutputWriter(
            NullLogger<CsvOutputWriter>(),
            new CsvWriterPluginOptions(),
            new CsvSchemaBuilder(NullLogger<CsvSchemaBuilder>()));

        var sourceData  = await reader.ReadAsync(
            new SourceOptions { Path = inputPath }, CancellationToken.None);
        var parsedData  = await parser.ParseAsync(sourceData, CancellationToken.None);
        var transformed = await transformer.TransformAsync(
            parsedData, new PipelineOptions(), CancellationToken.None);
        var result = await writer.WriteAsync(
            transformed,
            new TargetOptions { Path = tempOutputDir },
            new PipelineOptions(),
            CancellationToken.None);

        // Assert - 1 order * 2 lines = 2 exploded rows
        Assert.That(result.RowsWritten, Is.EqualTo(2));
    }

    /// <summary>
    /// Should_ProduceEmptyCsvWithHeaderOnly_When_JsonArrayIsEmpty.
    /// </summary>
    [Test]
    public async Task Should_ProduceEmptyCsvWithHeaderOnly_When_JsonArrayIsEmpty()
    {
        var inputPath = Path.Combine(tempInputDir, "empty.json");
        await File.WriteAllTextAsync(inputPath, "[]");

        var opts        = new JsonReaderPluginOptions();
        var reader      = new JsonSourceReader(NullLogger<JsonSourceReader>());
        var parser      = new JsonFormatParser(NullLogger<JsonFormatParser>(), opts);
        var transformer = new JsonDataTransformer(NullLogger<JsonDataTransformer>(), opts);
        var writer      = new CsvOutputWriter(
            NullLogger<CsvOutputWriter>(),
            new CsvWriterPluginOptions(),
            new CsvSchemaBuilder(NullLogger<CsvSchemaBuilder>()));

        var sourceData  = await reader.ReadAsync(
            new SourceOptions { Path = inputPath }, CancellationToken.None);
        var parsedData  = await parser.ParseAsync(sourceData, CancellationToken.None);
        var transformed = await transformer.TransformAsync(
            parsedData, new PipelineOptions(), CancellationToken.None);
        var result = await writer.WriteAsync(
            transformed,
            new TargetOptions { Path = tempOutputDir },
            new PipelineOptions(),
            CancellationToken.None);

        Assert.That(result.RowsWritten,  Is.EqualTo(0));
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
/// End-to-end integration tests for the JSON-to-Excel conversion path.
/// Assembles the full Read -> Parse -> Transform -> Write pipeline
/// using real plugin implementations and verifies the resulting xlsx workbook.
/// </summary>
[TestFixture]
public sealed class JsonToExcelIntegrationTests : AxbusTestBase
{
    private string tempInputDir  = null!;
    private string tempOutputDir = null!;

    /// <inheritdoc/>
    public override void SetUp()
    {
        base.SetUp();
        tempInputDir  = Path.Combine(Path.GetTempPath(), Path.GetRandomFileName());
        tempOutputDir = Path.Combine(Path.GetTempPath(), Path.GetRandomFileName());
        Directory.CreateDirectory(tempInputDir);
        Directory.CreateDirectory(tempOutputDir);
    }

    /// <inheritdoc/>
    public override void TearDown()
    {
        base.TearDown();
        foreach (var dir in new[] { tempInputDir, tempOutputDir })
        {
            if (Directory.Exists(dir)) Directory.Delete(dir, recursive: true);
        }
    }

    /// <summary>
    /// Should_ProduceValidXlsxFile_When_FlatJsonProcessed.
    /// </summary>
    [Test]
    public async Task Should_ProduceValidXlsxFile_When_FlatJsonProcessed()
    {
        // Arrange
        var inputPath = Path.Combine(tempInputDir, "products.json");
        var json = """
            [
              {"productId":"P001","name":"Widget A","price":25.50,"category":"Parts"},
              {"productId":"P002","name":"Widget B","price":42.00,"category":"Assembly"},
              {"productId":"P003","name":"Widget C","price":15.75,"category":"Parts"}
            ]
            """;
        await File.WriteAllTextAsync(inputPath, json);

        // Act
        var opts        = new JsonReaderPluginOptions();
        var reader      = new JsonSourceReader(NullLogger<JsonSourceReader>());
        var parser      = new JsonFormatParser(NullLogger<JsonFormatParser>(), opts);
        var transformer = new JsonDataTransformer(NullLogger<JsonDataTransformer>(), opts);
        var writer      = new ExcelOutputWriter(
            NullLogger<ExcelOutputWriter>(),
            new ExcelWriterPluginOptions
            {
                SheetName    = "Products",
                AutoFit      = false,
                BoldHeaders  = true,
                FreezeHeader = true,
            },
            new ExcelSchemaBuilder(NullLogger<ExcelSchemaBuilder>()));

        var sourceData  = await reader.ReadAsync(
            new SourceOptions { Path = inputPath }, CancellationToken.None);
        var parsedData  = await parser.ParseAsync(sourceData, CancellationToken.None);
        var transformed = await transformer.TransformAsync(
            parsedData, new PipelineOptions(), CancellationToken.None);
        var result = await writer.WriteAsync(
            transformed,
            new TargetOptions { Path = tempOutputDir },
            new PipelineOptions(),
            CancellationToken.None);

        // Assert file exists and has correct structure
        Assert.That(File.Exists(result.OutputPath), Is.True);
        Assert.That(result.RowsWritten,             Is.EqualTo(3));
        Assert.That(result.OutputPath,              Does.EndWith(".xlsx"));

        // Open with ClosedXML and verify content
        using var workbook = new XLWorkbook(result.OutputPath);
        var ws             = workbook.Worksheet("Products");

        Assert.That(ws,                       Is.Not.Null);
        Assert.That(ws.Cell(1, 1).GetString(), Is.EqualTo("productId"));
        Assert.That(ws.Cell(2, 1).GetString(), Is.EqualTo("P001"));
        Assert.That(ws.Cell(3, 1).GetString(), Is.EqualTo("P002"));
        Assert.That(ws.Cell(4, 1).GetString(), Is.EqualTo("P003"));
    }

    /// <summary>
    /// Should_ApplyBoldHeaderStyle_When_BoldHeadersOptionEnabled.
    /// </summary>
    [Test]
    public async Task Should_ApplyBoldHeaderStyle_When_BoldHeadersOptionEnabled()
    {
        var inputPath = Path.Combine(tempInputDir, "data.json");
        await File.WriteAllTextAsync(inputPath, "[{\"id\":\"1\",\"value\":\"X\"}]");

        var opts        = new JsonReaderPluginOptions();
        var reader      = new JsonSourceReader(NullLogger<JsonSourceReader>());
        var parser      = new JsonFormatParser(NullLogger<JsonFormatParser>(), opts);
        var transformer = new JsonDataTransformer(NullLogger<JsonDataTransformer>(), opts);
        var writer      = new ExcelOutputWriter(
            NullLogger<ExcelOutputWriter>(),
            new ExcelWriterPluginOptions { BoldHeaders = true, AutoFit = false },
            new ExcelSchemaBuilder(NullLogger<ExcelSchemaBuilder>()));

        var sourceData  = await reader.ReadAsync(
            new SourceOptions { Path = inputPath }, CancellationToken.None);
        var parsedData  = await parser.ParseAsync(sourceData, CancellationToken.None);
        var transformed = await transformer.TransformAsync(
            parsedData, new PipelineOptions(), CancellationToken.None);
        var result = await writer.WriteAsync(
            transformed,
            new TargetOptions { Path = tempOutputDir },
            new PipelineOptions(),
            CancellationToken.None);

        using var workbook = new XLWorkbook(result.OutputPath);
        var ws = workbook.Worksheets.First();

        Assert.That(ws.Cell(1, 1).Style.Font.Bold, Is.True,
            "Header cell should have bold formatting when BoldHeaders is enabled.");
    }
}
'@

New-SourceFile $IntegTestsRoot "Tests/ErrorHandlingIntegrationTests.cs" @'
// <copyright file="ErrorHandlingIntegrationTests.cs" company="Axel Johnson International">
// Copyright (c) 2026 Axel Johnson International. All rights reserved.
// </copyright>

namespace Axbus.Integration.Tests.Tests;

using Axbus.Core.Enums;
using Axbus.Core.Exceptions;
using Axbus.Core.Models.Configuration;
using Axbus.Plugin.Reader.Json.Options;
using Axbus.Plugin.Reader.Json.Parser;
using Axbus.Plugin.Reader.Json.Reader;
using Axbus.Plugin.Reader.Json.Transformer;
using Axbus.Tests.Common.Base;
using NUnit.Framework;

/// <summary>
/// Integration tests verifying error handling behaviour across the pipeline.
/// Tests missing files, invalid JSON and the error file output path.
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
        if (Directory.Exists(tempDir))
            Directory.Delete(tempDir, recursive: true);
    }

    /// <summary>
    /// Should_ThrowConnectorException_When_SourceFileDoesNotExist.
    /// </summary>
    [Test]
    public void Should_ThrowConnectorException_When_SourceFileDoesNotExist()
    {
        var reader = new JsonSourceReader(NullLogger<JsonSourceReader>());
        var opts   = new SourceOptions { Path = Path.Combine(tempDir, "missing.json") };

        Assert.ThrowsAsync<AxbusConnectorException>(async () =>
            await reader.ReadAsync(opts, CancellationToken.None));
    }

    /// <summary>
    /// Should_ThrowPipelineException_When_InvalidJsonParsed.
    /// </summary>
    [Test]
    public async Task Should_ThrowPipelineException_When_InvalidJsonParsed()
    {
        var badFile = Path.Combine(tempDir, "bad.json");
        await File.WriteAllTextAsync(badFile, "{ this is not valid json }");

        var reader = new JsonSourceReader(NullLogger<JsonSourceReader>());
        var parser = new JsonFormatParser(
            NullLogger<JsonFormatParser>(),
            new JsonReaderPluginOptions());

        var sourceData = await reader.ReadAsync(
            new SourceOptions { Path = badFile }, CancellationToken.None);

        var parsedData = await parser.ParseAsync(sourceData, CancellationToken.None);

        Assert.ThrowsAsync<AxbusPipelineException>(async () =>
        {
            await foreach (var _ in parsedData.Elements) { }
        });
    }

    /// <summary>
    /// Should_ProduceZeroRows_When_ValidJsonWithNoMatchingRootKey.
    /// </summary>
    [Test]
    public async Task Should_ThrowPipelineException_When_RootKeyNotFoundInJson()
    {
        var inputPath = Path.Combine(tempDir, "data.json");
        await File.WriteAllTextAsync(inputPath,
            "{\"orders\":[{\"id\":\"1\"}]}");

        var reader = new JsonSourceReader(NullLogger<JsonSourceReader>());
        var parser = new JsonFormatParser(
            NullLogger<JsonFormatParser>(),
            new JsonReaderPluginOptions { RootArrayKey = "items" }); // "items" does not exist

        var sourceData = await reader.ReadAsync(
            new SourceOptions { Path = inputPath }, CancellationToken.None);
        var parsedData = await parser.ParseAsync(sourceData, CancellationToken.None);

        Assert.ThrowsAsync<AxbusPipelineException>(async () =>
        {
            await foreach (var _ in parsedData.Elements) { }
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
/// Integration tests that produce both CSV and Excel output from the same
/// JSON source in a single test run, verifying that the schema and row counts
/// are consistent across both output formats.
/// </summary>
[TestFixture]
public sealed class MultiFormatIntegrationTests : AxbusTestBase
{
    private string tempInputDir  = null!;
    private string tempOutputDir = null!;

    /// <inheritdoc/>
    public override void SetUp()
    {
        base.SetUp();
        tempInputDir  = Path.Combine(Path.GetTempPath(), Path.GetRandomFileName());
        tempOutputDir = Path.Combine(Path.GetTempPath(), Path.GetRandomFileName());
        Directory.CreateDirectory(tempInputDir);
        Directory.CreateDirectory(tempOutputDir);
    }

    /// <inheritdoc/>
    public override void TearDown()
    {
        base.TearDown();
        foreach (var dir in new[] { tempInputDir, tempOutputDir })
        {
            if (Directory.Exists(dir)) Directory.Delete(dir, recursive: true);
        }
    }

    /// <summary>
    /// Should_ProduceSameRowCount_When_SameJsonWrittenToBothCsvAndExcel.
    /// </summary>
    [Test]
    public async Task Should_ProduceSameRowCount_When_SameJsonWrittenToBothCsvAndExcel()
    {
        // Arrange - write shared test JSON
        var inputPath = Path.Combine(tempInputDir, "inventory.json");
        var json = """
            [
              {"sku":"SKU-001","description":"Bolt M8","qty":500,"unitCost":0.15},
              {"sku":"SKU-002","description":"Nut M8","qty":500,"unitCost":0.10},
              {"sku":"SKU-003","description":"Washer M8","qty":1000,"unitCost":0.05}
            ]
            """;
        await File.WriteAllTextAsync(inputPath, json);

        var readerOpts = new JsonReaderPluginOptions();
        var reader     = new JsonSourceReader(NullLogger<JsonSourceReader>());
        var parser     = new JsonFormatParser(NullLogger<JsonFormatParser>(), readerOpts);
        var transformer = new JsonDataTransformer(NullLogger<JsonDataTransformer>(), readerOpts);
        var pipeline   = new PipelineOptions();
        var target     = new TargetOptions { Path = tempOutputDir };

        // --- CSV pass ---
        var csvSourceData  = await reader.ReadAsync(
            new SourceOptions { Path = inputPath }, CancellationToken.None);
        var csvParsed      = await parser.ParseAsync(csvSourceData, CancellationToken.None);
        var csvTransformed = await transformer.TransformAsync(csvParsed, pipeline, CancellationToken.None);
        var csvWriter      = new CsvOutputWriter(
            NullLogger<CsvOutputWriter>(),
            new CsvWriterPluginOptions(),
            new CsvSchemaBuilder(NullLogger<CsvSchemaBuilder>()));
        var csvResult = await csvWriter.WriteAsync(csvTransformed, target, pipeline, CancellationToken.None);

        // --- Excel pass ---
        var xlSourceData   = await reader.ReadAsync(
            new SourceOptions { Path = inputPath }, CancellationToken.None);
        var xlParsed       = await parser.ParseAsync(xlSourceData, CancellationToken.None);
        var xlTransformed  = await transformer.TransformAsync(xlParsed, pipeline, CancellationToken.None);
        var xlWriter       = new ExcelOutputWriter(
            NullLogger<ExcelOutputWriter>(),
            new ExcelWriterPluginOptions { AutoFit = false },
            new ExcelSchemaBuilder(NullLogger<ExcelSchemaBuilder>()));
        var xlResult = await xlWriter.WriteAsync(xlTransformed, target, pipeline, CancellationToken.None);

        // Assert both formats produced 3 rows
        Assert.That(csvResult.RowsWritten, Is.EqualTo(3), "CSV should have 3 data rows.");
        Assert.That(xlResult.RowsWritten,  Is.EqualTo(3), "Excel should have 3 data rows.");

        // Assert CSV has header + 3 data rows
        var csvLines = await File.ReadAllLinesAsync(csvResult.OutputPath);
        Assert.That(csvLines.Length, Is.EqualTo(4), "CSV: 1 header + 3 data rows.");

        // Assert Excel has header row + 3 data rows = 4 total rows
        using var workbook = new XLWorkbook(xlResult.OutputPath);
        var ws = workbook.Worksheets.First();
        Assert.That(ws.LastRowUsed()!.RowNumber(), Is.EqualTo(4),
            "Excel: header row 1 + 3 data rows = row 4 as last used.");

        // Assert same column count in both outputs
        var csvColumnCount   = csvLines[0].Split(',').Length;
        var excelColumnCount = ws.LastColumnUsed()!.ColumnNumber();
        Assert.That(csvColumnCount, Is.EqualTo(excelColumnCount),
            "CSV and Excel should have the same number of columns.");
    }
}
'@

# ==============================================================================
# SUMMARY
# ==============================================================================

Write-Host ""
Write-Host "===============================================================================" -ForegroundColor Green
Write-Host "  [DONE] All Test Projects - Code Generation Complete!" -ForegroundColor Green
Write-Host "===============================================================================" -ForegroundColor Green
Write-Host ""
Write-Host "  Test Project 1 - Axbus.Tests.Common       :  4 files" -ForegroundColor White
Write-Host "  Test Project 2 - Axbus.Core.Tests         :  6 files" -ForegroundColor White
Write-Host "  Test Project 3 - Axbus.Application.Tests  :  5 files" -ForegroundColor White
Write-Host "  Test Project 4 - Axbus.Infrastructure.Tests: 4 files" -ForegroundColor White
Write-Host "  Test Project 5 - Axbus.Plugin.Reader.Json.Tests: 5 files" -ForegroundColor White
Write-Host "  Test Project 6 - Axbus.Plugin.Writer.Csv.Tests : 4 files" -ForegroundColor White
Write-Host "  Test Project 7 - Axbus.Plugin.Writer.Excel.Tests: 4 files" -ForegroundColor White
Write-Host "  Test Project 8 - Axbus.Integration.Tests  :  4 files" -ForegroundColor White
Write-Host ""
Write-Host "  Total: 36 test source files" -ForegroundColor Cyan
Write-Host ""
Write-Host "  Next Steps:" -ForegroundColor Yellow
Write-Host "    1. Save to: scripts/generate-tests.ps1" -ForegroundColor White
Write-Host "    2. Run: PowerShell -ExecutionPolicy Bypass -File .\scripts\generate-tests.ps1" -ForegroundColor White
Write-Host "    3. Full solution build:" -ForegroundColor White
Write-Host "       dotnet build Axbus.slnx" -ForegroundColor White
Write-Host "    4. Run all tests:" -ForegroundColor White
Write-Host "       dotnet test Axbus.slnx" -ForegroundColor White
Write-Host "    5. Verify: 0 errors, all tests pass" -ForegroundColor White
Write-Host "    6. Commit everything to Git!" -ForegroundColor White
Write-Host ""
Write-Host "===============================================================================" -ForegroundColor Green
Write-Host ""

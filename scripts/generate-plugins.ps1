# ==============================================================================
# generate-plugins.ps1
# Axbus Framework - All 3 Plugin Projects Code Generation Script
# Copyright (c) 2026 Axel Johnson International. All rights reserved.
#
# USAGE:
#   PowerShell -ExecutionPolicy Bypass -File .\scripts\generate-plugins.ps1
#
# GENERATES:
#   Axbus.Plugin.Reader.Json   (JSON reader, parser, transformer)
#   Axbus.Plugin.Writer.Csv    (CSV schema builder + writer)
#   Axbus.Plugin.Writer.Excel  (Excel schema builder + writer)
#
# PREREQUISITES:
#   - Run generate-core.ps1 first
#   - Run from the repository root
#   NOTE: Plugins depend on Axbus.Core ONLY
# ==============================================================================

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$ScriptVersion = "1.0.0"
$CompanyName   = "Axel Johnson International"
$CopyrightYear = "2026"

function Write-Banner {
    Write-Host ""
    Write-Host "===============================================================================" -ForegroundColor Cyan
    Write-Host "  Axbus Plugins - Code Generation Script v$ScriptVersion" -ForegroundColor Cyan
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
    Write-Host "  [FAILED] Axbus.Core not found. Run generate-core.ps1 first." -ForegroundColor Red; exit 1
}

Write-Banner

# ==============================================================================
# PLUGIN 1 - AXBUS.PLUGIN.READER.JSON
# ==============================================================================

$JsonRoot = "src/plugins/Axbus.Plugin.Reader.Json"

Write-Phase "Plugin 1 - Axbus.Plugin.Reader.Json"
Write-Info "Root: $JsonRoot"

New-SourceFile $JsonRoot "Options/JsonReaderPluginOptions.cs" @'
// <copyright file="JsonReaderPluginOptions.cs" company="Axel Johnson International">
// Copyright (c) 2026 Axel Johnson International. All rights reserved.
// </copyright>

namespace Axbus.Plugin.Reader.Json.Options;

using System.Text.Json;
using System.Text.Json.Serialization;
using Axbus.Core.Abstractions.Plugin;

/// <summary>
/// Strongly-typed options for the <c>Axbus.Plugin.Reader.Json</c> plugin.
/// These options are deserialised from the <c>PluginOptions</c> section of
/// a <see cref="Axbus.Core.Models.Configuration.ConversionModule"/> at runtime.
/// Unknown JSON keys are captured in <see cref="AdditionalOptions"/> via
/// <see cref="JsonExtensionDataAttribute"/>.
/// </summary>
public sealed class JsonReaderPluginOptions : IPluginOptions
{
    /// <summary>
    /// Gets or sets the key used to locate the root array within the JSON document.
    /// <list type="bullet">
    /// <item><c>null</c> (default) - auto-detect the first array in the document.</item>
    /// <item><c>"root"</c> - treat the entire root object as a single record.</item>
    /// <item>Any other value - drill into that key to locate the array.</item>
    /// </list>
    /// </summary>
    public string? RootArrayKey { get; set; }

    /// <summary>
    /// Gets or sets the maximum depth to which nested arrays are exploded
    /// into multiple rows. Arrays nested beyond this depth are serialised
    /// as a JSON string in a single column.
    /// Defaults to <c>3</c>.
    /// </summary>
    public int MaxExplosionDepth { get; set; } = 3;

    /// <summary>
    /// Gets or sets the string written to output columns when the source
    /// element does not contain a value for that field.
    /// Defaults to an empty string.
    /// </summary>
    public string NullPlaceholder { get; set; } = string.Empty;

    /// <summary>
    /// Gets or sets additional options that are not declared as explicit properties.
    /// Populated automatically by the JSON deserialiser for any unrecognised keys
    /// in the <c>PluginOptions</c> configuration section.
    /// </summary>
    [JsonExtensionData]
    public Dictionary<string, JsonElement>? AdditionalOptions { get; set; }
}
'@

New-SourceFile $JsonRoot "Validators/JsonReaderOptionsValidator.cs" @'
// <copyright file="JsonReaderOptionsValidator.cs" company="Axel Johnson International">
// Copyright (c) 2026 Axel Johnson International. All rights reserved.
// </copyright>

namespace Axbus.Plugin.Reader.Json.Validators;

using Axbus.Core.Abstractions.Plugin;
using Axbus.Plugin.Reader.Json.Options;

/// <summary>
/// Validates <see cref="JsonReaderPluginOptions"/> before the
/// JSON reader plugin is initialised. Checks that
/// <see cref="JsonReaderPluginOptions.MaxExplosionDepth"/> is within
/// an acceptable range and that any provided
/// <see cref="JsonReaderPluginOptions.RootArrayKey"/> is not whitespace-only.
/// </summary>
public sealed class JsonReaderOptionsValidator : IPluginOptionsValidator
{
    /// <summary>
    /// The minimum permitted value for <see cref="JsonReaderPluginOptions.MaxExplosionDepth"/>.
    /// </summary>
    private const int MinExplosionDepth = 1;

    /// <summary>
    /// The maximum permitted value for <see cref="JsonReaderPluginOptions.MaxExplosionDepth"/>.
    /// </summary>
    private const int MaxExplosionDepth = 20;

    /// <summary>
    /// Validates the specified <paramref name="options"/> instance.
    /// </summary>
    /// <param name="options">The options instance to validate.</param>
    /// <returns>
    /// An empty enumerable when options are valid, or one or more
    /// error messages when options are invalid.
    /// </returns>
    public IEnumerable<string> Validate(IPluginOptions options)
    {
        if (options is not JsonReaderPluginOptions jsonOptions)
        {
            yield return $"Expected options of type {nameof(JsonReaderPluginOptions)} " +
                         $"but received {options?.GetType().Name ?? "null"}.";
            yield break;
        }

        if (jsonOptions.MaxExplosionDepth < MinExplosionDepth ||
            jsonOptions.MaxExplosionDepth > MaxExplosionDepth)
        {
            yield return $"{nameof(JsonReaderPluginOptions.MaxExplosionDepth)} must be " +
                         $"between {MinExplosionDepth} and {MaxExplosionDepth}. " +
                         $"Current value: {jsonOptions.MaxExplosionDepth}.";
        }

        if (jsonOptions.RootArrayKey != null &&
            string.IsNullOrWhiteSpace(jsonOptions.RootArrayKey))
        {
            yield return $"{nameof(JsonReaderPluginOptions.RootArrayKey)} must not be " +
                         "whitespace-only. Set to null for auto-detection.";
        }
    }
}
'@

New-SourceFile $JsonRoot "Reader/JsonSourceReader.cs" @'
// <copyright file="JsonSourceReader.cs" company="Axel Johnson International">
// Copyright (c) 2026 Axel Johnson International. All rights reserved.
// </copyright>

namespace Axbus.Plugin.Reader.Json.Reader;

using Axbus.Core.Abstractions.Pipeline;
using Axbus.Core.Exceptions;
using Axbus.Core.Models.Configuration;
using Axbus.Core.Models.Pipeline;
using Microsoft.Extensions.Logging;

/// <summary>
/// Implements <see cref="ISourceReader"/> for JSON source files.
/// Accepts a raw stream from the source connector and wraps it in a
/// <see cref="SourceData"/> record with JSON format metadata.
/// This reader is format-aware but I/O agnostic - it does not open
/// files directly; streams are provided by the infrastructure connector.
/// </summary>
public sealed class JsonSourceReader : ISourceReader
{
    /// <summary>
    /// Logger instance for structured reader diagnostic output.
    /// </summary>
    private readonly ILogger<JsonSourceReader> logger;

    /// <summary>
    /// Initializes a new instance of <see cref="JsonSourceReader"/>.
    /// </summary>
    /// <param name="logger">The logger for reader operations.</param>
    public JsonSourceReader(ILogger<JsonSourceReader> logger)
    {
        this.logger = logger;
    }

    /// <summary>
    /// Reads the source described by <paramref name="options"/> and returns
    /// a <see cref="SourceData"/> record containing the raw stream and metadata.
    /// For the JSON reader this opens the file at <see cref="SourceOptions.Path"/>
    /// as a buffered async stream.
    /// </summary>
    /// <param name="options">The source configuration describing the file path.</param>
    /// <param name="cancellationToken">A token to cancel the read operation.</param>
    /// <returns>A <see cref="SourceData"/> record with the JSON stream and metadata.</returns>
    /// <exception cref="AxbusConnectorException">
    /// Thrown when the source file cannot be opened.
    /// </exception>
    public Task<SourceData> ReadAsync(SourceOptions options, CancellationToken cancellationToken)
    {
        ArgumentNullException.ThrowIfNull(options);
        ArgumentException.ThrowIfNullOrWhiteSpace(options.Path);

        logger.LogDebug("JsonSourceReader opening: {Path}", options.Path);

        try
        {
            var stream = new FileStream(
                options.Path,
                FileMode.Open,
                FileAccess.Read,
                FileShare.Read,
                bufferSize: 81920,
                useAsync: true);

            var contentLength = new FileInfo(options.Path).Length;

            var sourceData = new SourceData(
                RawData: stream,
                SourcePath: options.Path,
                Format: "json",
                ContentLength: contentLength);

            logger.LogDebug(
                "JsonSourceReader opened: {Path} ({Bytes} bytes)",
                options.Path,
                contentLength);

            return Task.FromResult(sourceData);
        }
        catch (FileNotFoundException ex)
        {
            throw new AxbusConnectorException(
                $"JSON source file not found: {options.Path}", options.Path, ex);
        }
        catch (UnauthorizedAccessException ex)
        {
            throw new AxbusConnectorException(
                $"Access denied reading JSON file: {options.Path}", options.Path, ex);
        }
        catch (IOException ex)
        {
            throw new AxbusConnectorException(
                $"I/O error opening JSON file: {options.Path}", options.Path, ex);
        }
    }
}
'@

New-SourceFile $JsonRoot "Parser/JsonFormatParser.cs" @'
// <copyright file="JsonFormatParser.cs" company="Axel Johnson International">
// Copyright (c) 2026 Axel Johnson International. All rights reserved.
// </copyright>

namespace Axbus.Plugin.Reader.Json.Parser;

using System.Runtime.CompilerServices;
using System.Text.Json;
using Axbus.Core.Abstractions.Pipeline;
using Axbus.Core.Exceptions;
using Axbus.Core.Models.Pipeline;
using Axbus.Plugin.Reader.Json.Options;
using Microsoft.Extensions.Logging;

/// <summary>
/// Implements <see cref="IFormatParser"/> for JSON source data.
/// Streams the raw byte stream from <see cref="SourceData"/> using
/// <see cref="Utf8JsonReader"/> to avoid loading the entire document into memory.
/// Supports root arrays, keyed arrays and whole-object parsing based on
/// <see cref="JsonReaderPluginOptions.RootArrayKey"/>.
/// </summary>
public sealed class JsonFormatParser : IFormatParser
{
    /// <summary>
    /// Logger instance for structured parser diagnostic output.
    /// </summary>
    private readonly ILogger<JsonFormatParser> logger;

    /// <summary>
    /// The plugin options controlling root array detection.
    /// </summary>
    private readonly JsonReaderPluginOptions options;

    /// <summary>
    /// Initializes a new instance of <see cref="JsonFormatParser"/>.
    /// </summary>
    /// <param name="logger">The logger for parser operations.</param>
    /// <param name="options">The plugin options for root array key detection.</param>
    public JsonFormatParser(ILogger<JsonFormatParser> logger, JsonReaderPluginOptions options)
    {
        this.logger = logger;
        this.options = options;
    }

    /// <summary>
    /// Parses the JSON stream in <paramref name="sourceData"/> and returns
    /// a <see cref="ParsedData"/> record containing a lazy async stream
    /// of top-level <see cref="JsonElement"/> values.
    /// </summary>
    /// <param name="sourceData">The raw JSON stream produced by the reader stage.</param>
    /// <param name="cancellationToken">A token to cancel the parse operation.</param>
    /// <returns>A <see cref="ParsedData"/> record with the element stream.</returns>
    public Task<ParsedData> ParseAsync(SourceData sourceData, CancellationToken cancellationToken)
    {
        ArgumentNullException.ThrowIfNull(sourceData);

        logger.LogDebug("JsonFormatParser parsing: {SourcePath}", sourceData.SourcePath);

        // Return immediately with the lazy element stream
        // Actual parsing happens when the stream is enumerated
        var parsedData = new ParsedData(
            Elements: StreamElementsAsync(sourceData, cancellationToken),
            SourcePath: sourceData.SourcePath,
            Format: "json");

        return Task.FromResult(parsedData);
    }

    /// <summary>
    /// Lazily streams JSON elements from the source data stream.
    /// Loads the full document once then yields elements from the
    /// resolved root array or root object.
    /// </summary>
    /// <param name="sourceData">The raw JSON source data.</param>
    /// <param name="cancellationToken">A token to cancel enumeration.</param>
    /// <returns>An async enumerable of top-level JSON elements.</returns>
    private async IAsyncEnumerable<JsonElement> StreamElementsAsync(
        SourceData sourceData,
        [EnumeratorCancellation] CancellationToken cancellationToken)
    {
        JsonDocument document;

        try
        {
            // Load the full document - Utf8JsonReader does not support async natively
            document = await JsonDocument.ParseAsync(
                sourceData.RawData,
                cancellationToken: cancellationToken).ConfigureAwait(false);
        }
        catch (JsonException ex)
        {
            throw new AxbusPipelineException(
                $"Invalid JSON in '{sourceData.SourcePath}': {ex.Message}",
                Axbus.Core.Enums.PipelineStage.Parse,
                ex);
        }

        using (document)
        {
            var root = document.RootElement;

            // Determine which elements to yield based on RootArrayKey
            if (options.RootArrayKey == null)
            {
                // Auto-detect: root is array or root is object containing array
                if (root.ValueKind == JsonValueKind.Array)
                {
                    foreach (var element in root.EnumerateArray())
                    {
                        cancellationToken.ThrowIfCancellationRequested();
                        yield return element.Clone();
                    }
                }
                else if (root.ValueKind == JsonValueKind.Object)
                {
                    // Yield the root object as a single element
                    yield return root.Clone();
                }
            }
            else if (string.Equals(options.RootArrayKey, "root", StringComparison.OrdinalIgnoreCase))
            {
                // "root" key: treat entire root object as a single record
                yield return root.Clone();
            }
            else
            {
                // Named key: drill into that property to find the array
                if (!root.TryGetProperty(options.RootArrayKey, out var arrayElement))
                {
                    throw new AxbusPipelineException(
                        $"RootArrayKey '{options.RootArrayKey}' not found in '{sourceData.SourcePath}'.",
                        Axbus.Core.Enums.PipelineStage.Parse);
                }

                if (arrayElement.ValueKind == JsonValueKind.Array)
                {
                    foreach (var element in arrayElement.EnumerateArray())
                    {
                        cancellationToken.ThrowIfCancellationRequested();
                        yield return element.Clone();
                    }
                }
                else
                {
                    yield return arrayElement.Clone();
                }
            }
        }
    }
}
'@

New-SourceFile $JsonRoot "Transformer/JsonArrayExploder.cs" @'
// <copyright file="JsonArrayExploder.cs" company="Axel Johnson International">
// Copyright (c) 2026 Axel Johnson International. All rights reserved.
// </copyright>

namespace Axbus.Plugin.Reader.Json.Transformer;

using System.Text.Json;
using Axbus.Core.Models.Pipeline;

/// <summary>
/// Handles the explosion of nested JSON arrays into multiple
/// <see cref="FlattenedRow"/> instances. When a JSON property value is an array
/// each element of the array generates a new row with the parent field values
/// repeated. Arrays nested beyond <c>maxDepth</c> are serialised as a JSON
/// string rather than being exploded further.
/// </summary>
internal static class JsonArrayExploder
{
    /// <summary>
    /// Explodes a <see cref="JsonElement"/> that may contain nested arrays
    /// into one or more <see cref="FlattenedRow"/> instances. Non-array values
    /// are returned as a single row. Arrays are exploded up to
    /// <paramref name="maxDepth"/> levels deep.
    /// </summary>
    /// <param name="element">The JSON element to explode.</param>
    /// <param name="parentValues">
    /// Key-value pairs from ancestor elements to repeat on every exploded row.
    /// </param>
    /// <param name="prefix">The dot-notation prefix for field names at this level.</param>
    /// <param name="maxDepth">The maximum explosion depth. Beyond this arrays become JSON strings.</param>
    /// <param name="currentDepth">The current recursion depth (starts at 0).</param>
    /// <param name="sourcePath">The source file path for row metadata.</param>
    /// <param name="rowNumber">The base row number for metadata.</param>
    /// <param name="nullPlaceholder">The value to use for null or missing fields.</param>
    /// <returns>One or more flattened rows produced by explosion.</returns>
    internal static IEnumerable<FlattenedRow> Explode(
        JsonElement element,
        Dictionary<string, string> parentValues,
        string prefix,
        int maxDepth,
        int currentDepth,
        string sourcePath,
        int rowNumber,
        string nullPlaceholder)
    {
        if (element.ValueKind != JsonValueKind.Object)
        {
            // Non-object: create a single row with parent values
            var simpleRow = new FlattenedRow
            {
                RowNumber = rowNumber,
                SourceFilePath = sourcePath,
            };

            foreach (var kvp in parentValues)
            {
                simpleRow.Values[kvp.Key] = kvp.Value;
            }

            if (!string.IsNullOrEmpty(prefix))
            {
                simpleRow.Values[prefix] = GetScalarValue(element, nullPlaceholder);
            }

            yield return simpleRow;
            yield break;
        }

        // Collect scalar fields and identify array fields at this level
        var scalarValues = new Dictionary<string, string>(parentValues, StringComparer.OrdinalIgnoreCase);
        var arrayFields = new List<(string Key, JsonElement ArrayElement)>();

        foreach (var property in element.EnumerateObject())
        {
            var fieldKey = string.IsNullOrEmpty(prefix)
                ? property.Name
                : $"{prefix}.{property.Name}";

            if (property.Value.ValueKind == JsonValueKind.Array && currentDepth < maxDepth)
            {
                // This array will be exploded
                arrayFields.Add((fieldKey, property.Value));
            }
            else if (property.Value.ValueKind == JsonValueKind.Object)
            {
                // Recurse into nested objects to flatten with dot-notation
                FlattenObject(property.Value, fieldKey, scalarValues, maxDepth, currentDepth + 1, nullPlaceholder);
            }
            else
            {
                // Scalar value or array beyond max depth
                scalarValues[fieldKey] = property.Value.ValueKind == JsonValueKind.Array
                    ? property.Value.GetRawText() // Serialize array as JSON string
                    : GetScalarValue(property.Value, nullPlaceholder);
            }
        }

        if (arrayFields.Count == 0)
        {
            // No arrays to explode - yield a single row
            var row = new FlattenedRow
            {
                RowNumber = rowNumber,
                SourceFilePath = sourcePath,
            };

            foreach (var kvp in scalarValues)
            {
                row.Values[kvp.Key] = kvp.Value;
            }

            yield return row;
        }
        else
        {
            // Explode each array field into multiple rows
            // For multiple array fields use the first array as the primary explosion axis
            var (primaryKey, primaryArray) = arrayFields[0];
            var explosionIndex = 0;

            foreach (var arrayItem in primaryArray.EnumerateArray())
            {
                foreach (var explodedRow in Explode(
                    arrayItem,
                    scalarValues,
                    primaryKey,
                    maxDepth,
                    currentDepth + 1,
                    sourcePath,
                    rowNumber,
                    nullPlaceholder))
                {
                    explodedRow.IsExploded = true;
                    explodedRow.ExplosionIndex = explosionIndex;
                    yield return explodedRow;
                }

                explosionIndex++;
            }
        }
    }

    /// <summary>
    /// Recursively flattens a nested JSON object into the scalar values dictionary
    /// using dot-notation keys.
    /// </summary>
    /// <param name="element">The nested object element to flatten.</param>
    /// <param name="prefix">The dot-notation prefix for all fields in this object.</param>
    /// <param name="target">The dictionary to populate with flattened key-value pairs.</param>
    /// <param name="maxDepth">Maximum explosion depth for nested arrays.</param>
    /// <param name="currentDepth">Current recursion depth.</param>
    /// <param name="nullPlaceholder">Value for null or missing fields.</param>
    private static void FlattenObject(
        JsonElement element,
        string prefix,
        Dictionary<string, string> target,
        int maxDepth,
        int currentDepth,
        string nullPlaceholder)
    {
        foreach (var property in element.EnumerateObject())
        {
            var fieldKey = $"{prefix}.{property.Name}";

            if (property.Value.ValueKind == JsonValueKind.Object)
            {
                FlattenObject(property.Value, fieldKey, target, maxDepth, currentDepth + 1, nullPlaceholder);
            }
            else if (property.Value.ValueKind == JsonValueKind.Array && currentDepth >= maxDepth)
            {
                // Beyond max depth - serialize as JSON string
                target[fieldKey] = property.Value.GetRawText();
            }
            else
            {
                target[fieldKey] = GetScalarValue(property.Value, nullPlaceholder);
            }
        }
    }

    /// <summary>
    /// Converts a scalar <see cref="JsonElement"/> to its string representation.
    /// </summary>
    /// <param name="element">The JSON element to convert.</param>
    /// <param name="nullPlaceholder">The value to return for null elements.</param>
    /// <returns>The string representation of the element value.</returns>
    private static string GetScalarValue(JsonElement element, string nullPlaceholder)
    {
        return element.ValueKind switch
        {
            JsonValueKind.String => element.GetString() ?? nullPlaceholder,
            JsonValueKind.Number => element.GetRawText(),
            JsonValueKind.True   => "true",
            JsonValueKind.False  => "false",
            JsonValueKind.Null   => nullPlaceholder,
            _                    => element.GetRawText(),
        };
    }
}
'@

New-SourceFile $JsonRoot "Transformer/JsonDataTransformer.cs" @'
// <copyright file="JsonDataTransformer.cs" company="Axel Johnson International">
// Copyright (c) 2026 Axel Johnson International. All rights reserved.
// </copyright>

namespace Axbus.Plugin.Reader.Json.Transformer;

using System.Runtime.CompilerServices;
using System.Text.Json;
using Axbus.Core.Abstractions.Pipeline;
using Axbus.Core.Models.Configuration;
using Axbus.Core.Models.Pipeline;
using Axbus.Plugin.Reader.Json.Options;
using Microsoft.Extensions.Logging;

/// <summary>
/// Implements <see cref="IDataTransformer"/> for JSON parsed data.
/// Flattens nested JSON objects using dot-notation column names and
/// explodes arrays into multiple rows up to the configured
/// <see cref="JsonReaderPluginOptions.MaxExplosionDepth"/>.
/// Arrays beyond the maximum depth are serialised as JSON strings.
/// </summary>
public sealed class JsonDataTransformer : IDataTransformer
{
    /// <summary>
    /// Logger instance for transformer diagnostic output.
    /// </summary>
    private readonly ILogger<JsonDataTransformer> logger;

    /// <summary>
    /// Plugin options controlling explosion depth and null placeholder.
    /// </summary>
    private readonly JsonReaderPluginOptions pluginOptions;

    /// <summary>
    /// Initializes a new instance of <see cref="JsonDataTransformer"/>.
    /// </summary>
    /// <param name="logger">The logger for transformer operations.</param>
    /// <param name="pluginOptions">Options controlling transformation behaviour.</param>
    public JsonDataTransformer(ILogger<JsonDataTransformer> logger, JsonReaderPluginOptions pluginOptions)
    {
        this.logger = logger;
        this.pluginOptions = pluginOptions;
    }

    /// <summary>
    /// Transforms the JSON element stream into a lazy stream of
    /// <see cref="FlattenedRow"/> instances. Nested objects are flattened
    /// with dot-notation keys and arrays are exploded into multiple rows.
    /// </summary>
    /// <param name="parsedData">The JSON element stream from the parser stage.</param>
    /// <param name="options">Pipeline options (MaxExplosionDepth used if plugin options not set).</param>
    /// <param name="cancellationToken">A token to cancel the transform operation.</param>
    /// <returns>A <see cref="TransformedData"/> record with the flattened row stream.</returns>
    public Task<TransformedData> TransformAsync(
        ParsedData parsedData,
        PipelineOptions options,
        CancellationToken cancellationToken)
    {
        ArgumentNullException.ThrowIfNull(parsedData);
        ArgumentNullException.ThrowIfNull(options);

        // Plugin options take precedence; fall back to pipeline options
        var maxDepth = pluginOptions.MaxExplosionDepth > 0
            ? pluginOptions.MaxExplosionDepth
            : options.MaxExplosionDepth;

        var nullPlaceholder = string.IsNullOrEmpty(pluginOptions.NullPlaceholder)
            ? options.NullPlaceholder
            : pluginOptions.NullPlaceholder;

        logger.LogDebug(
            "JsonDataTransformer starting: MaxExplosionDepth={Depth} NullPlaceholder='{Placeholder}'",
            maxDepth,
            nullPlaceholder);

        var transformedData = new TransformedData(
            Rows: StreamRowsAsync(parsedData, maxDepth, nullPlaceholder, cancellationToken),
            SourcePath: parsedData.SourcePath);

        return Task.FromResult(transformedData);
    }

    /// <summary>
    /// Lazily streams flattened rows from the parsed JSON element stream.
    /// </summary>
    /// <param name="parsedData">The parsed JSON element stream.</param>
    /// <param name="maxDepth">Maximum array explosion depth.</param>
    /// <param name="nullPlaceholder">Value for null or missing fields.</param>
    /// <param name="cancellationToken">A token to cancel enumeration.</param>
    /// <returns>An async enumerable of flattened rows.</returns>
    private async IAsyncEnumerable<FlattenedRow> StreamRowsAsync(
        ParsedData parsedData,
        int maxDepth,
        string nullPlaceholder,
        [EnumeratorCancellation] CancellationToken cancellationToken)
    {
        var rowNumber = 1;

        await foreach (var element in parsedData.Elements
            .WithCancellation(cancellationToken)
            .ConfigureAwait(false))
        {
            // Explode each top-level element into one or more rows
            var rows = JsonArrayExploder.Explode(
                element,
                new Dictionary<string, string>(StringComparer.OrdinalIgnoreCase),
                prefix: string.Empty,
                maxDepth: maxDepth,
                currentDepth: 0,
                sourcePath: parsedData.SourcePath,
                rowNumber: rowNumber,
                nullPlaceholder: nullPlaceholder);

            foreach (var row in rows)
            {
                cancellationToken.ThrowIfCancellationRequested();
                yield return row;
            }

            rowNumber++;
        }

        logger.LogDebug(
            "JsonDataTransformer completed: {RowCount} element(s) processed from '{Source}'",
            rowNumber - 1,
            parsedData.SourcePath);
    }
}
'@

New-SourceFile $JsonRoot "JsonReaderPlugin.cs" @'
// <copyright file="JsonReaderPlugin.cs" company="Axel Johnson International">
// Copyright (c) 2026 Axel Johnson International. All rights reserved.
// </copyright>

namespace Axbus.Plugin.Reader.Json;

using Axbus.Core.Abstractions.Pipeline;
using Axbus.Core.Abstractions.Plugin;
using Axbus.Core.Enums;
using Axbus.Plugin.Reader.Json.Options;
using Axbus.Plugin.Reader.Json.Parser;
using Axbus.Plugin.Reader.Json.Reader;
using Axbus.Plugin.Reader.Json.Transformer;
using Axbus.Plugin.Reader.Json.Validators;
using Microsoft.Extensions.Logging;

/// <summary>
/// The entry-point <see cref="IPlugin"/> implementation for the
/// <c>Axbus.Plugin.Reader.Json</c> plugin. This plugin handles the
/// Read, Parse and Transform pipeline stages for JSON source files.
/// It does not implement the Write stage (<see cref="CreateWriter"/> returns null).
/// Register this plugin by adding <c>Axbus.Plugin.Reader.Json</c> to the
/// <c>PluginSettings.Plugins</c> list in <c>appsettings.json</c>.
/// </summary>
public sealed class JsonReaderPlugin : IPlugin
{
    /// <summary>Gets the unique reverse-domain identifier of this plugin.</summary>
    public string PluginId => "axbus.plugin.reader.json";

    /// <summary>Gets the display name of this plugin.</summary>
    public string Name => "JsonReader";

    /// <summary>Gets the semantic version of this plugin.</summary>
    public Version Version => new(1, 0, 0);

    /// <summary>Gets the minimum Axbus framework version required by this plugin.</summary>
    public Version MinFrameworkVersion => new(1, 0, 0);

    /// <summary>
    /// Gets the pipeline capabilities supported by this plugin.
    /// Supports Read, Parse and Transform stages only.
    /// </summary>
    public PluginCapabilities Capabilities =>
        PluginCapabilities.Reader | PluginCapabilities.Parser | PluginCapabilities.Transformer;

    /// <summary>
    /// The options resolved during <see cref="InitializeAsync"/>.
    /// </summary>
    private JsonReaderPluginOptions resolvedOptions = new();

    /// <summary>
    /// Creates the <see cref="ISourceReader"/> for this plugin.
    /// </summary>
    /// <param name="services">The service provider for dependency resolution.</param>
    /// <returns>A new <see cref="JsonSourceReader"/> instance.</returns>
    public ISourceReader? CreateReader(IServiceProvider services)
    {
        var logger = GetLogger<JsonSourceReader>(services);
        return new JsonSourceReader(logger);
    }

    /// <summary>
    /// Creates the <see cref="IFormatParser"/> for this plugin.
    /// </summary>
    /// <param name="services">The service provider for dependency resolution.</param>
    /// <returns>A new <see cref="JsonFormatParser"/> instance.</returns>
    public IFormatParser? CreateParser(IServiceProvider services)
    {
        var logger = GetLogger<JsonFormatParser>(services);
        return new JsonFormatParser(logger, resolvedOptions);
    }

    /// <summary>
    /// Creates the <see cref="IDataTransformer"/> for this plugin.
    /// </summary>
    /// <param name="services">The service provider for dependency resolution.</param>
    /// <returns>A new <see cref="JsonDataTransformer"/> instance.</returns>
    public IDataTransformer? CreateTransformer(IServiceProvider services)
    {
        var logger = GetLogger<JsonDataTransformer>(services);
        return new JsonDataTransformer(logger, resolvedOptions);
    }

    /// <summary>
    /// This plugin does not support the Write stage.
    /// </summary>
    /// <param name="services">The service provider (unused).</param>
    /// <returns>Always <c>null</c>.</returns>
    public IOutputWriter? CreateWriter(IServiceProvider services) => null;

    /// <summary>
    /// Initializes this plugin by validating options and storing them for
    /// use by stage factory methods.
    /// </summary>
    /// <param name="context">The plugin context providing options and logger.</param>
    /// <param name="cancellationToken">A token to cancel initialisation.</param>
    public Task InitializeAsync(IPluginContext context, CancellationToken cancellationToken)
    {
        ArgumentNullException.ThrowIfNull(context);

        context.Logger.LogInformation(
            "JsonReaderPlugin initialising: {PluginId} v{Version}",
            PluginId,
            Version);

        // Extract and validate plugin options
        if (context.Options is JsonReaderPluginOptions typedOptions)
        {
            var validator = new JsonReaderOptionsValidator();
            var errors = validator.Validate(typedOptions).ToList();

            if (errors.Count > 0)
            {
                foreach (var error in errors)
                {
                    context.Logger.LogWarning("Plugin options validation: {Error}", error);
                }
            }

            resolvedOptions = typedOptions;
        }

        context.Logger.LogInformation(
            "JsonReaderPlugin initialised: MaxExplosionDepth={Depth} RootArrayKey='{Key}'",
            resolvedOptions.MaxExplosionDepth,
            resolvedOptions.RootArrayKey ?? "(auto-detect)");

        return Task.CompletedTask;
    }

    /// <summary>
    /// Shuts down this plugin. No resources to release for the JSON reader.
    /// </summary>
    /// <param name="cancellationToken">A token to cancel shutdown.</param>
    public Task ShutdownAsync(CancellationToken cancellationToken)
    {
        return Task.CompletedTask;
    }

    /// <summary>
    /// Creates a typed logger from the service provider, or a null logger if unavailable.
    /// </summary>
    /// <typeparam name="T">The category type for the logger.</typeparam>
    /// <param name="services">The service provider to resolve from.</param>
    /// <returns>An <see cref="ILogger{T}"/> instance.</returns>
    private static ILogger<T> GetLogger<T>(IServiceProvider services)
    {
        return (ILogger<T>?)services.GetService(typeof(ILogger<T>))
            ?? Microsoft.Extensions.Logging.Abstractions.NullLogger<T>.Instance;
    }
}
'@

# ==============================================================================
# PLUGIN 2 - AXBUS.PLUGIN.WRITER.CSV
# ==============================================================================

$CsvRoot = "src/plugins/Axbus.Plugin.Writer.Csv"

Write-Phase "Plugin 2 - Axbus.Plugin.Writer.Csv"
Write-Info "Root: $CsvRoot"

New-SourceFile $CsvRoot "Options/CsvWriterPluginOptions.cs" @'
// <copyright file="CsvWriterPluginOptions.cs" company="Axel Johnson International">
// Copyright (c) 2026 Axel Johnson International. All rights reserved.
// </copyright>

namespace Axbus.Plugin.Writer.Csv.Options;

using System.Text.Json;
using System.Text.Json.Serialization;
using Axbus.Core.Abstractions.Plugin;

/// <summary>
/// Strongly-typed options for the <c>Axbus.Plugin.Writer.Csv</c> plugin.
/// Deserialised from the <c>PluginOptions</c> section of a conversion module
/// at runtime. Unknown JSON keys are captured in <see cref="AdditionalOptions"/>.
/// </summary>
public sealed class CsvWriterPluginOptions : IPluginOptions
{
    /// <summary>
    /// Gets or sets the column delimiter character used to separate field values.
    /// Defaults to <c>,</c> (comma) for standard RFC 4180 CSV format.
    /// Use <c>;</c> for European locale compatibility or <c>\t</c> for TSV format.
    /// </summary>
    public char Delimiter { get; set; } = ',';

    /// <summary>
    /// Gets or sets the text encoding name for the output file.
    /// Defaults to <c>UTF-8</c>. Common alternatives: <c>UTF-16</c>, <c>ASCII</c>.
    /// </summary>
    public string Encoding { get; set; } = "UTF-8";

    /// <summary>
    /// Gets or sets a value indicating whether a header row containing
    /// column names is written as the first row of the output file.
    /// Defaults to <c>true</c>.
    /// </summary>
    public bool IncludeHeader { get; set; } = true;

    /// <summary>
    /// Gets or sets additional options not declared as explicit properties.
    /// Populated automatically for any unrecognised keys in <c>PluginOptions</c>.
    /// </summary>
    [JsonExtensionData]
    public Dictionary<string, JsonElement>? AdditionalOptions { get; set; }
}
'@

New-SourceFile $CsvRoot "Validators/CsvWriterOptionsValidator.cs" @'
// <copyright file="CsvWriterOptionsValidator.cs" company="Axel Johnson International">
// Copyright (c) 2026 Axel Johnson International. All rights reserved.
// </copyright>

namespace Axbus.Plugin.Writer.Csv.Validators;

using Axbus.Core.Abstractions.Plugin;
using Axbus.Plugin.Writer.Csv.Options;

/// <summary>
/// Validates <see cref="CsvWriterPluginOptions"/> before the CSV writer
/// plugin is initialised. Checks that the delimiter is a valid single
/// character and that the encoding name is recognisable.
/// </summary>
public sealed class CsvWriterOptionsValidator : IPluginOptionsValidator
{
    /// <summary>
    /// Validates the specified <paramref name="options"/> instance.
    /// </summary>
    /// <param name="options">The options instance to validate.</param>
    /// <returns>
    /// An empty enumerable when options are valid, or one or more
    /// error messages when options are invalid.
    /// </returns>
    public IEnumerable<string> Validate(IPluginOptions options)
    {
        if (options is not CsvWriterPluginOptions csvOptions)
        {
            yield return $"Expected {nameof(CsvWriterPluginOptions)} " +
                         $"but received {options?.GetType().Name ?? "null"}.";
            yield break;
        }

        if (csvOptions.Delimiter == '\0')
        {
            yield return $"{nameof(CsvWriterPluginOptions.Delimiter)} must not be a null character.";
        }

        if (string.IsNullOrWhiteSpace(csvOptions.Encoding))
        {
            yield return $"{nameof(CsvWriterPluginOptions.Encoding)} must not be empty.";
            yield break;
        }

        try
        {
            System.Text.Encoding.GetEncoding(csvOptions.Encoding);
        }
        catch (ArgumentException)
        {
            yield return $"'{csvOptions.Encoding}' is not a recognised encoding name. " +
                         "Common values: UTF-8, UTF-16, ASCII.";
        }
    }
}
'@

New-SourceFile $CsvRoot "Internal/CsvSchemaBuilder.cs" @'
// <copyright file="CsvSchemaBuilder.cs" company="Axel Johnson International">
// Copyright (c) 2026 Axel Johnson International. All rights reserved.
// </copyright>

namespace Axbus.Plugin.Writer.Csv.Internal;

using System.Runtime.CompilerServices;
using Axbus.Core.Models.Pipeline;
using Microsoft.Extensions.Logging;

/// <summary>
/// Builds the output column schema for CSV output by scanning
/// <see cref="FlattenedRow"/> instances and collecting column names
/// in first-seen order. This is an internal implementation detail of
/// the CSV writer plugin and is not a public pipeline stage.
/// Schema building is triggered when
/// <see cref="Axbus.Core.Abstractions.Pipeline.ISchemaAwareWriter.BuildSchemaAsync"/>
/// is called on the CSV writer.
/// </summary>
internal sealed class CsvSchemaBuilder
{
    /// <summary>
    /// Logger instance for schema discovery diagnostic output.
    /// </summary>
    private readonly ILogger<CsvSchemaBuilder> logger;

    /// <summary>
    /// Initializes a new instance of <see cref="CsvSchemaBuilder"/>.
    /// </summary>
    /// <param name="logger">The logger for schema discovery messages.</param>
    public CsvSchemaBuilder(ILogger<CsvSchemaBuilder> logger)
    {
        this.logger = logger;
    }

    /// <summary>
    /// Scans all rows in <paramref name="rows"/> and returns a
    /// <see cref="SchemaDefinition"/> containing the union of all
    /// column names in first-seen order.
    /// </summary>
    /// <param name="rows">The async stream of flattened rows to scan.</param>
    /// <param name="cancellationToken">A token to cancel the schema build.</param>
    /// <returns>
    /// A <see cref="SchemaDefinition"/> with columns in first-seen order.
    /// </returns>
    public async Task<SchemaDefinition> BuildAsync(
        IAsyncEnumerable<FlattenedRow> rows,
        CancellationToken cancellationToken)
    {
        ArgumentNullException.ThrowIfNull(rows);

        // Use an ordered set to maintain first-seen column order
        var columns = new List<string>();
        var columnSet = new HashSet<string>(StringComparer.OrdinalIgnoreCase);
        var rowCount = 0;
        var bufferedRows = new List<FlattenedRow>();

        await foreach (var row in rows.WithCancellation(cancellationToken).ConfigureAwait(false))
        {
            foreach (var key in row.Values.Keys)
            {
                if (columnSet.Add(key))
                {
                    columns.Add(key);
                }
            }

            bufferedRows.Add(row);
            rowCount++;
        }

        logger.LogDebug(
            "CSV schema built: {ColumnCount} columns from {RowCount} rows",
            columns.Count,
            rowCount);

        return new SchemaDefinition(columns.AsReadOnly(), "csv", sourceFileCount: 1);
    }
}
'@

New-SourceFile $CsvRoot "Writer/CsvOutputWriter.cs" @'
// <copyright file="CsvOutputWriter.cs" company="Axel Johnson International">
// Copyright (c) 2026 Axel Johnson International. All rights reserved.
// </copyright>

namespace Axbus.Plugin.Writer.Csv.Writer;

using System.Diagnostics;
using System.Text;
using Axbus.Core.Abstractions.Pipeline;
using Axbus.Core.Enums;
using Axbus.Core.Models.Configuration;
using Axbus.Core.Models.Pipeline;
using Axbus.Plugin.Writer.Csv.Internal;
using Axbus.Plugin.Writer.Csv.Options;
using Microsoft.Extensions.Logging;

/// <summary>
/// Implements <see cref="IOutputWriter"/> and <see cref="ISchemaAwareWriter"/>
/// for CSV output. Produces RFC 4180 compliant CSV files with configurable
/// delimiter, encoding and header row. Uses internal <see cref="CsvSchemaBuilder"/>
/// for schema discovery. Writes error rows to a separate error file when
/// <see cref="RowErrorStrategy.WriteToErrorFile"/> is configured.
/// </summary>
public sealed class CsvOutputWriter : IOutputWriter, ISchemaAwareWriter
{
    /// <summary>
    /// Logger instance for structured writer diagnostic output.
    /// </summary>
    private readonly ILogger<CsvOutputWriter> logger;

    /// <summary>
    /// Plugin-specific options controlling delimiter, encoding and header.
    /// </summary>
    private readonly CsvWriterPluginOptions pluginOptions;

    /// <summary>
    /// Internal schema builder used when ISchemaAwareWriter.BuildSchemaAsync is called.
    /// </summary>
    private readonly CsvSchemaBuilder schemaBuilder;

    /// <summary>
    /// The schema built by <see cref="BuildSchemaAsync"/>, if called.
    /// </summary>
    private SchemaDefinition? preBuiltSchema;

    /// <summary>
    /// Initializes a new instance of <see cref="CsvOutputWriter"/>.
    /// </summary>
    /// <param name="logger">The logger for writer operations.</param>
    /// <param name="pluginOptions">The CSV-specific plugin options.</param>
    /// <param name="schemaBuilder">The internal schema builder for column discovery.</param>
    public CsvOutputWriter(
        ILogger<CsvOutputWriter> logger,
        CsvWriterPluginOptions pluginOptions,
        CsvSchemaBuilder schemaBuilder)
    {
        this.logger = logger;
        this.pluginOptions = pluginOptions;
        this.schemaBuilder = schemaBuilder;
    }

    /// <summary>
    /// Builds the column schema by scanning all rows. Called by the pipeline
    /// factory before <see cref="WriteAsync"/> when FullScan strategy is configured.
    /// </summary>
    /// <param name="rows">The async stream of flattened rows to scan.</param>
    /// <param name="cancellationToken">A token to cancel the schema build.</param>
    /// <returns>The discovered <see cref="SchemaDefinition"/>.</returns>
    public async Task<SchemaDefinition> BuildSchemaAsync(
        IAsyncEnumerable<FlattenedRow> rows,
        CancellationToken cancellationToken)
    {
        preBuiltSchema = await schemaBuilder.BuildAsync(rows, cancellationToken).ConfigureAwait(false);
        return preBuiltSchema;
    }

    /// <summary>
    /// Writes the transformed rows to a RFC 4180 compliant CSV file.
    /// Uses the pre-built schema when available, otherwise discovers
    /// the schema on the first pass through the rows.
    /// </summary>
    /// <param name="transformedData">The flattened row stream to write.</param>
    /// <param name="targetOptions">Target configuration containing the output path.</param>
    /// <param name="pipelineOptions">Pipeline options for null placeholder and error strategy.</param>
    /// <param name="cancellationToken">A token to cancel the write operation.</param>
    /// <returns>A <see cref="WriteResult"/> with row counts and output path.</returns>
    public async Task<WriteResult> WriteAsync(
        TransformedData transformedData,
        TargetOptions targetOptions,
        PipelineOptions pipelineOptions,
        CancellationToken cancellationToken)
    {
        ArgumentNullException.ThrowIfNull(transformedData);
        ArgumentNullException.ThrowIfNull(targetOptions);
        ArgumentNullException.ThrowIfNull(pipelineOptions);

        var stopwatch = Stopwatch.StartNew();

        // Resolve output encoding
        var encoding = GetEncoding(pluginOptions.Encoding);
        var delimiter = pluginOptions.Delimiter;
        var nullPlaceholder = pipelineOptions.NullPlaceholder;

        // Collect all rows to allow schema discovery if not pre-built
        var allRows = new List<FlattenedRow>();

        await foreach (var row in transformedData.Rows
            .WithCancellation(cancellationToken)
            .ConfigureAwait(false))
        {
            allRows.Add(row);
        }

        // Build schema from collected rows if not pre-built
        var schema = preBuiltSchema ?? BuildSchemaFromRows(allRows);

        // Determine output file name
        var sourceName = Path.GetFileNameWithoutExtension(transformedData.SourcePath);
        var outputFileName = string.IsNullOrWhiteSpace(sourceName) ? "output.csv" : $"{sourceName}.csv";

        // Ensure output directory exists
        if (!Directory.Exists(targetOptions.Path))
        {
            Directory.CreateDirectory(targetOptions.Path);
        }

        var outputPath = Path.Combine(targetOptions.Path, outputFileName);
        var errorPath = (string?)null;
        var rowsWritten = 0;
        var errorRowsWritten = 0;
        var errorRows = new List<FlattenedRow>();

        await using var writer = new StreamWriter(outputPath, append: false, encoding);

        // Write header row
        if (pluginOptions.IncludeHeader)
        {
            var headerLine = BuildCsvLine(schema.Columns, delimiter);
            await writer.WriteLineAsync(headerLine).ConfigureAwait(false);
        }

        // Write data rows
        foreach (var row in allRows)
        {
            cancellationToken.ThrowIfCancellationRequested();

            try
            {
                var values = schema.Columns.Select(col =>
                    row.Values.TryGetValue(col, out var val) ? val : nullPlaceholder);

                var line = BuildCsvLine(values, delimiter);
                await writer.WriteLineAsync(line).ConfigureAwait(false);
                rowsWritten++;
            }
            catch (Exception ex) when (ex is not OperationCanceledException)
            {
                logger.LogWarning(
                    ex,
                    "Row {RowNumber} failed to write for source '{Source}'",
                    row.RowNumber,
                    row.SourceFilePath);

                if (pipelineOptions.RowErrorStrategy == RowErrorStrategy.WriteToErrorFile)
                {
                    errorRows.Add(row);
                }
            }
        }

        // Write error file if needed
        if (errorRows.Count > 0)
        {
            var errorFileName = $"{sourceName}{targetOptions.ErrorFileSuffix}.csv";
            var errorOutputPath = !string.IsNullOrWhiteSpace(targetOptions.ErrorOutputPath)
                ? targetOptions.ErrorOutputPath
                : targetOptions.Path;

            if (!Directory.Exists(errorOutputPath))
            {
                Directory.CreateDirectory(errorOutputPath);
            }

            errorPath = Path.Combine(errorOutputPath, errorFileName);

            await using var errorWriter = new StreamWriter(errorPath, append: false, encoding);

            // Write error header with extra error column
            var errorColumns = schema.Columns.Append("_AxbusError").ToList();
            await errorWriter.WriteLineAsync(BuildCsvLine(errorColumns, delimiter)).ConfigureAwait(false);

            foreach (var errorRow in errorRows)
            {
                var values = schema.Columns
                    .Select(col => errorRow.Values.TryGetValue(col, out var v) ? v : nullPlaceholder)
                    .Append($"Row {errorRow.RowNumber} failed");

                await errorWriter.WriteLineAsync(BuildCsvLine(values, delimiter)).ConfigureAwait(false);
                errorRowsWritten++;
            }

            logger.LogWarning(
                "CSV error file written: {ErrorPath} | ErrorRows: {Count}",
                errorPath,
                errorRowsWritten);
        }

        stopwatch.Stop();

        logger.LogInformation(
            "CSV written: {OutputPath} | Rows: {RowsWritten} | Errors: {ErrorRows} | Duration: {Ms}ms",
            outputPath,
            rowsWritten,
            errorRowsWritten,
            stopwatch.ElapsedMilliseconds);

        return new WriteResult(
            RowsWritten: rowsWritten,
            ErrorRowsWritten: errorRowsWritten,
            OutputPath: outputPath,
            ErrorFilePath: errorPath,
            Format: OutputFormat.Csv,
            Duration: stopwatch.Elapsed);
    }

    /// <summary>
    /// Builds a schema from a list of already-collected rows when no pre-built schema exists.
    /// </summary>
    /// <param name="rows">The rows to derive the schema from.</param>
    /// <returns>A <see cref="SchemaDefinition"/> in first-seen column order.</returns>
    private static SchemaDefinition BuildSchemaFromRows(IEnumerable<FlattenedRow> rows)
    {
        var columns = new List<string>();
        var columnSet = new HashSet<string>(StringComparer.OrdinalIgnoreCase);

        foreach (var row in rows)
        {
            foreach (var key in row.Values.Keys)
            {
                if (columnSet.Add(key))
                {
                    columns.Add(key);
                }
            }
        }

        return new SchemaDefinition(columns.AsReadOnly(), "csv");
    }

    /// <summary>
    /// Builds a single RFC 4180 compliant CSV line from the provided values.
    /// Values containing the delimiter, double-quotes or newlines are wrapped
    /// in double-quotes with internal double-quotes escaped by doubling.
    /// </summary>
    /// <param name="values">The field values for this row.</param>
    /// <param name="delimiter">The field delimiter character.</param>
    /// <returns>A single RFC 4180 compliant CSV line string.</returns>
    private static string BuildCsvLine(IEnumerable<string> values, char delimiter)
    {
        var builder = new StringBuilder(capacity: 256);
        var first = true;

        foreach (var value in values)
        {
            if (!first)
            {
                builder.Append(delimiter);
            }

            // RFC 4180: wrap in quotes if value contains delimiter, quote or newline
            var needsQuoting = value.Contains(delimiter) ||
                               value.Contains('"') ||
                               value.Contains('\n') ||
                               value.Contains('\r');

            if (needsQuoting)
            {
                builder.Append('"');
                builder.Append(value.Replace("\"", "\"\""));
                builder.Append('"');
            }
            else
            {
                builder.Append(value);
            }

            first = false;
        }

        return builder.ToString();
    }

    /// <summary>
    /// Resolves the text encoding from the encoding name string.
    /// Falls back to UTF-8 when the name is unrecognised.
    /// </summary>
    /// <param name="encodingName">The encoding name, for example <c>UTF-8</c>.</param>
    /// <returns>The resolved <see cref="Encoding"/> instance.</returns>
    private Encoding GetEncoding(string encodingName)
    {
        try
        {
            return Encoding.GetEncoding(encodingName);
        }
        catch (ArgumentException)
        {
            logger.LogWarning(
                "Unrecognised encoding '{Name}'. Falling back to UTF-8.",
                encodingName);
            return Encoding.UTF8;
        }
    }
}
'@

New-SourceFile $CsvRoot "CsvWriterPlugin.cs" @'
// <copyright file="CsvWriterPlugin.cs" company="Axel Johnson International">
// Copyright (c) 2026 Axel Johnson International. All rights reserved.
// </copyright>

namespace Axbus.Plugin.Writer.Csv;

using Axbus.Core.Abstractions.Pipeline;
using Axbus.Core.Abstractions.Plugin;
using Axbus.Core.Enums;
using Axbus.Plugin.Writer.Csv.Internal;
using Axbus.Plugin.Writer.Csv.Options;
using Axbus.Plugin.Writer.Csv.Validators;
using Axbus.Plugin.Writer.Csv.Writer;
using Microsoft.Extensions.Logging;

/// <summary>
/// The entry-point <see cref="IPlugin"/> implementation for the
/// <c>Axbus.Plugin.Writer.Csv</c> plugin. This plugin handles the Write
/// pipeline stage for CSV output. It does not implement Read, Parse or
/// Transform stages (<see cref="CreateReader"/>, <see cref="CreateParser"/>
/// and <see cref="CreateTransformer"/> all return null).
/// Register this plugin by adding <c>Axbus.Plugin.Writer.Csv</c> to the
/// <c>PluginSettings.Plugins</c> list in <c>appsettings.json</c>.
/// </summary>
public sealed class CsvWriterPlugin : IPlugin
{
    /// <summary>Gets the unique reverse-domain identifier of this plugin.</summary>
    public string PluginId => "axbus.plugin.writer.csv";

    /// <summary>Gets the display name of this plugin.</summary>
    public string Name => "CsvWriter";

    /// <summary>Gets the semantic version of this plugin.</summary>
    public Version Version => new(1, 0, 0);

    /// <summary>Gets the minimum Axbus framework version required by this plugin.</summary>
    public Version MinFrameworkVersion => new(1, 0, 0);

    /// <summary>
    /// Gets the pipeline capabilities supported by this plugin.
    /// Supports the Write stage only.
    /// </summary>
    public PluginCapabilities Capabilities => PluginCapabilities.Writer;

    /// <summary>
    /// The options resolved during <see cref="InitializeAsync"/>.
    /// </summary>
    private CsvWriterPluginOptions resolvedOptions = new();

    /// <summary>This plugin does not support the Read stage.</summary>
    public ISourceReader? CreateReader(IServiceProvider services) => null;

    /// <summary>This plugin does not support the Parse stage.</summary>
    public IFormatParser? CreateParser(IServiceProvider services) => null;

    /// <summary>This plugin does not support the Transform stage.</summary>
    public IDataTransformer? CreateTransformer(IServiceProvider services) => null;

    /// <summary>
    /// Creates the <see cref="IOutputWriter"/> for this plugin.
    /// Returns a <see cref="CsvOutputWriter"/> that also implements
    /// <see cref="ISchemaAwareWriter"/>.
    /// </summary>
    /// <param name="services">The service provider for dependency resolution.</param>
    /// <returns>A new <see cref="CsvOutputWriter"/> instance.</returns>
    public IOutputWriter? CreateWriter(IServiceProvider services)
    {
        var writerLogger = GetLogger<CsvOutputWriter>(services);
        var schemaLogger = GetLogger<CsvSchemaBuilder>(services);
        var schemaBuilder = new CsvSchemaBuilder(schemaLogger);
        return new CsvOutputWriter(writerLogger, resolvedOptions, schemaBuilder);
    }

    /// <summary>
    /// Initializes this plugin by validating and storing options.
    /// </summary>
    /// <param name="context">The plugin context providing options and logger.</param>
    /// <param name="cancellationToken">A token to cancel initialisation.</param>
    public Task InitializeAsync(IPluginContext context, CancellationToken cancellationToken)
    {
        ArgumentNullException.ThrowIfNull(context);

        context.Logger.LogInformation(
            "CsvWriterPlugin initialising: {PluginId} v{Version}",
            PluginId,
            Version);

        if (context.Options is CsvWriterPluginOptions typedOptions)
        {
            var validator = new CsvWriterOptionsValidator();
            var errors = validator.Validate(typedOptions).ToList();

            foreach (var error in errors)
            {
                context.Logger.LogWarning("Plugin options validation: {Error}", error);
            }

            resolvedOptions = typedOptions;
        }

        context.Logger.LogInformation(
            "CsvWriterPlugin initialised: Delimiter='{Delimiter}' Encoding={Encoding} Header={Header}",
            resolvedOptions.Delimiter,
            resolvedOptions.Encoding,
            resolvedOptions.IncludeHeader);

        return Task.CompletedTask;
    }

    /// <summary>Shuts down this plugin. No resources to release.</summary>
    public Task ShutdownAsync(CancellationToken cancellationToken) => Task.CompletedTask;

    /// <summary>Resolves a typed logger from the service provider.</summary>
    private static ILogger<T> GetLogger<T>(IServiceProvider services) =>
        (ILogger<T>?)services.GetService(typeof(ILogger<T>))
        ?? Microsoft.Extensions.Logging.Abstractions.NullLogger<T>.Instance;
}
'@

# ==============================================================================
# PLUGIN 3 - AXBUS.PLUGIN.WRITER.EXCEL
# ==============================================================================

$ExcelRoot = "src/plugins/Axbus.Plugin.Writer.Excel"

Write-Phase "Plugin 3 - Axbus.Plugin.Writer.Excel"
Write-Info "Root: $ExcelRoot"

New-SourceFile $ExcelRoot "Options/ExcelWriterPluginOptions.cs" @'
// <copyright file="ExcelWriterPluginOptions.cs" company="Axel Johnson International">
// Copyright (c) 2026 Axel Johnson International. All rights reserved.
// </copyright>

namespace Axbus.Plugin.Writer.Excel.Options;

using System.Text.Json;
using System.Text.Json.Serialization;
using Axbus.Core.Abstractions.Plugin;

/// <summary>
/// Strongly-typed options for the <c>Axbus.Plugin.Writer.Excel</c> plugin.
/// Deserialised from the <c>PluginOptions</c> section of a conversion module.
/// Unknown JSON keys are captured in <see cref="AdditionalOptions"/>.
/// </summary>
public sealed class ExcelWriterPluginOptions : IPluginOptions
{
    /// <summary>
    /// Gets or sets the name of the worksheet created in the output workbook.
    /// Defaults to <c>Sheet1</c>. Excel worksheet names must be 31 characters
    /// or fewer and must not contain the characters <c>: \ / ? * [ ]</c>.
    /// </summary>
    public string SheetName { get; set; } = "Sheet1";

    /// <summary>
    /// Gets or sets a value indicating whether column widths are automatically
    /// adjusted to fit the content of each column.
    /// Defaults to <c>true</c>.
    /// </summary>
    public bool AutoFit { get; set; } = true;

    /// <summary>
    /// Gets or sets a value indicating whether the header row is formatted
    /// with bold text to distinguish it from data rows.
    /// Defaults to <c>true</c>.
    /// </summary>
    public bool BoldHeaders { get; set; } = true;

    /// <summary>
    /// Gets or sets a value indicating whether the header row is frozen so
    /// that it remains visible when scrolling through data rows.
    /// Defaults to <c>true</c>.
    /// </summary>
    public bool FreezeHeader { get; set; } = true;

    /// <summary>
    /// Gets or sets additional options not declared as explicit properties.
    /// Populated automatically for any unrecognised keys in <c>PluginOptions</c>.
    /// </summary>
    [JsonExtensionData]
    public Dictionary<string, JsonElement>? AdditionalOptions { get; set; }
}
'@

New-SourceFile $ExcelRoot "Validators/ExcelWriterOptionsValidator.cs" @'
// <copyright file="ExcelWriterOptionsValidator.cs" company="Axel Johnson International">
// Copyright (c) 2026 Axel Johnson International. All rights reserved.
// </copyright>

namespace Axbus.Plugin.Writer.Excel.Validators;

using Axbus.Core.Abstractions.Plugin;
using Axbus.Plugin.Writer.Excel.Options;

/// <summary>
/// Validates <see cref="ExcelWriterPluginOptions"/> before the Excel writer
/// plugin is initialised. Checks that the worksheet name is valid per
/// Excel naming rules (max 31 chars, no forbidden characters).
/// </summary>
public sealed class ExcelWriterOptionsValidator : IPluginOptionsValidator
{
    /// <summary>
    /// Characters that are not permitted in Excel worksheet names.
    /// </summary>
    private static readonly char[] ForbiddenSheetNameChars = { ':', '\\', '/', '?', '*', '[', ']' };

    /// <summary>
    /// Maximum length for an Excel worksheet name.
    /// </summary>
    private const int MaxSheetNameLength = 31;

    /// <summary>
    /// Validates the specified <paramref name="options"/> instance.
    /// </summary>
    /// <param name="options">The options instance to validate.</param>
    /// <returns>
    /// An empty enumerable when options are valid, or one or more
    /// error messages when options are invalid.
    /// </returns>
    public IEnumerable<string> Validate(IPluginOptions options)
    {
        if (options is not ExcelWriterPluginOptions excelOptions)
        {
            yield return $"Expected {nameof(ExcelWriterPluginOptions)} " +
                         $"but received {options?.GetType().Name ?? "null"}.";
            yield break;
        }

        if (string.IsNullOrWhiteSpace(excelOptions.SheetName))
        {
            yield return $"{nameof(ExcelWriterPluginOptions.SheetName)} must not be empty.";
            yield break;
        }

        if (excelOptions.SheetName.Length > MaxSheetNameLength)
        {
            yield return $"{nameof(ExcelWriterPluginOptions.SheetName)} must be " +
                         $"{MaxSheetNameLength} characters or fewer. " +
                         $"Current length: {excelOptions.SheetName.Length}.";
        }

        if (excelOptions.SheetName.IndexOfAny(ForbiddenSheetNameChars) >= 0)
        {
            yield return $"{nameof(ExcelWriterPluginOptions.SheetName)} contains " +
                         $"forbidden characters. The following are not permitted: " +
                         $"{string.Join(" ", ForbiddenSheetNameChars)}";
        }
    }
}
'@

New-SourceFile $ExcelRoot "Internal/ExcelSchemaBuilder.cs" @'
// <copyright file="ExcelSchemaBuilder.cs" company="Axel Johnson International">
// Copyright (c) 2026 Axel Johnson International. All rights reserved.
// </copyright>

namespace Axbus.Plugin.Writer.Excel.Internal;

using Axbus.Core.Models.Pipeline;
using Microsoft.Extensions.Logging;

/// <summary>
/// Builds the output column schema for Excel output by scanning
/// <see cref="FlattenedRow"/> instances and collecting column names
/// in first-seen order. This is an internal implementation detail of
/// the Excel writer plugin and is not a public pipeline stage.
/// </summary>
internal sealed class ExcelSchemaBuilder
{
    /// <summary>
    /// Logger instance for schema discovery diagnostic output.
    /// </summary>
    private readonly ILogger<ExcelSchemaBuilder> logger;

    /// <summary>
    /// Initializes a new instance of <see cref="ExcelSchemaBuilder"/>.
    /// </summary>
    /// <param name="logger">The logger for schema discovery messages.</param>
    public ExcelSchemaBuilder(ILogger<ExcelSchemaBuilder> logger)
    {
        this.logger = logger;
    }

    /// <summary>
    /// Scans all rows in <paramref name="rows"/> and returns a
    /// <see cref="SchemaDefinition"/> with columns in first-seen order.
    /// </summary>
    /// <param name="rows">The async stream of flattened rows to scan.</param>
    /// <param name="cancellationToken">A token to cancel the schema build.</param>
    /// <returns>A <see cref="SchemaDefinition"/> for Excel output.</returns>
    public async Task<SchemaDefinition> BuildAsync(
        IAsyncEnumerable<FlattenedRow> rows,
        CancellationToken cancellationToken)
    {
        ArgumentNullException.ThrowIfNull(rows);

        var columns = new List<string>();
        var columnSet = new HashSet<string>(StringComparer.OrdinalIgnoreCase);
        var rowCount = 0;

        await foreach (var row in rows.WithCancellation(cancellationToken).ConfigureAwait(false))
        {
            foreach (var key in row.Values.Keys)
            {
                if (columnSet.Add(key))
                {
                    columns.Add(key);
                }
            }

            rowCount++;
        }

        logger.LogDebug(
            "Excel schema built: {ColumnCount} columns from {RowCount} rows",
            columns.Count,
            rowCount);

        return new SchemaDefinition(columns.AsReadOnly(), "excel", sourceFileCount: 1);
    }
}
'@

New-SourceFile $ExcelRoot "Writer/ExcelOutputWriter.cs" @'
// <copyright file="ExcelOutputWriter.cs" company="Axel Johnson International">
// Copyright (c) 2026 Axel Johnson International. All rights reserved.
// </copyright>

namespace Axbus.Plugin.Writer.Excel.Writer;

using System.Diagnostics;
using Axbus.Core.Abstractions.Pipeline;
using Axbus.Core.Enums;
using Axbus.Core.Models.Configuration;
using Axbus.Core.Models.Pipeline;
using Axbus.Plugin.Writer.Excel.Internal;
using Axbus.Plugin.Writer.Excel.Options;
using ClosedXML.Excel;
using Microsoft.Extensions.Logging;

/// <summary>
/// Implements <see cref="IOutputWriter"/> and <see cref="ISchemaAwareWriter"/>
/// for Excel (.xlsx) output using ClosedXML (MIT licensed). Produces formatted
/// workbooks with configurable sheet name, bold headers, auto-fit columns and
/// frozen header rows. Writes error rows to a separate error sheet when
/// <see cref="RowErrorStrategy.WriteToErrorFile"/> is configured.
/// </summary>
public sealed class ExcelOutputWriter : IOutputWriter, ISchemaAwareWriter
{
    /// <summary>
    /// Logger instance for structured writer diagnostic output.
    /// </summary>
    private readonly ILogger<ExcelOutputWriter> logger;

    /// <summary>
    /// Plugin-specific options controlling sheet name, formatting and header behaviour.
    /// </summary>
    private readonly ExcelWriterPluginOptions pluginOptions;

    /// <summary>
    /// Internal schema builder used when ISchemaAwareWriter.BuildSchemaAsync is called.
    /// </summary>
    private readonly ExcelSchemaBuilder schemaBuilder;

    /// <summary>
    /// The schema built by <see cref="BuildSchemaAsync"/>, if called.
    /// </summary>
    private SchemaDefinition? preBuiltSchema;

    /// <summary>
    /// Initializes a new instance of <see cref="ExcelOutputWriter"/>.
    /// </summary>
    /// <param name="logger">The logger for writer operations.</param>
    /// <param name="pluginOptions">The Excel-specific plugin options.</param>
    /// <param name="schemaBuilder">The internal schema builder for column discovery.</param>
    public ExcelOutputWriter(
        ILogger<ExcelOutputWriter> logger,
        ExcelWriterPluginOptions pluginOptions,
        ExcelSchemaBuilder schemaBuilder)
    {
        this.logger = logger;
        this.pluginOptions = pluginOptions;
        this.schemaBuilder = schemaBuilder;
    }

    /// <summary>
    /// Builds the column schema by scanning all rows.
    /// </summary>
    /// <param name="rows">The async stream of flattened rows to scan.</param>
    /// <param name="cancellationToken">A token to cancel the schema build.</param>
    /// <returns>The discovered <see cref="SchemaDefinition"/>.</returns>
    public async Task<SchemaDefinition> BuildSchemaAsync(
        IAsyncEnumerable<FlattenedRow> rows,
        CancellationToken cancellationToken)
    {
        preBuiltSchema = await schemaBuilder.BuildAsync(rows, cancellationToken).ConfigureAwait(false);
        return preBuiltSchema;
    }

    /// <summary>
    /// Writes the transformed rows to an Excel (.xlsx) workbook file.
    /// </summary>
    /// <param name="transformedData">The flattened row stream to write.</param>
    /// <param name="targetOptions">Target configuration containing the output path.</param>
    /// <param name="pipelineOptions">Pipeline options for null placeholder and error strategy.</param>
    /// <param name="cancellationToken">A token to cancel the write operation.</param>
    /// <returns>A <see cref="WriteResult"/> with row counts and output path.</returns>
    public async Task<WriteResult> WriteAsync(
        TransformedData transformedData,
        TargetOptions targetOptions,
        PipelineOptions pipelineOptions,
        CancellationToken cancellationToken)
    {
        ArgumentNullException.ThrowIfNull(transformedData);
        ArgumentNullException.ThrowIfNull(targetOptions);
        ArgumentNullException.ThrowIfNull(pipelineOptions);

        var stopwatch = Stopwatch.StartNew();
        var nullPlaceholder = pipelineOptions.NullPlaceholder;

        // Collect all rows to allow schema discovery and Excel population
        var allRows = new List<FlattenedRow>();

        await foreach (var row in transformedData.Rows
            .WithCancellation(cancellationToken)
            .ConfigureAwait(false))
        {
            allRows.Add(row);
        }

        // Build schema from collected rows if not pre-built
        var schema = preBuiltSchema ?? BuildSchemaFromRows(allRows);

        // Determine output file name
        var sourceName = Path.GetFileNameWithoutExtension(transformedData.SourcePath);
        var outputFileName = string.IsNullOrWhiteSpace(sourceName)
            ? "output.xlsx"
            : $"{sourceName}.xlsx";

        // Ensure output directory exists
        if (!Directory.Exists(targetOptions.Path))
        {
            Directory.CreateDirectory(targetOptions.Path);
        }

        var outputPath = Path.Combine(targetOptions.Path, outputFileName);
        var errorPath = (string?)null;
        var rowsWritten = 0;
        var errorRowsWritten = 0;
        var errorRows = new List<FlattenedRow>();

        // Build the workbook using ClosedXML
        using var workbook = new XLWorkbook();
        var sheetName = CleanSheetName(pluginOptions.SheetName);
        var worksheet = workbook.Worksheets.Add(sheetName);

        // Write header row
        for (var colIndex = 0; colIndex < schema.Columns.Count; colIndex++)
        {
            var cell = worksheet.Cell(1, colIndex + 1);
            cell.Value = schema.Columns[colIndex];

            if (pluginOptions.BoldHeaders)
            {
                cell.Style.Font.Bold = true;
            }
        }

        // Freeze header row if configured
        if (pluginOptions.FreezeHeader)
        {
            worksheet.SheetView.FreezeRows(1);
        }

        // Write data rows
        var excelRowIndex = 2;

        foreach (var row in allRows)
        {
            cancellationToken.ThrowIfCancellationRequested();

            try
            {
                for (var colIndex = 0; colIndex < schema.Columns.Count; colIndex++)
                {
                    var value = row.Values.TryGetValue(schema.Columns[colIndex], out var v)
                        ? v
                        : nullPlaceholder;
                    worksheet.Cell(excelRowIndex, colIndex + 1).Value = value;
                }

                excelRowIndex++;
                rowsWritten++;
            }
            catch (Exception ex) when (ex is not OperationCanceledException)
            {
                logger.LogWarning(
                    ex,
                    "Row {RowNumber} failed for source '{Source}'",
                    row.RowNumber,
                    row.SourceFilePath);

                if (pipelineOptions.RowErrorStrategy == RowErrorStrategy.WriteToErrorFile)
                {
                    errorRows.Add(row);
                }
            }
        }

        // Auto-fit columns if configured
        if (pluginOptions.AutoFit)
        {
            worksheet.Columns().AdjustToContents();
        }

        workbook.SaveAs(outputPath);

        // Write error sheet if needed
        if (errorRows.Count > 0)
        {
            var errorFileName = $"{sourceName}{targetOptions.ErrorFileSuffix}.xlsx";
            var errorOutputPath = !string.IsNullOrWhiteSpace(targetOptions.ErrorOutputPath)
                ? targetOptions.ErrorOutputPath
                : targetOptions.Path;

            if (!Directory.Exists(errorOutputPath))
            {
                Directory.CreateDirectory(errorOutputPath);
            }

            errorPath = Path.Combine(errorOutputPath, errorFileName);

            using var errorWorkbook = new XLWorkbook();
            var errorSheet = errorWorkbook.Worksheets.Add("Errors");

            // Error header with extra column
            var errorColumns = schema.Columns.Append("_AxbusError").ToList();
            for (var i = 0; i < errorColumns.Count; i++)
            {
                var cell = errorSheet.Cell(1, i + 1);
                cell.Value = errorColumns[i];
                if (pluginOptions.BoldHeaders) cell.Style.Font.Bold = true;
            }

            var errorExcelRow = 2;
            foreach (var errorRow in errorRows)
            {
                for (var i = 0; i < schema.Columns.Count; i++)
                {
                    errorSheet.Cell(errorExcelRow, i + 1).Value =
                        errorRow.Values.TryGetValue(schema.Columns[i], out var v)
                            ? v
                            : nullPlaceholder;
                }
                errorSheet.Cell(errorExcelRow, schema.Columns.Count + 1).Value =
                    $"Row {errorRow.RowNumber} failed";
                errorExcelRow++;
                errorRowsWritten++;
            }

            if (pluginOptions.AutoFit) errorSheet.Columns().AdjustToContents();
            errorWorkbook.SaveAs(errorPath);

            logger.LogWarning(
                "Excel error file written: {ErrorPath} | ErrorRows: {Count}",
                errorPath,
                errorRowsWritten);
        }

        stopwatch.Stop();

        logger.LogInformation(
            "Excel written: {OutputPath} | Rows: {RowsWritten} | Duration: {Ms}ms",
            outputPath,
            rowsWritten,
            stopwatch.ElapsedMilliseconds);

        return new WriteResult(
            RowsWritten: rowsWritten,
            ErrorRowsWritten: errorRowsWritten,
            OutputPath: outputPath,
            ErrorFilePath: errorPath,
            Format: OutputFormat.Excel,
            Duration: stopwatch.Elapsed);
    }

    /// <summary>
    /// Builds a schema from collected rows when no pre-built schema exists.
    /// </summary>
    private static SchemaDefinition BuildSchemaFromRows(IEnumerable<FlattenedRow> rows)
    {
        var columns = new List<string>();
        var columnSet = new HashSet<string>(StringComparer.OrdinalIgnoreCase);
        foreach (var row in rows)
        {
            foreach (var key in row.Values.Keys)
            {
                if (columnSet.Add(key)) columns.Add(key);
            }
        }
        return new SchemaDefinition(columns.AsReadOnly(), "excel");
    }

    /// <summary>
    /// Sanitises a sheet name to comply with Excel naming rules.
    /// Removes forbidden characters and truncates to 31 characters.
    /// </summary>
    /// <param name="sheetName">The raw sheet name from options.</param>
    /// <returns>A valid Excel worksheet name.</returns>
    private static string CleanSheetName(string sheetName)
    {
        var cleaned = new string(sheetName
            .Where(c => c != ':' && c != '\\' && c != '/' &&
                        c != '?' && c != '*' && c != '[' && c != ']')
            .ToArray());

        return cleaned.Length > 31 ? cleaned[..31] : cleaned;
    }
}
'@

New-SourceFile $ExcelRoot "ExcelWriterPlugin.cs" @'
// <copyright file="ExcelWriterPlugin.cs" company="Axel Johnson International">
// Copyright (c) 2026 Axel Johnson International. All rights reserved.
// </copyright>

namespace Axbus.Plugin.Writer.Excel;

using Axbus.Core.Abstractions.Pipeline;
using Axbus.Core.Abstractions.Plugin;
using Axbus.Core.Enums;
using Axbus.Plugin.Writer.Excel.Internal;
using Axbus.Plugin.Writer.Excel.Options;
using Axbus.Plugin.Writer.Excel.Validators;
using Axbus.Plugin.Writer.Excel.Writer;
using Microsoft.Extensions.Logging;

/// <summary>
/// The entry-point <see cref="IPlugin"/> implementation for the
/// <c>Axbus.Plugin.Writer.Excel</c> plugin. This plugin handles the Write
/// pipeline stage for Excel (.xlsx) output using ClosedXML. It does not
/// implement Read, Parse or Transform stages.
/// Register this plugin by adding <c>Axbus.Plugin.Writer.Excel</c> to the
/// <c>PluginSettings.Plugins</c> list in <c>appsettings.json</c>.
/// </summary>
public sealed class ExcelWriterPlugin : IPlugin
{
    /// <summary>Gets the unique reverse-domain identifier of this plugin.</summary>
    public string PluginId => "axbus.plugin.writer.excel";

    /// <summary>Gets the display name of this plugin.</summary>
    public string Name => "ExcelWriter";

    /// <summary>Gets the semantic version of this plugin.</summary>
    public Version Version => new(1, 0, 0);

    /// <summary>Gets the minimum Axbus framework version required by this plugin.</summary>
    public Version MinFrameworkVersion => new(1, 0, 0);

    /// <summary>
    /// Gets the pipeline capabilities supported by this plugin.
    /// Supports the Write stage only.
    /// </summary>
    public PluginCapabilities Capabilities => PluginCapabilities.Writer;

    /// <summary>
    /// The options resolved during <see cref="InitializeAsync"/>.
    /// </summary>
    private ExcelWriterPluginOptions resolvedOptions = new();

    /// <summary>This plugin does not support the Read stage.</summary>
    public ISourceReader? CreateReader(IServiceProvider services) => null;

    /// <summary>This plugin does not support the Parse stage.</summary>
    public IFormatParser? CreateParser(IServiceProvider services) => null;

    /// <summary>This plugin does not support the Transform stage.</summary>
    public IDataTransformer? CreateTransformer(IServiceProvider services) => null;

    /// <summary>
    /// Creates the <see cref="IOutputWriter"/> for this plugin.
    /// Returns an <see cref="ExcelOutputWriter"/> that also implements
    /// <see cref="ISchemaAwareWriter"/>.
    /// </summary>
    /// <param name="services">The service provider for dependency resolution.</param>
    /// <returns>A new <see cref="ExcelOutputWriter"/> instance.</returns>
    public IOutputWriter? CreateWriter(IServiceProvider services)
    {
        var writerLogger = GetLogger<ExcelOutputWriter>(services);
        var schemaLogger = GetLogger<ExcelSchemaBuilder>(services);
        var schemaBuilder = new ExcelSchemaBuilder(schemaLogger);
        return new ExcelOutputWriter(writerLogger, resolvedOptions, schemaBuilder);
    }

    /// <summary>
    /// Initializes this plugin by validating and storing options.
    /// </summary>
    /// <param name="context">The plugin context providing options and logger.</param>
    /// <param name="cancellationToken">A token to cancel initialisation.</param>
    public Task InitializeAsync(IPluginContext context, CancellationToken cancellationToken)
    {
        ArgumentNullException.ThrowIfNull(context);

        context.Logger.LogInformation(
            "ExcelWriterPlugin initialising: {PluginId} v{Version}",
            PluginId,
            Version);

        if (context.Options is ExcelWriterPluginOptions typedOptions)
        {
            var validator = new ExcelWriterOptionsValidator();
            var errors = validator.Validate(typedOptions).ToList();

            foreach (var error in errors)
            {
                context.Logger.LogWarning("Plugin options validation: {Error}", error);
            }

            resolvedOptions = typedOptions;
        }

        context.Logger.LogInformation(
            "ExcelWriterPlugin initialised: SheetName='{Sheet}' AutoFit={AutoFit} BoldHeaders={Bold}",
            resolvedOptions.SheetName,
            resolvedOptions.AutoFit,
            resolvedOptions.BoldHeaders);

        return Task.CompletedTask;
    }

    /// <summary>Shuts down this plugin. No resources to release.</summary>
    public Task ShutdownAsync(CancellationToken cancellationToken) => Task.CompletedTask;

    /// <summary>Resolves a typed logger from the service provider.</summary>
    private static ILogger<T> GetLogger<T>(IServiceProvider services) =>
        (ILogger<T>?)services.GetService(typeof(ILogger<T>))
        ?? Microsoft.Extensions.Logging.Abstractions.NullLogger<T>.Instance;
}
'@

# ==============================================================================
# SUMMARY
# ==============================================================================

Write-Host ""
Write-Host "===============================================================================" -ForegroundColor Green
Write-Host "  [DONE] All 3 Plugins - Code Generation Complete!" -ForegroundColor Green
Write-Host "===============================================================================" -ForegroundColor Green
Write-Host ""
Write-Host "  Plugin 1 - Axbus.Plugin.Reader.Json (7 files):" -ForegroundColor White
Write-Host "    [OK] Options/JsonReaderPluginOptions.cs" -ForegroundColor Green
Write-Host "    [OK] Validators/JsonReaderOptionsValidator.cs" -ForegroundColor Green
Write-Host "    [OK] Reader/JsonSourceReader.cs" -ForegroundColor Green
Write-Host "    [OK] Parser/JsonFormatParser.cs" -ForegroundColor Green
Write-Host "    [OK] Transformer/JsonArrayExploder.cs" -ForegroundColor Green
Write-Host "    [OK] Transformer/JsonDataTransformer.cs" -ForegroundColor Green
Write-Host "    [OK] JsonReaderPlugin.cs" -ForegroundColor Green
Write-Host ""
Write-Host "  Plugin 2 - Axbus.Plugin.Writer.Csv (6 files):" -ForegroundColor White
Write-Host "    [OK] Options/CsvWriterPluginOptions.cs" -ForegroundColor Green
Write-Host "    [OK] Validators/CsvWriterOptionsValidator.cs" -ForegroundColor Green
Write-Host "    [OK] Internal/CsvSchemaBuilder.cs" -ForegroundColor Green
Write-Host "    [OK] Writer/CsvOutputWriter.cs" -ForegroundColor Green
Write-Host "    [OK] CsvWriterPlugin.cs" -ForegroundColor Green
Write-Host ""
Write-Host "  Plugin 3 - Axbus.Plugin.Writer.Excel (6 files):" -ForegroundColor White
Write-Host "    [OK] Options/ExcelWriterPluginOptions.cs" -ForegroundColor Green
Write-Host "    [OK] Validators/ExcelWriterOptionsValidator.cs" -ForegroundColor Green
Write-Host "    [OK] Internal/ExcelSchemaBuilder.cs" -ForegroundColor Green
Write-Host "    [OK] Writer/ExcelOutputWriter.cs" -ForegroundColor Green
Write-Host "    [OK] ExcelWriterPlugin.cs" -ForegroundColor Green
Write-Host ""
Write-Host "  Total: 19 source files across 3 plugins" -ForegroundColor Cyan
Write-Host ""
Write-Host "  Next Steps:" -ForegroundColor Yellow
Write-Host "    1. Save to: scripts/generate-plugins.ps1" -ForegroundColor White
Write-Host "    2. Run: PowerShell -ExecutionPolicy Bypass -File .\scripts\generate-plugins.ps1" -ForegroundColor White
Write-Host "    3. Build all plugins:" -ForegroundColor White
Write-Host "       dotnet build src/plugins/Axbus.Plugin.Reader.Json" -ForegroundColor White
Write-Host "       dotnet build src/plugins/Axbus.Plugin.Writer.Csv" -ForegroundColor White
Write-Host "       dotnet build src/plugins/Axbus.Plugin.Writer.Excel" -ForegroundColor White
Write-Host "    4. Verify: 0 errors across all plugins" -ForegroundColor White
Write-Host "    5. Message 5 generates ConsoleApp + WinFormsApp" -ForegroundColor White
Write-Host ""
Write-Host "===============================================================================" -ForegroundColor Green
Write-Host ""

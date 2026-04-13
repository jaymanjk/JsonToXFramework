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
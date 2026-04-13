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
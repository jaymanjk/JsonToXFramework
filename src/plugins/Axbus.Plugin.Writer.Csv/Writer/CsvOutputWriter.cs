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
    /// This constructor is internal and only called by <see cref="CsvWriterPlugin"/>.
    /// </summary>
    /// <param name="logger">The logger for writer operations.</param>
    /// <param name="pluginOptions">The CSV-specific plugin options.</param>
    /// <param name="schemaBuilder">The internal schema builder for column discovery.</param>
    internal CsvOutputWriter(
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

        // Create StreamWriter with async I/O for CSV output
        var writer = new StreamWriter(outputPath, append: false, encoding);
        await using (writer.ConfigureAwait(false))
        {
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
        } // Close await using for main writer

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

            // Create StreamWriter with async I/O for error CSV output
            var errorWriter = new StreamWriter(errorPath, append: false, encoding);
            await using (errorWriter.ConfigureAwait(false))
            {
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
            } // Close await using for error writer

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
            // Note: Contains(char) has no StringComparison overload - char comparison is always ordinal
#pragma warning disable CA1307 // Specify StringComparison for clarity
            var needsQuoting = value.Contains(delimiter) ||
                               value.Contains('"') ||
                               value.Contains('\n') ||
                               value.Contains('\r');
#pragma warning restore CA1307

            if (needsQuoting)
            {
                builder.Append('"');
                builder.Append(value.Replace("\"", "\"\"", StringComparison.Ordinal));
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

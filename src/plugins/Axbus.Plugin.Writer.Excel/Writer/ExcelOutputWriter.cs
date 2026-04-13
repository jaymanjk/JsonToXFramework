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
    /// This constructor is internal and only called by <see cref="ExcelWriterPlugin"/>.
    /// </summary>
    /// <param name="logger">The logger for writer operations.</param>
    /// <param name="pluginOptions">The Excel-specific plugin options.</param>
    /// <param name="schemaBuilder">The internal schema builder for column discovery.</param>
    internal ExcelOutputWriter(
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

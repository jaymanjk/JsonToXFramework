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
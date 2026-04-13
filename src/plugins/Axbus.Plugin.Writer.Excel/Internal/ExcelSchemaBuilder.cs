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
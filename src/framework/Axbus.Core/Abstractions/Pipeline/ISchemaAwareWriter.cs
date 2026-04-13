// <copyright file="ISchemaAwareWriter.cs" company="Axel Johnson International">
// Copyright (c) 2026 Axel Johnson International. All rights reserved.
// </copyright>

namespace Axbus.Core.Abstractions.Pipeline;

using Axbus.Core.Models.Pipeline;

/// <summary>
/// Optional capability interface implemented by writer plugins that need
/// to perform schema discovery before writing output. Schema building is
/// an internal writer concern and is not a public pipeline stage.
/// Writers that implement this interface are detected by the pipeline factory
/// and given the opportunity to build a schema before <see cref="IOutputWriter.WriteAsync"/>
/// is called.
/// </summary>
public interface ISchemaAwareWriter : IOutputWriter
{
    /// <summary>
    /// Discovers the output column schema by streaming through the transformed rows.
    /// This method is called by the pipeline factory before
    /// <see cref="IOutputWriter.WriteAsync"/> when
    /// <see cref="Axbus.Core.Enums.SchemaStrategy.FullScan"/> is configured.
    /// </summary>
    /// <param name="rows">
    /// The asynchronous stream of flattened rows to scan for column names.
    /// </param>
    /// <param name="cancellationToken">A token to cancel the schema build operation.</param>
    /// <returns>
    /// A <see cref="SchemaDefinition"/> containing the discovered column names
    /// in first-seen order.
    /// </returns>
    Task<SchemaDefinition> BuildSchemaAsync(
        IAsyncEnumerable<FlattenedRow> rows,
        CancellationToken cancellationToken);
}
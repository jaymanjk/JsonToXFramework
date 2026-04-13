// <copyright file="IOutputWriter.cs" company="Axel Johnson International">
// Copyright (c) 2026 Axel Johnson International. All rights reserved.
// </copyright>

namespace Axbus.Core.Abstractions.Pipeline;

using Axbus.Core.Models.Configuration;
using Axbus.Core.Models.Pipeline;

/// <summary>
/// Defines Stage 4 of the Axbus conversion pipeline.
/// Writes the transformed row stream to the target connector in the
/// appropriate output format. Implemented by writer plugins such as
/// <c>Axbus.Plugin.Writer.Csv</c> and <c>Axbus.Plugin.Writer.Excel</c>.
/// Writer plugins that perform schema discovery should also implement
/// <see cref="ISchemaAwareWriter"/>.
/// </summary>
public interface IOutputWriter
{
    /// <summary>
    /// Writes the rows from <paramref name="transformedData"/> to the target
    /// described by <paramref name="targetOptions"/> and returns a
    /// <see cref="WriteResult"/> with statistics about the write operation.
    /// </summary>
    /// <param name="transformedData">The flattened row stream produced by Stage 3 (Transform).</param>
    /// <param name="targetOptions">The target configuration describing where to write.</param>
    /// <param name="pipelineOptions">Pipeline options controlling null placeholders and error strategy.</param>
    /// <param name="cancellationToken">A token to cancel the write operation.</param>
    /// <returns>
    /// A <see cref="WriteResult"/> containing row counts, output paths and duration.
    /// </returns>
    /// <exception cref="Axbus.Core.Exceptions.AxbusPipelineException">
    /// Thrown when a write failure occurs that cannot be handled by the configured row error strategy.
    /// </exception>
    Task<WriteResult> WriteAsync(
        TransformedData transformedData,
        TargetOptions targetOptions,
        PipelineOptions pipelineOptions,
        CancellationToken cancellationToken);
}
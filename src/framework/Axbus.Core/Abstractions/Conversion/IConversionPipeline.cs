// <copyright file="IConversionPipeline.cs" company="Axel Johnson International">
// Copyright (c) 2026 Axel Johnson International. All rights reserved.
// </copyright>

namespace Axbus.Core.Abstractions.Conversion;

using Axbus.Core.Models.Configuration;
using Axbus.Core.Models.Pipeline;

/// <summary>
/// Orchestrates the execution of all pipeline stages for a single source file
/// within a conversion module. Assembles the stage chain
/// (Read -> Parse -> Transform -> Write) and wraps each stage in the
/// configured middleware. One pipeline instance is created per conversion module.
/// </summary>
public interface IConversionPipeline
{
    /// <summary>
    /// Executes the full pipeline for the source file at <paramref name="sourcePath"/>
    /// within the context of the specified <paramref name="module"/> configuration.
    /// Returns a <see cref="WriteResult"/> with statistics about the completed write.
    /// </summary>
    /// <param name="module">The conversion module configuration to use.</param>
    /// <param name="sourcePath">The full path or URI of the source file to process.</param>
    /// <param name="cancellationToken">A token to cancel the pipeline execution.</param>
    /// <returns>A <see cref="WriteResult"/> containing row counts and output paths.</returns>
    /// <exception cref="Axbus.Core.Exceptions.AxbusPipelineException">
    /// Thrown when a stage fails and the error cannot be handled by the configured strategy.
    /// </exception>
    Task<WriteResult> ExecuteAsync(
        ConversionModule module,
        string sourcePath,
        CancellationToken cancellationToken);
}
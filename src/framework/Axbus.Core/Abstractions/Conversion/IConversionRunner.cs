// <copyright file="IConversionRunner.cs" company="Axel Johnson International">
// Copyright (c) 2026 Axel Johnson International. All rights reserved.
// </copyright>

namespace Axbus.Core.Abstractions.Conversion;

using Axbus.Core.Models.Notifications;
using Axbus.Core.Models.Results;

/// <summary>
/// Orchestrates the execution of all enabled conversion modules defined in
/// <see cref="Axbus.Core.Models.Configuration.AxbusRootSettings.ConversionModules"/>.
/// Handles sequential and parallel execution, progress reporting and event publishing.
/// The primary entry point for both the ConsoleApp and WinFormsApp clients.
/// </summary>
public interface IConversionRunner
{
    /// <summary>
    /// Executes all enabled conversion modules and returns a
    /// <see cref="ConversionSummary"/> with aggregated results.
    /// Modules are executed sequentially or in parallel based on the
    /// root and module-level <c>RunInParallel</c> configuration.
    /// </summary>
    /// <param name="progress">
    /// An optional progress reporter. When provided, the runner reports
    /// <see cref="ConversionProgress"/> updates as each file and row is processed.
    /// Safe to pass <c>null</c> when progress reporting is not needed.
    /// </param>
    /// <param name="cancellationToken">
    /// A token to cancel the entire run. When cancelled, the current module
    /// completes its current file and then stops.
    /// </param>
    /// <returns>
    /// A <see cref="ConversionSummary"/> containing per-module results
    /// and aggregated statistics for the entire run.
    /// </returns>
    Task<ConversionSummary> RunAsync(
        IProgress<ConversionProgress>? progress = null,
        CancellationToken cancellationToken = default);
}
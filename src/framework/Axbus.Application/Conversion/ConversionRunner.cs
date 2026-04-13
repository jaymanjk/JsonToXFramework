// <copyright file="ConversionRunner.cs" company="Axel Johnson International">
// Copyright (c) 2026 Axel Johnson International. All rights reserved.
// </copyright>

namespace Axbus.Application.Conversion;

using System.Diagnostics;
using Axbus.Core.Abstractions.Conversion;
using Axbus.Core.Abstractions.Factories;
using Axbus.Core.Abstractions.Notifications;
using Axbus.Core.Enums;
using Axbus.Core.Exceptions;
using Axbus.Core.Models.Configuration;
using Axbus.Core.Models.Notifications;
using Axbus.Core.Models.Pipeline;
using Axbus.Core.Models.Results;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;

/// <summary>
/// Orchestrates the execution of all enabled conversion modules defined in
/// <see cref="AxbusRootSettings.ConversionModules"/>. Handles sequential and
/// parallel execution, progress reporting, event publishing and result aggregation.
/// This is the primary entry point called by both the ConsoleApp and WinFormsApp.
/// </summary>
public sealed class ConversionRunner : IConversionRunner
{
    /// <summary>
    /// Logger instance for structured runner lifecycle messages.
    /// </summary>
    private readonly ILogger<ConversionRunner> logger;

    /// <summary>
    /// Factory for creating conversion pipelines per module.
    /// </summary>
    private readonly IPipelineFactory pipelineFactory;

    /// <summary>
    /// Publisher for lifecycle event notifications.
    /// </summary>
    private readonly IEventPublisher eventPublisher;

    /// <summary>
    /// Reporter for percentage progress notifications.
    /// </summary>
    private readonly IProgressReporter progressReporter;

    /// <summary>
    /// Root settings containing module list and parallelism configuration.
    /// </summary>
    private readonly AxbusRootSettings settings;

    /// <summary>
    /// Initializes a new instance of <see cref="ConversionRunner"/>.
    /// </summary>
    /// <param name="logger">Logger for runner lifecycle messages.</param>
    /// <param name="pipelineFactory">Factory that creates pipelines per module.</param>
    /// <param name="eventPublisher">Publisher for observable event notifications.</param>
    /// <param name="progressReporter">Reporter for IProgress progress notifications.</param>
    /// <param name="options">Root Axbus settings bound from configuration.</param>
    public ConversionRunner(
        ILogger<ConversionRunner> logger,
        IPipelineFactory pipelineFactory,
        IEventPublisher eventPublisher,
        IProgressReporter progressReporter,
        IOptions<AxbusRootSettings> options)
    {
        this.logger = logger;
        this.pipelineFactory = pipelineFactory;
        this.eventPublisher = eventPublisher;
        this.progressReporter = progressReporter;
        this.settings = options.Value;
    }

    /// <summary>
    /// Executes all enabled conversion modules and returns a
    /// <see cref="ConversionSummary"/> with aggregated results.
    /// </summary>
    /// <param name="progress">Optional progress reporter for UI feedback.</param>
    /// <param name="cancellationToken">Token to cancel the run.</param>
    /// <returns>A <see cref="ConversionSummary"/> with per-module results.</returns>
    public async Task<ConversionSummary> RunAsync(
        IProgress<ConversionProgress>? progress = null,
        CancellationToken cancellationToken = default)
    {
        // Register external progress consumer if provided
        if (progress != null)
        {
            progressReporter.Register(progress);
        }

        // Filter and order enabled modules
        var enabledModules = settings.ConversionModules
            .Where(m => m.IsEnabled)
            .OrderBy(m => m.ExecutionOrder)
            .ToList();

        var skippedModules = settings.ConversionModules
            .Where(m => !m.IsEnabled)
            .ToList();

        logger.LogInformation(
            "Conversion run starting | Enabled: {Enabled} | Skipped: {Skipped}",
            enabledModules.Count,
            skippedModules.Count);

        // Publish skipped module events
        foreach (var skipped in skippedModules)
        {
            Publish(skipped.ConversionName, ConversionEventType.ModuleSkipped,
                $"Module '{skipped.ConversionName}' is disabled and will be skipped.");
        }

        var stopwatch = Stopwatch.StartNew();
        var moduleResults = new List<ModuleResult>();

        // Determine whether to run in parallel
        // Root RunInParallel=false is the master safety switch - overrides all module flags
        var rootParallel = settings.RunInParallel;

        if (rootParallel == false)
        {
            // Sequential execution - root safety switch is active
            foreach (var module in enabledModules)
            {
                cancellationToken.ThrowIfCancellationRequested();
                var result = await ExecuteModuleAsync(module, cancellationToken).ConfigureAwait(false);
                moduleResults.Add(result);
            }
        }
        else
        {
            // Root is null or true - respect individual module RunInParallel flags
            var parallelModules = enabledModules.Where(m => m.RunInParallel).ToList();
            var sequentialModules = enabledModules.Where(m => !m.RunInParallel).ToList();

            // Run sequential modules first in order
            foreach (var module in sequentialModules)
            {
                cancellationToken.ThrowIfCancellationRequested();
                var result = await ExecuteModuleAsync(module, cancellationToken).ConfigureAwait(false);
                moduleResults.Add(result);
            }

            // Run parallel modules concurrently with throttling
            if (parallelModules.Count > 0)
            {
                var maxDegree = settings.ParallelSettings.MaxDegreeOfParallelism;
                var semaphore = new SemaphoreSlim(maxDegree);
                var parallelTasks = parallelModules.Select(async module =>
                {
                    await semaphore.WaitAsync(cancellationToken).ConfigureAwait(false);
                    try
                    {
                        return await ExecuteModuleAsync(module, cancellationToken).ConfigureAwait(false);
                    }
                    finally
                    {
                        semaphore.Release();
                    }
                });

                var parallelResults = await Task.WhenAll(parallelTasks).ConfigureAwait(false);
                moduleResults.AddRange(parallelResults);
            }
        }

        stopwatch.Stop();

        // Build and return summary
        var summary = BuildSummary(moduleResults, skippedModules.Count, stopwatch.Elapsed);

        logger.LogInformation(
            "Conversion run complete | Duration: {Duration}ms | Success: {Success} | Failed: {Failed}",
            stopwatch.ElapsedMilliseconds,
            summary.SuccessfulModules,
            summary.FailedModules);

        eventPublisher.Complete();

        return summary;
    }

    /// <summary>
    /// Executes a single conversion module and returns its result.
    /// Handles ContinueOnError logic and publishes lifecycle events.
    /// </summary>
    /// <param name="module">The module to execute.</param>
    /// <param name="cancellationToken">Token to cancel execution.</param>
    /// <returns>A <see cref="ModuleResult"/> for the executed module.</returns>
    private async Task<ModuleResult> ExecuteModuleAsync(
        ConversionModule module,
        CancellationToken cancellationToken)
    {
        var stopwatch = Stopwatch.StartNew();

        logger.LogInformation(
            "Module starting: {ModuleName}",
            module.ConversionName);

        Publish(module.ConversionName, ConversionEventType.ModuleStarted,
            $"Module '{module.ConversionName}' started.");

        var result = new ModuleResult
        {
            ModuleName = module.ConversionName,
            Status = ConversionStatus.Converting,
        };

        try
        {
            // Create pipeline for this module
            var pipeline = pipelineFactory.Create(module);

            // Report discovering status
            progressReporter.Report(new ConversionProgress
            {
                ModuleName = module.ConversionName,
                Status = ConversionStatus.Discovering,
                PercentComplete = 0,
            });

            // Get list of source files from source path
            // For now, treat single file execution - full file enumeration
            // is handled by the infrastructure layer connectors
            var writeResult = await pipeline.ExecuteAsync(
                module,
                module.Source.Path,
                cancellationToken).ConfigureAwait(false);

            result.FilesProcessed = 1;
            result.RowsWritten = writeResult.RowsWritten;
            result.ErrorRowsWritten = writeResult.ErrorRowsWritten;
            result.OutputFilePath = writeResult.OutputPath;
            result.ErrorFilePath = writeResult.ErrorFilePath;
            result.Status = ConversionStatus.Completed;

            if (!string.IsNullOrEmpty(writeResult.OutputPath))
            {
                result.OutputFiles.Add(writeResult.OutputPath);
            }

            Publish(module.ConversionName, ConversionEventType.ModuleCompleted,
                $"Module '{module.ConversionName}' completed. Rows written: {result.RowsWritten}");

            logger.LogInformation(
                "Module completed: {ModuleName} | Rows: {Rows} | ErrorRows: {ErrorRows}",
                module.ConversionName,
                result.RowsWritten,
                result.ErrorRowsWritten);
        }
        catch (OperationCanceledException)
        {
            // Always propagate cancellation
            throw;
        }
        catch (Exception ex)
        {
            result.Status = ConversionStatus.Failed;
            result.Errors.Add(ex.Message);

            logger.LogError(
                ex,
                "Module failed: {ModuleName}",
                module.ConversionName);

            Publish(module.ConversionName, ConversionEventType.ModuleFailed,
                $"Module '{module.ConversionName}' failed: {ex.Message}",
                exception: ex);

            if (!module.ContinueOnError)
            {
                throw new AxbusPipelineException(
                    $"Module '{module.ConversionName}' failed and ContinueOnError is false.",
                    ex);
            }
        }
        finally
        {
            stopwatch.Stop();
            result.Duration = stopwatch.Elapsed;

            // Report final progress for this module
            progressReporter.Report(new ConversionProgress
            {
                ModuleName = module.ConversionName,
                Status = result.Status,
                PercentComplete = 100,
            });
        }

        return result;
    }

    /// <summary>
    /// Publishes a <see cref="ConversionEvent"/> to the event stream.
    /// </summary>
    /// <param name="moduleName">The name of the module raising the event.</param>
    /// <param name="eventType">The type of lifecycle event.</param>
    /// <param name="message">A human-readable event message.</param>
    /// <param name="fileName">Optional file name associated with the event.</param>
    /// <param name="exception">Optional exception associated with a failure event.</param>
    private void Publish(
        string moduleName,
        ConversionEventType eventType,
        string message,
        string? fileName = null,
        Exception? exception = null)
    {
        eventPublisher.Publish(new ConversionEvent
        {
            ModuleName = moduleName,
            Type = eventType,
            Message = message,
            FileName = fileName,
            Exception = exception,
        });
    }

    /// <summary>
    /// Builds the <see cref="ConversionSummary"/> from individual module results.
    /// </summary>
    /// <param name="results">The list of module results to aggregate.</param>
    /// <param name="skippedCount">The number of modules that were skipped.</param>
    /// <param name="totalDuration">The total elapsed time for the run.</param>
    /// <returns>A populated <see cref="ConversionSummary"/>.</returns>
    private static ConversionSummary BuildSummary(
        List<ModuleResult> results,
        int skippedCount,
        TimeSpan totalDuration)
    {
        return new ConversionSummary
        {
            TotalModules = results.Count + skippedCount,
            SuccessfulModules = results.Count(r => r.Status == ConversionStatus.Completed),
            FailedModules = results.Count(r => r.Status == ConversionStatus.Failed),
            SkippedModules = skippedCount,
            TotalFilesProcessed = results.Sum(r => r.FilesProcessed),
            TotalRowsWritten = results.Sum(r => r.RowsWritten),
            TotalErrorRows = results.Sum(r => r.ErrorRowsWritten),
            TotalDuration = totalDuration,
            Results = results,
        };
    }
}